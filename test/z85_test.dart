import 'dart:async';

import 'package:test/test.dart';

import 'package:z85/z85.dart';

final testBytes = [0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B];
final testString = 'HelloWorld';

void main() {
  test('oneshot encoding works', () {
    expect(z85.encode(testBytes), equals(testString));
  });

  test('chunked encoding works', () async {
    var outputStreamSink = StreamController<String>();
    var inputSink = z85.encoder.startChunkedConversion(outputStreamSink.sink);
    inputSink.add(testBytes.sublist(0, 2));
    inputSink.add(testBytes.sublist(2, 4));
    inputSink.add(testBytes.sublist(4, 7));
    inputSink.add(testBytes.sublist(7));
    inputSink.close();

    expect(await outputStreamSink.stream.join(''), equals(testString));
  });

  test('oneshot decoding works', () {
    expect(z85.decode(testString), equals(testBytes));
  });

  test('chunked decoding works', () async {
    var outputStreamSink = StreamController<List<int>>();
    var inputSink = z85.decoder.startChunkedConversion(outputStreamSink.sink);
    inputSink.add(testString.substring(0, 3));
    inputSink.add(testString.substring(3, 7));
    inputSink.add(testString.substring(7, 10));
    inputSink.close();

    expect(await outputStreamSink.stream.expand((i) => i).toList(), equals(testBytes));
  });
}
