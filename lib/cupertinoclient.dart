// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart';

import 'cupertinohttp.dart';

class _TaskTracker {
  var numRedirects = 0;
  final completer = Completer<Object>();
  BaseRequest request;
  final responseController = StreamController<Uint8List>();

  _TaskTracker(this.request);

  void close() {
    responseController.close();
  }
}

/// A HTTP [Client] based on the
/// [Foundation URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system).
///
/// For example:
/// ```
/// void main() async {
///   var client = CupertinoClient.defaultSessionConfiguration();
///   final response = await client.get(
///       Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': '{http}'}));
///   if (response.statusCode != 200) {
///     throw HttpException('bad response: ${response.statusCode}');
///   }
///
///   final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
///
///   final itemCount = decodedResponse['totalItems'];
///   print('Number of books about http: $itemCount.');
///   for (var i = 0; i < min(itemCount, 10); ++i) {
///     print(decodedResponse['items'][i]['volumeInfo']['title']);
///   }
/// }
/// ```
class CupertinoClient extends BaseClient {
  static Map<int, _TaskTracker> tasks = {};

  URLSession _urlSession;

  CupertinoClient._(this._urlSession);

  static _TaskTracker _getTracker(URLSessionTask task) {
    return tasks[task.taskIdentifider]!;
  }

  static void _onComplete(
      URLSession session, URLSessionTask task, Error? error) {
    final t = _getTracker(task);

    if (error != null) {
      final exception =
          ClientException(error.localizedDescription ?? "No description");
      if (t.completer.isCompleted) {
        t.responseController.addError(exception);
      } else {
        t.completer.complete(exception);
      }
    } else if (!t.completer.isCompleted) {
      t.completer.complete(
          new StateError("task completed without an error or response"));
    }
    t.close();
    tasks.remove(task.taskIdentifider);
  }

  static void _onData(URLSession session, URLSessionTask task, Data data) {
    final t = _getTracker(task);
    t.responseController.add(data.bytes);
  }

  static URLRequest? _onRedirect(URLSession session, URLSessionTask task,
      HTTPURLResponse response, URLRequest request) {
    final t = _getTracker(task);
    ++t.numRedirects;
    if (t.request.followRedirects && t.numRedirects <= t.request.maxRedirects) {
      return request;
    }
    return null;
  }

  static URLSessionResponseDisposition _onResponse(
      URLSession session, URLSessionTask task, URLResponse response) {
    final t = _getTracker(task);
    t.completer.complete(response);
    return URLSessionResponseDisposition.urlSessionResponseAllow;
  }

  factory CupertinoClient.defaultSessionConfiguration() {
    final URLSessionConfiguration config =
        URLSessionConfiguration.defaultSessionConfiguration();
    return CupertinoClient.fromSessionConfiguration(config);
  }

  factory CupertinoClient.fromSessionConfiguration(
      URLSessionConfiguration config) {
    final session = URLSession.sessionWithConfiguration(config,
        onComplete: _onComplete,
        onData: _onData,
        onRedirect: _onRedirect,
        onResponse: _onResponse);
    return CupertinoClient._(session);
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final stream = request.finalize();

    final bytes = await stream.toBytes();
    final d = Data.fromUint8List(bytes);

    MutableURLRequest urlRequest = MutableURLRequest.fromUrl(request.url)
      ..httpMethod = request.method
      ..httpBody = d;

    // This will preserve Apple default headers - is that what we want?
    request.headers.forEach(
        (key, value) => urlRequest.setValueForHttpHeaderField(key, value));

    final task = _urlSession.dataTaskWithRequest(urlRequest);
    final t = _TaskTracker(request);
    tasks[task.taskIdentifider] = t;
    task.resume();

    final maxRedirects = request.followRedirects ? request.maxRedirects : 0;

    final result = await t.completer.future;
    if (result is Exception || result is Error) {
      throw result;
    }
    final response = result as HTTPURLResponse;

    if (request.followRedirects && t.numRedirects > maxRedirects) {
      throw ClientException('Redirect limit exceeded', request.url);
    }

    final contentLength = response.expectedContentLength;
    return StreamedResponse(
      t.responseController.stream,
      response.statusCode,
      contentLength: contentLength == -1 ? null : contentLength,
      isRedirect: !request.followRedirects && t.numRedirects > 0,
      headers: response.allHeaderFields
          .map((key, value) => MapEntry(key.toLowerCase(), value)),
    );
  }
}
