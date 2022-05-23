// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A macOS/iOS Flutter plugin that provides access to the
/// [Foundation URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system).

import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/native_cupertino_bindings.dart' as ncb;
import 'src/utils.dart';

abstract class _ObjectHolder<T extends ncb.NSObject> {
  final T _nsObject;

  _ObjectHolder(this._nsObject);
}

/// Settings for controlling whether cookies will be accepted.
///
/// See [HTTPCookieAcceptPolicy](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1408933-httpcookieacceptpolicy).
enum HTTPCookieAcceptPolicy {
  httpCookieAcceptPolicyAlways,
  httpCookieAcceptPolicyNever,
  httpCookieAcceptPolicyOnlyFromMainDocumentDomain,
}

/// Controls the behavior of a URLSession.
///
/// See [NSURLSessionConfiguration](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration)
class URLSessionConfiguration
    extends _ObjectHolder<ncb.NSURLSessionConfiguration> {
  URLSessionConfiguration._(ncb.NSURLSessionConfiguration c) : super(c);

  /// A configuration suitable for performing HTTP uploads and downloads in
  /// the background.
  ///
  /// See [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1407496-backgroundsessionconfigurationwi)
  factory URLSessionConfiguration.backgroundSession(String identifier) {
    return URLSessionConfiguration._(ncb.NSURLSessionConfiguration
        .backgroundSessionConfigurationWithIdentifier_(
            linkedLibs, identifier.toNSString(linkedLibs)));
  }

  /// A configuration that uses caching and saves cookies and credentials.
  ///
  /// See [NSURLSessionConfiguration defaultSessionConfiguration](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1411560-defaultsessionconfiguration)
  factory URLSessionConfiguration.defaultSessionConfiguration() {
    return URLSessionConfiguration._(ncb.NSURLSessionConfiguration.castFrom(
        ncb.NSURLSessionConfiguration.getDefaultSessionConfiguration(
            linkedLibs)!));
  }

  /// A configuration that uses caching and saves cookies and credentials.
  ///
  /// See [NSURLSessionConfiguration ephemeralSessionConfiguration](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1410529-ephemeralsessionconfiguration)
  factory URLSessionConfiguration.ephemeralSessionConfiguration() {
    return URLSessionConfiguration._(ncb.NSURLSessionConfiguration.castFrom(
        ncb.NSURLSessionConfiguration.getEphemeralSessionConfiguration(
            linkedLibs)!));
  }

  /// Whether connections over a cellular network are allowed.
  ///
  /// See [NSURLSessionConfiguration.allowsCellularAccess](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1409406-allowscellularaccess)
  bool get allowsCellularAccess => _nsObject.allowsCellularAccess;
  set allowsCellularAccess(bool value) =>
      _nsObject.allowsCellularAccess = value;

  /// Whether connections are allowed when the user has selected Low Data Mode.
  ///
  /// See [NSURLSessionConfiguration.allowsConstrainedNetworkAccess](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/3235751-allowsconstrainednetworkaccess)
  bool get allowsConstrainedNetworkAccess =>
      _nsObject.allowsConstrainedNetworkAccess;
  set allowsConstrainedNetworkAccess(bool value) =>
      _nsObject.allowsConstrainedNetworkAccess = value;

  /// Whether connections are allowed over expensive networks.
  ///
  /// See [NSURLSessionConfiguration.allowsExpensiveNetworkAccess](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/3235752-allowsexpensivenetworkaccess)
  bool get allowsExpensiveNetworkAccess =>
      _nsObject.allowsExpensiveNetworkAccess;
  set allowsExpensiveNetworkAccess(bool value) =>
      _nsObject.allowsExpensiveNetworkAccess = value;

  /// Whether background tasks can be delayed by the system.
  ///
  /// See [NSURLSessionConfiguration.discretionary](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1411552-discretionary)
  bool get discretionary => _nsObject.discretionary;
  set discretionary(bool value) => _nsObject.discretionary = value;

  /// What policy to use when deciding whether to accept cookies.
  ///
  /// See [NSURLSessionConfiguration.HTTPCookieAcceptPolicy](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1408933-httpcookieacceptpolicy).
  HTTPCookieAcceptPolicy get httpCookieAcceptPolicy =>
      HTTPCookieAcceptPolicy.values[_nsObject.HTTPCookieAcceptPolicy];
  set httpCookieAcceptPolicy(HTTPCookieAcceptPolicy value) =>
      _nsObject.HTTPCookieAcceptPolicy = value.index;

  /// Whether requests should include cookies from the cookie store.
  ///
  /// See [NSURLSessionConfiguration.HTTPShouldSetCookies](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1411589-httpshouldsetcookies)
  bool get httpShouldSetCookies => _nsObject.HTTPShouldSetCookies;
  set httpShouldSetCookies(bool value) =>
      _nsObject.HTTPShouldSetCookies = value;

  /// Whether to use [HTTP pipelining](https://en.wikipedia.org/wiki/HTTP_pipelining).
  ///
  /// See [NSURLSessionConfiguration.HTTPShouldUsePipelining](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1411657-httpshouldusepipelining)
  bool get httpShouldUsePipelining => _nsObject.HTTPShouldUsePipelining;
  set httpShouldUsePipelining(bool value) =>
      _nsObject.HTTPShouldUsePipelining = value;

  /// Whether the app should be resumed when background tasks complete.
  ///
  /// See [NSURLSessionConfiguration.sessionSendsLaunchEvents](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1617174-sessionsendslaunchevents)
  bool get sessionSendsLaunchEvents => _nsObject.sessionSendsLaunchEvents;
  set sessionSendsLaunchEvents(bool value) =>
      _nsObject.sessionSendsLaunchEvents = value;

  /// Whether connections will be preserved if the app moves to the background.
  ///
  /// See [NSURLSessionConfiguration.shouldUseExtendedBackgroundIdleMode](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1409517-shoulduseextendedbackgroundidlem)
  bool get shouldUseExtendedBackgroundIdleMode =>
      _nsObject.shouldUseExtendedBackgroundIdleMode;
  set shouldUseExtendedBackgroundIdleMode(bool value) =>
      _nsObject.shouldUseExtendedBackgroundIdleMode = value;

  /// The timeout interval if data is not received.
  ///
  /// See [NSURLSessionConfiguration.timeoutIntervalForRequest](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/1408259-timeoutintervalforrequest)
  Duration get timeoutIntervalForRequest {
    return Duration(
        microseconds: (_nsObject.timeoutIntervalForRequest *
                Duration.microsecondsPerSecond)
            .round());
  }

  set timeoutIntervalForRequest(Duration interval) {
    _nsObject.timeoutIntervalForRequest =
        interval.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
  }

  /// Whether tasks should wait for connectivity or fail immediately.
  ///
  /// See [NSURLSessionConfiguration.waitsForConnectivity](https://developer.apple.com/documentation/foundation/nsurlsessionconfiguration/2908812-waitsforconnectivity)
  bool get waitsForConnectivity => _nsObject.waitsForConnectivity;
  set waitsForConnectivity(bool value) =>
      _nsObject.waitsForConnectivity = value;

  @override
  String toString() {
    return "[URLSessionConfiguration "
        "allowsCellularAccess=$allowsCellularAccess "
        "allowsConstrainedNetworkAccess=$allowsConstrainedNetworkAccess "
        "allowsExpensiveNetworkAccess=$allowsExpensiveNetworkAccess "
        "discretionary=$discretionary "
        "httpCookieAcceptPolicy=$httpCookieAcceptPolicy "
        "httpShouldSetCookies=$httpShouldSetCookies "
        "httpShouldUsePipelining=$httpShouldUsePipelining "
        "sessionSendsLaunchEvents=$sessionSendsLaunchEvents "
        "shouldUseExtendedBackgroundIdleMode=$shouldUseExtendedBackgroundIdleMode "
        "timeoutIntervalForRequest=$timeoutIntervalForRequest "
        "waitsForConnectivity=$waitsForConnectivity"
        "]";
  }
}

