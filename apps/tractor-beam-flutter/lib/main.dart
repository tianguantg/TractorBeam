import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'bridge/generated/api.dart' as bridge;
import 'bridge/generated/frb_generated.dart';
import 'l10n/generated/app_localizations.dart';
import 'locale/ui_locale_store.dart';
import 'models/tractor_beam_controller.dart';
import 'screens/main_shell.dart';
import 'screens/lightweight_session_view.dart';
import 'startup/startup_warmup.dart';
import 'theme/app_theme.dart';
import 'widgets/app_dialogs.dart';
import 'widgets/app_notification.dart';
import 'widgets/asset_shape_shadow.dart';
import 'window_placement_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  final startupValues = await Future.wait<Object?>([
    if (isDesktop) WindowPlacementStore.load() else Future.value(null),
    UiLocaleStore.loadAndRemember(
      WidgetsBinding.instance.platformDispatcher.locales,
    ),
  ]);
  final initialPlacement = startupValues[0] as SavedWindowPlacement?;
  final initialLocale = startupValues[1] as Locale;
  final windowReady = Completer<void>();
  if (isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    // Rust is intentionally initialized after the first visible Flutter frame.
    const title = 'Tractor Beam';
    final windowOptions = WindowOptions(
      size: initialPlacement?.bounds.size ?? const Size(960, 824),
      minimumSize: const Size(640, 420),
      center: initialPlacement == null,
      backgroundColor: Colors.black,
      skipTaskbar: false,
      title: title,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (initialPlacement != null) {
        await windowManager.setBounds(initialPlacement.bounds);
        if (initialPlacement.maximized) await windowManager.maximize();
      }
      if (!windowReady.isCompleted) windowReady.complete();
    });
  }

  runApp(
    _TractorBeamBootstrap(
      desktopIntegration: isDesktop,
      windowReady: windowReady.future,
      initialPlacement: initialPlacement,
      initialLocale: initialLocale,
    ),
  );
}

/// Shows a minimal first frame before loading Rust or any of the paper UI.
class _TractorBeamBootstrap extends StatefulWidget {
  const _TractorBeamBootstrap({
    required this.desktopIntegration,
    required this.windowReady,
    required this.initialLocale,
    this.initialPlacement,
  });

  final bool desktopIntegration;
  final Future<void> windowReady;
  final SavedWindowPlacement? initialPlacement;
  final Locale initialLocale;

  @override
  State<_TractorBeamBootstrap> createState() => _TractorBeamBootstrapState();
}

class _TractorBeamBootstrapState extends State<_TractorBeamBootstrap>
    with WindowListener {
  TractorBeamController? _controller;
  Object? _startupError;
  bool _ownsWindowListener = false;

  @override
  void initState() {
    super.initState();
    if (widget.desktopIntegration) {
      _ownsWindowListener = true;
      windowManager.addListener(this);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_revealWindow());
      unawaited(_initializeApplication());
    });
  }

  Future<void> _revealWindow() async {
    if (!widget.desktopIntegration) return;
    try {
      await widget.windowReady;
      await windowManager.show();
      await windowManager.focus();
    } catch (error, stack) {
      debugPrint('Unable to reveal startup window: $error\n$stack');
    }
  }

  Future<void> _initializeApplication() async {
    if (mounted) setState(() => _startupError = null);
    try {
      await RustLib.init();
      final initialization = bridge.initialize();
      if (!initialization.accepted &&
          initialization.rejection?.code != 'already_initialized') {
        throw StateError(initialization.rejection?.displayText ?? 'Rust 初始化失败');
      }
      if (widget.desktopIntegration) {
        await windowManager.setTitle('Tractor Beam ${bridge.bridgeVersion()}');
      }
      final controller = TractorBeamController.native();
      if (!mounted) {
        controller.dispose();
        return;
      }
      if (_ownsWindowListener) {
        windowManager.removeListener(this);
        _ownsWindowListener = false;
      }
      setState(() => _controller = controller);
    } catch (error, stack) {
      debugPrint('Application startup failed: $error\n$stack');
      if (mounted) setState(() => _startupError = error);
    }
  }

  @override
  Future<void> onWindowClose() async {
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  @override
  void dispose() {
    if (_ownsWindowListener) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return TbNetApp(
        controller: controller,
        desktopIntegration: widget.desktopIntegration,
        startupShaderWarmUp: widget.desktopIntegration
            ? TractorBeamShaderWarmUp()
            : null,
        onStartupWarmupComplete: widget.desktopIntegration ? () {} : null,
        initialWindowPlacement: widget.initialPlacement,
        initialLocale: widget.initialLocale,
      );
    }
    return MaterialApp(
      title: 'Tractor Beam',
      debugShowCheckedModeBanner: false,
      locale: widget.initialLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: StartupSplash(
        error: _startupError,
        onRetry: () => unawaited(_initializeApplication()),
        onExit: () => unawaited(onWindowClose()),
      ),
    );
  }
}

