//
//  CMChunkedDownloadRequest.m
//  Cumulus
//
//  Created by John Clayton on 5/29/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMChunkedDownloadRequest.h"

#import "CMRequest+Protected.h"
#import "CMDownloadRequest.h"
#import "Cumulus.h"

#define kCMChunkedDownloadRequestMinUpdateInterval 0.5


@interface CMDownloadChunk : NSObject
@property (nonatomic) NSUInteger sequence;
@property (nonatomic) long long size;
@property (nonatomic, strong) CMRequest *request;
@property (nonatomic, strong) CMResponse *response;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSURL *file;
@property (nonatomic) long long fileOffset;
@end
@implementation CMDownloadChunk
@end


@interface CMChunkedDownloadRequest () {
	dispatch_semaphore_t _chunksSemaphore;
}
@property BOOL sentInitialProgress;
@property (strong) NSDate *lastProgressUpdateSentAt;
@property (readonly) NSTimeInterval timeSinceLastProgressUpdate;
@property (nonatomic) long long expectedAggregatedContentLength;
@property long long receivedAggregatedContentLength;
@property (readonly) long long totalAggregatedContentLength;
@property long long assembledAggregatedContentLength;
@property (nonatomic, strong) NSURLRequest *baseChunkRequest;
@property (copy) NSURL *downloadedFileTempURL;
@property (copy) NSString *downloadedFilename;
@property (nonatomic, strong) NSURL *chunksDirURL;

@property (readonly, getter = isDownloadingChunks) BOOL downloadingChunks;
@property (strong) NSMutableSet *waitingChunks;
@property (strong) NSMutableSet *runningChunks;
@property (strong) NSMutableSet *completedChunks;
@property (strong) NSMutableSet *allChunks;
@property (nonatomic, readonly) NSSet *chunkErrors;
@end

@implementation CMChunkedDownloadRequest

// ========================================================================== //

#pragma mark - Properties

- (NSTimeInterval) timeSinceLastProgressUpdate {
	if (nil == _lastProgressUpdateSentAt) {
		return 0;
	}
	NSTimeInterval interval = fabs([_lastProgressUpdateSentAt timeIntervalSinceNow]);
	return interval;
}

- (long long) totalAggregatedContentLength {
	__block long long totalAggregatedContentLength = 0;
	[_allChunks enumerateObjectsUsingBlock:^(CMDownloadChunk *chunk, BOOL *stop) {
//		RCLog(@"** totalAggregatedContentLength: %lld",totalAggregatedContentLength);
//		RCLog(@"** chunk.fileOffset: %lld",chunk.fileOffset);
		totalAggregatedContentLength += chunk.fileOffset;
	}];
	return totalAggregatedContentLength;
}

- (NSSet *) chunkErrors {
	return [_completedChunks valueForKey:@"error"];
}

@dynamic downloadingChunks;
- (BOOL) isDownloadingChunks {
	dispatch_semaphore_wait(_chunksSemaphore, DISPATCH_TIME_FOREVER);
	NSUInteger waitingCount = self.waitingChunks.count;
	NSUInteger runningCount = self.runningChunks.count;
	dispatch_semaphore_signal(_chunksSemaphore);
	return (waitingCount > 0 || runningCount > 0);
}

@dynamic bytesPerSecond;
- (NSUInteger) bytesPerSecond {
	NSUInteger bytesPerSecond = 0;
	NSTimeInterval elapsed = self.elapsed;
	if (elapsed > 0) {
		long long receivedBytes = self.receivedAggregatedContentLength;
		bytesPerSecond = receivedBytes/elapsed;
	}
	return bytesPerSecond;
}

@dynamic completed;
- (BOOL) didComplete {
	return self.expectedAggregatedContentLength == self.assembledAggregatedContentLength;
}

- (CMProgressInfo *) progressReceivedInfo {
	CMProgressInfo *progressReceivedInfo = [super progressReceivedInfo];
	progressReceivedInfo.tempFileURL = self.downloadedFileTempURL;
	progressReceivedInfo.tempDirURL = self.chunksDirURL;
	progressReceivedInfo.chunkSize = @(self.lastChunkSize);
	float progress = 0;
	long long totalAggregatedContentLength = 0;
	if (self.expectedAggregatedContentLength > 0) {
		totalAggregatedContentLength = self.totalAggregatedContentLength;
		progress = (float)totalAggregatedContentLength / (float)self.expectedAggregatedContentLength;
	}
	progressReceivedInfo.progress = @(progress);
	progressReceivedInfo.fileOffset = @(totalAggregatedContentLength);
	
	return progressReceivedInfo;
}



// ========================================================================== //

