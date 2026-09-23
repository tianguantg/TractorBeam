import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import '../bridge/generated/api.dart' as bridge;
import '../l10n/bridge_message_localizer.dart';
import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_notification.dart';
import '../widgets/asset_shape_shadow.dart';
import '../widgets/custom_title_bar.dart';
import '../widgets/sidebar.dart';
import '../widgets/status_bar.dart';
import 'home_screen.dart';
import 'log_screen.dart';
import 'about_screen.dart';
import 'room_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class MainShell extends StatefulWidget {
  final TractorBeamController? controller;
  final VoidCallback? onEnterLightweight;
  final VoidCallback? onToggleLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  const MainShell({
    super.key,
    this.controller,
    this.onEnterLightweight,
    this.onToggleLocale,
    this.onLocaleChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const Size _designSize = Size(960, 824);
  static const double _pageGap = 80;
  static const double _statusBarHorizontalMargin = 16;
  static const double _statusBarHeight = 48;
  static const double _statusBarBottom = 12;
  static const double _canvasStatusGap = 12;
  static const Duration _pageTransitionDuration = Duration(milliseconds: 640);
  // Preserve the quick departure, but spread the remaining travel over a
  // longer tail so the board eases into its final centered position.
  static const Curve _pageTransitionCurve = Cubic(0.165, 1.0, 0.42, 1.0);

  late final TractorBeamController _controller;
  late final bool _ownsController;
  final _roomController = RoomScreenController();
  late final List<Widget> _pageBoards;
  late final List<Widget> _pageLayers;
  late final ValueNotifier<_PageInteractionState> _pageInteraction;
  Offset _cameraFocus = Offset(_designSize.width / 2, _designSize.height / 2);
  int _selectedNavIndex = 0;
  bool _isPageTransitioning = false;
  int? _prepaintTargetIndex;
  int? _prepaintTargetVersion;
  Timer? _prepaintDelay;
  final Map<int, int> _preparedPageVersions = {0: 0};
  String? _roomVisualSignature;
  int _roomVisualVersion = 0;
  bool _openJoinDialogAfterTransition = false;
  int _handledEventSerial = 0;
  BigInt? _foregroundedLaunchFailureGeneration;
  bool _udpFallbackDialogOpen = false;
  bool _updateNotificationShown = false;
  bridge.SteamIdentityMismatchDto? _lastSteamMismatch;

  static final Map<int, Offset> _pageOrigins = {
    0: Offset.zero,
    1: Offset(_designSize.width + _pageGap, 0),
    2: Offset(-(_designSize.width + _pageGap), 0),
    3: Offset(-(_designSize.width + _pageGap), _designSize.height + _pageGap),
    4: Offset(0, _designSize.height + _pageGap),
    5: Offset(_designSize.width + _pageGap, _designSize.height + _pageGap),
  };

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TractorBeamController.detached();
    _controller.addListener(_handleApplicationUpdate);
    _pageInteraction = ValueNotifier(
      const _PageInteractionState(selectedIndex: 0, isTransitioning: false),
    );
    _pageBoards = [
      _buildPageBoard(
        0,
        HomeScreen(
          onJoinRoom: _onJoinRoomFromHome,
          onLaunchGame: _onLaunchGame,
        ),
      ),
      _buildPageBoard(1, RoomScreen(controller: _roomController)),
      _buildPageBoard(
        2,
        SettingsScreen(onLocaleChanged: widget.onLocaleChanged),
      ),
      _buildPageBoard(3, const StatisticsScreen()),
      _buildPageBoard(4, const LogScreen()),
      _buildPageBoard(5, const AboutScreen()),
    ];
    _pageLayers = [
      for (var pageIndex = 0; pageIndex < _pageBoards.length; pageIndex++)
        _StableWorldPageLayer(
          key: ValueKey('world-page-layer-$pageIndex'),
          pageIndex: pageIndex,
          designSize: _designSize,
          interaction: _pageInteraction,
          child: _pageBoards[pageIndex],
        ),
    ];
  }

  @override
  void dispose() {
    _prepaintDelay?.cancel();
    _controller.removeListener(_handleApplicationUpdate);
    _pageInteraction.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleApplicationUpdate() {
    _surfaceLaunchFailureIfNeeded();
    _trackRoomVisualVersion();
    _notifyUpdateAvailableIfNeeded();
    final mismatch = _controller.steamIdentityMismatch;
    final mismatchAppeared = mismatch != null && _lastSteamMismatch == null;
    _lastSteamMismatch = mismatch;
    if (mismatchAppeared) {
      _onPageSelected(1);
    }
    final event = _controller.latestEvent;
    if (!mounted ||
        event == null ||
        _controller.eventSerial <= _handledEventSerial) {
      return;
    }
    _handledEventSerial = _controller.eventSerial;
    if (event.code == 'shutdown_complete') return;
    // The Relay list already shows its in-progress state. Batch probing can
    // produce many state revisions, so only surface the single final summary.
    if (event.code == 'latency_test' && event.success) return;
    if (event.message.key == 'event.relay_room_joined.udp_unavailable' &&
        event.value != null) {
      unawaited(_offerTcpFallback(event.value!));
      return;
    }
    final isInputDelayWarning =
        !event.success && event.code == 'input_delay_read';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppNotification.show(
        context,
        localizeBridgeEvent(context, event),
        type: event.success || isInputDelayWarning
            ? NotificationType.info
            : NotificationType.error,
        duration: Duration(
          milliseconds: !event.success
              ? (isInputDelayWarning ? 3600 : 4500)
              : 2200,
        ),
      );
    });
  }

  Future<void> _offerTcpFallback(String joinCode) async {
    if (!mounted || _udpFallbackDialogOpen) return;
    _udpFallbackDialogOpen = true;
    try {
      final choice = await showUdpFallbackDialog(context);
      if (!mounted) return;
      switch (choice) {
        case UdpFallbackChoice.retryTcp:
          final receipt = _controller.retryRelayRoomWithTcp(joinCode);
          if (receipt.accepted) {
            AppNotification.info(context, context.l10n.udpTcpRetryStarted);
          } else {
            AppNotification.error(
              context,
              localizeBridgeRejection(
                context,
                receipt.rejection,
                fallback: context.l10n.udpTcpRetryFailed,
              ),
            );
          }
        case UdpFallbackChoice.openSettings:
          _onPageSelected(2);
        case UdpFallbackChoice.cancel:
          break;
      }
    } finally {
      _udpFallbackDialogOpen = false;
    }
  }

  void _notifyUpdateAvailableIfNeeded() {
    if (_updateNotificationShown) return;
    final update = _controller.availableUpdate;
    if (_controller.updateStatus != bridge.UpdateStatusDto.available ||
        update == null) {
      return;
    }
    _updateNotificationShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppNotification.info(
        context,
        context.l10n.startupUpdateAvailableNotice(update.version),
        duration: const Duration(milliseconds: 6000),
        actionLabel: context.l10n.aboutViewUpdateBtn,
        onAction: () async {
          final uri = Uri.tryParse(update.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      );
    });
  }

  void _trackRoomVisualVersion() {
    final room = _controller.snapshot?.room;
    if (room == null) return;
    final signature = '${room.status.name}:${room.generation}:${room.active}';
    if (signature == _roomVisualSignature) return;
    _roomVisualSignature = signature;
    _roomVisualVersion++;
    if (_selectedNavIndex != 1 || _isPageTransitioning) {
      _preparedPageVersions.remove(1);
      return;
    }
    final version = _roomVisualVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _selectedNavIndex == 1 &&
          !_isPageTransitioning &&
          _roomVisualVersion == version) {
        _preparedPageVersions[1] = version;
      }
    });
  }

  void _surfaceLaunchFailureIfNeeded() {
    final launch = _controller.launchProgress;
    if (!_controller.isNative ||
        launch?.status != bridge.LaunchStatusDto.failed ||
        launch!.generation == _foregroundedLaunchFailureGeneration) {
      return;
    }
    _foregroundedLaunchFailureGeneration = launch.generation;
    unawaited(_showLaunchFailure());
  }

  Future<void> _showLaunchFailure() async {
    try {
      // Launching Isaac must never pin or repeatedly refocus this window.
      // Only a terminal failure is important enough to surface to the user.
      if (await windowManager.isMinimized()) await windowManager.restore();
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {
      // Presentation failures must not alter the authoritative launch state.
    }
  }

  void _onLaunchGame() {
    final l10n = context.l10n;
    if (_controller.primarySessionAction ==
        PrimarySessionAction.resolveSteamMismatch) {
      _onPageSelected(1);
      return;
    }
    if (!_controller.isInRoom) {
      if (_controller.isHookReady) {
        AppNotification.info(context, l10n.gameReadyJoinRoomPrompt);
        _onPageSelected(1);
        return;
      }
      AppNotification.warning(context, l10n.pleaseJoinRoomFirst);
      return;
    }
    if (_controller.isSessionRunning) {
      AppNotification.warning(context, l10n.errSessionRunning);
      return;
    }
    if (_controller.isLaunching) {
      AppNotification.info(context, l10n.gameLaunching);
      return;
    }
    final receipt = _controller.startGame();
    if (!receipt.accepted) {
      AppNotification.error(
        context,
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: l10n.errLaunchGeneric,
        ),
      );
      return;
    }
    showLaunchGameDialog(
      context,
      controller: _controller,
      onOpenLogs: () => _onPageSelected(4),
    );
  }

  void _onJoinRoomFromHome() {
    if (_selectedNavIndex == 1 && !_isPageTransitioning) {
      _roomController.requestJoinRoom();
      return;
    }
    _openJoinDialogAfterTransition = true;
    _onPageSelected(1);
  }

  void _onPageSelected(int index) {
    if (!_pageOrigins.containsKey(index) ||
        index == _selectedNavIndex ||
        _isPageTransitioning) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final version = _pageVisualVersion(index);
    if (_preparedPageVersions[index] != version) {
      _preparePageBeforeTransition(index, version);
      return;
    }
    _startPageTransition(index);
  }

  int _pageVisualVersion(int index) => index == 1 ? _roomVisualVersion : 0;

  void _preparePageBeforeTransition(int index, int version) {
    developer.Timeline.instantSync(
      'page_prepaint_begin',
      arguments: {'page': index, 'version': version},
    );
    setState(() {
      _isPageTransitioning = true;
      _prepaintTargetIndex = index;
      _prepaintTargetVersion = version;
    });
    _syncPageInteraction();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _prepaintTargetIndex != index) return;
      // Give the raster thread a short interval to finish the hidden paint
      // before moving the already-built layer into view.
      _prepaintDelay?.cancel();
      _prepaintDelay = Timer(const Duration(milliseconds: 12), () {
        if (!mounted || _prepaintTargetIndex != index) return;
        final latestVersion = _pageVisualVersion(index);
        if (latestVersion != _prepaintTargetVersion) {
          setState(() => _prepaintTargetVersion = latestVersion);
          _preparePageBeforeTransition(index, latestVersion);
          return;
        }
        _preparedPageVersions[index] = latestVersion;
        developer.Timeline.instantSync(
          'page_prepaint_complete',
          arguments: {'page': index, 'version': latestVersion},
        );
        _startPageTransition(index);
      });
    });
  }

  void _startPageTransition(int index) {
    developer.Timeline.instantSync(
      'page_transition_begin',
      arguments: {'from': _selectedNavIndex, 'to': index},
    );
    setState(() {
      _selectedNavIndex = index;
      _isPageTransitioning = true;
      _prepaintTargetIndex = null;
      _prepaintTargetVersion = null;
    });
    _syncPageInteraction();
  }

  void _syncPageInteraction() {
    _pageInteraction.value = _PageInteractionState(
      selectedIndex: _selectedNavIndex,
      isTransitioning: _isPageTransitioning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindowResizing = WindowResizePerformanceScope.isResizingOf(context);
    return TractorBeamScope(
      notifier: _controller,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.paperBorder, width: 1),
        ),
        child: Scaffold(
          backgroundColor: AppColors.canvasBg,
          body: Column(
            children: [
              const CustomTitleBar(),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasWidth = math.max(0.0, constraints.maxWidth);
                      final canvasHeight = math.max(
                        0.0,
                        constraints.maxHeight -
                            _statusBarBottom -
                            _statusBarHeight -
                            _canvasStatusGap,
                      );
                      final canvasScale = math.min(
                        1.0,
                        math.min(
                          canvasWidth / _designSize.width,
                          canvasHeight / _designSize.height,
                        ),
                      );

                      return Stack(
                        children: [
                          Positioned.fill(
                            left: 0,
                            top: 0,
                            right: 0,
                            bottom:
                                _statusBarBottom +
                                _statusBarHeight +
                                _canvasStatusGap,
                            child: _buildWorldViewport(canvasScale),
                          ),
                          if (!isWindowResizing)
                            const Positioned.fill(
                              child: RepaintBoundary(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _WindowVignettePainter(),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            left: _statusBarHorizontalMargin,
                            right: _statusBarHorizontalMargin,
                            bottom: _statusBarBottom,
                            height: _statusBarHeight,
                            child: RepaintBoundary(
                              child: BottomStatusBar(
                                contentScale: canvasScale,
                                onLaunchGame: _onLaunchGame,
                                onNavigateToRoom: () => _onPageSelected(1),
                                onEnterLightweight: widget.onEnterLightweight,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorldViewport(double canvasScale) {
    final targetOrigin = _pageOrigins[_selectedNavIndex]!;
    final targetFocus =
        targetOrigin + Offset(_designSize.width / 2, _designSize.height / 2);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isWindowResizing = WindowResizePerformanceScope.isResizingOf(context);

    return LayoutBuilder(
      builder: (context, viewport) => ClipRect(
        key: const ValueKey('adaptive-design-canvas'),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(begin: _cameraFocus, end: targetFocus),
          duration: reduceMotion ? Duration.zero : _pageTransitionDuration,
          curve: _pageTransitionCurve,
          onEnd: () {
            if (!mounted) return;
            if (_prepaintTargetIndex != null) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_isPageTransitioning) {
                setState(() => _isPageTransitioning = false);
                _syncPageInteraction();
                _preparedPageVersions[_selectedNavIndex] = _pageVisualVersion(
                  _selectedNavIndex,
                );
                developer.Timeline.instantSync(
                  'page_transition_complete',
                  arguments: {'page': _selectedNavIndex},
                );
              }
              if (_openJoinDialogAfterTransition && _selectedNavIndex == 1) {
                _openJoinDialogAfterTransition = false;
                _roomController.requestJoinRoom();
              }
            });
          },
          builder: (context, focus, child) {
            _cameraFocus = focus;
            final pageOrder = List<int>.generate(
              _pageLayers.length,
              (index) => index,
            );
            final prepaintTarget = _prepaintTargetIndex;
            if (prepaintTarget != null) {
              pageOrder
                ..remove(prepaintTarget)
                ..remove(_selectedNavIndex)
                ..add(prepaintTarget)
                ..add(_selectedNavIndex);
            }
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final pageIndex in pageOrder)
                  _positionWorldPage(
                    viewport: viewport.biggest,
                    scale: canvasScale,
                    focus: focus,
                    isWindowResizing: isWindowResizing,
                    pageIndex: pageIndex,
                    forceAtCurrentOrigin: pageIndex == prepaintTarget,
                    child: _pageLayers[pageIndex],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _positionWorldPage({
    required Size viewport,
    required double scale,
    required Offset focus,
    required bool isWindowResizing,
    required int pageIndex,
    bool forceAtCurrentOrigin = false,
    required Widget child,
  }) {
    final origin = forceAtCurrentOrigin
        ? _pageOrigins[_selectedNavIndex]!
        : _pageOrigins[pageIndex]!;
    final screenOrigin = Offset(
      (viewport.width / 2 + (origin.dx - focus.dx) * scale).roundToDouble(),
      (viewport.height / 2 + (origin.dy - focus.dy) * scale).roundToDouble(),
    );
    final screenRect = screenOrigin & (_designSize * scale);
    // Keep every board that intersects the viewport visible even while the camera
    // is idle or the window is being resized. Wide, tall, strip, or pillar windows
    // reveal adjacent pages on the continuous 2D parchment canvas, maintaining the
    // immersive "all pages on one giant canvas" Isaac world-map experience.
    // Pages completely outside the viewport remain mounted. A fully opaque or
    // transparent layer preserves inherited-widget and Windows semantics
    // propagation while the Stack itself clips all off-viewport paint.
    final isVisible =
        forceAtCurrentOrigin ||
        (pageIndex == _selectedNavIndex) ||
        screenRect.overlaps((Offset.zero & viewport).inflate(32));

    return Positioned(
      key: ValueKey('world-page-position-$pageIndex'),
      left: 0,
      top: 0,
      width: _designSize.width,
      height: _designSize.height,
      child: Opacity(
        opacity: isVisible ? 1 : 0,
        alwaysIncludeSemantics: true,
        child: Transform.translate(
          offset: screenOrigin,
          transformHitTests: true,
          child: Transform.scale(
            alignment: Alignment.topLeft,
            scale: scale,
            filterQuality: isWindowResizing ? FilterQuality.low : null,
            transformHitTests: true,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildPageBoard(int pageIndex, Widget content) {
    final boardName = switch (pageIndex) {
      0 => 'home-page-board',
      1 => 'room-page-board',
      2 => 'settings-page-board',
      3 => 'statistics-page-board',
      4 => 'log-page-board',
      5 => 'about-page-board',
      _ => 'page-board-$pageIndex',
    };
    return ColoredBox(
      key: ValueKey(boardName),
      color: AppColors.canvasBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 760,
                child: RepaintBoundary(
                  child: PaperSidebar(
                    selectedIndex: pageIndex,
                    onItemSelected: _onPageSelected,
                    onToggleLocale: widget.onToggleLocale,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// A lightweight, single-pass elliptical vignette painter.
/// Uses a unified elliptical radial gradient matching the window's content aspect ratio:
/// - 1 single GPU draw call (zero saveLayer offscreen passes, zero BlendMode.src cuts).
/// - 100% continuous mathematical falloff with zero color truncation, seams, or arcs.
/// - Keeps the center completely clean and transparent, gently darkening edges and corners.
class _WindowVignettePainter extends CustomPainter {
  const _WindowVignettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final contentRect = Offset.zero & size;
    // Deep warm charcoal ink for authentic Isaac dungeon/parchment shadows
    const shadowInk = Color(0xFF181311);

    // 1. Overall elliptical vignette (pronounced dark edges & corners, clean interior)
    // Clamping aspect ratio avoids extreme distortion when resized into extreme aspect ratios.
    final rawAspect = size.width / size.height;
    final aspect = rawAspect.clamp(0.6, 2.4);
    final transform = Matrix4.identity()
      ..translateByDouble(
        contentRect.center.dx,
        contentRect.center.dy,
        0.0,
        1.0,
      )
      ..scaleByDouble(aspect, 1.0, 1.0, 1.0)
      ..translateByDouble(
        -contentRect.center.dx,
        -contentRect.center.dy,
        0.0,
        1.0,
      );

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.10,
        colors: [
          Colors.transparent,
          Colors.transparent,
          shadowInk.withValues(alpha: 0.32),
          shadowInk.withValues(alpha: 0.68),
          shadowInk.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 0.38, 0.62, 0.84, 1.0],
        transform: _EllipticalGradientTransform(transform),
      ).createShader(contentRect);

    canvas.drawRect(contentRect, vignettePaint);

    // 2. Bottom-left circular head shadow (simulating Isaac's head casting a shadow)
    // Shifted slightly inwards so the circular silhouette peeks gracefully into the viewport.
    final headRadius = math.min(size.height * 0.42, 330.0);
    final headCenter = Offset(
      math.min(size.width * 0.09, 80.0),
      size.height - 15.0,
    );
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          shadowInk.withValues(alpha: 0.45),
          shadowInk.withValues(alpha: 0.30),
          shadowInk.withValues(alpha: 0.14),
          shadowInk.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.72, 0.88, 1.0],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));

    canvas.drawCircle(headCenter, headRadius, headPaint);
  }

  @override
  bool shouldRepaint(covariant _WindowVignettePainter oldDelegate) => false;
}

class _EllipticalGradientTransform extends GradientTransform {
  const _EllipticalGradientTransform(this.matrix);
  final Matrix4 matrix;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => matrix;
}

@immutable
class _PageInteractionState {
  const _PageInteractionState({
    required this.selectedIndex,
    required this.isTransitioning,
  });

  final int selectedIndex;
  final bool isTransitioning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PageInteractionState &&
          selectedIndex == other.selectedIndex &&
          isTransitioning == other.isTransitioning;

  @override
  int get hashCode => Object.hash(selectedIndex, isTransitioning);
}

/// A stable page wrapper that survives every viewport constraint update.
/// Only interaction state changes and resize boundaries rebuild this subtree;
/// native WM_SIZE frames update the compositor transforms above it.
class _StableWorldPageLayer extends StatelessWidget {
  const _StableWorldPageLayer({
    super.key,
    required this.pageIndex,
    required this.designSize,
    required this.interaction,
    required this.child,
  });

  final int pageIndex;
  final Size designSize;
  final ValueListenable<_PageInteractionState> interaction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWindowResizing = WindowResizePerformanceScope.isResizingOf(context);
    return ValueListenableBuilder<_PageInteractionState>(
      valueListenable: interaction,
      builder: (context, pageState, _) {
        final isCurrentPage = pageIndex == pageState.selectedIndex;
        final isInteractive =
            isCurrentPage && !pageState.isTransitioning && !isWindowResizing;

        return RepaintBoundary(
          key: ValueKey('repaint-board-$pageIndex'),
          child: SizedBox.fromSize(
            size: designSize,
            child: Semantics(
              key: ValueKey('page-semantics-$pageIndex'),
              container: true,
              hidden: !isInteractive,
              child: TickerMode(
                enabled:
                    isCurrentPage &&
                    !pageState.isTransitioning &&
                    !isWindowResizing,
                child: IgnorePointer(
                  key: ValueKey('page-pointer-$pageIndex'),
                  ignoring: !isInteractive,
                  child: FocusScope(
                    key: ValueKey('page-focus-scope-$pageIndex'),
                    canRequestFocus: isCurrentPage && !isWindowResizing,
                    descendantsAreFocusable: isInteractive,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
