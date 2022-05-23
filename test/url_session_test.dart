// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:cupertinohttp/cupertinohttp.dart';

testURLSession(URLSession session) {
  group('URLSession', () {
    late HttpServer server;
    setUp(() async {
      server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          request.response.headers.set('Content-Type', 'text/plain');
          request.response.write("Hello World");
          await request.response.close();
        });
    });
    tearDown(() {
      server.close();
    });

    test('dataTask', () async {
      final task = session.dataTaskWithRequest(
          URLRequest.fromUrl(Uri.parse('http://localhost:${server.port}')));

      task.resume();
      while (task.state != URLSessionTaskState.urlSessionTaskStateCompleted) {
        // Let the event loop run.
        await Future.delayed(const Duration());
      }
      final response = task.response as HTTPURLResponse;
      expect(response.statusCode, 200);
    });
  });
}

void main() {
  group('sharedSession', () {
    final session = URLSession.sharedSession();

    test('configration', () {
      expect(session.configuration, isA<URLSessionConfiguration>());
    });

    testURLSession(session);
  });

  group('defaultSessionConfiguration', () {
    final config = URLSessionConfiguration.defaultSessionConfiguration()
      ..allowsCellularAccess = false;
    final session = URLSession.sessionWithConfiguration(config);

    test('configration', () {
      expect(session.configuration.allowsCellularAccess, false);
    });

    testURLSession(session);
  });
}
