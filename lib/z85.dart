library z85;

import 'dart:convert';
import 'dart:typed_data';

const _encodeMap =
    r'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        r'.-:+=^!/*?&<>()[]{}@%$#';
Map<String, int> _decodeMap;

/// z85 encoding converter. Encodes a list of bytes, with a length of a multiple of 4,
/// into an ASCII string, with a length of a multiple of 5.
class _Z85ByteConversionSink extends ByteConversionSink {
  Sink<String> _output;
  final _buffer = <int>[];

  _Z85ByteConversionSink(this._output);

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    add(chunk.sublist(start, end));

    if (isLast) {
      _output.close();
    }
  }

  @override
  void add(List<int> chunk) {
    _buffer.addAll(chunk);
    _flushBuffer();
  }

  @override
  void close() {
    assert(_buffer.length % 4 == 0);
    _output.close();
  }

  void _flushBuffer() {
    final result = StringBuffer();

    for (var i = 0; i + 4 <= _buffer.length; i += 4) {
      _convertFrame(result, _buffer.sublist(i, i + 4));
    }

    _buffer.removeRange(0, _buffer.length - (_buffer.length % 4));
    _output.add(result.toString());
  }

  static void _convertFrame(StringBuffer result, List<int> input) {
    assert(input.length == 4);
    assert(input.every((b) => b < 256));

    int value =
        (input[0] << 24) | (input[1] << 16) | (input[2] << 8) | input[3];

    var factor = 85 * 85 * 85 * 85;
    for (var i = 0; i < 5; i++) {
      result.writeCharCode(_encodeMap.codeUnitAt(value ~/ factor % 85));
      factor ~/= 85;
    }
  }
}

class Z85Encoder extends Converter<List<int>, String> {
  String convert(List<int> input) {
    assert(input.length % 4 == 0);

    final result = StringBuffer();

    for (var i = 0; i < input.length; i += 4) {
      final frame = input.sublist(i, i + 4);
      _Z85ByteConversionSink._convertFrame(result, frame);
    }

    return result.toString();
  }

  ByteConversionSink startChunkedConversion(Sink<String> sink) =>
      _Z85ByteConversionSink(sink is StringConversionSink
          ? sink
          : StringConversionSink.from(sink));
}

class _Z85StringConversionSink extends StringConversionSinkBase {
  Sink<List<int>> _output;
  final _buffer = StringBuffer();

  _Z85StringConversionSink(this._output);

  @override
  void addSlice(String chunk, int start, int end, bool isLast) {
    add(chunk.substring(start, end));

    if (isLast) {
      _output.close();
    }
  }

  @override
  void add(String chunk) {
    _buffer.write(chunk);
    _flushBuffer();
  }

  @override
  void close() {
    assert(_buffer.length % 5 == 0);
    _output.close();
  }

  void _flushBuffer() {
    final bufStr = _buffer.toString();
    final result = Uint8List(bufStr.length ~/ 5 * 4);

    for (var i = 0; i + 5 <= bufStr.length; i += 5) {
      _convertFrame(result, i ~/ 5 * 4, bufStr.substring(i, i + 5));
    }

    _buffer.clear();
    if (bufStr.length % 5 != 0) {
      _buffer.write(bufStr.substring(bufStr.length - (bufStr.length % 5)));
    }

    _output.add(result);
  }

  static void _convertFrame(Uint8List result, int offs, String input) {
    assert(input.length == 5);

    if (_decodeMap == null) {
      _decodeMap = Map<String, int>.fromIterable(
          List<int>.generate(_encodeMap.length, (i) => i),
          key: (i) => _encodeMap[i],
          value: (i) => i);
    }

    var value = 0;
    var factor = 85 * 85 * 85 * 85;
    for (var i = 0; i < 5; i++) {
      value += _decodeMap[input[i]] * factor;
      factor ~/= 85;
    }

    for (var i = 0; i < 4; i++) {
      result[offs + 3 - i] = value >> (8 * i) & 0xFF;
    }
  }
}

/// Decoder for z85-encoded data. Decodes a string, with a length a multiple of 5, into
/// the decoded list of bytes, with a length a multiple of 4.
class Z85Decoder extends Converter<String, List<int>> {
  List<int> convert(String input) {
    assert(input.length % 5 == 0);

    final result = Uint8List(input.length ~/ 5 * 4);

    for (var i = 0; i < input.length; i += 5) {
      final frame = input.substring(i, i + 5);
      _Z85StringConversionSink._convertFrame(result, i ~/ 5 * 4, frame);
    }

    return result;
  }

  StringConversionSink startChunkedConversion(Sink<List<int>> sink) =>
      _Z85StringConversionSink(
          sink is ByteConversionSink ? sink : ByteConversionSink.from(sink));
}

/// A [z85](https://rfc.zeromq.org/spec:32/Z85/) encoder and decoder.
///
/// A [Z85Codec] allows z85 encoding bytes into ASCII strings and decoding valid encodings
/// back to bytes.
///
/// This implementation conforms to the z85 spec used by ZeroMQ, and it enforces the length
/// requirements:
///
/// - Encoder input length must be a multiple of 4.
/// - Decoder input length must be a multiple of 5.
class Z85Codec extends Codec<List<int>, String> {
  const Z85Codec();

  Z85Encoder get encoder => Z85Encoder();
  Z85Decoder get decoder => Z85Decoder();
}

final z85 = Z85Codec();
