# z85

A [z85](https://rfc.zeromq.org/spec:32/Z85/) encoder and decoder. Implements the full
`dart:convert` [Codec](https://api.dartlang.org/stable/2.1.0/dart-convert/Codec-class.html) API.

## Usage

*z85* can be used just like all the `dart:convert` codecs (e.g. base64):

```dart
import 'package:z85/z85.dart';

void main() {
  final testBytes = [0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B];
  final testString = 'HelloWorld';

  assert(z85.encode(testBytes) == testString);
  assert(z85.decode(testString) == testBytes);
}
```

Chunked conversions are also supported, again by following the same API. See the API docs
for more information.

## Links

- [GitHub.](https://github.com/kirbyfan64/z85.dart)
- [Pub.](https://pub.dartlang.org/packages/z85)
- [API docs.](https://pub.dartlang.org/documentation/z85/latest/)
