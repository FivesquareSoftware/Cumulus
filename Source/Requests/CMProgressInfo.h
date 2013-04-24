//
//  CMProgressInfo.h
//  Cumulus
//
//  Created by John Clayton on 5/2/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMRequest;

/** Issued by requests as arguments to a supplied progress block when they receive data on their connection. */
@interface CMProgressInfo : NSObject

/** A weak pointer to the request issuing this progress information.
 *  @note This value is nil on the completion of a request (progress == 1.0) as it is in the process of being destroyed.
 */
@property (nonatomic, weak) CMRequest *request;

/** The URL being fetched. */
@property (nonatomic, strong) NSURL *URL;

/** If a file is being downloaded, representes the location of the temporary file. */
@property (nonatomic, strong) NSURL *tempFileURL;

/** If a file is being downloaded, represents the filename the server may have sent in the Content-Disposition header. Can be nil. */
@property (nonatomic, strong) NSString *filename;

/** A number from 0.0 to 1.0 representing the amount of data received on the connected in relation to the expected content length.
 *  @note If a file is being streamed (and the content length is not known) this value is meaningless. 
 */
@property (nonatomic, strong) NSNumber *progress;

@end
