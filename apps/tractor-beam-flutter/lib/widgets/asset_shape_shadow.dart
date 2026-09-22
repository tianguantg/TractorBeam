import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Enables cheaper transient painting while the native window is being resized.
///
/// The value changes only at the beginning and end of a resize gesture, so
/// dependents are not rebuilt for every WM_SIZE event.
enum WindowResizeAspect { geometry, effects }

class WindowResizePerformanceScope extends InheritedModel<WindowResizeAspect> {
  const WindowResizePerformanceScope({
    super.key,
    required this.isResizing,
    bool? useLightweightEffects,
    required super.child,
  }) : useLightweightEffects = useLightweightEffects ?? isResizing;

  final bool isResizing;
  final bool useLightweightEffects;

  static bool isResizingOf(BuildContext context) =>
      InheritedModel.inheritFrom<WindowResizePerformanceScope>(
        context,
        aspect: WindowResizeAspect.geometry,
      )?.isResizing ??
      false;

  static bool useLightweightEffectsOf(BuildContext context) =>
      InheritedModel.inheritFrom<WindowResizePerformanceScope>(
        context,
        aspect: WindowResizeAspect.effects,
      )?.useLightweightEffects ??
      false;

  static FilterQuality largeImageQualityOf(BuildContext context) =>
      useLightweightEffectsOf(context) ? FilterQuality.low : FilterQuality.high;

  @override
  bool updateShouldNotify(WindowResizePerformanceScope oldWidget) =>
      isResizing != oldWidget.isResizing ||
      useLightweightEffects != oldWidget.useLightweightEffects;

  @override
  bool updateShouldNotifyDependent(
    WindowResizePerformanceScope oldWidget,
    Set<WindowResizeAspect> dependencies,
  ) =>
      (dependencies.contains(WindowResizeAspect.geometry) &&
          isResizing != oldWidget.isResizing) ||
      (dependencies.contains(WindowResizeAspect.effects) &&
          useLightweightEffects != oldWidget.useLightweightEffects);
}

/// Freezes a fixed-size subtree into a texture while the native window is
/// being resized. The child remains mounted, preserving state and semantics,
/// while repeated scale changes no longer repaint its contents.
class WindowResizeSnapshot extends StatefulWidget {
  const WindowResizeSnapshot({
    super.key,
    required this.child,
    this.activationDelay = Duration.zero,
    this.maxPixelRatio = 1,
    this.fitDuringResize,
    this.liveOnVerticalResize = false,
    this.resizeBackgroundColor = Colors.transparent,
  }) : assert(maxPixelRatio > 0);

  final Widget child;
  final Duration activationDelay;
  final double maxPixelRatio;

  /// When set, keeps the captured logical size stable and fits that texture
  /// inside the changing viewport. [BoxFit.none] crops/reveals without scaling.
  /// A null value preserves the legacy constraint-filling behavior.
  final BoxFit? fitDuringResize;

  /// Uses the live lightweight subtree when the viewport height changes.
  /// Cropping a fixed snapshot is visually disruptive for vertical resizing.
  final bool liveOnVerticalResize;
  final Color resizeBackgroundColor;

  @override
  State<WindowResizeSnapshot> createState() => _WindowResizeSnapshotState();
}

class _WindowResizeSnapshotState extends State<WindowResizeSnapshot> {
  late final SnapshotController _controller;
  Timer? _activationTimer;
  bool _snapshotWanted = false;
  Size? _lastLiveSize;
  MediaQueryData? _lastLiveMedia;