/// A container for byte data.
///
/// See [NSData](https://developer.apple.com/documentation/foundation/nsdata)
class Data extends _ObjectHolder<ncb.NSData> {
  Data._(ncb.NSData c) : super(c);

  /// A new [Data] object containing the given bytes.
  factory Data.fromUint8List(Uint8List l) {
    final f = calloc<Uint8>(l.length);
    try {
      f.asTypedList(l.length).setAll(0, l);

      final data =
          ncb.NSData.dataWithBytes_length_(linkedLibs, f.cast(), l.length);
      return Data._(data);
    } finally {
      calloc.free(f);
    }
  }

  /// The number of bytes contained in the object.
  ///
  /// See [NSData.length](https://developer.apple.com/documentation/foundation/nsdata/1416769-length)
  int get length => _nsObject.length;

  /// The data contained in the object.
  ///
  /// See [NSData.bytes](https://developer.apple.com/documentation/foundation/nsdata/1410616-bytes)
  Uint8List get bytes {
    final bytes = _nsObject.bytes;
    if (bytes.address == 0) {
      return Uint8List(0);
    } else {
      // `NSData.byte` has the same lifetime as the `NSData` so make a copy to
      // ensure memory safety.
      // TODO(https://github.com/dart-lang/ffigen/issues/375): Remove copy.
      return Uint8List.fromList(bytes.cast<Uint8>().asTypedList(length));
    }
  }

