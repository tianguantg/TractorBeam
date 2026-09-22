import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import 'custom_icons.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  static const double height = 44;

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _toggleMaximized() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> _close() async {
    await windowManager.close();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('custom-title-bar'),
      height: CustomTitleBar.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.canvasBg,
          border: Border(
            bottom: BorderSide(color: AppColors.paperBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                key: const ValueKey('titlebar-drag-area'),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      const TbPngAsset(
                        asset: 'assets/icons/app_mark.png',
                        width: 24,
                        height: 24,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          'Tractor Beam ${TractorBeamScope.maybeOf(context)?.snapshot?.buildInfo.versionLabel ?? 'v0.5.2'}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: AppTextStyles.metadataInk.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _TitleBarButton(
              key: const ValueKey('titlebar-minimize'),
              tooltip: context.l10n.windowMinimize,
              assetName: 'assets/icons/window_minimize.png',
              onPressed: windowManager.minimize,
            ),
            _TitleBarButton(
              key: const ValueKey('titlebar-maximize'),
              tooltip: _isMaximized
                  ? context.l10n.windowRestore
                  : context.l10n.windowMaximize,
              assetName: _isMaximized
                  ? 'assets/icons/window_restore.png'
                  : 'assets/icons/window_maximize.png',
              onPressed: _toggleMaximized,
            ),
            _TitleBarButton(
              key: const ValueKey('titlebar-close'),
              tooltip: context.l10n.windowClose,
              assetName: 'assets/icons/window_close.png',
              isClose: true,
              onPressed: _close,
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  const _TitleBarButton({
    super.key,
    required this.tooltip,
    required this.assetName,
    required this.onPressed,
    this.isClose = false,
  });

  final String tooltip;
  final String assetName;
  final Future<void> Function() onPressed;
  final bool isClose;

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isClose
        ? AppColors.accentRed
        : AppColors.ink.withValues(alpha: 0.10);
    final foregroundColor = widget.isClose && _hovered
        ? Colors.white
        : AppColors.ink;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: _hovered ? hoverColor : Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            child: SizedBox(
              width: 48,
              height: CustomTitleBar.height,
              child: Center(
                child: TbPngAsset(
                  asset: widget.assetName,
                  width: 20,
                  height: 20,
                  color: foregroundColor,
                  colorBlendMode: BlendMode.srcIn,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
