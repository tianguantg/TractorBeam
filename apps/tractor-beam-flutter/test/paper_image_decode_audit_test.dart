import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/widgets/asset_shape_shadow.dart';
import 'package:tbnet_app/widgets/paper_image.dart';

class _ImageSize {
  const _ImageSize(this.width, this.height);

  final int width;
  final int height;
}

class _PaperTarget {
  const _PaperTarget(this.width, [this.height]);

  final double width;
  final double? height;
}

_ImageSize _readImageSize(File file) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(0) == 0x89504e47) {
    return _ImageSize(data.getUint32(16), data.getUint32(20));
  }
  if (bytes.length >= 30 &&
      data.getUint32(0) == 0x52494646 &&
      data.getUint32(8) == 0x57454250) {
    final w = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16);
    final h = bytes[27] | (bytes[28] << 8) | (bytes[29] << 16);
    return _ImageSize(w + 1, h + 1);
  }
  throw UnsupportedError('Unsupported image format: ${file.path}');
}

int _estimatedBytes(String name, _ImageSize source, _PaperTarget target) {
  final spec = TbPaperImageScope.decodeSpec(
    asset: 'assets/images/paper/$name',
    pixelRatio: 1,
    logicalWidth: target.width,
    logicalHeight: target.height,
  );
  final width = spec.cacheWidth == null
      ? source.width
      : spec.cacheWidth!.clamp(1, source.width);
  final height = spec.cacheHeight == null
      ? (width * source.height / source.width).ceil()
      : spec.cacheHeight!.clamp(1, source.height);
  return width * height * 4;
}

void main() {
  const targets = <String, _PaperTarget>{
    'about_identity_card.webp': _PaperTarget(386, 246),
    'about_links_card.webp': _PaperTarget(386, 246),
    'about_thanks_card.webp': _PaperTarget(790, 356),
    'connection_lan_torn.webp': _PaperTarget(782),
    'connection_paper.webp': _PaperTarget(782),
    'log_console_card_dark.webp': _PaperTarget(790, 587),
    'log_toolbar_card.webp': _PaperTarget(790, 86),
    'notice_paper.webp': _PaperTarget(782),
    'party_card_collapsed.webp': _PaperTarget(790, 85),
    'party_card.webp': _PaperTarget(790, 417),
    'room_code_card.webp': _PaperTarget(386, 252),
    'settings_latency_card.webp': _PaperTarget(386, 293),
    'settings_language_card.webp': _PaperTarget(386, 177),
    'settings_mode_card.webp': _PaperTarget(386, 177),
    'settings_protocol_card.webp': _PaperTarget(386, 190),
    'sidebar_card.webp': _PaperTarget(84, 760),
    'sidebar_pin.webp': _PaperTarget(32, 32),
    'statistics_counter_card.webp': _PaperTarget(386, 305),
    'statistics_hook_card.webp': _PaperTarget(386, 190),
    'statistics_session_card.webp': _PaperTarget(386, 245),
    'statistics_test_card.webp': _PaperTarget(386, 360),
    'steam_account_card.webp': _PaperTarget(386, 252),
  };

  test('paper decode budget stays below 21 MiB at DPR 1.0', () {
    final directory = Directory('assets/images/paper');
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.webp'))
        .toList();
    expect(files, hasLength(24));

    final sizes = <String, _ImageSize>{};
    var sourceBytes = 0;
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final size = _readImageSize(file);
      sizes[name] = size;
      sourceBytes += size.width * size.height * 4;
    }

    var navigationBytes = 0;
    for (final entry in targets.entries) {
      if (entry.key.startsWith('connection_') ||
          entry.key.startsWith('party_card')) {
        continue;
      }
      navigationBytes += _estimatedBytes(
        entry.key,
        sizes[entry.key]!,
        entry.value,
      );
    }
    navigationBytes +=
        <String>['connection_paper.webp', 'connection_lan_torn.webp']
            .map((name) => _estimatedBytes(name, sizes[name]!, targets[name]!))
            .reduce((left, right) => left > right ? left : right);
    navigationBytes += <String>['party_card.webp', 'party_card_collapsed.webp']
        .map((name) => _estimatedBytes(name, sizes[name]!, targets[name]!))
        .reduce((left, right) => left > right ? left : right);

    // empty_room_card.webp and log_console_card.webp are retained source assets
    // but are not referenced by the application. Relay/LAN and expanded/
    // collapsed party papers are mutually exclusive runtime states.
    // ignore: avoid_print
    print(
      'Paper WebP audit: ${(sourceBytes / 1048576).toStringAsFixed(2)} MiB '
      'all-source -> ${(navigationBytes / 1048576).toStringAsFixed(2)} MiB '
      'worst normal navigation at DPR 1.0',
    );
    expect(navigationBytes, lessThanOrEqualTo(21 * 1048576));
  });

  test('application code has no direct full-size paper asset decoding', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final source = dartFiles.map((file) => file.readAsStringSync()).join('\n');
    expect(
      RegExp(
        r'''AssetImage\s*\(\s*['"]assets/images/paper/''',
      ).hasMatch(source),
      isFalse,
    );
    expect(
      RegExp(
        r'''Image\.asset\s*\(\s*['"]assets/images/paper/''',
      ).hasMatch(source),
      isFalse,
    );
  });

  testWidgets('paper background and shadow share one resize cache key', (
    tester,
  ) async {
    ImageProvider<Object>? backgroundProvider;
    ImageProvider<Object>? shadowProvider;
    Object? firstKey;

    Widget app(Size mediaSize) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: mediaSize, devicePixelRatio: 1),
        child: Center(
          child: SizedBox(
            width: 386,
            height: 252,
            child: TbPaperImageScope(
              asset: 'assets/images/paper/room_code_card.webp',
              builder: (context, provider) {
                backgroundProvider = provider;
                shadowProvider = provider;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    AssetShapeShadow(imageProvider: provider),
                    Image(image: provider, fit: BoxFit.fill),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(const Size(960, 824)));
    expect(identical(backgroundProvider, shadowProvider), isTrue);
    firstKey = await backgroundProvider!.obtainKey(
      createLocalImageConfiguration(tester.element(find.byType(Image).last)),
    );

    await tester.pumpWidget(app(const Size(1280, 720)));
    final resizedKey = await backgroundProvider!.obtainKey(
      createLocalImageConfiguration(tester.element(find.byType(Image).last)),
    );
    expect(resizedKey, firstKey, reason: 'window size must not change the key');
  });

  test('paper buckets are DPR-aware and stable', () {
    expect(TbPaperImageScope.bucketForLogicalExtent(386, 1), 512);
    expect(TbPaperImageScope.bucketForLogicalExtent(386, 1.25), 768);
    expect(TbPaperImageScope.bucketForLogicalExtent(386, 1.5), 768);
    expect(TbPaperImageScope.bucketForLogicalExtent(386, 2), 1024);
  });
}
