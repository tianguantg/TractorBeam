/// Coalesces identical asynchronous loads and keeps successful results for a
/// short period. A successful empty collection is still a valid cached value.
class RequestCache<T> {
  RequestCache({
    required Future<T?> Function() loader,
    required this.ttl,
    DateTime Function()? now,
  }) : _loader = loader,
       _now = now ?? DateTime.now;

  final Future<T?> Function() _loader;
  final Duration ttl;
  final DateTime Function() _now;

  Future<T?>? _inFlight;
  T? _value;
  DateTime? _loadedAt;
  bool _hasValue = false;

  bool get hasFreshValue {
    final loadedAt = _loadedAt;
    return _hasValue && loadedAt != null && _now().difference(loadedAt) < ttl;
  }

  Future<T?> load({bool forceRefresh = false}) {
    final active = _inFlight;
    if (active != null) return active;
    if (!forceRefresh && hasFreshValue) return Future<T?>.value(_value);

    late final Future<T?> request;
    request = _loader()
        .then((value) {
          if (value != null) seed(value);
          return value;
        })
        .whenComplete(() {
          if (identical(_inFlight, request)) _inFlight = null;
        });
    _inFlight = request;
    return request;
  }

  void seed(T value) {
    _value = value;
    _loadedAt = _now();
    _hasValue = true;
  }

  void invalidate() {
    _value = null;
    _loadedAt = null;
    _hasValue = false;
  }
}