  @override
  String toString() {
    final subrange =
        length == 0 ? Uint8List(0) : bytes.sublist(0, min(length - 1, 20));
    final b = subrange.map((e) => e.toRadixString(16)).join();
    return "[Data " + "length=$length " + "bytes=0x$b..." + "]";
  }
}

/// The response associated with loading an URL.
///
/// See [NSURLResponse](https://developer.apple.com/documentation/foundation/nsurlresponse)
class URLResponse extends _ObjectHolder<ncb.NSURLResponse> {
  URLResponse._(ncb.NSURLResponse c) : super(c);

  /// The expected amount of data returned with the response.
  ///
  /// See [NSURLResponse.expectedContentLength](https://developer.apple.com/documentation/foundation/nsurlresponse/1413507-expectedcontentlength)
  int get expectedContentLength => _nsObject.expectedContentLength;

  /// The MIME type of the response.
  ///
  /// See [NSURLResponse.MIMEType](https://developer.apple.com/documentation/foundation/nsurlresponse/1411613-mimetype)
  String? get mimeType => toStringOrNull(_nsObject.MIMEType);
}

/// The response associated with loading a HTTP URL.
///
/// See [NSHTTPURLResponse](https://developer.apple.com/documentation/foundation/nshttpurlresponse)
class HTTPURLResponse extends URLResponse {
  final ncb.NSHTTPURLResponse _httpUrlResponse;

  HTTPURLResponse._(ncb.NSHTTPURLResponse c)
      : _httpUrlResponse = c,
        super._(c);

  /// The HTTP status code of the response (e.g. 200).
  ///
  /// See [HTTPURLResponse.statusCode](https://developer.apple.com/documentation/foundation/nshttpurlresponse/1409395-statuscode)
  int get statusCode => _httpUrlResponse.statusCode;

  /// The HTTP headers of the response.
  ///
  /// See [HTTPURLResponse.allHeaderFields](https://developer.apple.com/documentation/foundation/nshttpurlresponse/1417930-allheaderfields)
  Map<String, String> get allHeaderFields {
    final headers =
        ncb.NSDictionary.castFrom(_httpUrlResponse.allHeaderFields!);
    return (stringDictToMap(headers));
  }

  @override
  String toString() {
    return "[HTTPURLResponse " +
        "statusCode=$statusCode " +
        "mimeType=$mimeType " +
        "expectedContentLength=$expectedContentLength" +
        "]";
  }
}

/// The possible states of a [URLSessionTask].
///
/// See [NSURLSessionTaskState](https://developer.apple.com/documentation/foundation/nsurlsessiontaskstate)
enum URLSessionTaskState {
  urlSessionTaskStateRunning,
  urlSessionTaskStateSuspended,
  urlSessionTaskStateCanceling,
  urlSessionTaskStateCompleted,
}

/// A task associated with downloading a URI.
///
/// See [NSURLSessionTask](https://developer.apple.com/documentation/foundation/nsurlsessiontask)
class URLSessionTask extends _ObjectHolder<ncb.NSURLSessionTask> {
  URLSessionTask._(ncb.NSURLSessionTask c) : super(c);

  /// Cancels the task.
  ///
  /// See [NSURLSessionTask cancel](https://developer.apple.com/documentation/foundation/nsurlsessiontask/1411591-cancel)
  void cancel() {
    this._nsObject.cancel();
  }

  /// Resumes a suspended task (new tasks start as suspended).
  ///
  /// See [NSURLSessionTask resume](https://developer.apple.com/documentation/foundation/nsurlsessiontask/1411121-resume)
  void resume() {
    this._nsObject.resume();
  }

