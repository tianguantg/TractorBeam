import 'package:flutter/material.dart';

typedef TbPaperImageBuilder =
    Widget Function(BuildContext context, ImageProvider<Object> imageProvider);

/// Resolves a paper PNG close to its physical display size and gives every
/// consumer of that surface the exact same ImageProvider/cache key.
class TbPaperImageScope extends StatelessWidget {
  const TbPaperImageScope({
    super.key,
    required this.asset,
    required this.builder,
    this.logicalWidth,
    this.logicalHeight,
  });

  static const double decodeOversample = 1.25;
  static const List<int> decodeBuckets = <int>[
    128,
    192,
    256,
    384,
    512,
    768,
    1024,
    1536,
    2048,
  ];

  final String asset;
  final TbPaperImageBuilder builder;

  /// Optional stable design-space dimensions. These are primarily useful for
  /// startup precaching before the corresponding surface has been laid out.
  final double? logicalWidth;
  final double? logicalHeight;

  static int bucketForLogicalExtent(double logicalExtent, double pixelRatio) {
    final required = (logicalExtent * pixelRatio * decodeOversample).ceil();
    for (final bucket in decodeBuckets) {
      if (required <= bucket) return bucket;
    }
    return decodeBuckets.last;
  }

  static TbPaperDecodeSpec decodeSpec({
    required String asset,
    required double pixelRatio,
    double? logicalWidth,
    double? logicalHeight,
  }) {
    int? cacheWidth;
    int? cacheHeight;
    if (logicalWidth != null && logicalWidth.isFinite && logicalWidth > 0) {
      cacheWidth = bucketForLogicalExtent(logicalWidth, pixelRatio);
    }
    if (logicalHeight != null && logicalHeight.isFinite && logicalHeight > 0) {
      cacheHeight = bucketForLogicalExtent(logicalHeight, pixelRatio);
    }
    return TbPaperDecodeSpec(
      asset: asset,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  static ImageProvider<Object> providerFor({
    required String asset,
    required double pixelRatio,
    double? logicalWidth,
    double? logicalHeight,
  }) => decodeSpec(
    asset: asset,
    pixelRatio: pixelRatio,
    logicalWidth: logicalWidth,
    logicalHeight: logicalHeight,
  ).provider;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            logicalWidth ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : null);
        final height =
            logicalHeight ??
            (constraints.hasBoundedHeight ? constraints.maxHeight : null);
        assert(
          width != null || height != null,
          'Paper asset $asset has no bounded decode dimension.',
        );
        return builder(
          context,
          providerFor(
            asset: asset,
            pixelRatio: pixelRatio,
            logicalWidth: width,
            logicalHeight: height,
          ),
        );
      },
    );
  }
}

@immutable
class TbPaperDecodeSpec {
  const TbPaperDecodeSpec({
    required this.asset,
    required this.cacheWidth,
    required this.cacheHeight,
  });

  final String asset;
  final int? cacheWidth;
  final int? cacheHeight;

  ImageProvider<Object> get provider =>
      ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, AssetImage(asset));

  int? get estimatedRgbaBytes => cacheWidth != null && cacheHeight != null
      ? cacheWidth! * cacheHeight! * 4
      : null;
}