#pragma mark - Object

- (void)dealloc {
    dispatch_release(_chunksSemaphore);
}


- (id)initWithURLRequest:(NSURLRequest *)URLRequest {
    self = [super initWithURLRequest:URLRequest];
    if (self) {
		_maxConcurrentChunks = kCMChunkedDownloadRequestDefaultMaxConcurrentChunks;
		_chunkSize = 0;
		_waitingChunks = [NSMutableSet new];
		_runningChunks = [NSMutableSet new];
		_completedChunks = [NSMutableSet new];
		_allChunks = [NSMutableSet new];
		_chunksSemaphore = dispatch_semaphore_create(1);
		_readBufferLength = kCMChunkedDownloadRequestDefaultBufferSize;
    }
    return self;
}


// ========================================================================== //

#pragma mark - CMRequest


- (void) cancel {
	dispatch_semaphore_wait(_chunksSemaphore, DISPATCH_TIME_FOREVER);
	[_allChunks enumerateObjectsUsingBlock:^(CMDownloadChunk *chunk, BOOL *stop) {
		[chunk.request cancel];
	}];
	dispatch_semaphore_signal(_chunksSemaphore);
	[super cancel];
}

- (void) handleConnectionWillStart {
	NSAssert(self.URLRequest.HTTPMethod = kCumulusHTTPMethodHEAD, @"Chunked downloads need to start with a HEAD request!");
	NSAssert(self.cachesDir && self.cachesDir.length, @"Attempted a download without setting cachesDir!");
	NSFileManager *fm = [NSFileManager new];
	if (NO == [fm fileExistsAtPath:self.cachesDir]) {
		NSError *error = nil;
		if (NO == [fm createDirectoryAtPath:self.cachesDir withIntermediateDirectories:YES attributes:nil error:&error]) {
			RCLog(@"Could not create cachesDir: %@ %@ (%@)", self.cachesDir, [error localizedDescription], [error userInfo]);
		}
	}
		
	
	CMDownloadInfo *downloadInfo = [CMDownloadInfo downloadInfoForCacheIdentifier:self.cacheIdentifier];
	NSURL *tempFileURL = downloadInfo.downloadedFileTempURL;
	if (tempFileURL) {
		self.downloadedFileTempURL = tempFileURL;
	}
	else {
		CFUUIDRef UUID = CFUUIDCreate(NULL);
		NSString *tempFilename = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, UUID);
		CFRelease(UUID);
		
		NSString *filePath = [self.cachesDir stringByAppendingPathComponent:tempFilename];
		self.downloadedFileTempURL = [NSURL fileURLWithPath:filePath];
		
		downloadInfo.downloadedFileTempURL = self.downloadedFileTempURL;
		// Record addition info for possible future resumes
		downloadInfo.totalContentLength = self.responseInternal.totalContentLength;

		NSDictionary *responseHeaders = [self.URLResponse allHeaderFields];
		downloadInfo.ETag = [responseHeaders valueForKey:kCumulusHTTPHeaderETag];
		downloadInfo.lastModifiedDate = [responseHeaders valueForKey:kCumulusHTTPHeaderLastModified];
		
		[CMDownloadInfo saveDownloadInfo];
	}
	
	_chunksDirURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@-%@",[self.downloadedFileTempURL path],@"chunks"] isDirectory:YES];
	if (NO == [fm fileExistsAtPath:[_chunksDirURL path]]) {
		NSError *error = nil;
		if (NO == [fm createDirectoryAtPath:[_chunksDirURL path] withIntermediateDirectories:YES attributes:nil error:&error]) {
			RCLog(@"Could not create chunks dir: %@ %@ (%@)", _chunksDirURL, [error localizedDescription], [error userInfo]);
		}
	}
}

- (void) handleConnectionDidReceiveData {
	if (NO == _sentInitialProgress) {
		_sentInitialProgress = YES;
		_lastProgressUpdateSentAt = [NSDate date];
		[super handleConnectionDidReceiveData];
	}
	// do nothing here, see #reallyHandleConnectionDidReceiveData which is called when chunk requests get data
}