  /// Suspends a task (prevents it from transfering data).
  ///
  /// See [NSURLSessionTask suspend](https://developer.apple.com/documentation/foundation/nsurlsessiontask/1411565-suspend)
  void suspend() {
    this._nsObject.suspend();
  }

  /// The current state of the task.
  ///
  /// See [NSURLSessionTask.state](https://developer.apple.com/documentation/foundation/nsurlsessiontask/1409888-state)
  URLSessionTaskState get state => URLSessionTaskState.values[_nsObject.state];

  /// The server response to the request associated with this task.
  ///
  /// See [NSURLSessionTask.response](https://developer.apple.com/documentation/foundation/nsurlsessiontask/1410586-response)
  URLResponse? get response {
    if (_nsObject.response == null) {
      return null;
    } else {
      // TODO(https://github.com/dart-lang/ffigen/issues/374): Check the actual
      // type of the response instead of assuming that it is a
      // NSHTTPURLResponse.
      return HTTPURLResponse._(
          ncb.NSHTTPURLResponse.castFrom(_nsObject.response!));
    }
  }

  /// The number of content bytes that have been received from the server.
  ///
  /// [NSURLSessionTask.countOfBytesReceived](https://developer.apple.com/documentation/foundation/nsurlsessiontask/1411581-countofbytesreceived)
  int get countOfBytesReceived => _nsObject.countOfBytesReceived;

  /// The number of content bytes that are expected to be received from the server.
  ///
  /// [NSURLSessionTask.countOfBytesReceived](https://developer.apple.com/documentation/foundation/nsurlsessiontask/1410663-countofbytesexpectedtoreceive)
  int get countOfBytesExpectedToReceive =>
      _nsObject.countOfBytesExpectedToReceive;

  @override
  String toString() {
    return "[URLSessionTask "
        "countOfBytesExpectedToReceive=$countOfBytesExpectedToReceive "
        "countOfBytesReceived=$countOfBytesReceived "
        "state=$state"
        "]";
  }
}

/// A request to load a URL.
///
/// See [NSURLRequest](https://developer.apple.com/documentation/foundation/nsurlrequest)
class URLRequest extends _ObjectHolder<ncb.NSURLRequest> {
  URLRequest._(ncb.NSURLRequest c) : super(c);

  /// Creates a request for a URL.
  ///
  /// See [NSURLRequest.requestWithURL:](https://developer.apple.com/documentation/foundation/nsurlrequest/1528603-requestwithurl)
  factory URLRequest.fromUrl(Uri uri) {
    // TODO(https://github.com/dart-lang/ffigen/issues/373): remove NSObject
    // cast when precise type signatures are generated.
    final url = ncb.NSURL.URLWithString_(linkedLibs,
        ncb.NSObject.castFrom(uri.toString().toNSString(linkedLibs)));
    return URLRequest._(ncb.NSURLRequest.requestWithURL_(linkedLibs, url));
  }

  /// Returns all of the HTTP headers for the request.
  ///
  /// See [NSURLRequest.allHTTPHeaderFields](https://developer.apple.com/documentation/foundation/nsurlrequest/1418477-allhttpheaderfields)
  Map<String, String>? get allHttpHeaderFields {
    if (_nsObject.allHTTPHeaderFields == null) {
      return null;
    } else {
      final headers = ncb.NSDictionary.castFrom(_nsObject.allHTTPHeaderFields!);
      return stringDictToMap(headers);
    }
  }

  /// The body of the request.
  ///
  /// See [NSURLRequest.HTTPBody](https://developer.apple.com/documentation/foundation/nsurlrequest/1411317-httpbody)
  Data? get httpBody {
    final body = _nsObject.HTTPBody;
    if (body == null) {
      return null;
    }
    return Data._(ncb.NSData.castFrom(body));
  }

  /// The HTTP request method (e.g. 'GET').
  ///
  /// See [NSURLRequest.HTTPMethod](https://developer.apple.com/documentation/foundation/nsurlrequest/1413030-httpmethod)
  ///
  /// NOTE: The documentation for `NSURLRequest.HTTPMethod` says that the
  /// property is nullable but, in practice, assigning it to null will produce
  /// an error.
  String get httpMethod {
    return toStringOrNull(_nsObject.HTTPMethod)!;
  }