class TbNetApp extends StatefulWidget {
  const TbNetApp({
    super.key,
    this.controller,
    this.startupShaderWarmUp,
    this.onStartupWarmupComplete,
    this.desktopIntegration = false,
    this.initialWindowPlacement,
    this.initialLocale = const Locale('zh', 'CN'),
  });

  final TractorBeamController? controller;
  final TractorBeamShaderWarmUp? startupShaderWarmUp;
  final FutureOr<void> Function()? onStartupWarmupComplete;
  final bool desktopIntegration;
  final SavedWindowPlacement? initialWindowPlacement;
  final Locale initialLocale;

  @override
  State<TbNetApp> createState() => _TbNetAppState();
}

enum _PresentationMode {
  full,
  enteringLightweight,
  restoringFull,
  lightweightVisible,
  lightweightHidden,
  exiting,
}

class _TbNetAppState extends State<TbNetApp> with WindowListener, TrayListener {
  // WindowManager callbacks are delivered to this State, whose [context]
  // sits above MaterialApp's Navigator. Keep an explicit key so native window
  // events can present routes from the Navigator overlay instead.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _closing = false;
  bool _isWindowResizing = false;
  bool _useLightweightResizeEffects = false;
  Timer? _resizeIdleTimer;
  Timer? _effectRestoreTimer;
  Timer? _imageCacheClearTimer;
  Timer? _windowPlacementSaveTimer;
  late final TractorBeamController _controller;
  _PresentationMode _presentationMode = _PresentationMode.full;
  _PresentationMode _modeBeforeHide = _PresentationMode.full;
  DateTime? _lastTrayClickTime;
  bool _presentationTransitioning = false;
  bool _trayAvailable = false;
  Rect? _fullWindowBounds;
  bool _fullWindowWasMaximized = false;
  Offset? _lastLightweightPosition;
  BigInt _handledReadyGeneration = BigInt.from(-1);
  bool _wasSessionRunning = false;
  bool _closePromptOpen = false;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TractorBeamController.detached();
    _locale = widget.initialLocale.languageCode == 'zh'
        ? const Locale('zh', 'CN')
        : const Locale('en', 'US');
    _wasSessionRunning = _controller.isSessionRunning;
    _fullWindowBounds = widget.initialWindowPlacement?.bounds;
    _fullWindowWasMaximized = widget.initialWindowPlacement?.maximized ?? false;
    _controller.addListener(_handleControllerUpdate);
    windowManager.addListener(this);
    if (widget.desktopIntegration && Platform.isWindows) {
      trayManager.addListener(this);
      unawaited(_initializeTray());
    }
  }

  @override
  void dispose() {
    _resizeIdleTimer?.cancel();
    _effectRestoreTimer?.cancel();
    _imageCacheClearTimer?.cancel();
    _windowPlacementSaveTimer?.cancel();
    windowManager.removeListener(this);
    _controller.removeListener(_handleControllerUpdate);
    if (widget.desktopIntegration && Platform.isWindows) {
      trayManager.removeListener(this);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  void onWindowResize() {
    if (_presentationMode != _PresentationMode.full) return;
    _resizeIdleTimer?.cancel();
    _effectRestoreTimer?.cancel();
    _effectRestoreTimer = null;
    if ((!_isWindowResizing || !_useLightweightResizeEffects) && mounted) {
      setState(() {
        _isWindowResizing = true;
        _useLightweightResizeEffects = true;
      });
    }
    // WM_EXITSIZEMOVE normally ends the mode immediately. This longer timeout
    // is only a fallback for a missing native event and avoids repeatedly
    // discarding/recreating the snapshot while the pointer briefly pauses.
    _resizeIdleTimer = Timer(const Duration(milliseconds: 600), _finishResize);
  }

  @override
  void onWindowResized() => _finishResize();

  @override
  void onWindowMoved() => _scheduleWindowPlacementSave();

  void _finishResize() {
    _resizeIdleTimer?.cancel();
    _resizeIdleTimer = null;
    if (_isWindowResizing && mounted) {
      // First release the texture into a cheap live page. Restore expensive
      // shadows later, after the final native resize frame has been presented.
      setState(() {
        _isWindowResizing = false;
        _useLightweightResizeEffects = true;
      });
      _effectRestoreTimer?.cancel();
      _effectRestoreTimer = Timer(const Duration(milliseconds: 120), () {
        if (mounted && !_isWindowResizing) {
          setState(() => _useLightweightResizeEffects = false);
        }
      });
    }
    _scheduleWindowPlacementSave();
  }

  @override
  void onWindowFocus() {
    if (_presentationMode == _PresentationMode.lightweightHidden) {
      if (_controller.isSessionRunning) {
        unawaited(_showLightweight());
      } else {
        unawaited(_showFullInterface(bringToFront: true));
      }
    }
  }

  @override
  Future<void> onWindowClose() async {
    if (_closePromptOpen || !mounted) return;
    if (_presentationMode == _PresentationMode.full || !_trayAvailable) {
      _closePromptOpen = true;
      try {
        final dialogContext = _navigatorKey.currentState?.overlay?.context;
        if (dialogContext == null) {
          debugPrint('Close dialog skipped because Navigator is not ready');
          return;
        }
        final choice = await showCloseApplicationDialog(
          dialogContext,
          isInRoom: _controller.isInRoom,
          isSessionRunning: _controller.isSessionRunning,
          hasTray: _trayAvailable,
        );
        if (choice == CloseApplicationChoice.hideToTray) {
          await _hideToTray();
        } else if (choice == CloseApplicationChoice.exit) {
          await _exitApplication();
        }
      } finally {
        _closePromptOpen = false;
      }
      return;
    }
    if (_presentationMode != _PresentationMode.full && _trayAvailable) {
      await _hideToTray();
      return;
    }
    await _exitApplication();
  }

  Future<void> _exitApplication() async {
    if (_closing) return;
    _closing = true;
    await _captureAndSaveFullWindowPlacement();
    if (mounted) setState(() => _presentationMode = _PresentationMode.exiting);
    if (_trayAvailable) {
      await trayManager.destroy().catchError((_) {});
      _trayAvailable = false;
    }
    final clean = await _controller.shutdownAndWait();
    if (!clean) {
      debugPrint('TractorBeam shutdown exceeded three seconds; forcing exit');
    }
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  void _scheduleWindowPlacementSave() {
    if (!widget.desktopIntegration ||
        _presentationMode != _PresentationMode.full) {
      return;
    }
    _windowPlacementSaveTimer?.cancel();
    _windowPlacementSaveTimer = Timer(
      const Duration(milliseconds: 350),
      _captureAndSaveFullWindowPlacement,
    );
  }

  Future<void> _captureAndSaveFullWindowPlacement() async {
    if (!widget.desktopIntegration ||
        _presentationMode != _PresentationMode.full) {
      return;
    }
    try {
      final bounds = await windowManager.getBounds();
      final maximized = await windowManager.isMaximized();
      _fullWindowBounds = bounds;
      _fullWindowWasMaximized = maximized;
      await WindowPlacementStore.save(
        SavedWindowPlacement(bounds: bounds, maximized: maximized),
      );
    } catch (error, stack) {
      debugPrint('Unable to persist window placement: $error\n$stack');
    }
  }

  Future<void> _initializeTray() async {
    try {
      await trayManager.setIcon('windows/runner/resources/app_icon.ico');
      await trayManager.setToolTip('Tractor Beam');
      _trayAvailable = true;
      if (_presentationMode == _PresentationMode.lightweightVisible) {
        await windowManager.setSkipTaskbar(true);
      }
      await _updateTrayMenu();
    } catch (error, stack) {
      _trayAvailable = false;
      debugPrint('Unable to initialize system tray: $error\n$stack');
    }
  }

  Future<void> _updateTrayMenu() async {
    if (!_trayAvailable) return;
    final l10n = lookupAppLocalizations(_locale);
    final visible = _presentationMode == _PresentationMode.lightweightVisible;
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            key: 'show_lightweight',
            label: l10n.trayShowMonitor,
            disabled: visible || !_controller.isSessionRunning,
          ),
          MenuItem(
            key: 'show_full',
            label: l10n.trayOpenFull,
            disabled:
                _presentationMode == _PresentationMode.full ||
                _presentationMode == _PresentationMode.restoringFull,
          ),
          MenuItem(
            key: 'hide_window',
            label: l10n.trayHide,
            disabled: _presentationMode == _PresentationMode.lightweightHidden,
          ),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: l10n.trayExit),
        ],
      ),
    );
  }

  void _setLocale(Locale next) {
    if (_locale == next) return;
    setState(() => _locale = next);
    unawaited(UiLocaleStore.save(next));
    unawaited(_updateTrayMenu());
  }

  void _toggleLocale() {
    final next = _locale.languageCode == 'zh'
        ? const Locale('en', 'US')
        : const Locale('zh', 'CN');
    _setLocale(next);
  }

  void _handleControllerUpdate() {
    final launch = _controller.launchProgress;
    final running = _controller.isSessionRunning;
    if (launch?.status == bridge.LaunchStatusDto.ready &&
        launch!.generation != _handledReadyGeneration) {
      _handledReadyGeneration = launch.generation;
      if (_presentationMode == _PresentationMode.full) {
        unawaited(_enterLightweight());
      }
    }
    if (_wasSessionRunning &&
        !running &&
        _presentationMode != _PresentationMode.full &&
        _presentationMode != _PresentationMode.exiting) {
      unawaited(_showFullInterface(bringToFront: true));
    }
    _wasSessionRunning = running;
  }

  Future<void> _enterLightweight() async {
    if (_presentationTransitioning ||
        !_controller.isSessionRunning ||
        _controller.launchProgress?.status != bridge.LaunchStatusDto.ready) {
      return;
    }
    _presentationTransitioning = true;
    var restoreFull = false;
    try {
      if (widget.desktopIntegration) {
        _fullWindowBounds = await windowManager.getBounds();
        _fullWindowWasMaximized = await windowManager.isMaximized();
        await WindowPlacementStore.save(
          SavedWindowPlacement(
            bounds: _fullWindowBounds!,
            maximized: _fullWindowWasMaximized,
          ),
        );
      }
      final profileReady = _controller.waitForSnapshotProfile(
        bridge.SnapshotProfileDto.lightweight,
      );
      if (mounted) {
        setState(() {
          _presentationMode = _PresentationMode.enteringLightweight;
        });
        await WidgetsBinding.instance.endOfFrame;
      }
      final results = await Future.wait<bool>([
        profileReady,
        Future<bool>.delayed(const Duration(milliseconds: 340), () => true),
      ]);
      restoreFull = !results.first || !_controller.isSessionRunning;
      if (!restoreFull) {
        if (widget.desktopIntegration) {
          await windowManager.hide();
          await _configureLightweightWindow(reveal: false);
        }
        if (mounted) {
          setState(
            () => _presentationMode = _PresentationMode.lightweightVisible,
          );
          await WidgetsBinding.instance.endOfFrame;
        }
        if (widget.desktopIntegration) {
          await windowManager.show(inactive: true);
        }
        _scheduleFullUiImageCacheClear();
        await _updateTrayMenu();
      }
    } finally {
      _presentationTransitioning = false;
    }
    if (restoreFull || !_controller.isSessionRunning) {
      await _showFullInterface(bringToFront: true);
    }
  }

  Future<void> _configureLightweightWindow({bool reveal = true}) async {
    const size = Size(380, 360);
    try {
      await windowManager.setAlwaysOnTop(false);
      if (await windowManager.isMaximized()) await windowManager.unmaximize();
      await windowManager.setResizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setMinimumSize(size);
      await windowManager.setMaximumSize(size);
      await windowManager.setSize(size);
      await windowManager.setSkipTaskbar(_trayAvailable);
      await windowManager.setPosition(await _lightweightPosition(size));
      await windowManager.setAlwaysOnTop(true);
      if (reveal) await windowManager.show(inactive: true);
    } catch (error, stack) {
      debugPrint('Unable to configure lightweight window: $error\n$stack');
      await windowManager.setSkipTaskbar(false).catchError((_) {});
      await windowManager.show(inactive: true).catchError((_) {});
    }
  }

  void _scheduleFullUiImageCacheClear() {
    _imageCacheClearTimer?.cancel();
    _imageCacheClearTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted ||
          _presentationMode != _PresentationMode.lightweightVisible) {
        return;
      }
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    });
  }

  Future<Offset> _lightweightPosition(Size size) async {
    final displays = await screenRetriever.getAllDisplays();
    final anchor = _lastLightweightPosition ??
        _fullWindowBounds?.center ??
        await screenRetriever.getCursorScreenPoint();
    var display = displays.isEmpty
        ? await screenRetriever.getPrimaryDisplay()
        : displays.first;
    for (final candidate in displays) {
      final rect =
          (candidate.visiblePosition ?? Offset.zero) &
          (candidate.visibleSize ?? candidate.size);
      if (rect.contains(anchor)) {
        display = candidate;
        break;
      }
    }
    final work =
        (display.visiblePosition ?? Offset.zero) &
        (display.visibleSize ?? display.size);
    final desired =
        _lastLightweightPosition ??
        Offset(work.right - size.width - 16, work.top + 16);
    final maxX = math.max(work.left, work.right - size.width);
    final maxY = math.max(work.top, work.bottom - size.height);
    return Offset(
      desired.dx.clamp(work.left, maxX),
      desired.dy.clamp(work.top, maxY),
    );
  }

  Future<void> _hideToTray() async {
    if (_presentationTransitioning) return;
    if (!_trayAvailable) {
      await windowManager.minimize();
      return;
    }
    _modeBeforeHide = _presentationMode;
    final sessionWasRunning = _controller.isSessionRunning;
    _presentationTransitioning = true;
    try {
      if (_presentationMode == _PresentationMode.full &&
          widget.desktopIntegration) {
        _fullWindowBounds = await windowManager.getBounds();
        _fullWindowWasMaximized = await windowManager.isMaximized();
        await WindowPlacementStore.save(
          SavedWindowPlacement(
            bounds: _fullWindowBounds!,
            maximized: _fullWindowWasMaximized,
          ),
        );
      } else if (_presentationMode == _PresentationMode.lightweightVisible) {
        _lastLightweightPosition = await windowManager.getPosition();
      }
      await _controller.waitForSnapshotProfile(
        bridge.SnapshotProfileDto.background,
      );
      if (mounted) {
        setState(() => _presentationMode = _PresentationMode.lightweightHidden);
        await WidgetsBinding.instance.endOfFrame;
        PaintingBinding.instance.imageCache
          ..clear()
          ..clearLiveImages();
      }
      await windowManager.hide();
      await _updateTrayMenu();
    } finally {
      _presentationTransitioning = false;
    }
    if (sessionWasRunning && !_controller.isSessionRunning) {
      await _showFullInterface(bringToFront: true);
    }
  }

  Future<void> _showLightweight() async {
    if (_presentationMode == _PresentationMode.full) {
      await _enterLightweight();
      return;
    }
    if (!_controller.isSessionRunning) {
      await _showFullInterface(bringToFront: true);
      return;
    }
    if (_presentationTransitioning) return;
    _presentationTransitioning = true;
    try {
      await _controller.waitForSnapshotProfile(
        bridge.SnapshotProfileDto.lightweight,
      );
      if (mounted) {
        setState(
          () => _presentationMode = _PresentationMode.lightweightVisible,
        );
      }
      if (widget.desktopIntegration) await _configureLightweightWindow();
      await _updateTrayMenu();
    } finally {
      _presentationTransitioning = false;
    }
    if (!_controller.isSessionRunning) {
      await _showFullInterface(bringToFront: true);
    }
  }

  Future<void> _showFullInterface({bool bringToFront = true}) async {
    if (_presentationTransitioning ||
        _presentationMode == _PresentationMode.full) {
      return;
    }
    _presentationTransitioning = true;
    final previousMode = _presentationMode;
    try {
      _imageCacheClearTimer?.cancel();
      if (_presentationMode == _PresentationMode.lightweightVisible &&
          widget.desktopIntegration) {
        _lastLightweightPosition = await windowManager.getPosition();
      }
      if (mounted) {
        setState(() => _presentationMode = _PresentationMode.restoringFull);
        await WidgetsBinding.instance.endOfFrame;
      }
      final profileReady = _controller.waitForSnapshotProfile(
        bridge.SnapshotProfileDto.full,
      );
      if (previousMode == _PresentationMode.lightweightVisible) {
        await Future<void>.delayed(const Duration(milliseconds: 340));
      }
      if (widget.desktopIntegration) {
        await windowManager.hide();
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setSkipTaskbar(false);
        await windowManager.setResizable(true);
        await windowManager.setMaximizable(true);
        await windowManager.setMinimumSize(const Size(640, 420));
        await windowManager.setMaximumSize(const Size(10000, 10000));
        if (!_fullWindowWasMaximized && _fullWindowBounds != null) {
          await windowManager.setBounds(_fullWindowBounds!);
        }
        if (_fullWindowWasMaximized) await windowManager.maximize();
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame.timeout(
          const Duration(milliseconds: 120),
          onTimeout: () {},
        );
        await windowManager.show(inactive: !bringToFront);
        if (bringToFront) await windowManager.focus();
      }
      final results = await Future.wait<bool>([
        profileReady,
        Future<bool>.delayed(const Duration(milliseconds: 180), () => true),
      ]);
      if (!results.first) {
        if (mounted) setState(() => _presentationMode = previousMode);
        if (widget.desktopIntegration) {
          if (previousMode == _PresentationMode.lightweightHidden) {
            await windowManager.hide();
          } else if (previousMode == _PresentationMode.lightweightVisible) {
            await _configureLightweightWindow();
          }
        }
        final ctx = _navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          AppNotification.warning(ctx, lookupAppLocalizations(_locale).busy);
        }
        return;
      }
      if (mounted) setState(() => _presentationMode = _PresentationMode.full);
      await _updateTrayMenu();
    } finally {
      _presentationTransitioning = false;
    }
  }

  @override
  void onTrayIconMouseDown() {
    final now = DateTime.now();
    if (_lastTrayClickTime != null &&
        now.difference(_lastTrayClickTime!) < const Duration(milliseconds: 350)) {
      return;
    }
    _lastTrayClickTime = now;
    if (_presentationMode == _PresentationMode.lightweightHidden) {
      if (_modeBeforeHide == _PresentationMode.lightweightVisible &&
          _controller.isSessionRunning) {
        unawaited(_showLightweight());
      } else {
        unawaited(_showFullInterface(bringToFront: true));
      }
    } else {
      unawaited(_hideToTray());
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_lightweight':
        unawaited(_showLightweight());
      case 'show_full':
        unawaited(_showFullInterface());
      case 'hide_window':
        unawaited(_hideToTray());
      case 'exit':
        unawaited(_exitApplication());
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_presentationMode) {
      _PresentationMode.full => WindowResizePerformanceScope(
        isResizing: _isWindowResizing,
        useLightweightEffects: _useLightweightResizeEffects,
        child: MainShell(
          controller: _controller,
          onEnterLightweight: _enterLightweight,
          onToggleLocale: _toggleLocale,
          onLocaleChanged: _setLocale,
        ),
      ),
      _PresentationMode.lightweightVisible => LightweightSessionView(
        controller: _controller,
        onOpenFull: _showFullInterface,
        onHideToTray: _hideToTray,
      ),
      _PresentationMode.enteringLightweight => const StartupSplash(
        key: ValueKey('enter-lightweight-splash'),
      ),
      _PresentationMode.restoringFull => const StartupSplash(
        key: ValueKey('restore-full-splash'),
      ),
      _PresentationMode.lightweightHidden || _PresentationMode.exiting =>
        const SizedBox.expand(key: ValueKey('background-empty-view')),
    };
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Tractor Beam',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Xiaolai',
        fontFamilyFallback: const [
          'Microsoft YaHei',
          'PingFang SC',
          'SimHei',
          'sans-serif',
        ],
        scaffoldBackgroundColor: AppColors.canvasBg,
        // The default Windows ZoomPageTransitionsBuilder permanently wraps
        // the home route in an autoresizing SnapshotWidget. That recreates a
        // full-window raster during native resize even though this app handles
        // navigation on its own two-dimensional canvas.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentRed,
          surface: AppColors.canvasBg,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          insetPadding: EdgeInsets.only(bottom: 76, left: 32, right: 32),
        ),
        cardTheme: CardThemeData(
          color: AppColors.dialogPaper,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: AppColors.paperBorder, width: 1.4),
          ),
        ),
      ),
      builder: VirtualWindowFrameInit(),
      home: widget.onStartupWarmupComplete == null
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: content,
            )
          : StartupWarmupGate(
              controller: _controller,
              shaderWarmUp: widget.startupShaderWarmUp,
              onComplete: widget.onStartupWarmupComplete!,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: content,
              ),
            ),
    );
  }
}
