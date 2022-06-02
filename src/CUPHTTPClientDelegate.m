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

@implementation CUPHTTPRedirect

- (id) initWithSession:(NSURLSession *)session
                  task:(NSURLSessionTask *) task
              response:(NSHTTPURLResponse *)response
               request:(NSURLRequest *)request{
  self = [super init];
  if (self != nil) {
    self->_session = [session retain];
    self->_task = [task retain];
    self->_response = [response retain];
    self->_request = [request retain];
    self->_lock = [NSLock new];
  }
  return self;
}

- (void) dealloc {
  [self->_session release];
  [self->_task release];
  [self->_response release];
  [self->_request release];
  [self->_lock release];
  [super dealloc];
}

- (void) continueWithRequest:(NSURLRequest *) request {
  self->_redirectRequest = [request retain];
  [self->_lock unlock];
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

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  CUPHTTPTaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config != nil) {
    [response retain];

    Dart_CObject ctype = MessageTypeToCObject(ResponseMessage);
    Dart_CObject cresponse = NSObjectToCObject(response);
    Dart_CObject* message_carray[] = { &ctype, &cresponse};

    Dart_CObject message_cobj;
    message_cobj.type = Dart_CObject_kArray;
    message_cobj.value.as_array.length = 2;
    message_cobj.value.as_array.values = message_carray;

    const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
    if (!success) {
      os_log_error(OS_LOG_DEFAULT, "Dart_PostCObject_DL failed.");
    }
  }
  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
  CUPHTTPTaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
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
    didReceiveData:(NSData *)data {
  CUPHTTPTaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    return;
  }

  [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
    Dart_CObject ctype = MessageTypeToCObject(DataMessage);

    Dart_CObject cdata;
    cdata.type = Dart_CObject_kTypedData;
    cdata.value.as_typed_data.type = Dart_TypedData_kUint8;
    cdata.value.as_typed_data.length = byteRange.length;
    cdata.value.as_typed_data.values = (uint8_t *) bytes;

    Dart_CObject* message_carray[] = { &ctype, &cdata};

    Dart_CObject message_cobj;
    message_cobj.type = Dart_CObject_kArray;
    message_cobj.value.as_array.length = 2;
    message_cobj.value.as_array.values = message_carray;

    const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
    if (!success) {
      os_log_error(OS_LOG_DEFAULT, "Dart_PostCObject_DL failed.");
    }
  }];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
  CUPHTTPTaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    return;
  }
  
  Dart_CObject ctype = MessageTypeToCObject(CompletedMessage);
  Dart_CObject cerror;
  if (error != nil) {
    [error retain];
    cerror.type = Dart_CObject_kInt64;
    cerror.value.as_int64 = (int64_t) error;
  } else {
    cerror.type = Dart_CObject_kNull;
  }

  Dart_CObject* message_carray[] = { &ctype, &cerror};

  Dart_CObject message_cobj;
  message_cobj.type = Dart_CObject_kArray;
  message_cobj.value.as_array.length = 2;
  message_cobj.value.as_array.values = message_carray;

  const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
  [self unregisterTask: task];
  if (!success) {
    os_log_error(OS_LOG_DEFAULT, "Dart_PostCObject_DL failed.");
  }
}

@end
