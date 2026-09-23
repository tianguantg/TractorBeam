import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bridge/generated/api.dart' as bridge;
import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import 'custom_icons.dart';

class BottomStatusBar extends StatefulWidget {
  final VoidCallback? onLaunchGame;
  final VoidCallback? onEnterLightweight;
  final VoidCallback? onNavigateToRoom;
  final double contentScale;
  final int? latencyMs;

  const BottomStatusBar({
    super.key,
    this.onLaunchGame,
    this.onEnterLightweight,
    this.onNavigateToRoom,
    this.contentScale = 1,
    this.latencyMs,
  });

  @override
  State<BottomStatusBar> createState() => _BottomStatusBarState();
}

class _BottomStatusBarState extends State<BottomStatusBar> {
  bool _launchHovered = false;
  bool _launchFocused = false;
  bool _lightweightHovered = false;
  bool _lightweightFocused = false;

  @override
  Widget build(BuildContext context) {
    final app = TractorBeamScope.maybeOf(context);
    final effectiveLatency = widget.latencyMs ?? app?.activeServerLatency;
    final running = app?.isSessionRunning ?? false;
    final hookReady = !running && (app?.isHookReady ?? false);
    final hook = app?.snapshot?.hook;
    final counters = app?.snapshot?.counters;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.statusBarBg,
        borderRadius: BorderRadius.circular(AppRadii.bar),
        border: Border.all(
          color: AppColors.statusBarBorder,
          width: AppStrokes.control,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentScale = widget.contentScale.clamp(0.0, 1.0);
          final virtualWidth = contentScale == 0
              ? constraints.maxWidth
              : constraints.maxWidth / contentScale;
          final virtualHeight = contentScale == 0
              ? constraints.maxHeight
              : constraints.maxHeight / contentScale;
          final isEn = Localizations.localeOf(context).languageCode == 'en';
          final fittedContentWidth = math.max(
            virtualWidth,
            isEn ? 1500.0 : 1000.0,
          );

          return ClipRect(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.scale(
                key: const ValueKey('status-content-scale'),
                scale: contentScale,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: virtualWidth,
                  height: virtualHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: fittedContentWidth,
                      child: Row(
                        children: [
                          // Left Status Indicator: [ ● 运行中 ]
                          Semantics(
                            label: running
                                ? context.l10n.running
                                : hookReady
                                ? context.l10n.gameReadyStandby
                                : context.l10n.idle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: running
                                    ? AppColors.statusIndicatorBg
                                    : hookReady
                                    ? const Color(0xFF1B2A1E)
                                    : AppColors.statusBarBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.control,
                                ),
                                border: Border.all(
                                  color: running
                                      ? AppColors.statusIndicatorBorder
                                      : hookReady
                                      ? const Color(0xFF2E5E36)
                                      : AppColors.statusBarBorder,
                                  width: AppStrokes.subtle,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: running
                                          ? AppColors.statusRunningText
                                          : hookReady
                                          ? AppColors.greenDot
                                          : AppColors.statusText,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    running
                                        ? context.l10n.running
                                        : hookReady
                                        ? context.l10n.gameReadyStandby
                                        : context.l10n.idle,
                                    style: AppTextStyles.statusRunning.copyWith(
                                      color: running
                                          ? AppColors.statusRunningText
                                          : hookReady
                                          ? AppColors.statusRunningText
                                          : AppColors.statusText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Diagnostic info: 重连 0 | Hook OK | 错误 0
                          Text(
                            context.l10n.reconnectCount(hook?.reconnects ?? 0),
                            style: AppTextStyles.statusText,
                          ),
                          _buildPipe(),
                          Text(
                            'Hook ${_formatHookStatus(context, hook?.connection)}',
                            style: AppTextStyles.statusText,
                          ),
                          _buildPipe(),
                          Text(
                            context.l10n.errorCount(
                              '${counters?.errors ?? BigInt.zero}',
                            ),
                            style: AppTextStyles.statusText,
                          ),

                          const Spacer(),

                          // Client-to-server latency (底部的延迟和relay服务器处的延迟是同一个)
                          // When LAN is selected, latency is null (当选择局域网联机不会有这个值)
                          if (effectiveLatency != null) ...[
                            () {
                              final gradeLabel = LatencyTheme.ofServer(
                                effectiveLatency,
                              ).grade.localizedLabel(context);
                              final tooltip = switch (app?.relayLatencySource) {
                                RelayLatencySource.activeRoom =>
                                  context.l10n.activeRelayLatencyTooltip(
                                    effectiveLatency,
                                    gradeLabel,
                                  ),
                                RelayLatencySource.selectedNodeProbe =>
                                  context.l10n.selectedRelayLatencyTooltip(
                                    effectiveLatency,
                                    gradeLabel,
                                  ),
                                _ => '$gradeLabel: ${effectiveLatency}ms',
                              };
                              return Semantics(
                                label: tooltip,
                                child: Tooltip(
                                  message: tooltip,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TbIcons.latencyIconForGrade(
                                        LatencyTheme.evaluateServer(
                                          effectiveLatency,
                                        ),
                                        size: 17,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${effectiveLatency}ms',
                                        style: AppTextStyles.statusLatency
                                            .copyWith(
                                              color: LatencyTheme.ofServer(
                                                effectiveLatency,
                                              ).statusColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }(),
                            const SizedBox(width: 16),
                          ] else if (app?.activeRelay?.link ==
                              bridge.RelayLinkStatusDto.reconnecting) ...[
                            Semantics(
                              label: context.l10n.relayReconnecting,
                              child: Tooltip(
                                message: context.l10n.relayReconnectingTooltip,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.latencyYellow,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      context.l10n.relayReconnecting,
                                      style: AppTextStyles.statusLatency
                                          .copyWith(
                                            color: AppColors.latencyYellow,
                                            fontSize: 12.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],

                          if (running && widget.onEnterLightweight != null) ...[
                            Semantics(
                              key: const ValueKey('enter-lightweight-mode'),
                              button: true,
                              enabled: true,
                              label: context.l10n.monitorWindow,
                              hint: context.l10n.monitorWindowTooltip,
                              child: Tooltip(
                                message: context.l10n.monitorWindowTooltip,
                                waitDuration: const Duration(milliseconds: 350),
                                child: FocusableActionDetector(
                                  enabled: true,
                                  onShowFocusHighlight: (v) =>
                                      setState(() => _lightweightFocused = v),
                                  onShowHoverHighlight: (v) =>
                                      setState(() => _lightweightHovered = v),
                                  actions: {
                                    ActivateIntent:
                                        CallbackAction<ActivateIntent>(
                                          onInvoke: (_) =>
                                              widget.onEnterLightweight?.call(),
                                        ),
                                  },
                                  shortcuts: const {
                                    SingleActivator(LogicalKeyboardKey.enter):
                                        ActivateIntent(),
                                    SingleActivator(LogicalKeyboardKey.space):
                                        ActivateIntent(),
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: widget.onEnterLightweight,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 120,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _lightweightHovered
                                              ? AppColors.peachPaperHover
                                              : AppColors.peachPaper,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.control,
                                          ),
                                          border: _lightweightFocused
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 1.8,
                                                )
                                              : Border.all(
                                                  color: AppColors.paperBorder,
                                                  width: 1.4,
                                                ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.35,
                                              ),
                                              offset: const Offset(0, 2),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TbIcons.floatingWindow(
                                              size: 18,
                                              color: AppColors.ink,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              context.l10n.monitorWindow,
                                              style: AppTextStyles.buttonText
                                                  .copyWith(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.ink,
                                                    letterSpacing: 0.3,
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
                            const SizedBox(width: 10),
                          ],

                          // Launch Game Button [ 🎮 启动游戏 / ⚠ 同步 Steam 账号 ]
                          () {
                            final primaryAction =
                                app?.primarySessionAction ??
                                PrimarySessionAction.launchGame;
                            final isMismatch =
                                primaryAction ==
                                PrimarySessionAction.resolveSteamMismatch;
                            final onTrigger = isMismatch
                                ? (widget.onNavigateToRoom ??
                                      widget.onLaunchGame)
                                : widget.onLaunchGame;

                            return Semantics(
                              key: const ValueKey('status-bar-launch-button'),
                              button: true,
                              enabled: onTrigger != null,
                              child: FocusableActionDetector(
                                enabled: onTrigger != null,
                                onShowFocusHighlight: (v) =>
                                    setState(() => _launchFocused = v),
                                onShowHoverHighlight: (v) =>
                                    setState(() => _launchHovered = v),
                                actions: {
                                  ActivateIntent:
                                      CallbackAction<ActivateIntent>(
                                        onInvoke: (_) => onTrigger?.call(),
                                      ),
                                },
                                shortcuts: const {
                                  SingleActivator(LogicalKeyboardKey.enter):
                                      ActivateIntent(),
                                  SingleActivator(LogicalKeyboardKey.space):
                                      ActivateIntent(),
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: onTrigger,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _launchHovered
                                            ? AppColors.accentRedHover
                                            : AppColors.accentRed,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.control,
                                        ),
                                        border: _launchFocused
                                            ? Border.all(
                                                color: Colors.white,
                                                width: 1.6,
                                              )
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            offset: const Offset(0, 2),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          isMismatch
                                              ? TbIcons.noticeAlert(
                                                  size: 20,
                                                  color: Colors.white,
                                                )
                                              : TbIcons.gamepad(
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _launchButtonLabel(context, app),
                                            style: AppTextStyles.statusAction,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPipe() {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          '|',
          style: AppTextStyles.statusText.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: AppColors.statusBarBorder.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  static String _formatHookStatus(BuildContext context, String? connection) {
    final l10n = context.l10n;
    if (connection == null) return l10n.hookDisconnected;
    return switch (connection.toLowerCase()) {
      'connected' || '已连接' => l10n.hookConnected,
      'connecting' || 'listening' || '连接中' || '监听中' => l10n.hookConnecting,
      'reconnecting' || '重连中' => l10n.hookReconnecting,
      'failed' || '失败' => l10n.hookFailed,
      'disconnected' || '已断开' => l10n.hookClosed,
      'inactive' || '未激活' || '未连接' || _ => l10n.hookDisconnected,
    };
  }

  static String _launchButtonLabel(
    BuildContext context,
    TractorBeamController? app,
  ) => switch (app?.primarySessionAction ?? PrimarySessionAction.launchGame) {
    PrimarySessionAction.resolveSteamMismatch => context.l10n.syncSteamAccount,
    PrimarySessionAction.running => context.l10n.gameRunning,
    PrimarySessionAction.launching =>
      app?.launchProgress?.status == bridge.LaunchStatusDto.cancelling
          ? context.l10n.cancelling
          : context.l10n.launching,
    PrimarySessionAction.resumeGameplay => context.l10n.startMultiplayer,
    PrimarySessionAction.unavailable => context.l10n.gameReady,
    PrimarySessionAction.launchGame => context.l10n.launchGame,
  };
}
