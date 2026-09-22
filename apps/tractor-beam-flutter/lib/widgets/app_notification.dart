import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/app_theme.dart';
import 'custom_icons.dart';
import 'custom_title_bar.dart';
import 'torn_paper.dart';

/// Types of top-banner notifications.
enum NotificationType { info, success, warning, error }

/// Global top-anchored toast notification system styled with torn-paper aesthetics.
/// Appears directly beneath the CustomTitleBar at the top of the window, completely
/// avoiding any overlap with the bottom status bar and launch game action.
class AppNotification {
  static OverlayEntry? _activeEntry;
  static _TopToastHostState? _activeHostState;

  /// Shows a notification with the given [message] and [type].
  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    // Clear any currently running notification cleanly
    dismiss();

    final view = View.maybeOf(context);
    final directionality = Directionality.maybeOf(context) ?? TextDirection.ltr;
    if (view != null) {
      SemanticsService.sendAnnouncement(view, message, directionality);
    }

    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopToastHost(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (_activeEntry == entry) {
            _activeEntry = null;
            _activeHostState = null;
          }
          if (entry.mounted) {
            entry.remove();
            entry.dispose();
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  /// Convenience helper for info messages.
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(context, message, type: NotificationType.info, duration: duration);
  }

  /// Convenience helper for success messages.
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(context, message, type: NotificationType.success, duration: duration);
  }

  /// Convenience helper for warning messages.
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(context, message, type: NotificationType.warning, duration: duration);
  }

  /// Convenience helper for error messages.
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(context, message, type: NotificationType.error, duration: duration);
  }

  /// Dismisses the active notification.
  /// If [animated] is true, triggers a smooth exit animation.
  static void dismiss({bool animated = false}) {
    if (animated &&
        _activeHostState != null &&
        !_activeHostState!._isDismissing) {
      _activeHostState?.dismiss();
      return;
    }
    final entry = _activeEntry;
    _activeEntry = null;
    _activeHostState = null;
    if (entry != null && entry.mounted) {
      entry.remove();
      entry.dispose();
    }
  }
}

class _TopToastHost extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastHost({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopToastHost> createState() => _TopToastHostState();
}

class _TopToastHostState extends State<_TopToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    AppNotification._activeHostState = this;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInQuad,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();
    _startDismissTimer(widget.duration);
  }

  void _startDismissTimer(Duration duration) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(duration, () {
      if (!mounted || _isHovered) return;
      dismiss();
    });
  }

  void _onMouseEnter() {
    if (_isDismissing) return;
    _isHovered = true;
    _dismissTimer?.cancel();
    _dismissTimer = null;
  }

  void _onMouseExit() {
    if (_isDismissing) return;
    _isHovered = false;
    if (mounted) {
      _startDismissTimer(const Duration(milliseconds: 1200));
    }
  }

  void dismiss() {
    if (_isDismissing || !mounted) return;
    setState(() {
      _isDismissing = true;
    });
    _dismissTimer?.cancel();
    _dismissTimer = null;

    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (AppNotification._activeHostState == this) {
      AppNotification._activeHostState = null;
      AppNotification._activeEntry = null;
    }
    _fadeAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon() {
    switch (widget.type) {
      case NotificationType.error:
        return TbIcons.noticeAlert(size: 20, color: AppColors.accentRed);
      case NotificationType.warning:
        return TbIcons.noticeAlert(size: 20, color: AppColors.latencyFair);
      case NotificationType.success:
        return TbIcons.relayCheckbox(
          selected: true,
          size: 20,
          color: AppColors.latencyExcellent,
        );
      case NotificationType.info:
        return TbIcons.infoCircle(size: 20, color: AppColors.ink);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 8px breathing room directly underneath CustomTitleBar (height: 44)
    const topMargin = CustomTitleBar.height + 8.0;

    return Positioned(
      top: topMargin,
      left: 16,
      right: 16,
      child: Center(
        child: IgnorePointer(
          ignoring: _isDismissing,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                type: MaterialType.transparency,
                child: Semantics(
                  liveRegion: true,
                  label: widget.message,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => _onMouseEnter(),
                    onExit: (_) => _onMouseExit(),
                    child: GestureDetector(
                      onTap: dismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Semantics(
                        button: true,
                        label: '关闭通知: ${widget.message}',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: TornPaperContainer(
                            fillColor: AppColors.dialogPaper,
                            borderColor: widget.type == NotificationType.error
                                ? AppColors.accentRed
                                : AppColors.paperBorder,
                            borderWidth: AppStrokes.paperOutline,
                            cornerRadius: 6.0,
                            roughness: 0.9,
                            seed: 37,
                            showShadow: true,
                            shadowColor: const Color(0x35000000),
                            shadowOffset: const Offset(1.5, 2.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ExcludeSemantics(child: _buildIcon()),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    widget.message,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ExcludeSemantics(
                                  child: TbIcons.close(
                                    size: 14,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
