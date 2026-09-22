import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/models/request_cache.dart';

void main() {
  test('coalesces concurrent loads into one request', () async {
    final result = Completer<List<int>?>();
    var calls = 0;
    final cache = RequestCache<List<int>>(
      loader: () {
        calls++;
        return result.future;
      },
      ttl: const Duration(seconds: 30),
    );

    final first = cache.load();
    final second = cache.load();
    expect(identical(first, second), isTrue);
    expect(calls, 1);

    result.complete(const <int>[]);
    expect(await first, isEmpty);
    expect(await cache.load(), isEmpty);
    expect(calls, 1, reason: 'a successful empty value must be cached');
  });

  test('refreshes after expiry and when explicitly forced', () async {
    var now = DateTime(2026, 9, 16);
    var calls = 0;
    final cache = RequestCache<int>(
      loader: () async => ++calls,
      ttl: const Duration(seconds: 30),
      now: () => now,
    );

    expect(await cache.load(), 1);
    now = now.add(const Duration(seconds: 29));
    expect(await cache.load(), 1);
    expect(await cache.load(forceRefresh: true), 2);
    now = now.add(const Duration(seconds: 31));
    expect(await cache.load(), 3);
  });

  test('does not cache failures represented by null', () async {
    var calls = 0;
    final cache = RequestCache<int>(
      loader: () async {
        calls++;
        return null;
      },
      ttl: const Duration(seconds: 30),
    );

    expect(await cache.load(), isNull);
    expect(await cache.load(), isNull);
    expect(calls, 2);
  });
}
