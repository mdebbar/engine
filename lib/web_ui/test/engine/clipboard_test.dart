// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();
  group('message handler', () {
    const String testText = 'test text';

    late ClipboardMessageHandler clipboardMessageHandler;
    late MockClipboardAPIStrategy clipboardAPIStrategy;

    setUp(() {
      clipboardMessageHandler = ClipboardMessageHandler();
      clipboardAPIStrategy = MockClipboardAPIStrategy();
      clipboardMessageHandler.copyToClipboardStrategy = clipboardAPIStrategy;
      clipboardMessageHandler.pasteFromClipboardStrategy = clipboardAPIStrategy;
    });

    test('set data successful', () async {
      clipboardAPIStrategy.setDataResult = true;
      const MethodCodec codec = JSONMethodCodec();
      final Completer<bool> completer = Completer<bool>();
      void callback(ByteData? data) {
        completer.complete(codec.decodeEnvelope(data!) as bool);
      }

      clipboardMessageHandler.setDataMethodCall(
          const MethodCall('Clipboard.setData', <String, dynamic>{
            'text': testText,
          }),
          callback);

      expect(await completer.future, isTrue);
    });

    test('set data error', () async {
      clipboardAPIStrategy.setDataResult = false;
      const MethodCodec codec = JSONMethodCodec();
      final Completer<ByteData> completer = Completer<ByteData>();
      void callback(ByteData? data) {
        completer.complete(data);
      }

      clipboardMessageHandler.setDataMethodCall(
          const MethodCall('Clipboard.setData', <String, dynamic>{
            'text': testText,
          }),
          callback);

      final ByteData result = await completer.future;
      expect(
        () =>codec.decodeEnvelope(result),
        throwsA(const TypeMatcher<PlatformException>()
          .having((PlatformException e) => e.code, 'code', equals('copy_fail'))));
    });

    test('get data successful', () async {
      clipboardAPIStrategy.getDataResult = testText;
      const MethodCodec codec = JSONMethodCodec();
      final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();
      void callback(ByteData? data) {
        completer.complete(codec.decodeEnvelope(data!) as Map<String, dynamic>);
      }

      clipboardMessageHandler.getDataMethodCall(callback);

      final Map<String, dynamic> result = await completer.future;
      expect(result['text'], testText);
    });
  });
}

class MockClipboardAPIStrategy implements ClipboardAPIStrategy {
  bool setDataResult = true;

  @override
  Future<bool> setData(String? text) {
    return Future<bool>.value(setDataResult);
  }

  String getDataResult = '';

  @override
  Future<String> getData() {
    return Future<String>.value(getDataResult);
  }
}
