// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import "CUPHTTPClientDelegate.h"

#import <Foundation/Foundation.h>
#include <os/log.h>

static Dart_CObject NSObjectToCObject(NSObject* n) {
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = (int64_t) n;
  return cobj;
}

static Dart_CObject MessageTypeToCObject(MessageType messageType) {
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = messageType;
  return cobj;
}

@implementation CUPHTTPTaskConfiguration

- (id) initWithPort:(Dart_Port)sendPort {
  self = [super init];
  if (self != nil) {
    self->_sendPort = sendPort;
  }
  return self;
}

@end

@implementation CUPHTTPDelegateData

- (id) initWithSession:(NSURLSession *)session
                  task:(NSURLSessionTask *) task {
  self = [super init];
  if (self != nil) {
    self->_session = [session retain];
    self->_task = [task retain];
    self->_lock = [NSLock new];
  }
  return self;
}

- (void) dealloc {
  [self->_session release];
  [self->_task release];
  [self->_lock release];
  [super dealloc];
}

- (void) finish {
  [self->_lock unlock];
}

@end

@implementation CUPHTTPRedirect

- (id) initWithSession:(NSURLSession *)session
                  task:(NSURLSessionTask *) task
              response:(NSHTTPURLResponse *)response
               request:(NSURLRequest *)request{
  self = [super initWithSession: session task: task];
  if (self != nil) {
    self->_response = [response retain];
    self->_request = [request retain];
  }
  return self;
}

- (void) dealloc {
  [self->_response release];
  [self->_request release];
  [super dealloc];
}

- (void) finishWithRequest:(NSURLRequest *) request {
  self->_redirectRequest = [request retain];
  [super finish];
}

@end

@implementation CUPHTTPResponseReceived

- (id) initWithSession:(NSURLSession *)session
                  task:(NSURLSessionTask *) task
              response:(NSURLResponse *)response {
  self = [super initWithSession: session task: task];
  if (self != nil) {
    self->_response = [response retain];
  }
  return self;
}

- (void) dealloc {
  [self->_response release];
  [super dealloc];
}

- (void) finishWithDisposition:(NSURLSessionResponseDisposition) disposition {
  self->_disposition = disposition;
  [super finish];
}

@end

@implementation CUPHTTPComplete

- (id) initWithSession:(NSURLSession *)session
                  task:(NSURLSessionTask *) task
            error:(NSError *)error {
  self = [super initWithSession: session task: task];
  if (self != nil) {
    self->_error = [error retain];
  }
  return self;
}

- (void) dealloc {
//  [self->_error release];
  [super dealloc];
}

@end

@implementation CUPHTTPReceiveData

- (id) initWithSession:(NSURLSession *)session
                  task:(NSURLSessionTask *) task
            data:(NSData *)data {
  self = [super initWithSession: session task: task];
  if (self != nil) {
    self->_data = [data retain];
  }
  return self;
}

- (void) dealloc {
//  [self->_data release];
  [super dealloc];
}

@end

@implementation CUPHTTPClientDelegate {
  NSMapTable<NSURLSessionTask *, CUPHTTPTaskConfiguration *> *taskConfigurations;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    taskConfigurations = [NSMapTable strongToStrongObjectsMapTable];
  }
  return self;
}

- (void)dealloc {
  [taskConfigurations release];
  [super dealloc];
}

- (void)registerTask:(NSURLSessionTask *) task withConfiguration:(CUPHTTPTaskConfiguration *)config {
  [taskConfigurations setObject:config forKey:task];
}