/// All we do here is set up for requesting chunks, see #reallyHandleConnectionFinished which gets called when all chunks are done, including when they are canceled
- (void) handleConnectionFinished {
	// Since we override super, we must check for cancelation ourselves
	if (self.canceled) {
		return;
	}

	// If we failed to get a good response from the initial HEAD request, go no further
	if (self.responseInternal.wasUnsuccessful) {
		[self reallyHandleConnectionFinished];
		return;
	}
	
	// If we got a zero content length we are done
	self.expectedAggregatedContentLength = self.responseInternal.expectedContentLength;
	if (self.expectedAggregatedContentLength < 1LL) {
		[self reallyHandleConnectionFinished];
		return;
	}
	
	// Ok, good to request chunks	
	NSMutableURLRequest *baseChunkRequest = [self.originalURLRequest mutableCopy];
	baseChunkRequest.HTTPMethod = kCumulusHTTPMethodGET;
	_baseChunkRequest = baseChunkRequest;
	
	if (_chunkSize == 0) {
		if (_maxConcurrentChunks > 0) {
			long long bytesRangeLength = (self.expectedAggregatedContentLength+1);// remember, byte ranges are zero indexed
			_chunkSize = bytesRangeLength/(long long)_maxConcurrentChunks;
		}
		else {
			_chunkSize = kCMChunkedDownloadRequestDefaultChunkSize;
		}
	}
	
	NSUInteger idx = 0;
	for (long long i = 0; i < self.expectedContentLength; i+=_chunkSize) {
		long long len = _chunkSize;
		if (i+len > self.expectedAggregatedContentLength) {
			len = self.expectedAggregatedContentLength - i;
		}
		CMContentRange range = CMContentRangeMake(i, len, 0);
		[self startChunkForRange:range sequence:idx++];
	}
	
	//???: What if all the chunks were actually done?
}

- (void) startChunkForRange:(CMContentRange)range sequence:(NSUInteger)idx {
	RCLog(@"%@.startChunkForRange:%@ sequence:%@",self.URL,[NSString stringWithFormat:@"(%lld,%lld)",range.location,range.length],@(idx));
	CMDownloadChunk *chunk = [CMDownloadChunk new];
	chunk.sequence = idx;
	chunk.size = range.length;
	
	// Check if the chunk is complete before starting a request
	NSFileManager *fm = [NSFileManager new];
	NSURL *completedChunkURL = [self completedChunkFileURLForRange:range];
	if ([fm fileExistsAtPath:[completedChunkURL path]]) {
		RCLog(@"Found completed chunk: %@",completedChunkURL);
		chunk.file = completedChunkURL;
		chunk.fileOffset = chunk.size;
		dispatch_semaphore_wait(_chunksSemaphore, DISPATCH_TIME_FOREVER);
		[_completedChunks addObject:chunk];
		[_allChunks addObject:chunk];
		dispatch_semaphore_signal(_chunksSemaphore);
	}
	else {
		CMDownloadRequest *chunkRequest = [[CMDownloadRequest alloc] initWithURLRequest:_baseChunkRequest];
		chunk.request = chunkRequest;
		
		chunkRequest.timeout = self.timeout;
		[chunkRequest.authProviders addObjectsFromArray:self.authProviders];
		chunkRequest.cachePolicy = self.cachePolicy;
		[chunkRequest.headers addEntriesFromDictionary:self.headers];
//		chunkRequest.cachesDir = self.cachesDir;
		chunkRequest.cachesDir = [self.chunksDirURL path];
		chunkRequest.range = range;
		chunkRequest.shouldResume = YES;
		
		__weak typeof(self) self_ = self;
		__weak typeof(chunk) chunk_ = chunk;
		chunkRequest.didReceiveDataBlock = ^(CMProgressInfo *progressInfo) {
			long long chunkSize = [progressInfo.chunkSize longLongValue];
			self_.receivedAggregatedContentLength += chunkSize;
			chunk_.fileOffset = [progressInfo.fileOffset longLongValue];
			if (chunkSize > 0LL) {
				[self_ setLastChunkSize:chunkSize];
				[self_ reallyHandleConnectionDidReceiveData];
			}
		};
		chunkRequest.completionBlock = ^(CMResponse *response) {
			dispatch_semaphore_wait(_chunksSemaphore, DISPATCH_TIME_FOREVER);
			[self_.completedChunks addObject:chunk_];
			[self_.runningChunks removeObject:chunk_];
			dispatch_semaphore_signal(_chunksSemaphore);
			
			
			chunk_.response = response;
			chunk_.request = nil;
			
			CMProgressInfo *result = response.result;
			
			if (response.error) {
				chunk_.error = response.error;
			}
			else if (result.tempFileURL && NO == self.wasCanceled) {
				CMProgressInfo *result = response.result;
				NSURL *chunkTempURL = result.tempFileURL;
//				CMContentRange range = response.request.range;
				NSURL *chunkNewURL = [self completedChunkFileURLForRange:range];//[_chunksDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@,bytes=%lld-%lld",[chunkTempURL lastPathComponent],range.location,CMContentRangeLastByte(range)]];
				
				if (nil == self.downloadedFilename) {
					self.downloadedFilename = result.filename;
				}
				
				NSFileManager *fm = [NSFileManager new];
				
				NSError *moveError = nil;
				if (NO == [fm moveItemAtURL:chunkTempURL toURL:chunkNewURL error:&moveError]) {
					RCLog(@"Error moving completed chunk into place! %@ (%@)",[moveError localizedDescription],[moveError userInfo]);
					chunk_.error = moveError;
				}
				else {
					chunk_.file = chunkNewURL;
				}
			}
			if (NO == self_.isDownloadingChunks) {
				[self_ reallyHandleConnectionFinished];
			}
			else {
				[self_ dispatchNextChunk];
			}
		};
		dispatch_semaphore_wait(_chunksSemaphore, DISPATCH_TIME_FOREVER);
		[_waitingChunks addObject:chunk];
		[_allChunks addObject:chunk];
		dispatch_semaphore_signal(_chunksSemaphore);
		[self dispatchNextChunk];
	}
}

