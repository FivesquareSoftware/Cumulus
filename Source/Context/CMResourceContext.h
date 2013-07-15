//
//  CMResourceContext.h
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

/*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of Fivesquare Software, LLC nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL FIVESQUARE SOFTWARE BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

extern NSString *kCMResourceContextKey;

@class CMResource;

/** A resource context is used to coordinate a series of requests by either grouping them and waiting until they are complete or by scoping their lifecycle to the existence of an arbitratry scope object; when that object disappears remaining requests are automatically canceled. 
 */
@interface CMResourceContext : NSObject

/// Used to identify the receiver
@property (nonatomic, strong) NSString *name;


+ (id) withName:(NSString *)name;

/** Submits a block of work to the receiver's private queue. The array of all response objects from requests launched during the block is collected and passed to the completion block, along with a summary of group success/failure. 
 *  @param work A block containing a series of requests made with CMResource objects that you wish to coordinate and get notified of on completion.
 *  @returns An identifier that can be used to cancel requests launched from work.
 *  @note Only requests launched during the execution of the top level block are included in the scope of the work. For example, if you launch a new request from the completion block of an asynchronous request launched inside the work block, the receiver does not wait for that request to complete, nor is it part of any subsequent work scope.
 */
- (id) performRequestsAndWait:(void(^)())work withCompletionBlock:(void(^)(BOOL success, NSSet *responses))completionBlock;

/** Cancels requests launched from the top level of a work block identified by the return value of performRequestsAndWait:withCompletionBlock:. 
 *  @param identifier An identifier returned from an invocation of performRequestsAndWait:withCompletionBlock:
 */
- (void) cancelRequestsForIdentifier:(id)identifier;

/** Cancels all requests for all currently running groups. */
- (void) cancelAllRequests;

/** Performs a block of requests in the scope of the receiver: when the receiver is deallocated, any remaining requests are canceled.
 *  @param work A block containing a series of requests made with CMResource objects that you wish to scope to the lifetime of the scope parameter.
 *  @param scope An object whose lifetime will define the scope of any requests launched at the top level of the work block; when scope is deallocated, any running requests are canceled.
 *  @note Only requests launched during the execution of the top level block are included in the scope of the work. For example, if you launch a new request from the completion block of an asynchronous request launched inside the work block, the receiver does not control the lifecycle of that request, nor is it part of any subsequent work scope.
*/
- (void) performRequests:(void(^)())work inScope:(id)scope;

@end