  /// The requested URL.
  ///
  /// See [URLRequest.URL](https://developer.apple.com/documentation/foundation/nsurlrequest/1408996-url)
  Uri? get url {
    final nsUrl = _nsObject.URL;
    if (nsUrl == null) {
      return null;
    }
    // TODO(https://github.com/dart-lang/ffigen/issues/373): remove NSObject
    // cast when precise type signatures are generated.
    return Uri.parse(toStringOrNull(ncb.NSURL.castFrom(nsUrl).absoluteString)!);
  }

  @override
  String toString() {
    return "[URLRequest "
        "allHttpHeaderFields=$allHttpHeaderFields "
        "httpBody=$httpBody "
        "httpMethod=$httpMethod "
        "]";
  }
}

/// A mutable request to load a URL.
///
/// See [NSMutableURLRequest](https://developer.apple.com/documentation/foundation/nsmutableurlrequest)
class MutableURLRequest extends URLRequest {
  final ncb.NSMutableURLRequest _mutableUrlRequest;

  MutableURLRequest._(ncb.NSMutableURLRequest c)
      : _mutableUrlRequest = c,
        super._(c);

  /// Creates a request for a URL.
  ///
  /// See [NSMutableURLRequest.requestWithURL:](https://developer.apple.com/documentation/foundation/nsmutableurlrequest/1414617-allhttpheaderfields)
  factory MutableURLRequest.fromUrl(Uri uri) {
    final url = ncb.NSURL
        .URLWithString_(linkedLibs, uri.toString().toNSString(linkedLibs));
    return MutableURLRequest._(
        ncb.NSMutableURLRequest.requestWithURL_(linkedLibs, url));
  }

  set httpBody(Data? data) {
    _mutableUrlRequest.HTTPBody = data?._nsObject;
  }

  set httpMethod(String method) {
    _mutableUrlRequest.HTTPMethod = method.toNSString(linkedLibs);
  }

  /// Set the value of a header field.
  ///
  /// See [NSMutableURLRequest setValue:forHTTPHeaderField:](https://developer.apple.com/documentation/foundation/nsmutableurlrequest/1408793-setvalue)
  void setValueForHttpHeaderField(String value, String field) {
    _mutableUrlRequest.setValue_forHTTPHeaderField_(
        field.toNSString(linkedLibs), value.toNSString(linkedLibs));
  }

  @override
  String toString() {
    return "[MutableURLRequest "
        "allHttpHeaderFields=$allHttpHeaderFields "
        "httpBody=$httpBody "
        "httpMethod=$httpMethod "
        "]";
  }
}

/// A client that can make network requests to a server.
///
/// See [NSURLSession](https://developer.apple.com/documentation/foundation/nsurlsession)
class URLSession extends _ObjectHolder<ncb.NSURLSession> {
  URLSession._(ncb.NSURLSession c) : super(c);

  /// A client with reasonable default behavior.
  ///
  /// See [NSURLSession.sharedSession](https://developer.apple.com/documentation/foundation/nsurlsession/1409000-sharedsession)
  factory URLSession.sharedSession() {
    return URLSession._(ncb.NSURLSession.castFrom(
        ncb.NSURLSession.getSharedSession(linkedLibs)!));
  }

  /// A client with a given configuration.
  ///
  /// See [NSURLSession sessionWithConfiguration:](https://developer.apple.com/documentation/foundation/nsurlsession/1411474-sessionwithconfiguration)
  factory URLSession.sessionWithConfiguration(URLSessionConfiguration config) {
    return URLSession._(ncb.NSURLSession.sessionWithConfiguration_(
        linkedLibs, config._nsObject));
  }

  // A **copy** of the configuration for this sesion.
  //
  // See [NSURLSession.configuration](https://developer.apple.com/documentation/foundation/nsurlsession/1411477-configuration)
  URLSessionConfiguration get configuration {
    return URLSessionConfiguration._(
        ncb.NSURLSessionConfiguration.castFrom(_nsObject.configuration!));
  }

  // Create a [URLSessionTask] that acccess a server URL.
  //
  // See [NSURLSession dataTaskWithRequest:](https://developer.apple.com/documentation/foundation/nsurlsession/1410592-datataskwithrequest)
  URLSessionTask dataTaskWithRequest(URLRequest request) {
    final task = _nsObject.dataTaskWithRequest_(request._nsObject);
    return URLSessionTask._(task);
  }
}
