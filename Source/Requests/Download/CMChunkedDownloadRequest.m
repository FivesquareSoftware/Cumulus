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

#define kCMChunkedDownloadRequestChunkSize (1024*1024)


@interface CMDownloadChunk : NSObject
@property (nonatomic) NSUInteger sequence;
@property (nonatomic) long long size;
@property (nonatomic, weak) CMRequest *request;
@property (nonatomic, strong) CMResponse *response;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSURL *file;
@end
@implementation CMDownloadChunk
@end


@interface CMChunkedDownloadRequest ()
@property BOOL sentInitialProgress;
@property (nonatomic) long long expectedAggregatedContentLength;
@property long long receivedAggregatedContentLength;
@property long long assembledAggregatedContentLength;
@property (nonatomic, strong) NSURLRequest *baseChunkRequest;
@property (copy) NSURL *downloadedFileTempURL;
@property (copy) NSString *downloadedFilename;
@property (nonatomic, strong) NSURL *chunksDirURL;

@property (nonatomic, strong) NSMutableSet *runningChunks;
@property (nonatomic, strong) NSMutableSet *completedChunks;
@property (nonatomic, readonly) NSSet *chunkErrors;
@end

@implementation CMChunkedDownloadRequest

// ========================================================================== //

#pragma mark - Properties

- (NSSet *) chunkErrors {
	return [_completedChunks valueForKey:@"error"];
}

@dynamic completed;
- (BOOL) didComplete {
	return self.expectedAggregatedContentLength == self.assembledAggregatedContentLength;
}



// ========================================================================== //

#pragma mark - CMRequest


- (void) cancel {
	[super cancel];
	[_runningChunks enumerateObjectsUsingBlock:^(CMDownloadChunk *chunk, BOOL *stop) {
		[chunk.request cancel];
	}];
}

- (CMProgressInfo *) progressReceivedInfo {
	CMProgressInfo *progressReceivedInfo = [CMProgressInfo new];
	progressReceivedInfo.request = self;
	progressReceivedInfo.URL = [self.URLRequest URL];
	progressReceivedInfo.tempFileURL = self.downloadedFileTempURL;
	progressReceivedInfo.chunkSize = @(self.lastChunkSize);
	float progress = 0;
	if (self.expectedAggregatedContentLength > 0) {
		progress = (float)self.receivedAggregatedContentLength / (float)self.expectedAggregatedContentLength;
		progressReceivedInfo.progress = @(progress);
	}
	else {
		progressReceivedInfo.progress = @(0);
	}
	return progressReceivedInfo;
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
	
	CFUUIDRef UUID = CFUUIDCreate(NULL);
	NSString *tempFilename = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, UUID);
	CFRelease(UUID);
	
	NSString *filePath = [self.cachesDir stringByAppendingPathComponent:tempFilename];
	self.downloadedFileTempURL = [NSURL fileURLWithPath:filePath];
	
	_chunksDirURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@-%@",[self.downloadedFileTempURL path],@"chunks"] isDirectory:YES];
	if (NO == [fm fileExistsAtPath:[_chunksDirURL path]]) {
		NSError *error = nil;
		if (NO == [fm createDirectoryAtPath:[_chunksDirURL path] withIntermediateDirectories:YES attributes:nil error:&error]) {
			RCLog(@"Could not create chunks dir: %@ %@ (%@)", _chunksDirURL, [error localizedDescription], [error userInfo]);
		}
	}
	
//	_chunks = [NSMutableArray new];
//	_chunkErrors = [NSMutableSet new];
//	_chunkFiles = [NSMutableArray new];
	
	
	_runningChunks = [NSMutableSet new];
	_completedChunks = [NSMutableSet new];
}

- (void) handleConnectionDidReceiveData {
	if (NO == _sentInitialProgress) {
		_sentInitialProgress = YES;
		[super handleConnectionDidReceiveData];
	}
	// do nothing here, see #reallyHandleConnectionDidReceiveData which is called when chunk requests get data
}

- (void) handleConnectionFinished {
	self.expectedAggregatedContentLength = self.expectedContentLength;
	if (self.expectedAggregatedContentLength < 1LL) {
		[self reallyHandleConnectionFinished];
		return;
	}
	
	NSMutableURLRequest *baseChunkRequest = [self.originalURLRequest mutableCopy];
	baseChunkRequest.HTTPMethod = kCumulusHTTPMethodGET;
	_baseChunkRequest = baseChunkRequest;
	
	NSUInteger idx = 0;
	for (long long i = 0; i < self.expectedContentLength; i+=kCMChunkedDownloadRequestChunkSize) {
		long long len = kCMChunkedDownloadRequestChunkSize;
		if (i+len > self.expectedAggregatedContentLength) {
			len = self.expectedAggregatedContentLength - i;
		}
		CMContentRange range = CMContentRangeMake(i, len, 0);
		[self startChunkForRange:range sequence:idx++];
	}
}

