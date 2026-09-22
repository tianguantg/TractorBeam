import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Decodes a PNG close to its physical display size while retaining the
/// original asset and layout behavior.
class TbPngAsset extends StatelessWidget {
  const TbPngAsset({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode,
    this.filterQuality = FilterQuality.high,
    this.gaplessPlayback = false,
    this.decodeAxis = Axis.horizontal,
    this.decodeToLayoutBounds = false,
    this.aspectRatio,
    this.excludeFromSemantics = true,
    this.semanticLabel,
  });

  static const double decodeOversample = 1.25;
  static const List<int> decodeBuckets = <int>[
    16,
    24,
    32,
    48,
    64,
    96,
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
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;

  /// The single dimension sent to the decoder for aspect-preserving assets.
  final Axis decodeAxis;

  /// Uses bounded layout width and height for intentionally stretched assets.
  final bool decodeToLayoutBounds;

  /// Keeps layout based on the source aspect ratio instead of the decoder's
  /// integer-rounded target dimensions.
  final double? aspectRatio;

  /// Whether to exclude this image asset from the accessibility semantics tree.
  final bool excludeFromSemantics;

  /// Optional semantic label when the image conveys meaningful information.
  final String? semanticLabel;

  static int bucketForLogicalExtent(double logicalExtent, double pixelRatio) {
    final required = (logicalExtent * pixelRatio * decodeOversample).ceil();
    for (final bucket in decodeBuckets) {
      if (required <= bucket) return bucket;
    }
    return decodeBuckets.last;
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    if (!decodeToLayoutBounds) {
      final image = _image(pixelRatio: pixelRatio);
      if (aspectRatio == null || width == null || height != null) return image;
      return SizedBox(
        width: width,
        height: width! / aspectRatio!,
        child: image,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => _image(
        pixelRatio: pixelRatio,
        layoutWidth: constraints.hasBoundedWidth ? constraints.maxWidth : null,
        layoutHeight: constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null,
      ),
    );
  }

  Widget _image({
    required double pixelRatio,
    double? layoutWidth,
    double? layoutHeight,
  }) {
    int? cacheWidth;
    int? cacheHeight;
    if (decodeToLayoutBounds) {
      final targetWidth = width ?? layoutWidth;
      final targetHeight = height ?? layoutHeight;
      if (targetWidth != null && targetWidth.isFinite && targetWidth > 0) {
        cacheWidth = bucketForLogicalExtent(targetWidth, pixelRatio);
      }
      if (targetHeight != null && targetHeight.isFinite && targetHeight > 0) {
        cacheHeight = bucketForLogicalExtent(targetHeight, pixelRatio);
      }
    } else if (decodeAxis == Axis.horizontal && width != null) {
      cacheWidth = bucketForLogicalExtent(width!, pixelRatio);
    } else if (decodeAxis == Axis.vertical && height != null) {
      cacheHeight = bucketForLogicalExtent(height!, pixelRatio);
    }

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      excludeFromSemantics: excludeFromSemantics,
      semanticLabel: semanticLabel,
    );
  }
}

class TbIcons {
  static const String _root = 'assets/icons/ui';

  static Widget _asset(
    String name, {
    required double size,
    Color? color,
    Key? key,
  }) {
    return TbPngAsset(
      key: key,
      asset: '$_root/$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }

  static Widget homeNetwork({double size = 24, Color? color}) =>
      _asset('home', size: size, color: color);

  static Widget roomBars({double size = 24, Color? color}) =>
      _asset('room', size: size, color: color);

  static Widget settingsSliders({double size = 24, Color? color}) =>
      _asset('settings', size: size, color: color);

  static Widget settingsReadGame({double size = 20, Color? color}) =>
      _asset('settings_read_game', size: size, color: color);

  static Widget settingsWriteGame({double size = 20, Color? color}) =>
      _asset('settings_write_game', size: size, color: color);

  static Widget floatingWindow({double size = 20, Color? color}) =>
      _asset('floating_window', size: size, color: color);

  static Widget language({double size = 22, Color? color, Key? key}) =>
      _asset('language', size: size, color: color, key: key);

  static Widget settingsTitle({double width = 112}) => TbPngAsset(
    asset: '$_root/settings_title.png',
    width: width,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
    excludeFromSemantics: false,
    semanticLabel: '设置',
  );

  static Widget settingsLatencyLevel({
    required int level,
    double width = 76,
    double height = 42,
  }) {
    final safeLevel = level.clamp(0, 5);
    const fillStops = <double>[0, .197, .357, .554, .747, 1];
    final asset = '$_root/settings_latency_level.png';

    Widget tinted(Color color) => ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: TbPngAsset(
        asset: asset,
        width: width,
        height: height,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        decodeToLayoutBounds: true,
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          tinted(AppColors.inkMuted.withValues(alpha: .42)),
          if (safeLevel > 0)
            ClipRect(
              clipper: _FractionalWidthClipper(fillStops[safeLevel]),
              child: tinted(AppColors.ink),
            ),
        ],
      ),
    );
  }

