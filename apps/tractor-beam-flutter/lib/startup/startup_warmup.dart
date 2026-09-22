import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:window_manager/window_manager.dart';

import '../bridge/generated/api.dart' as bridge;
import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/custom_icons.dart';
import '../widgets/paper_image.dart';
import '../widgets/torn_paper.dart';

/// Warms only the Skia operations used by the paper UI and its dialogs.
class TractorBeamShaderWarmUp extends ShaderWarmUp {
  TractorBeamShaderWarmUp();

  final Completer<void> _completed = Completer<void>();

  Future<void> get completed => _completed.future;

  @override
  ui.Size get size => const ui.Size(360, 240);

  @override
  Future<void> execute() async {
    final task = TimelineTask()..start('shader_warmup');
    final stopwatch = Stopwatch()..start();
    try {
      await super.execute();
    } catch (error, stack) {
      debugPrint('Startup warm-up shader_warmup failed: $error\n$stack');
    } finally {
      task.finish(arguments: {'elapsed_us': stopwatch.elapsedMicroseconds});
      if (!_completed.isCompleted) _completed.complete();
    }
  }

  @override
  Future<void> warmUpOnCanvas(ui.Canvas canvas) async {
    final rect = const ui.Rect.fromLTWH(18, 18, 250, 150);
    final paperPath = buildTornPaperPath(
      rect.size,
      radius: 7,
      seed: 96,
      roughness: 2.2,
    ).shift(rect.topLeft);

    canvas.drawPath(
      paperPath.shift(const ui.Offset(5, 6)),
      ui.Paint()..color = const ui.Color(0x42000000),
    );
    canvas.drawPath(
      paperPath,
      ui.Paint()
        ..color = AppColors.dialogPaper
        ..style = ui.PaintingStyle.fill,
    );
    canvas.drawPath(
      paperPath,
      ui.Paint()
        ..color = AppColors.paperBorder
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round,
    );

    canvas.save();
    canvas.clipPath(paperPath);
    canvas.scale(1.025, 0.99);
    canvas.saveLayer(
      rect,
      ui.Paint()..color = const ui.Color.fromARGB(210, 255, 255, 255),
    );
    canvas.drawRect(
      rect,
      ui.Paint()
        ..color = AppColors.accentRed
        ..colorFilter = const ui.ColorFilter.mode(
          AppColors.ink,
          ui.BlendMode.srcIn,
        ),
    );
    canvas.restore();
    canvas.restore();

    canvas.saveLayer(
      const ui.Rect.fromLTWH(275, 35, 70, 70),
      ui.Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
    );
    canvas.drawCircle(
      const ui.Offset(310, 70),
      26,
      ui.Paint()..color = const ui.Color(0x66000000),
    );
    canvas.restore();
  }
}

/// Keeps a cheap visible startup frame mounted until common first-use paths
/// have either warmed successfully or reached the hard startup deadline.
class StartupSplash extends StatelessWidget {
  const StartupSplash({super.key, this.error, this.onRetry, this.onExit});

  final Object? error;
  final VoidCallback? onRetry;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('startup-splash'),
      color: Colors.black,
      child: error == null
          ? Center(
              child: Image.asset(
                'assets/icons/app_mark.png',
                key: const ValueKey('startup-app-mark'),
                width: 112,
                height: 112,
                cacheWidth: 128,
                cacheHeight: 128,
                filterQuality: FilterQuality.medium,
              ),
            )
          : Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 44,
                  child: Row(
                    children: [
                      const Expanded(
                        child: DragToMoveArea(child: SizedBox.expand()),
                      ),
                      if (onExit != null)
                        IconButton(
                          key: const ValueKey('startup-error-close'),
                          tooltip: context.l10n.windowClose,
                          onPressed: onExit,
                          icon: TbIcons.close(
                            size: 16,
                            color: const Color(0xFFB7ADB0),
                          ),
                        ),
                    ],
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/app_mark.png',
                          width: 96,
                          height: 96,
                          cacheWidth: 128,
                          cacheHeight: 128,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.startupFailed,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Text(
                            '$error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB7ADB0),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onExit != null) ...[
                              OutlinedButton(
                                key: const ValueKey('startup-error-exit'),
                                onPressed: onExit,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFF5A5255),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                child: Text(context.l10n.dialogExitButton),
                              ),
                              const SizedBox(width: 14),
                            ],
                            if (onRetry != null)
                              FilledButton(
                                key: const ValueKey('startup-error-retry'),
                                onPressed: onRetry,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accentRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                ),
                                child: Text(context.l10n.retry),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class StartupWarmupGate extends StatefulWidget {
  const StartupWarmupGate({
    super.key,
    required this.controller,
    required this.child,
    required this.onComplete,
    this.shaderWarmUp,
    this.timeout = const Duration(milliseconds: 750),
  });

  final TractorBeamController controller;
  final Widget child;
  final FutureOr<void> Function() onComplete;
  final TractorBeamShaderWarmUp? shaderWarmUp;
  final Duration timeout;

  @override
  State<StartupWarmupGate> createState() => _StartupWarmupGateState();
}

class _StartupWarmupGateState extends State<StartupWarmupGate> {
  final GlobalKey _dialogBoundaryKey = GlobalKey(
    debugLabel: 'startup-lan-dialog-boundary',
  );
  bool _showWarmupScene = true;
  bool _started = false;
  bool _released = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    final warmup = () async {
      try {
        await _runWarmup();
      } catch (error, stack) {
        debugPrint('Startup warm-up failed: $error\n$stack');
      }
    }();
    await Future.any<void>([warmup, Future<void>.delayed(widget.timeout)]);
    await _releaseWindow();
  }

