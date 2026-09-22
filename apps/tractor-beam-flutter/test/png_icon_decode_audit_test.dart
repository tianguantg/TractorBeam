import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/widgets/custom_icons.dart';

class _PngSize {
  const _PngSize(this.width, this.height);

  final int width;
  final int height;
}

class _DecodeTarget {
  const _DecodeTarget({this.width = 32, this.height, this.stretched = false});

  final double width;
  final double? height;
  final bool stretched;
}

_PngSize _readPngSize(File file) {
  final bytes = file.readAsBytesSync();
  expect(bytes.length, greaterThanOrEqualTo(24), reason: file.path);
  final data = ByteData.sublistView(bytes);
  expect(data.getUint32(0), 0x89504e47, reason: file.path);
  return _PngSize(data.getUint32(16), data.getUint32(20));
}

void main() {
  const specialTargets = <String, _DecodeTarget>{
    'about_title.png': _DecodeTarget(width: 112),
    'home_title.png': _DecodeTarget(width: 104),
    'log_title.png': _DecodeTarget(width: 112),
    'room_title.png': _DecodeTarget(width: 112),
    'settings_title.png': _DecodeTarget(width: 112),
    'statistics_title.png': _DecodeTarget(width: 112),
    'launch_game.png': _DecodeTarget(width: 34),
    'party_page_previous.png': _DecodeTarget(width: 18, height: 64),
    'party_page_next.png': _DecodeTarget(width: 18, height: 64),
    'settings_latency_level.png': _DecodeTarget(
      width: 76,
      height: 42,
      stretched: true,
    ),
    'room_dashed_line.png': _DecodeTarget(
      width: 800,
      height: 6,
      stretched: true,
    ),
    'dashed_line.png': _DecodeTarget(width: 800, height: 12, stretched: true),
  };

  test('PNG icon decode budget stays below twenty percent at DPR 1.0', () {
    final directory = Directory('assets/icons/ui');
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.png'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));

    expect(files, isNotEmpty);
    var sourceBytes = 0;
    var targetBytes = 0;

    for (final file in files) {
      final size = _readPngSize(file);
      final name = file.uri.pathSegments.last;
      final target = specialTargets[name] ?? const _DecodeTarget();
      sourceBytes += size.width * size.height * 4;

      final decodedWidth = TbPngAsset.bucketForLogicalExtent(target.width, 1);
      final decodedHeight = target.stretched
          ? TbPngAsset.bucketForLogicalExtent(target.height!, 1)
          : (decodedWidth * size.height / size.width).ceil();
      targetBytes += decodedWidth * decodedHeight * 4;

      if (target.width <= 32 && (size.width >= 500 || size.height >= 500)) {
        expect(
          decodedWidth,
          lessThan(500),
          reason: '$name must not decode at its oversized source dimensions',
        );
      }
    }

    final reduction = 1 - (targetBytes / sourceBytes);
    // Kept visible in test logs so asset additions have an immediate cost.
    // ignore: avoid_print
    print(
      'PNG icon audit: ${(sourceBytes / 1048576).toStringAsFixed(2)} MiB '
      'source -> ${(targetBytes / 1048576).toStringAsFixed(2)} MiB target '
      '(${(reduction * 100).toStringAsFixed(1)}% reduction)',
    );
    expect(targetBytes, lessThanOrEqualTo(sourceBytes * .20));
  });

  test('common icon sizes create no more than two buckets per DPR', () {
    for (final pixelRatio in <double>[1, 1.25, 1.5, 2]) {
      final buckets = <int>{
        for (final size in <double>[16, 18, 20, 24])
          TbPngAsset.bucketForLogicalExtent(size, pixelRatio),
      };
      expect(buckets.length, lessThanOrEqualTo(2), reason: 'DPR $pixelRatio');
    }
  });
}