  static Widget statsChart({double size = 24, Color? color}) =>
      _asset('statistics', size: size, color: color);

  static Widget statisticsTitle({double width = 112, Key? key}) => TbPngAsset(
    asset: '$_root/statistics_title.png',
    key: key,
    width: width,
    aspectRatio: 1309 / 638,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
    excludeFromSemantics: false,
    semanticLabel: '统计',
  );

  static Widget logTitle({double width = 112, Key? key}) => TbPngAsset(
    asset: '$_root/log_title.png',
    key: key,
    width: width,
    aspectRatio: 247 / 128,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
    excludeFromSemantics: false,
    semanticLabel: '日志',
  );

  static Widget aboutTitle({double width = 112, Key? key}) => TbPngAsset(
    asset: '$_root/about_title.png',
    key: key,
    width: width,
    aspectRatio: 240 / 128,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
    excludeFromSemantics: false,
    semanticLabel: '关于',
  );

  static Widget externalLink({double size = 18, Color? color}) =>
      _asset('external_link', size: size, color: color);

  static Widget thanksHeart({double size = 22, Color? color}) =>
      _asset('thanks_heart', size: size, color: color);

  static Widget exportDiagnostics({double size = 18, Color? color}) =>
      _asset('export_diagnostics', size: size, color: color);

  static Widget locateFolder({double size = 18, Color? color}) =>
      _asset('locate_folder', size: size, color: color);

  static Widget clearLogs({double size = 18, Color? color}) =>
      _asset('clear_logs', size: size, color: color);

  static Widget openSourceLinks({double size = 20, Color? color}) =>
      _asset('open_source_links', size: size, color: color);

  static Widget logsTerminal({double size = 24, Color? color}) =>
      _asset('logs', size: size, color: color);

  static Widget infoCircle({double size = 16, Color? color}) =>
      _asset('about', size: size, color: color);

