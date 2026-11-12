// Draws hall.png, the picture of the `hall` page of the two-doors example: a
// dark hall of mirrors with a red door and a blue door at its far end.
// Plain shapes computed pixel by pixel, so the picture is original and
// anyone can change it. Run from site/:
//   dart run examples/02-pages-and-choices/images/draw_hall.dart
import 'dart:io';
import 'dart:typed_data';

const width = 480;
const height = 270;

// The far wall; the hall narrows towards it.
const _backLeft = 150, _backRight = 330, _backTop = 70, _backBottom = 170;

typedef _Color = (int, int, int);

const _ceiling = (16, 14, 26);
const _floor = (28, 24, 38);
const _wall = (22, 20, 34);
const _mirror = (46, 48, 70);
const _shine = (88, 92, 122);
const _back = (34, 30, 48);
const _red = (206, 44, 52);
const _blue = (44, 96, 214);

void main() {
  // Self-check: every PNG's empty IEND chunk carries this CRC.
  if (_crc32('IEND'.codeUnits) != 0xae426082) throw StateError('bad CRC-32');
  final file = File.fromUri(Platform.script.resolve('hall.png'));
  file.writeAsBytesSync(_encodePng(width, height, _pixel));
  stdout.writeln('wrote ${file.path}');
}

_Color _pixel(int x, int y) {
  if (x < _backLeft) return _side(x / _backLeft, y);
  if (x >= _backRight) return _side((width - 1 - x) / (width - _backRight), y);
  if (y < _backTop) return _ceiling;
  if (y >= _backBottom) return _floorAt(x, y);
  return _backWall(x, y);
}

/// A side wall at depth [u] (0 at the viewer, 1 at the far wall), with the
/// ceiling above it and the floor below.
_Color _side(double u, int y) {
  final top = _backTop * u;
  final bottom = height - (height - _backBottom) * u;
  if (y < top) return _ceiling;
  if (y >= bottom) return _floor;
  final v = (y - top) / (bottom - top);
  final inPanel =
      v > 0.12 &&
      v < 0.88 &&
      [
        (0.08, 0.3),
        (0.42, 0.62),
        (0.72, 0.86),
      ].any((p) => u > p.$1 && u < p.$2);
  if (!inPanel) return _wall;
  // A diagonal glint across each mirror.
  return ((u * 9 + v * 2) % 1.0) < 0.12 ? _shine : _mirror;
}

const _doors = [(172, 222, _red), (258, 308, _blue)];
const _doorTop = 92;

_Color _backWall(int x, int y) {
  for (final (left, right, color) in _doors) {
    if (x >= left && x < right && y >= _doorTop) {
      // A darker frame, then the glowing door.
      final edge = [x - left, right - 1 - x, y - _doorTop].reduce(_min);
      return edge < 3 ? _mix(color, _back, 0.55) : color;
    }
    final dx = x < left ? left - x : (x >= right ? x - right + 1 : 0);
    final dy = y < _doorTop ? _doorTop - y : 0;
    final distance = dx > dy ? dx : dy;
    if (distance < 6) return _mix(color, _back, 0.35);
    if (distance < 12) return _mix(color, _back, 0.18);
  }
  return _back;
}

/// The floor, with each door's light spilling towards the viewer.
_Color _floorAt(int x, int y) {
  for (final (left, right, color) in _doors) {
    if (x >= left && x < right && y < _backBottom + 40) {
      return _mix(color, _floor, y < _backBottom + 16 ? 0.3 : 0.15);
    }
  }
  return _floor;
}

int _min(int a, int b) => a < b ? a : b;

_Color _mix(_Color a, _Color b, double t) => (
  (a.$1 * t + b.$1 * (1 - t)).round(),
  (a.$2 * t + b.$2 * (1 - t)).round(),
  (a.$3 * t + b.$3 * (1 - t)).round(),
);

/// An 8-bit RGB PNG of [pixel], each row filtered with "Sub" (it suits
/// flat shapes).
Uint8List _encodePng(int w, int h, _Color Function(int x, int y) pixel) {
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(1); // Sub filter
    var previous = (0, 0, 0);
    for (var x = 0; x < w; x++) {
      final c = pixel(x, y);
      raw
        ..addByte((c.$1 - previous.$1) & 0xff)
        ..addByte((c.$2 - previous.$2) & 0xff)
        ..addByte((c.$3 - previous.$3) & 0xff);
      previous = c;
    }
  }
  final header = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2); // RGB
  final png = BytesBuilder()
    ..add(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    ..add(_chunk('IHDR', header.buffer.asUint8List()))
    ..add(_chunk('IDAT', ZLibCodec(level: 9).encode(raw.takeBytes())))
    ..add(_chunk('IEND', const []));
  return png.takeBytes();
}

List<int> _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  final out = ByteData(12 + data.length)..setUint32(0, data.length);
  for (var i = 0; i < body.length; i++) {
    out.setUint8(4 + i, body[i]);
  }
  out.setUint32(4 + body.length, _crc32(body));
  return out.buffer.asUint8List();
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var k = 0; k < 8; k++) {
      crc = crc & 1 == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return crc ^ 0xffffffff;
}
