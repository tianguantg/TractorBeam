import 'package:flutter/material.dart';
import '../l10n/bridge_message_localizer.dart';
import '../l10n/l10n.dart';

import '../bridge/generated/api.dart' as bridge;
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/asset_shape_shadow.dart';
import '../widgets/custom_icons.dart';
import '../widgets/paper_image.dart';
import '../widgets/torn_paper.dart';

String _formatBytes(BigInt? bytes) {
  if (bytes == null || bytes <= BigInt.zero) return '0 B';
  final value = bytes.toDouble();
  if (value < 1024) return '$bytes B';
  if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  if (value < 1024 * 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (value < 1024.0 * 1024 * 1024 * 1024) {
    return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  return '${(value / (1024.0 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB';
}

String _formatCount(BigInt? count) {
  if (count == null || count <= BigInt.zero) return '0';
  final s = count.toString();
  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return s.replaceAllMapped(reg, (Match m) => '${m[1]},');
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _refreshingHook = false;
  bool _testingLatency = false;

  Future<void> _refreshHookStatus() async {
    if (_refreshingHook) return;
    setState(() => _refreshingHook = true);
    final app = TractorBeamScope.maybeOf(context);
    final receipt = app?.refreshHookStatus();
    if (receipt != null && !receipt.accepted && mounted) {
      AppNotification.error(
        context,
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: context.l10n.statsHookRefreshFailed,
        ),
      );
    } else if (receipt != null && receipt.accepted && mounted) {
      AppNotification.info(
        context,
        context.l10n.statsHookRefreshSuccess,
        duration: const Duration(milliseconds: 1400),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _refreshingHook = false);
  }

  Future<void> _testRelayLatency() async {
    final app = TractorBeamScope.maybeOf(context);
    if (app == null) return;
    if (_testingLatency || app.isTestingLatency) return;
    if (app.selectedRelay == null) {
      AppNotification.show(
        context,
        context.l10n.statsSelectRelayPrompt,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    setState(() => _testingLatency = true);
    final receipt = app.testRelayLatency();
    if (!receipt.accepted && mounted) {
      AppNotification.error(
        context,
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: context.l10n.statsSpeedtestRejected,
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _testingLatency = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = TractorBeamScope.maybeOf(context);
    final snapshot = app?.snapshot;
    final isTestingLatency =
        _testingLatency || (app?.isTestingLatency ?? false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TbIcons.statisticsTitle(
              width: 112,
              key: const ValueKey('statistics-page-title'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 245,
                      child: _StatsCard(
                        key: const ValueKey('session-quality-card'),
                        title: l10n.statsSessionQualityTitle,
                        tooltip: l10n.statsSessionQualityHelp,
                        backgroundAsset:
                            'assets/images/paper/statistics_session_card.webp',
                        child: _SessionQualityContent(
                          session: snapshot?.session,
                          room: snapshot?.room,
                          clientConfig: snapshot?.clientConfig,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 305,
                      child: _StatsCard(
                        key: const ValueKey('statistics-counter-card'),
                        title: l10n.statsCountersTitle,
                        tooltip: l10n.statsCountersHelp,
                        backgroundAsset:
                            'assets/images/paper/statistics_counter_card.webp',
                        child: _CounterGrid(counters: snapshot?.counters),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 360,
                      child: _StatsCard(
                        key: const ValueKey('connection-test-card'),
                        title: l10n.statsConnectionTestTitle,
                        tooltip: l10n.statsConnectionTestHelp,
                        backgroundAsset:
                            'assets/images/paper/statistics_test_card.webp',
                        trailing: _CardActionButton(
                          actionKey: const ValueKey(
                            'test-relay-latency-button',
                          ),
                          label: l10n.statsStartSpeedtest,
                          loadingLabel: l10n.statsSpeedtesting,
                          loading: isTestingLatency,
                          icon: TbIcons.speedGauge(
                            size: 15,
                            color: AppColors.ink,
                          ),
                          onTap: _testRelayLatency,
                        ),
                        child: _ConnectionTestTable(
                          reports: snapshot?.connectionTests,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 190,
                      child: _StatsCard(
                        key: const ValueKey('connection-status-card'),
                        title: l10n.statsHookIpcTitle,
                        tooltip: l10n.statsHookIpcHelp,
                        backgroundAsset:
                            'assets/images/paper/statistics_hook_card.webp',
                        trailing: _CardActionButton(
                          actionKey: const ValueKey('refresh-hook-status'),
                          label: l10n.statsRefreshHook,
                          loadingLabel: l10n.statsRefreshingHook,
                          loading: _refreshingHook,
                          icon: TbIcons.refreshAccount(
                            size: 15,
                            color: AppColors.ink,
                          ),
                          onTap: _refreshHookStatus,
                        ),
                        child: _HookStatusTable(
                          hook: snapshot?.hook,
                          counters: snapshot?.counters,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String backgroundAsset;
  final Widget child;
  final Widget? trailing;
  final String? tooltip;

  const _StatsCard({
    super.key,
    required this.title,
    required this.backgroundAsset,
    required this.child,
    this.trailing,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) => TbPaperImageScope(
    asset: backgroundAsset,
    builder: (context, imageProvider) => Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: AssetShapeShadow(imageProvider: imageProvider)),
        Container(
          key: ValueKey('statistics-panel-background-$title'),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.fill,
              filterQuality: WindowResizePerformanceScope.largeImageQualityOf(
                context,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TbIcons.sectionTriangle(size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              style: AppTextStyles.cardHeader,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (tooltip != null)
                          Tooltip(
                            message: tooltip!,
                            child: TbIcons.infoCircle(
                              size: 16,
                              color: AppColors.inkMuted,
                            ),
                          )
                        else
                          TbIcons.infoCircle(
                            size: 16,
                            color: AppColors.inkMuted,
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 8),
              TbIcons.roomDashedLine(height: 6),
              const SizedBox(height: 11),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InsetPanel extends StatelessWidget {
  final int seed;
  final Widget child;
  final EdgeInsets padding;

  const _InsetPanel({
    required this.seed,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    return TornPaperContainer(
      seed: seed,
      roughness: 1.15,
      borderWidth: 1.6,
      fillColor: AppColors.paperInnerBg,
      borderColor: AppColors.paperBorder.withValues(alpha: 0.75),
      showShadow: false,
      padding: padding,
      child: child,
    );
  }
}

class _SessionQualityContent extends StatelessWidget {
  final bridge.SessionSnapshot? session;
  final bridge.RoomSnapshot? room;
  final bridge.ClientConfigDto? clientConfig;

  const _SessionQualityContent({this.session, this.room, this.clientConfig});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRunning = session?.status == bridge.SessionStatusDto.running;
    final (smoothnessLabel, dotColor) = switch (session?.smoothness
        .toLowerCase()) {
      'good' when isRunning => (l10n.statsQualityGood, AppColors.greenBadgeText),
      'watch' when isRunning => (l10n.statsQualityWatch, const Color(0xFFD97706)),
      'poor' when isRunning => (l10n.statsQualityPoor, AppColors.accentRed),
      _ when isRunning => (l10n.statsQualityEvaluating, AppColors.inkMuted),
      _ => (l10n.statsQualityInactive, AppColors.inkMuted),
    };

    final modeLabel = isRunning
        ? switch (session?.activeMode) {
            bridge.SessionModeDto.official => l10n.statsModeOfficial,
            bridge.SessionModeDto.fallback => l10n.statsModeFallback,
            _ => l10n.statsModePure,
          }
        : '—';

    final roomLabel = (room?.active ?? false)
        ? (room?.joinCode != null
              ? l10n.statsRoomNumber(room!.joinCode!)
              : l10n.statsRoomJoined)
        : l10n.statsRoomNotJoined;

    final relayName = clientConfig?.relays
        .where((r) => r.id == clientConfig?.selectedRelayId)
        .firstOrNull
        ?.name;

    final routeLabel = (room?.active ?? false)
        ? switch (room?.route) {
            bridge.RoomRouteDto.relay =>
              relayName != null
                  ? l10n.statsRouteRelayNode(relayName)
                  : l10n.statsRouteRelay,
            bridge.RoomRouteDto.lan => l10n.statsRouteLan,
            bridge.RoomRouteDto.unknown => l10n.statsRouteUnknown,
            null => (relayName ?? '—'),
          }
        : (relayName ?? '—');

    final transportLabel = (room?.active ?? false)
        ? (room?.transport == bridge.TransportSelection.udp ? 'UDP' : 'TCP')
        : (clientConfig?.transport == bridge.TransportSelection.udp
              ? 'UDP'
              : (clientConfig?.transport == bridge.TransportSelection.tcp
                    ? 'TCP'
                    : l10n.statsTransportAuto));

    final health = session?.health;
    final stopReason = session?.lastStopReason;

    return _InsetPanel(
      seed: 311,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TornPaperContainer(
              seed: 321,
              roughness: 1.2,
              borderWidth: 1.6,
              fillColor: AppColors.paperBg,
              borderColor: AppColors.paperBorder,
              showShadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        smoothnessLabel,
                        maxLines: 1,
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 16.5,
                          color: isRunning ? AppColors.ink : AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _SessionInfoTile(
                          label: l10n.statsLabelMode,
                          value: modeLabel,
                          seed: 501,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SessionInfoTile(
                          label: l10n.statsLabelRoomStatus,
                          value: roomLabel,
                          seed: 502,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _SessionInfoTile(
                          label: l10n.statsLabelRouteNode,
                          value: routeLabel,
                          seed: 503,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SessionInfoTile(
                          label: l10n.statsLabelTransport,
                          value: transportLabel,
                          seed: 504,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (health != null && health.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Tooltip(
              message: health,
              child: Text(
                l10n.statsHealthDiagnostic(health),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.metadataInk.copyWith(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ] else if (!isRunning &&
              stopReason != null &&
              stopReason.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Tooltip(
              message: stopReason,
              child: Text(
                l10n.statsLastStopReason(stopReason),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.metadataInk.copyWith(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final int seed;

  const _SessionInfoTile({
    required this.label,
    required this.value,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    return TornPaperContainer(
      seed: seed,
      roughness: 1.15,
      borderWidth: 1.3,
      fillColor: AppColors.paperBg,
      borderColor: AppColors.paperBorder.withValues(alpha: 0.7),
      showShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Flexible(
            flex: 5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTextStyles.metadataInk.copyWith(
                    fontSize: 12.5,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.metadataInk.copyWith(
                    fontSize: 13,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterItem {
  final String label;
  final String value;
  final bool isError;

  const _CounterItem(this.label, this.value, {this.isError = false});
}

class _CounterGrid extends StatelessWidget {
  final bridge.CountersDto? counters;

  const _CounterGrid({this.counters});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <_CounterItem>[
      _CounterItem(l10n.statsCounterHookToRelay, _formatCount(counters?.hookToRelay)),
      _CounterItem(l10n.statsCounterBytesReceived, _formatBytes(counters?.receivedBytes)),
      _CounterItem(l10n.statsCounterRelayToHook, _formatCount(counters?.relayToHook)),
      _CounterItem(
        l10n.statsCounterErrors,
        _formatCount(counters?.errors),
        isError: (counters?.errors ?? BigInt.zero) > BigInt.zero,
      ),
      _CounterItem(l10n.statsCounterBytesSent, _formatBytes(counters?.sentBytes)),
      _CounterItem(
        l10n.statsCounterReconnectDrops,
        _formatCount(counters?.reconnectDroppedPackets),
        isError:
            (counters?.reconnectDroppedPackets ?? BigInt.zero) > BigInt.zero,
      ),
    ];
    return Column(
      children: List.generate(3, (row) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: row == 2 ? 0 : 8),
            child: Row(
              children: [
                Expanded(child: _CounterCell(item: items[row * 2])),
                const SizedBox(width: 8),
                Expanded(child: _CounterCell(item: items[row * 2 + 1])),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _CounterCell extends StatelessWidget {
  final _CounterItem item;

  const _CounterCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return TornPaperContainer(
      seed: item.label.hashCode,
      roughness: 1.15,
      borderWidth: 1.6,
      fillColor: AppColors.paperBg,
      borderColor: AppColors.paperBorder,
      showShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: AppTextStyles.metadataInk.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.isError
                    ? AppColors.peachPaper
                    : AppColors.paperInnerBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: item.isError
                      ? AppColors.accentRed.withValues(alpha: 0.6)
                      : AppColors.paperBorder,
                  width: 1.2,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.value,
                  maxLines: 1,
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: item.isError ? AppColors.accentRed : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionTestTable extends StatelessWidget {
  final List<bridge.ConnectionTestDto>? reports;

  const _ConnectionTestTable({this.reports});

  @override
  Widget build(BuildContext context) {
    final hasReports = reports != null && reports!.isNotEmpty;

    return _InsetPanel(
      seed: 312,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: !hasReports
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TbIcons.infoCircle(size: 26, color: AppColors.inkMuted),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.statsNoTestRecords,
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.statsNoTestRecordsPrompt,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.metadataInk.copyWith(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                const _TestTableHeader(),
                Container(
                  height: 1.5,
                  color: AppColors.paperBorder.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: reports!.length,
                      itemBuilder: (context, index) =>
                          _TestTableRow(report: reports![index]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TestTableHeader extends StatelessWidget {
  const _TestTableHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _TableText(l10n.statsTableHeaderNode, flex: 6, isHeader: true),
          _TableText(l10n.statsTableHeaderTransport, flex: 4, isHeader: true),
          _TableText(l10n.statsTableHeaderPackets, flex: 5, isHeader: true),
          _TableText(l10n.statsTableHeaderLoss, flex: 4, isHeader: true),
          _TableText(
            l10n.statsTableHeaderLatency,
            flex: 6,
            alignment: Alignment.centerRight,
            isHeader: true,
          ),
        ],
      ),
    );
  }
}

class _TestTableRow extends StatelessWidget {
  final bridge.ConnectionTestDto report;

  const _TestTableRow({required this.report});

  @override
  Widget build(BuildContext context) {
    final isUdp = report.transport == bridge.TransportSelection.udp;
    final protocol = isUdp ? 'UDP' : 'TCP';
    final protocolColor = isUdp
        ? AppColors.greenBadgeText
        : AppColors.accentRed;

    final sent = report.sent;
    final received = report.received;
    final lost = sent > received ? sent - received : 0;
    final lossPercent = sent > 0 ? ((lost / sent) * 100).toInt() : 0;
    final hasLoss = lost > 0;

    final relayTarget =
        report.relayName ??
        (report.endpoint.isNotEmpty ? report.endpoint : 'Relay');

    final latencyText = report.medianRttMs != null
        ? '${report.medianRttMs} ms'
        : (report.failureReason ?? context.l10n.statsTestTimeout);
    final latencyColor = report.medianRttMs != null
        ? AppColors.ink
        : AppColors.accentRed;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.paperBorder.withValues(alpha: .15),
          ),
        ),
      ),
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            _TableText(
              relayTarget,
              flex: 6,
              tooltip: relayTarget,
            ),
            _TableText(
              protocol,
              flex: 4,
              color: protocolColor,
              weight: FontWeight.w800,
            ),
            _TableText('$received/$sent', flex: 5),
            _TableText(
              '$lossPercent%',
              flex: 4,
              color: hasLoss ? AppColors.accentRed : AppColors.greenBadgeText,
              weight: FontWeight.w700,
            ),
            _TableText(
              latencyText,
              flex: 6,
              alignment: Alignment.centerRight,
              color: latencyColor,
              weight: FontWeight.w700,
              tooltip: report.failureReason,
            ),
          ],
        ),
      ),
    );
  }
}

class _HookStatusTable extends StatelessWidget {
  final bridge.HookSnapshot? hook;
  final bridge.CountersDto? counters;

  const _HookStatusTable({this.hook, this.counters});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rawConnection = hook?.connection.toLowerCase() ?? 'inactive';
    final (statusText, statusColor) = switch (rawConnection) {
      'connected' || '已连接' => (l10n.hookConnected, AppColors.greenBadgeText),
      'connecting' ||
      'listening' ||
      '连接中' ||
      '监听中' => (l10n.hookConnecting, const Color(0xFFD97706)),
      'reconnecting' || '重连中' => (l10n.hookReconnecting, const Color(0xFFD97706)),
      'failed' || '失败' => (l10n.hookFailed, AppColors.accentRed),
      'disconnected' || '已断开' => (l10n.hookClosed, AppColors.accentRed),
      'inactive' || '未连接' || _ => (l10n.hookDisconnected, AppColors.inkMuted),
    };

    final hookDrops = counters?.detachedHookDroppedPackets ?? BigInt.zero;
    final clientDrops = counters?.detachedRelayDroppedPackets ?? BigInt.zero;
    final dropText = '${_formatCount(hookDrops)} / ${_formatCount(clientDrops)}';
    final malformed = hook?.malformedFrames ?? BigInt.zero;
    final malformedText = _formatCount(malformed);
    final lastError = hook?.lastError;

    return _InsetPanel(
      seed: 313,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Row(
              children: [
                _TableText(l10n.statsTableHeaderStatus, flex: 7, isHeader: true),
                _TableText(l10n.statsTableHeaderVersion, flex: 4, isHeader: true),
                _TableText(l10n.statsTableHeaderReconnects, flex: 4, isHeader: true),
                _TableText(l10n.statsTableHeaderDrops, flex: 9, isHeader: true),
                _TableText(
                  l10n.statsTableHeaderBadFrames,
                  flex: 5,
                  alignment: Alignment.centerRight,
                  isHeader: true,
                ),
              ],
            ),
          ),
          Container(
            height: 1.5,
            color: AppColors.paperBorder.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TornPaperContainer(
                      seed: 401,
                      roughness: 1.15,
                      borderWidth: 1.3,
                      showShadow: false,
                      fillColor: AppColors.paperBg,
                      borderColor: AppColors.paperBorder.withValues(
                        alpha: 0.65,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          statusText,
                          maxLines: 1,
                          style: AppTextStyles.bodyBold.copyWith(
                            fontSize: 13,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _TableText(hook?.version ?? '-', flex: 4),
                _TableText('${hook?.reconnects ?? 0}', flex: 4),
                _TableText(dropText, flex: 9),
                _TableText(
                  malformedText,
                  flex: 5,
                  alignment: Alignment.centerRight,
                  color: malformed > BigInt.zero ? AppColors.accentRed : null,
                ),
              ],
            ),
          ),
          if (lastError != null && lastError.trim().isNotEmpty) ...[
            Tooltip(
              message: lastError,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.peachPaper,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.accentRed.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    TbIcons.noticeAlert(size: 13, color: AppColors.accentRed),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lastError,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.metadataInk.copyWith(
                          fontSize: 13,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final bool loading;
  final VoidCallback? onTap;
  final Widget icon;
  final Key? actionKey;

  const _CardActionButton({
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onTap,
    required this.icon,
    this.actionKey,
  });

  @override
  Widget build(BuildContext context) {
    return TornPaperButton(
      key: actionKey,
      onTap: loading ? null : onTap,
      seed: label.hashCode,
      roughness: 1.25,
      borderWidth: 1.8,
      fillColor: loading ? AppColors.paperBg : AppColors.peachPaper,
      hoverFillColor: loading ? AppColors.paperBg : AppColors.peachPaperHover,
      borderColor: AppColors.paperBorder,
      showShadow: !loading,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.ink,
                ),
              )
            else
              icon,
            const SizedBox(width: 5),
            Text(
              loading ? loadingLabel : label,
              maxLines: 1,
              style: AppTextStyles.buttonText.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableText extends StatelessWidget {
  final String text;
  final int flex;
  final Alignment alignment;
  final Color? color;
  final FontWeight? weight;
  final bool isHeader;
  final String? tooltip;

  const _TableText(
    this.text, {
    required this.flex,
    this.alignment = Alignment.centerLeft,
    this.color,
    this.weight,
    this.isHeader = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final content = Text(
      text,
      maxLines: 1,
      style: isHeader
          ? AppTextStyles.bodyBold.copyWith(
              fontSize: 14,
              color: AppColors.ink,
            )
          : AppTextStyles.metadataInk.copyWith(
              fontSize: 14,
              color: color ?? AppColors.ink,
              fontWeight: weight ?? FontWeight.w700,
            ),
    );

    final wrapped = tooltip != null
        ? Tooltip(message: tooltip!, child: content)
        : content;

    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: wrapped,
        ),
      ),
    );
  }
}
