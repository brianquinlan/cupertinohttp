// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Normally, we'd "import <Foundation/Foundation.h>"
// but that would mean that ffigen would process every file in the Foundation
// framework, which is huge. So just import the headers that we need.
#import <Foundation/NSObject.h>
#import <Foundation/NSURLSession.h>

#include "dart-sdk/include/dart_api_dl.h"

/**
 * The type of message being sent to a Dart port. See CUPHTTPClientDelegate.
 */
typedef NS_ENUM(NSInteger, MessageType) {
  ResponseMessage = 0,
  DataMessage = 1,
  CompletedMessage = 2,
  RedirectMessage = 3,
};

/**
 * The configuration associated with a NSURLSessionTask.
 * See CUPHTTPClientDelegate.
 */
@interface CUPHTTPTaskConfiguration : NSObject

- (id) initWithPort:(Dart_Port)sendPort;

@property (readonly) Dart_Port sendPort;

@end

/**
 * An object used to communicate redirect information to Dart code.
 *
 * The flow is:
 *  1. CUPHTTPClientDelegate receives a
 *    [URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:]
 *    message.
 *  2. CUPHTTPClientDelegate creates a new CUPHTTPRedirect.
 *  3. CUPHTTPClientDelegate sends the CUPHTTPRedirect to the configured
 *    Dart_Port.
 *  4. CUPHTTPClientDelegate waits on CUPHTTPRedirect.lock
 *  5. When the Dart code is done process the message received on the port,
 *    it calls [CUPHTTPRedirect continueWithRequest:], which releases the lock.
 *  6. CUPHTTPClientDelegate continues running and returns the value passed to
 *    [CUPHTTPRedirect continueWithRequest:].
 */
@interface CUPHTTPRedirect : NSObject

/**
 * Indicates that the task should continue executing using the given request.
 * If the request is NIL then the redirect is not followed and the task is
 * complete.
 */
- (void) continueWithRequest:(NSURLRequest *) request;

@property (readonly) NSURLSession *session;
@property (readonly) NSURLSessionTask *task;
@property (readonly) NSHTTPURLResponse *response;
@property (readonly) NSURLRequest *request;

// These properties are meant to be used only by CUPHTTPClientDelegate.
@property (readonly) NSLock *lock;
@property (readonly) NSURLRequest *redirectRequest;

@end

/**
 * A delegate for NSURLSession that forwards events for registered
 * NSURLSessionTasks and forwards them to a port for consumption in Dart.
 *
 * The messages sent to the port are contained in a List with one of 3
 * possible formats:
 *
 * 1. When the delegate receives a HTTP redirect response:
 *    [MessageType::RedirectMessage, <int: pointer to CUPHTTPRedirect>]
 *
 * 2. When the delegate receives a HTTP response:
 *    [MessageType::ResponseMessage, <int: pointer to NSURLResponse>]
 *
 * 3. When the delegate receives some HTTP data:
 *    [MessageType::DataMessage, <Uint8List: the received data>]
 *
 * 4. When the delegate is informed that the response is complete:
 *    [MessageType::CompletedMessage, <int: pointer to NSError> | null]
 */
@interface CUPHTTPClientDelegate : NSObject

/**
 * Instruct the delegate to forward events for the given task to the port
 * specified in the configuration.
 */
- (void)registerTask:(NSURLSessionTask *) task withConfiguration:(CUPHTTPTaskConfiguration *)config;
@end
