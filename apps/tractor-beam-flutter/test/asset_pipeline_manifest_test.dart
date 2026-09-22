import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PNG normalization manifest covers every paper asset', () {
    final spec = jsonDecode(
      File('tool/asset_specs.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(spec['schemaVersion'], 1);

    final papers = spec['papers'] as Map<String, dynamic>;
    expect(papers['mode'], 'audit-only');
    final items = papers['items'] as Map<String, dynamic>;
    final files = Directory(papers['source'] as String)
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.webp'))
        .map((file) => file.uri.pathSegments.last)
        .toSet();

    expect(items.keys.toSet(), files);
    for (final entry in items.entries) {
      final rule = entry.value as Map<String, dynamic>;
      final size = rule['renderSize'] as List<dynamic>;
      expect(size, hasLength(2), reason: entry.key);
      expect(size.every((value) => value is int && value > 0), isTrue);
      expect(rule['strokeClass'], isNotEmpty, reason: entry.key);
    }
  });

  test('icon normalization overrides reference existing PNG assets', () {
    final spec = jsonDecode(
      File('tool/asset_specs.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final icons = spec['icons'] as Map<String, dynamic>;
    final source = Directory(icons['source'] as String);
    final files = source
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.png'))
        .map((file) => file.uri.pathSegments.last)
        .toSet();
    expect(files, isNotEmpty);

    final overrides = icons['overrides'] as Map<String, dynamic>;
    expect(overrides.keys.toSet().difference(files), isEmpty);
    final defaults = icons['defaults'] as Map<String, dynamic>;
    expect(defaults['opticalCenter'], isTrue);
    expect(defaults['visibleRatio'], inInclusiveRange(0.7, 0.85));
  });
}