- (NSURL *) completedChunkFileURLForRange:(CMContentRange)range {
	NSURL *completedChunkURL = [_chunksDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@,bytes=%lld-%lld",[self.downloadedFileTempURL lastPathComponent],range.location,CMContentRangeLastByte(range)]];
	return completedChunkURL;
}

- (void) dispatchNextChunk {
	dispatch_semaphore_wait(_chunksSemaphore, DISPATCH_TIME_FOREVER);
	NSUInteger runningChunkCount = self.runningChunks.count;
	RCLog(@"Current chunk workers: %@",@(runningChunkCount));
	if (runningChunkCount < self.maxConcurrentChunks) {
		CMDownloadChunk *nextChunk = [self.waitingChunks anyObject];
		if (nextChunk) {
			[self.runningChunks addObject:nextChunk];
			[self.waitingChunks removeObject:nextChunk];
			[nextChunk.request start];
			RCLog(@"Launched chunk request: %@",nextChunk.request);
		}
	}
	dispatch_semaphore_signal(_chunksSemaphore);
}


// ========================================================================== //

#pragma mark - Oh Really? Handlers :)



- (void) reallyHandleConnectionFinished {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		if (self.chunkErrors.count < 1 && NO == self.wasCanceled) {
			
			dispatch_semaphore_wait(_chunksSemaphore, DISPATCH_TIME_FOREVER);
			NSArray *sortedChunks = [_completedChunks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES]]];
			dispatch_semaphore_signal(_chunksSemaphore);

			NSFileManager *fm = [NSFileManager new];
			if ([fm createFileAtPath:[self.downloadedFileTempURL path] contents:nil attributes:nil]) {
				@autoreleasepool {
					NSError *writeError = nil;
					NSFileHandle *outHandle = [NSFileHandle fileHandleForWritingToURL:self.downloadedFileTempURL error:&writeError];
					if (outHandle) {
						[sortedChunks enumerateObjectsUsingBlock:^(CMDownloadChunk *chunk, NSUInteger idx, BOOL *stop) {
							NSAssert(idx == chunk.sequence, @"Chunks must be sequential");
							if (idx != chunk.sequence) {
								*stop = YES;
								NSDictionary *info = @{ NSLocalizedDescriptionKey : @"Chunk order not sane" };
								self.error = [NSError errorWithDomain:kCumulusErrorDomain code:kCumulusErrorCodeErrorOutOfOrderChunks userInfo:info];
								RCLog(info[NSLocalizedDescriptionKey]);
								return;
							}
							NSError *readError = nil;
							long long movedChunkDataLength = 0;
							@autoreleasepool {
//								NSUInteger readBufferLength = (1024*1024);
								NSFileHandle *chunkReadHandle = [NSFileHandle fileHandleForReadingFromURL:chunk.file error:&readError];
								if (chunkReadHandle) {
									NSData *readData = [chunkReadHandle readDataOfLength:_readBufferLength];
									NSUInteger length = [readData length];
									while ( length > 0 ) {
										@autoreleasepool {
											@try {
												[outHandle writeData:readData];
												movedChunkDataLength += length;
												self.assembledAggregatedContentLength += length;
												readData = [chunkReadHandle readDataOfLength:_readBufferLength];
												length = [readData length];
												if (length < 1) {
													RCLog(@"Read end of chunk: %@ assembled: %@",@(movedChunkDataLength),@(self.assembledAggregatedContentLength));
												}
											}
											@catch (NSException *exception) {
												*stop = YES;
												NSMutableDictionary *info = [NSMutableDictionary new];
												if ([exception reason]) {
													info[NSLocalizedDescriptionKey] = [exception reason];
												}
												if ([exception userInfo]) {
													[info addEntriesFromDictionary:[exception userInfo]];
												}
												NSError *readWriteError = [NSError errorWithDomain:kCumulusErrorDomain code:kCumulusErrorCodeErrorWritingToTempFile userInfo:info];
												self.error = readWriteError;
												RCLog(@"Error moving data from chunk to aggregate file: %@->%@ %@ (%@)", chunk.file, self.downloadedFileTempURL, [readWriteError localizedDescription], [readWriteError userInfo]);
												length = 0;
												return;
											}
										}
									}
									readData = nil;
									[chunkReadHandle closeFile];
									chunkReadHandle = nil;
								}
								else {
									*stop = YES;
									self.error = readError;
									RCLog(@"Could not create file handle to read chunk file: %@ %@ (%@)", chunk.file, [readError localizedDescription], [readError userInfo]);
									return;
								}
							}
							if (movedChunkDataLength != chunk.size) {
								*stop = YES;
								NSDictionary *info = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Actual chunk size did not match expected chunk size %@ != %@ (%@)",@(movedChunkDataLength), @(chunk.size),[chunk.file lastPathComponent]] };
								self.error = [NSError errorWithDomain:kCumulusErrorDomain code:kCumulusErrorCodeErrorMismatchedChunkSize userInfo:info];
								RCLog(info[NSLocalizedDescriptionKey]);
								RCLog(@"chunk.request.headers: %@",chunk.request.headers);
								RCLog(@"chunk.response.headers: %@",chunk.response.headers);
							}
						}];
						[outHandle closeFile];
						outHandle = nil;
					}
					else {
						self.error = writeError;
						RCLog(@"Could not create file handle to aggregated file: %@ %@ (%@)", self.downloadedFileTempURL, [writeError localizedDescription], [writeError userInfo]);
					}
				}
			}
			else {
				NSDictionary *info = @{ NSLocalizedDescriptionKey : @"Not able to create temporary file for chunked download" };
				self.error = [NSError errorWithDomain:kCumulusErrorDomain code:kCumulusErrorCodeErrorCreatingTempFile userInfo:info];
				RCLog(info[NSLocalizedDescriptionKey]);
			}
		}
		else if (self.chunkErrors.count > 0) {
			self.error = [self.chunkErrors anyObject];
		}
		
		self.receivedContentLength = self.assembledAggregatedContentLength;
		
		// Make sure that even though we are limiting the rate of these updates we send one last one
		[super handleConnectionDidReceiveData];

		CMProgressInfo *progressInfo = [CMProgressInfo new];
		progressInfo.progress = @(1.f);
		progressInfo.tempFileURL = self.downloadedFileTempURL;
		progressInfo.tempDirURL = self.chunksDirURL;
		progressInfo.URL = [self.URLRequest URL];
		progressInfo.filename = self.downloadedFilename;

		self.result = progressInfo;
		[super handleConnectionFinished];
		
		// even in the case of a pause we remove this file because we assemble at the end from chunks
		[self removeAggregateFile];
		// If we have merely canceled, leave chunk files in place so they can be resumed
		if (self.didComplete || (NO == self.wasCanceled && self.responseInternal.wasUnsuccessful && NO == self.responseInternal.shouldRetry)) {
			[self removeTempFiles];
			[CMDownloadInfo resetDownloadInfoForCacheIdentifier:self.cacheIdentifier];
			[CMDownloadInfo saveDownloadInfo];
		}
	});
}

- (void) removeAggregateFile {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		if ([fm fileExistsAtPath:[self.downloadedFileTempURL path]] && NO == [fm removeItemAtURL:self.downloadedFileTempURL error:&error]) {
			RCLog(@"Could not remove aggregate file: %@ %@ (%@)", self.downloadedFileTempURL, [error localizedDescription], [error userInfo]);
		}
	});
}

- (void) removeTempFiles {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		if ([fm fileExistsAtPath:[self.chunksDirURL path]] && NO == [fm removeItemAtURL:self.chunksDirURL error:&error]) {
			RCLog(@"Could not remove chunks dir: %@ %@ (%@)", self.chunksDirURL, [error localizedDescription], [error userInfo]);
		}
	});
}

- (void) reallyHandleConnectionDidReceiveData {
	// rate limit these updates since we can have multiple workers all hammering away we really don't need many updates per-second
	NSTimeInterval sinceLastUpdate = self.timeSinceLastProgressUpdate;
	if (sinceLastUpdate >= kCMChunkedDownloadRequestMinUpdateInterval) {
		_lastProgressUpdateSentAt = [NSDate date];
		[super handleConnectionDidReceiveData];
	}
}


@end