  @override
  void initState() {
    super.initState();
    _controller = SnapshotController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resizing = WindowResizePerformanceScope.isResizingOf(context);
    _snapshotWanted = resizing;
    if (!resizing) {
      _activationTimer?.cancel();
      _activationTimer = null;
      _controller.allowSnapshotting = false;
      return;
    }
    if (_controller.allowSnapshotting || _activationTimer != null) {
      return;
    }
    if (widget.activationDelay == Duration.zero) {
      _controller.allowSnapshotting = true;
    } else {
      _activationTimer = Timer(widget.activationDelay, () {
        _activationTimer = null;
        if (mounted && _snapshotWanted) {
          _controller.allowSnapshotting = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read without registering for every MediaQuery aspect. The native window
    // changes MediaQuery.size on every WM_SIZE event, while this fixed-size
    // layer only needs a fresh value when the resize scope itself changes.
    final media =
        context.getInheritedWidgetOfExactType<MediaQuery>()?.data ??
        const MediaQueryData();
    if (!_snapshotWanted) {
      _lastLiveMedia = media;
    }
    final childMedia = _snapshotWanted && widget.fitDuringResize != null
        ? (_lastLiveMedia ?? media)
        : media;
    final snapshotMedia = childMedia.copyWith(
      devicePixelRatio: math.min(media.devicePixelRatio, widget.maxPixelRatio),
    );
    final snapshot = MediaQuery(
      data: snapshotMedia,
      child: SnapshotWidget(
        controller: _controller,
        mode: SnapshotMode.permissive,
        // The wrapped board has a fixed design-space size. Recreating this
        // texture for every native window size would defeat the optimization.
        autoresize: false,
        child: MediaQuery(
          // Snapshot at a cheaper transient pixel ratio without changing the
          // media metrics observed by the real page subtree.
          data: childMedia,
          child: WindowResizePerformanceScope(
            isResizing: false,
            // The page was already painted and cached at full quality before
            // resizing. Keep that subtree stable and snapshot the existing
            // layer at a cheaper pixel ratio instead of rebuilding every
            // image and blur at both ends of the native resize gesture.
            useLightweightEffects: false,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.fitDuringResize == null) return snapshot;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest;
        if (!_snapshotWanted && available.isFinite && !available.isEmpty) {
          _lastLiveSize = available;
        }
        final captured = _lastLiveSize;
        if (!_snapshotWanted || captured == null || captured.isEmpty) {
          return snapshot;
        }
        final verticalResize =
            widget.liveOnVerticalResize &&
            (available.height - captured.height).abs() > 1;
        if (verticalResize) {
          _controller.allowSnapshotting = false;
          return MediaQuery(
            data: media,
            child: WindowResizePerformanceScope(
              isResizing: false,
              useLightweightEffects: true,
              child: widget.child,
            ),
          );
        }
        if (_snapshotWanted && !_controller.allowSnapshotting) {
          _controller.allowSnapshotting = true;
        }
        return ColoredBox(
          color: widget.resizeBackgroundColor,
          child: ClipRect(
            child: FittedBox(
              fit: widget.fitDuringResize!,
              alignment: Alignment.center,
              child: SizedBox.fromSize(size: captured, child: snapshot),
            ),
          ),
        );
      },
    );
  }
}

/// A drop shadow derived from an image's alpha channel, so transparent and
/// torn edges keep their original silhouette instead of becoming a rectangle.
class AssetShapeShadow extends StatelessWidget {
  final ImageProvider<Object> imageProvider;
  final BoxFit fit;
  final Offset offset;
  final double blurRadius;
  final Color color;

  const AssetShapeShadow({
    super.key,
    required this.imageProvider,
    this.fit = BoxFit.fill,
    this.offset = const Offset(5, 6),
    this.blurRadius = 2.2,
    this.color = const Color(0x42000000),
  });

  @override
  Widget build(BuildContext context) {
    final useLightweightEffects =
        WindowResizePerformanceScope.useLightweightEffectsOf(context);
    final silhouette = ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image(
        image: imageProvider,
        fit: fit,
        filterQuality: useLightweightEffects
            ? FilterQuality.low
            : FilterQuality.high,
      ),
    );
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Transform.translate(
          offset: offset,
          // Blur creates a large off-screen saveLayer. Keep the same shaped
          // shadow during live resize, but defer its blur until resizing ends.
          child: useLightweightEffects
              ? silhouette
              : ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: blurRadius,
                    sigmaY: blurRadius,
                  ),
                  child: silhouette,
                ),
        ),
      ),
    );
  }
}