  Future<void> _runWarmup() async {
    final shader = widget.shaderWarmUp?.execute() ?? Future<void>.value();
    final images = _trace('image_precache', _precacheImages);
    final adapters = _trace('lan_adapter_prefetch', _prefetchLanAdapters);
    await Future.wait<void>([shader, images]);
    await _trace('dialog_preraster', _prerasterDialog);
    await adapters;
  }

  Future<void> _precacheImages() async {
    if (!mounted) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    const homePaperWidth = 782.0;
    final relayPaper = TbPaperImageScope.decodeSpec(
      asset: 'assets/images/paper/connection_paper.webp',
      pixelRatio: dpr,
      logicalWidth: homePaperWidth,
    );
    final lanPaper = TbPaperImageScope.decodeSpec(
      asset: 'assets/images/paper/connection_lan_torn.webp',
      pixelRatio: dpr,
      logicalWidth: homePaperWidth,
    );
    Timeline.instantSync(
      'paper_decode_spec',
      arguments: {
        'dpr': dpr,
        'logical_width': homePaperWidth,
        'relay_cache_width': relayPaper.cacheWidth,
        'lan_cache_width': lanPaper.cacheWidth,
      },
    );
    final lanExtent = TbPngAsset.bucketForLogicalExtent(24, dpr);
    final checkExtent = TbPngAsset.bucketForLogicalExtent(20, dpr);
    final dashWidth = TbPngAsset.bucketForLogicalExtent(616, dpr);
    final dashHeight = TbPngAsset.bucketForLogicalExtent(6, dpr);
    final providers = <ImageProvider<Object>>[
      relayPaper.provider,
      lanPaper.provider,
      ResizeImage.resizeIfNeeded(
        lanExtent,
        lanExtent,
        const AssetImage('assets/icons/ui/lan.png'),
      ),
      ResizeImage.resizeIfNeeded(
        checkExtent,
        checkExtent,
        const AssetImage('assets/icons/ui/relay_checkbox_on.png'),
      ),
      ResizeImage.resizeIfNeeded(
        checkExtent,
        checkExtent,
        const AssetImage('assets/icons/ui/relay_checkbox_off.png'),
      ),
      ResizeImage.resizeIfNeeded(
        dashWidth,
        dashHeight,
        const AssetImage('assets/icons/ui/room_dashed_line.png'),
      ),
    ];
    await Future.wait<void>([
      for (final provider in providers) precacheImage(provider, context),
    ]);
  }

  Future<void> _prerasterDialog() async {
    if (!mounted || !_showWarmupScene) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_showWarmupScene) return;
    final boundary = _dialogBoundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) return;
    final image = await boundary.toImage(pixelRatio: 1);
    image.dispose();
  }

  Future<void> _prefetchLanAdapters() async {
    if (!widget.controller.isNative) return;
    if (widget.controller.snapshot?.bootstrap !=
        bridge.BootstrapStateDto.ready) {
      final ready = Completer<void>();
      late final VoidCallback listener;
      listener = () {
        if (widget.controller.snapshot?.bootstrap ==
                bridge.BootstrapStateDto.ready &&
            !ready.isCompleted) {
          ready.complete();
        }
      };
      widget.controller.addListener(listener);
      listener();
      await ready.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
      widget.controller.removeListener(listener);
    }
    if (widget.controller.snapshot?.bootstrap ==
        bridge.BootstrapStateDto.ready) {
      await widget.controller.prefetchLanAdapters();
    }
  }

  Future<void> _trace(String name, Future<void> Function() action) async {
    final task = TimelineTask()..start(name);
    final stopwatch = Stopwatch()..start();
    try {
      await action();
    } catch (error, stack) {
      debugPrint('Startup warm-up $name failed: $error\n$stack');
      rethrow;
    } finally {
      task.finish(arguments: {'elapsed_us': stopwatch.elapsedMicroseconds});
    }
  }

  Future<void> _releaseWindow() async {
    if (_released) return;
    _released = true;
    if (mounted) {
      setState(() => _showWarmupScene = false);
      await WidgetsBinding.instance.endOfFrame;
    }
    try {
      await widget.onComplete();
    } catch (error, stack) {
      debugPrint('Unable to reveal the main window: $error\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, ?currentChild],
      ),
      child: _released
          ? KeyedSubtree(
              key: const ValueKey('warmed-application'),
              child: widget.child,
            )
          : Stack(
              key: const ValueKey('warming-startup-splash'),
              fit: StackFit.expand,
              children: [
                if (_showWarmupScene)
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        key: _dialogBoundaryKey,
                        child: ColoredBox(
                          color: AppColors.canvasBg,
                          child: Center(child: buildLanDialogWarmupScene()),
                        ),
                      ),
                    ),
                  ),
                const StartupSplash(),
              ],
            ),
    );
  }
}