-(void)unregisterTask:(NSURLSessionTask *) task {
  [taskConfigurations removeObjectForKey:task];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
  CUPHTTPTaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    os_log_error(OS_LOG_DEFAULT, "No configuration for task.");
    completionHandler(nil);
    return;
  }
  CUPHTTPRedirect *redirect = [[[CUPHTTPRedirect alloc]
                                initWithSession:session task:task response:response request:request]
                               autorelease];
  Dart_CObject ctype = MessageTypeToCObject(RedirectMessage);
  Dart_CObject credirect = NSObjectToCObject(redirect);
  Dart_CObject* message_carray[] = { &ctype, &credirect };

  Dart_CObject message_cobj;
  message_cobj.type = Dart_CObject_kArray;
  message_cobj.value.as_array.length = 2;
  message_cobj.value.as_array.values = message_carray;

  [redirect.lock lock];  // After this line, any attempt to acquire the lock will wait.
  const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
  if (!success) {
    os_log_error(OS_LOG_DEFAULT, "Dart_PostCObject_DL failed.");
    completionHandler(nil);
    return;
  }
  // Will be unlocked by [CUPHTTPRedirect continueWithRequest:], which will
  // set `redirect.redirectRequest`.
  //
  // See the @interface description for CUPHTTPRedirect.
  [redirect.lock lock];

  completionHandler(redirect.redirectRequest);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  CUPHTTPTaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    os_log_error(OS_LOG_DEFAULT, "No configuration for task.");
    completionHandler(NSURLSessionResponseCancel);
    return;
  }
  CUPHTTPResponseReceived *responseReceived = [[[CUPHTTPResponseReceived alloc]
                                initWithSession:session task:task response:response]
                               autorelease];


  Dart_CObject ctype = MessageTypeToCObject(ResponseMessage);
  Dart_CObject cRsponseReceived = NSObjectToCObject(responseReceived);
  Dart_CObject* message_carray[] = { &ctype, &cRsponseReceived };

  Dart_CObject message_cobj;
  message_cobj.type = Dart_CObject_kArray;
  message_cobj.value.as_array.length = 2;
  message_cobj.value.as_array.values = message_carray;

  [responseReceived.lock lock];  // After this line, any attempt to acquire the lock will wait.
  const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
  if (!success) {
    os_log_error(OS_LOG_DEFAULT, "Dart_PostCObject_DL failed.");
    completionHandler(NSURLSessionResponseCancel);
    return;
  }
  // Will be unlocked by [CUPHTTPRedirect continueWithRequest:], which will
  // set `redirect.redirectRequest`.
  //
  // See the @interface description for CUPHTTPRedirect.
  [responseReceived.lock lock];

  completionHandler(responseReceived.disposition);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task
    didReceiveData:(NSData *)data {
  CUPHTTPTaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    os_log_error(OS_LOG_DEFAULT, "No configuration for task.");
    return;
  }
  CUPHTTPReceiveData *receiveData = [[[CUPHTTPReceiveData alloc]
                                initWithSession:session task:task data: data]
                               autorelease];


  Dart_CObject ctype = MessageTypeToCObject(DataMessage);
  Dart_CObject cReceiveData = NSObjectToCObject(receiveData);
  Dart_CObject* message_carray[] = { &ctype, &cReceiveData };

  Dart_CObject message_cobj;
  message_cobj.type = Dart_CObject_kArray;
  message_cobj.value.as_array.length = 2;
  message_cobj.value.as_array.values = message_carray;

  [receiveData.lock lock];  // After this line, any attempt to acquire the lock will wait.
  const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
  if (!success) {
    os_log_error(OS_LOG_DEFAULT, "Dart_PostCObject_DL failed.");
    return;
  }
  // Will be unlocked by [CUPHTTPRedirect continueWithRequest:], which will
  // set `redirect.redirectRequest`.
  //
  // See the @interface description for CUPHTTPRedirect.
  [receiveData.lock lock];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
  CUPHTTPTaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    os_log_error(OS_LOG_DEFAULT, "No configuration for task.");
    return;
  }
  CUPHTTPComplete *complete = [[[CUPHTTPComplete alloc]
                                initWithSession:session task:task error: error]
                               autorelease];


  Dart_CObject ctype = MessageTypeToCObject(CompletedMessage);
  Dart_CObject cComplete = NSObjectToCObject(complete);
  Dart_CObject* message_carray[] = { &ctype, &cComplete };

  Dart_CObject message_cobj;
  message_cobj.type = Dart_CObject_kArray;
  message_cobj.value.as_array.length = 2;
  message_cobj.value.as_array.values = message_carray;

  [complete.lock lock];  // After this line, any attempt to acquire the lock will wait.
  const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
  if (!success) {
    os_log_error(OS_LOG_DEFAULT, "Dart_PostCObject_DL failed.");
    return;
  }
  // Will be unlocked by [CUPHTTPRedirect continueWithRequest:], which will
  // set `redirect.redirectRequest`.
  //
  // See the @interface description for CUPHTTPRedirect.
  [complete.lock lock];
}

@end