- (void) startChunkForRange:(CMContentRange)range sequence:(NSUInteger)idx {
	CMDownloadChunk *chunk = [CMDownloadChunk new];
	chunk.sequence = idx;
	chunk.size = range.length;

	
	CMDownloadRequest *chunkRequest = [[CMDownloadRequest alloc] initWithURLRequest:_baseChunkRequest];
	
	chunkRequest.timeout = self.timeout;
	[chunkRequest.authProviders addObjectsFromArray:self.authProviders];
	chunkRequest.cachePolicy = self.cachePolicy;
	[chunkRequest.headers addEntriesFromDictionary:self.headers];
	chunkRequest.cachesDir = self.cachesDir;
	chunkRequest.range = range;
	chunkRequest.shouldResume = YES;
	
	__weak typeof(self) self_ = self;
	chunkRequest.didReceiveDataBlock = ^(CMProgressInfo *progressInfo) {
		long long chunkSize = [progressInfo.chunkSize longLongValue];
		self_.receivedAggregatedContentLength += chunkSize;
		if (chunkSize > 0LL) {
			[self_ setLastChunkSize:chunkSize];
			[self_ reallyHandleConnectionDidReceiveData];
		}
	};
	chunkRequest.completionBlock = ^(CMResponse *response) {
		[self_.completedChunks addObject:chunk];
		[self_.runningChunks removeObject:chunk];
		chunk.response = response;
		
		if (response.error) {
			chunk.error = response.error;
		}
		else {
			CMProgressInfo *result = response.result;
			NSURL *chunkTempURL = result.tempFileURL;
			NSURL *chunkNewURL = [_chunksDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",@(idx),[chunkTempURL lastPathComponent]]];
			
			if (nil == self.downloadedFilename) {
				self.downloadedFilename = result.filename;
			}
			
			NSFileManager *fm = [NSFileManager new];
			
			NSError *moveError = nil;
			if (NO == [fm moveItemAtURL:chunkTempURL toURL:chunkNewURL error:&moveError]) {
				RCLog(@"Error moving completed chunk into place! %@ (%@)",[moveError localizedDescription],[moveError userInfo]);
				chunk.error = moveError;
			}
			else {
				chunk.file = chunkNewURL;
			}
		}
		if (self_.runningChunks.count < 1) {
			[self_ reallyHandleConnectionFinished];
		}
	};
	
	[_runningChunks addObject:chunk];
	[chunkRequest start];
	chunk.request = chunkRequest;
}


// ========================================================================== //

#pragma mark - Oh Really? Handlers :)



- (void) reallyHandleConnectionFinished {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		if (self.chunkErrors.count < 1) {
			
			NSArray *sortedChunks = [_completedChunks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES]]];
			
			NSFileManager *fm = [NSFileManager new];
			if ([fm createFileAtPath:[self.downloadedFileTempURL path] contents:nil attributes:nil]) {
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
						NSFileHandle *chunkReadHandle = [NSFileHandle fileHandleForReadingFromURL:chunk.file error:&readError];
						if (chunkReadHandle) {
							NSData *readData = nil;
							while ( [(readData = [chunkReadHandle readDataOfLength:1024]) length] > 0 ) {
								[outHandle writeData:readData];
								NSInteger length = [readData length];
								movedChunkDataLength += length;
								self.assembledAggregatedContentLength += length;
							}
						}
						else {
							*stop = YES;
							self.error = readError;
							RCLog(@"Could not create file handle to read chunk file: %@ %@ (%@)", chunk.file, [readError localizedDescription], [readError userInfo]);
							return;
						}
						if (movedChunkDataLength != chunk.size) {
							*stop = YES;
							NSDictionary *info = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Actual chunk size did not match expected chunk size %@ != %@",@(movedChunkDataLength), @(chunk.size)] };
							self.error = [NSError errorWithDomain:kCumulusErrorDomain code:kCumulusErrorCodeErrorMismatchedChunkSize userInfo:info];
							RCLog(info[NSLocalizedDescriptionKey]);
						}
					}];
				}
				else {
					self.error = writeError;
					RCLog(@"Could not create file handle to aggregated file: %@ %@ (%@)", self.downloadedFileTempURL, [writeError localizedDescription], [writeError userInfo]);
				}
			}
			else {
				NSDictionary *info = @{ NSLocalizedDescriptionKey : @"Not able to create temporary file for chunked download" };
				self.error = [NSError errorWithDomain:kCumulusErrorDomain code:kCumulusErrorCodeErrorCreatingTempFile userInfo:info];
				RCLog(info[NSLocalizedDescriptionKey]);
			}
		}
		else {
			self.error = [self.chunkErrors anyObject];
		}
		
		CMProgressInfo *progressInfo = [CMProgressInfo new];
		progressInfo.progress = @(1.f);
		progressInfo.tempFileURL = self.downloadedFileTempURL;
		progressInfo.URL = [self.URLRequest URL];
		progressInfo.filename = self.downloadedFilename;

		self.result = progressInfo;

		[super handleConnectionFinished];
		if (self.didComplete || (NO == self.wasCanceled && self.responseInternal.wasUnsuccessful)) {
			[self removeTempFiles];
		}
	});
}

- (void) removeTempFiles {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		if (NO == [fm removeItemAtURL:self.downloadedFileTempURL error:&error]) {
			RCLog(@"Could not remove temp file: %@ %@ (%@)", self.downloadedFileTempURL, [error localizedDescription], [error userInfo]);
		}
		if (NO == [fm removeItemAtURL:self.chunksDirURL error:&error]) {
			RCLog(@"Could not remove chunks dir: %@ %@ (%@)", self.chunksDirURL, [error localizedDescription], [error userInfo]);
		}
	});
}

- (void) reallyHandleConnectionDidReceiveData {
	[super handleConnectionDidReceiveData];
}


@end