  static Widget gamepad({double size = 20, Color? color}) {
    return TbPngAsset(
      asset: '$_root/launch_game.png',
      width: size * 1.68,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }

  static Widget relayNodes({double size = 18, Color? color}) =>
      _asset('relay_server', size: size, color: color);

  static Widget lanRadar({double size = 18, Color? color}) =>
      _asset('lan', size: size, color: color);

  static Widget switchDirection({double size = 18, Color? color}) =>
      _asset('switch', size: size, color: color);

  static Widget add({double size = 18, Color? color}) =>
      _asset('add', size: size, color: color);

  static Widget edit({double size = 18, Color? color}) =>
      _asset('edit', size: size, color: color);

  static Widget speedGauge({double size = 16, Color? color}) =>
      _asset('test_latency', size: size, color: color);

  static Widget latencyGreen({double size = 16}) =>
      _asset('latency_green', size: size);

  static Widget latencyYellow({double size = 16}) =>
      _asset('latency_yellow', size: size);

  static Widget latencyRed({double size = 16, Color? color}) =>
      _asset('latency_red', size: size, color: color);

  static Widget noticeAlert({double size = 24, Color? color}) =>
      _asset('notice_alert', size: size, color: color);

  static Widget sectionTriangle({double size = 18, Color? color}) =>
      _asset('section_triangle', size: size, color: color);

  static Widget copyRoomCode({double size = 18, Color? color}) =>
      _asset('copy_room_code', size: size, color: color);

  static Widget roomHistory({double size = 18, Color? color}) =>
      _asset('room_history', size: size, color: color);

  static Widget joinRoom({double size = 20, Color? color}) =>
      _asset('join_room', size: size, color: color);

  static Widget leaveRoom({double size = 20, Color? color}) =>
      _asset('leave_room', size: size, color: color);

  static Widget partyPagePrevious({
    double width = 18,
    double height = 64,
    Color? color,
  }) => TbPngAsset(
    asset: '$_root/party_page_previous.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
    filterQuality: FilterQuality.high,
    decodeAxis: Axis.vertical,
  );

  static Widget partyPageNext({
    double width = 18,
    double height = 64,
    Color? color,
  }) => TbPngAsset(
    asset: '$_root/party_page_next.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
    filterQuality: FilterQuality.high,
    decodeAxis: Axis.vertical,
  );

  static Widget refreshAccount({double size = 20, Color? color}) =>
      _asset('refresh_account', size: size, color: color);

  static Widget relayRadio({required bool selected, double size = 20}) =>
      _asset(selected ? 'relay_radio_on' : 'relay_radio_off', size: size);

  static Widget relayCheckbox({
    required bool selected,
    double size = 20,
    Color? color,
  }) => _asset(
    selected ? 'relay_checkbox_on' : 'relay_checkbox_off',
    size: size,
    color: color,
  );

  static Widget close({double size = 16, Color? color}) => TbPngAsset(
    asset: 'assets/icons/window_close.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
  );

  static Widget roomTitle({double width = 112}) => TbPngAsset(
    asset: '$_root/room_title.png',
    width: width,
    aspectRatio: 2262 / 1230,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
    excludeFromSemantics: false,
    semanticLabel: '房间',
  );

  static Widget roomDashedLine({double height = 6, Key? key}) => TbPngAsset(
    asset: '$_root/room_dashed_line.png',
    key: key,
    height: height,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
    decodeToLayoutBounds: true,
  );

  /// Renders the appropriate latency icon according to LatencyGrade:
  /// - excellent: green
  /// - fair: yellow
  /// - poor: orange-red
  /// - severe: deep red
  static Widget latencyIconForGrade(LatencyGrade grade, {double size = 16}) {
    switch (grade) {
      case LatencyGrade.excellent:
        return latencyGreen(size: size);
      case LatencyGrade.fair:
        return latencyYellow(size: size);
      case LatencyGrade.poor:
        return _asset(
          'latency_red',
          size: size,
          color: const Color(0xFFE67E22),
        );
      case LatencyGrade.severe:
        return latencyRed(size: size);
    }
  }

  /// Server latency icon (0-30 优秀, 30-60 一般, 60-100 差, >100 严重)
  static Widget latencyServerIcon(int milliseconds, {double size = 16}) =>
      latencyIconForGrade(
        LatencyTheme.evaluateServer(milliseconds),
        size: size,
      );

  /// P2P latency icon (0-60 优秀, 60-100 一般, 100-150 差, >150 严重)
  static Widget latencyP2pIcon(int milliseconds, {double size = 16}) =>
      latencyIconForGrade(LatencyTheme.evaluateP2p(milliseconds), size: size);

  /// Backwards-compatible alias for P2P latency.
  static Widget latencyFor(int milliseconds, {double size = 16}) =>
      latencyP2pIcon(milliseconds, size: size);

  static Widget doorJoin({double size = 16, Color? color}) =>
      roomBars(size: size, color: color);

  static Widget routingBoxes({double size = 16, Color? color}) =>
      relayNodes(size: size, color: color);

  static Widget dashedLine({double height = 12, Color? color, Key? key}) {
    return TbPngAsset(
      asset: '$_root/dashed_line.png',
      key: key,
      height: height,
      fit: BoxFit.fill,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      decodeToLayoutBounds: true,
    );
  }
}

class _FractionalWidthClipper extends CustomClipper<Rect> {
  final double fraction;

  const _FractionalWidthClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionalWidthClipper oldClipper) =>
      fraction != oldClipper.fraction;
}
