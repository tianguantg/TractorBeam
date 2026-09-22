import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../bridge/generated/api.dart' as bridge;
import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';

class LightweightSessionView extends StatefulWidget {
  const LightweightSessionView({
    super.key,
    required this.controller,
    required this.onOpenFull,
    required this.onHideToTray,
  });

  final TractorBeamController controller;
  final VoidCallback onOpenFull;
  final VoidCallback onHideToTray;

  @override
  State<LightweightSessionView> createState() => _LightweightSessionViewState();
}

class _LightweightSessionViewState extends State<LightweightSessionView> {
  late LightweightViewState _viewState;

  @override
  void initState() {
    super.initState();
    _viewState = widget.controller.lightweightViewState;
    widget.controller.addListener(_handleUpdate);
  }

  @override
  void didUpdateWidget(LightweightSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleUpdate);
      _viewState = widget.controller.lightweightViewState;
      widget.controller.addListener(_handleUpdate);
    }
  }

  void _handleUpdate() {
    final next = widget.controller.lightweightViewState;
    if (next != _viewState && mounted) setState(() => _viewState = next);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: 'Microsoft YaHei UI'),
      ),
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            widget.onHideToTray();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          key: const ValueKey('lightweight-session-view'),
          color: AppColors.canvasDarker,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                _buildStatus(context),
                Expanded(child: _buildMembers()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final roomCode = _viewState.roomCode?.trim();
    final hasRoomCode = roomCode != null && roomCode.isNotEmpty;

    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusRunningText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Tractor Beam',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasRoomCode) ...[
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Tooltip(
                message:
                    '${context.l10n.roomCurrentCode}：$roomCode (${context.l10n.copy})',
                preferBelow: false,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: roomCode));
                    if (context.mounted) {
                      AppNotification.show(
                        context,
                        context.l10n.roomCodeCopied,
                        duration: const Duration(milliseconds: 1200),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B3430),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.statusBarBorder.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '#$roomCode',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.mono.copyWith(
                              fontSize: 12.5,
                              color: AppColors.accentRedLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.copy_rounded,
                          size: 11,
                          color: AppColors.statusText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            key: const ValueKey('lightweight-open-full'),
            tooltip: context.l10n.fullInterface,
            onPressed: widget.onOpenFull,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(
              Icons.open_in_full,
              color: AppColors.statusText,
              size: 15,
            ),
          ),
          IconButton(
            key: const ValueKey('lightweight-hide'),
            tooltip: context.l10n.hideToTray,
            onPressed: widget.onHideToTray,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(
              Icons.remove,
              color: AppColors.statusText,
              size: 18,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildStatus(BuildContext context) {
    final route = switch (_viewState.route) {
      bridge.RoomRouteDto.relay => context.l10n.relayConnectionRoute,
      bridge.RoomRouteDto.lan => context.l10n.lanRoute,
      _ => context.l10n.unknownRoute,
    };
    final transport = switch (_viewState.transport) {
      bridge.TransportSelection.udp => 'UDP',
      bridge.TransportSelection.tcp => 'TCP',
      bridge.TransportSelection.relayDefault => context.l10n.relayDefault,
      _ => '—',
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2725),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.statusBarBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$route  ·  $transport',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD6CEC7),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _viewState.hookReady
                      ? AppColors.statusRunningText
                      : AppColors.latencyYellow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _viewState.hookReady
                    ? context.l10n.hookReady
                    : context.l10n.hookConnecting,
                style: TextStyle(
                  color: _viewState.hookReady
                    ? AppColors.statusRunningText
                    : AppColors.latencyYellow,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembers() {
    final members = _viewState.members;
    if (members.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noMembers,
          style: const TextStyle(color: AppColors.statusText),
        ),
      );
    }
    return ListView.separated(
      key: const ValueKey('lightweight-member-list'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) => _MemberRow(
        member: members[index],
        route: _viewState.route,
        transport: _viewState.transport,
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.route,
    required this.transport,
  });

  final bridge.RoomMemberDto member;
  final bridge.RoomRouteDto? route;
  final bridge.TransportSelection? transport;

  @override
  Widget build(BuildContext context) {
    final initial = member.displayName.characters.firstOrNull ?? '?';
    final connLower = member.connection.trim().toLowerCase();
    final isDisconnected = !member.isLocal &&
        (connLower == 'disconnected' ||
            connLower == '已断开' ||
            connLower == 'inactive' ||
            connLower == '未连接');

    final Widget trailingWidget;
    if (isDisconnected) {
      final statusLabel = (connLower == 'inactive' || connLower == '未连接')
          ? context.l10n.memberStatusInactive
          : context.l10n.memberStatusDisconnected;
      trailingWidget = Text(
        statusLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.statusText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (member.isLocal) {
      trailingWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF3B3430),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.statusRunningText.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Text(
          context.l10n.localPlayer.replaceAll(RegExp(r'[()（）]'), ''),
          style: const TextStyle(
            color: AppColors.statusRunningText,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (member.latencyMs == null) {
      trailingWidget = Text(
        route == bridge.RoomRouteDto.lan ? context.l10n.connected : '—',
        style: const TextStyle(
          color: AppColors.latencyYellow,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      final latency = member.latencyMs!.toInt();
      final theme = LatencyTheme.ofP2p(latency);
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${latency}ms',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF302B29),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: member.isLocal
              ? AppColors.statusRunningText.withValues(alpha: 0.15)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: member.isLocal
                ? AppColors.accentRed
                : isDisconnected
                ? AppColors.paperBorder
                : AppColors.statusBarBorder,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              member.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: trailingWidget,
          ),
        ],
      ),
    );
  }
}
