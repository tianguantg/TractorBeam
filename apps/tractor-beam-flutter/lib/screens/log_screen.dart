import 'package:flutter/material.dart';
import '../l10n/bridge_message_localizer.dart';
import '../l10n/l10n.dart';
import 'package:flutter/services.dart';

import '../bridge/generated/api.dart' as bridge;
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_notification.dart';
import '../widgets/asset_shape_shadow.dart';
import '../widgets/custom_icons.dart';
import '../widgets/paper_image.dart';
import '../widgets/torn_paper.dart';

enum _LogLevel { trace, debug, info, warning, error }

class _LogEntry {
  final String time;
  final String source;
  final String message;
  final _LogLevel level;
  const _LogEntry(this.time, this.source, this.message, this.level);
}

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  static final RegExp _sourceBracketRegex = RegExp(r'^\[([A-Za-z0-9_\-]+)\]');

  _LogLevel? _filter;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();
  String? _lastScrollSignature;
  late final List<_LogEntry> _localEntries = List.of(_initialEntries);
  bool _isExporting = false;
  bool _isOpeningFolder = false;

  static const _initialEntries = <_LogEntry>[
    _LogEntry(
      '14:32:01.890',
      'Hook',
      '目标进程已定位（PID: 14208），执行 DLL 动态内存挂载',
      _LogLevel.info,
    ),
    _LogEntry('14:32:02.110', 'Net', '内存挂载完成，输入重定向已成功接管', _LogLevel.info),
    _LogEntry(
      '14:32:05.420',
      'Net',
      '正在连入 Relay 节点：relay.sh.net:19842（UDP）',
      _LogLevel.debug,
    ),
    _LogEntry(
      '14:32:05.880',
      'Room',
      '握手成功，分派会话 Token：#8849-OK，RTT：24ms',
      _LogLevel.info,
    ),
    _LogEntry(
      '14:32:08.330',
      'Buffer',
      '房间 RP-8849-STEAM-CN 加入成功，等待对局帧同步',
      _LogLevel.warning,
    ),
    _LogEntry(
      '14:32:15.002',
      'P2P',
      '远端玩家 Alex Wolf 出现微小瞬时网络抖动（4.2ms），已自适应缓冲',
      _LogLevel.warning,
    ),
    _LogEntry(
      '14:32:16.118',
      'P2P',
      '局域网广播信标同步，本地网络适配器 TAP0 就绪',
      _LogLevel.info,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = (pos.maxScrollExtent - pos.pixels).abs() <= 32;
    if (!atBottom && _autoScroll) {
      setState(() {
        _autoScroll = false;
      });
    } else if (atBottom && !_autoScroll) {
      setState(() {
        _autoScroll = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static String _formatTimestamp(int timestampMs) {
    if (timestampMs <= 0) return '00:00:00.000';
    try {
      if (timestampMs > 8640000000000000) return '99:99:99.999';
      final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      final ms = dt.millisecond.toString().padLeft(3, '0');
      return '$h:$m:$s.$ms';
    } catch (_) {
      return '00:00:00.000';
    }
  }

  static String _extractSource(String message, bridge.LogLevelDto level) {
    final bracketMatch = _sourceBracketRegex.firstMatch(message.trim());
    if (bracketMatch != null) {
      return bracketMatch.group(1)!;
    }
    final lower = message.toLowerCase();
    if (lower.contains('hook') || lower.contains('dll')) return 'Hook';
    if (lower.contains('relay') || lower.contains('endpoint')) return 'Relay';
    if (lower.contains('lan') || lower.contains('adapter')) return 'LAN';
    if (lower.contains('p2p') ||
        lower.contains('latency') ||
        lower.contains('probe')) {
      return 'P2P';
    }
    if (lower.contains('steam')) return 'Steam';
    if (lower.contains('room') || lower.contains('session')) return 'Room';
    return _levelLabel(_mapLevel(level));
  }

  static _LogLevel _mapLevel(bridge.LogLevelDto level) => switch (level) {
    bridge.LogLevelDto.trace => _LogLevel.trace,
    bridge.LogLevelDto.debug => _LogLevel.debug,
    bridge.LogLevelDto.info => _LogLevel.info,
    bridge.LogLevelDto.warn => _LogLevel.warning,
    bridge.LogLevelDto.error => _LogLevel.error,
    bridge.LogLevelDto.unknown => _LogLevel.debug,
  };

  static String _levelLabel(_LogLevel level) => switch (level) {
    _LogLevel.trace => 'TRACE',
    _LogLevel.debug => 'DEBUG',
    _LogLevel.info => 'INFO',
    _LogLevel.warning => 'WARN',
    _LogLevel.error => 'ERROR',
  };

  static String _localizedLevelName(_LogLevel level, AppLocalizations l10n) => switch (level) {
    _LogLevel.trace => l10n.logsLevelTrace,
    _LogLevel.debug => l10n.logsLevelDebug,
    _LogLevel.info => l10n.logsLevelInfo,
    _LogLevel.warning => l10n.logsLevelWarn,
    _LogLevel.error => l10n.logsLevelError,
  };

  static bool _matchesQuery(_LogEntry entry, String query, AppLocalizations l10n) {
    if (query.isEmpty) return true;
    final inMsg = entry.message.toLowerCase().contains(query);
    if (inMsg) return true;
    final inSrc = entry.source.toLowerCase().contains(query);
    if (inSrc) return true;
    final inTime = entry.time.toLowerCase().contains(query);
    if (inTime) return true;
    final levelName = entry.level.name.toLowerCase();
    if (levelName.contains(query)) return true;
    final levelLabel = _levelLabel(entry.level).toLowerCase();
    if (levelLabel.contains(query)) return true;
    final localizedLevel = _localizedLevelName(entry.level, l10n).toLowerCase();
    if (localizedLevel.contains(query)) return true;
    return false;
  }

  void _runCommand(bridge.CommandReceipt? receipt, String started) {
    if (receipt == null || receipt.accepted) {
      _notice(started);
    } else {
      final errorMsg = localizeBridgeRejection(
        context,
        receipt.rejection,
        fallback: context.l10n.genericError,
      );
      AppNotification.show(
        context,
        errorMsg,
        type: NotificationType.error,
        duration: const Duration(milliseconds: 2500),
      );
    }
  }

  void _notice(String text) {
    AppNotification.show(
      context,
      text,
      duration: const Duration(milliseconds: 1200),
    );
  }

  Future<void> _copyAll(List<_LogEntry> visible) async {
    if (visible.isEmpty) {
      if (mounted) _notice(context.l10n.logsNoCopyableLogs);
      return;
    }
    final buffer = StringBuffer();
    for (int i = 0; i < visible.length; i++) {
      final e = visible[i];
      if (i > 0) buffer.write('\n');
      buffer.write('[${e.time}] [${e.source}] ${e.message}');
    }
    try {
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) _notice(context.l10n.logsCopiedCount(visible.length));
    } catch (_) {
      if (mounted) {
        AppNotification.show(
          context,
          context.l10n.logsCopyFailed,
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _copyLine(_LogEntry entry) async {
    final text = '[${entry.time}] [${entry.source}] ${entry.message}';
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) _notice(context.l10n.logsCopiedSingle);
    } catch (_) {
      if (mounted) {
        AppNotification.show(
          context,
          context.l10n.logsCopyFailed,
          type: NotificationType.error,
        );
      }
    }
  }

  void _setFilter(_LogLevel? value) {
    setState(() {
      _filter = value;
      _lastScrollSignature = null;
    });
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _lastScrollSignature = null;
    });
  }

  void _maybeScheduleScrollToLatest(List<_LogEntry> visible) {
    final signature =
        '${_filter?.name}:$_searchQuery:${visible.length}:${visible.lastOrNull?.time}';
    if (!_autoScroll || signature == _lastScrollSignature) return;
    _lastScrollSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_autoScroll || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final core = TractorBeamScope.maybeOf(context)?.snapshot?.logs;
    final List<_LogEntry> entries;
    if (core == null) {
      entries = _localEntries;
    } else {
      entries = core
          .map(
            (entry) => _LogEntry(
              _formatTimestamp(entry.timestampMs.toInt()),
              _extractSource(entry.message, entry.level),
              entry.message,
              _mapLevel(entry.level),
            ),
          )
          .toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    final visible = entries.where((entry) {
      if (_filter != null && entry.level != _filter) return false;
      return _matchesQuery(entry, query, l10n);
    }).toList();

    _maybeScheduleScrollToLatest(visible);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
      child: Column(
        children: [
          Center(
            child: TbIcons.logTitle(
              width: 112,
              key: const ValueKey('log-page-title'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 86,
            child: _toolbar(entries, query, l10n),
          ),
          const SizedBox(height: 18),
          Expanded(child: _console(entries, visible, l10n)),
        ],
      ),
    );
  }

  Widget _toolbar(
    List<_LogEntry> entries,
    String query,
    AppLocalizations l10n,
  ) {
    final Map<_LogLevel?, int> counts = {
      null: 0,
      _LogLevel.trace: 0,
      _LogLevel.debug: 0,
      _LogLevel.info: 0,
      _LogLevel.warning: 0,
      _LogLevel.error: 0,
    };
    for (final entry in entries) {
      if (_matchesQuery(entry, query, l10n)) {
        counts[null] = (counts[null] ?? 0) + 1;
        counts[entry.level] = (counts[entry.level] ?? 0) + 1;
      }
    }

    return _LogPaperPanel(
      asset: 'assets/images/paper/log_toolbar_card.webp',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterButton(
              label: l10n.logsLevelAll,
              count: counts[null] ?? 0,
              active: _filter == null,
              color: AppColors.accentRed,
              onTap: () => _setFilter(null),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              label: l10n.logsLevelTrace,
              count: counts[_LogLevel.trace] ?? 0,
              active: _filter == _LogLevel.trace,
              color: AppColors.inkMuted,
              onTap: () => _setFilter(_LogLevel.trace),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              label: l10n.logsLevelDebug,
              count: counts[_LogLevel.debug] ?? 0,
              active: _filter == _LogLevel.debug,
              color: const Color(0xFF365789),
              onTap: () => _setFilter(_LogLevel.debug),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              label: l10n.logsLevelInfo,
              count: counts[_LogLevel.info] ?? 0,
              active: _filter == _LogLevel.info,
              color: AppColors.greenBadgeText,
              onTap: () => _setFilter(_LogLevel.info),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              label: l10n.logsLevelWarn,
              count: counts[_LogLevel.warning] ?? 0,
              active: _filter == _LogLevel.warning,
              color: const Color(0xFFD77A5E),
              onTap: () => _setFilter(_LogLevel.warning),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              label: l10n.logsLevelError,
              count: counts[_LogLevel.error] ?? 0,
              active: _filter == _LogLevel.error,
              color: const Color(0xFFB51F28),
              onTap: () => _setFilter(_LogLevel.error),
            ),
            const SizedBox(width: 18),
            _ToolbarButton(
              label: l10n.logsExportBundle,
              tooltip: l10n.logsExportBundleTooltip,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentRed,
                      ),
                    )
                  : TbIcons.exportDiagnostics(
                      size: 18,
                      color: AppColors.accentRed,
                    ),
              onTap: _isExporting
                  ? null
                  : () async {
                      setState(() => _isExporting = true);
                      try {
                        _runCommand(
                          TractorBeamScope.maybeOf(context)?.exportDiagnosticsBundle(),
                          l10n.logsExportingNotice,
                        );
                      } finally {
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (mounted) setState(() => _isExporting = false);
                        });
                      }
                    },
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              label: l10n.logsOpenFolder,
              tooltip: l10n.logsOpenFolderTooltip,
              icon: TbIcons.locateFolder(size: 18, color: AppColors.ink),
              onTap: _isOpeningFolder
                  ? null
                  : () async {
                      setState(() => _isOpeningFolder = true);
                      try {
                        _runCommand(
                          TractorBeamScope.maybeOf(context)?.openLogDirectory(),
                          l10n.logsOpeningFolderNotice,
                        );
                      } finally {
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          if (mounted) setState(() => _isOpeningFolder = false);
                        });
                      }
                    },
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              label: l10n.logsClear,
              tooltip: l10n.logsClearTooltip,
              icon: TbIcons.clearLogs(
                size: 18,
                color: entries.isEmpty ? AppColors.inkMuted : AppColors.accentRed,
              ),
              onTap: () async {
                if (entries.isEmpty) {
                  _notice(l10n.logsAlreadyEmpty);
                  return;
                }
                final confirmed = await showClearLogsConfirmDialog(context);
                if (!confirmed || !mounted) return;
                final app = TractorBeamScope.maybeOf(context);
                if (app == null || app.snapshot == null) {
                  setState(_localEntries.clear);
                  _notice(l10n.logsClearedNotice);
                } else {
                  _runCommand(app.clearLogs(), l10n.logsClearedNotice);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _console(
    List<_LogEntry> entries,
    List<_LogEntry> visible,
    AppLocalizations l10n,
  ) {
    return _LogPaperPanel(
      asset: 'assets/images/paper/log_console_card_dark.webp',
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const _ConsoleDot(color: Color(0xFFE78064)),
                  const SizedBox(width: 8),
                  const _ConsoleDot(color: Color(0xFFFFD45E)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.logsShowingCount(visible.length, entries.length),
                        style: AppTextStyles.mono.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF9E9895),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_isSearching || _searchQuery.isNotEmpty)
                    SizedBox(
                      width: 176,
                      height: 32,
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.escape) {
                            _closeSearch();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          key: const ValueKey('log-search-field'),
                          autofocus: true,
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: AppTextStyles.mono.copyWith(
                            fontSize: 12,
                            color: const Color(0xFFE7DFD8),
                          ),
                          cursorColor: const Color(0xFFFFCF45),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            hintText: l10n.logsSearchHint,
                            hintStyle: AppTextStyles.mono.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF9E9895),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 15,
                              color: Color(0xFF9E9895),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            suffixIcon: Semantics(
                              button: true,
                              label: l10n.dialogClose,
                              child: Tooltip(
                                message: l10n.dialogClose,
                                child: GestureDetector(
                                  onTap: _closeSearch,
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Color(0xFF9E9895),
                                  ),
                                ),
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF221E1C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(
                                color: Color(0xFF4A423E),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(
                                color: Color(0xFF4A423E),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFCF45),
                                width: 1.2,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                              _lastScrollSignature = null;
                            });
                          },
                        ),
                      ),
                    )
                  else
                    _DarkAction(
                      label: l10n.logsSearchButton,
                      icon: Icons.search,
                      onTap: () => setState(() => _isSearching = true),
                    ),
                  const SizedBox(width: 8),
                  _DarkAction(
                    label: l10n.logsCopyAll,
                    icon: Icons.copy_outlined,
                    onTap: () => _copyAll(visible),
                  ),
                  const SizedBox(width: 8),
                  _DarkAction(
                    label: _autoScroll
                        ? l10n.logsAutoScrollOn
                        : l10n.logsAutoScrollPaused,
                    icon: _autoScroll
                        ? Icons.vertical_align_bottom
                        : Icons.pause,
                    onTap: () {
                      setState(() {
                        _autoScroll = !_autoScroll;
                        if (_autoScroll) {
                          _lastScrollSignature = null;
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent,
                            );
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3D3734)),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.terminal_rounded,
                          size: 32,
                          color: const Color(0xFF6C6560),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? l10n.logsEmptyNoMatch(_searchQuery)
                              : l10n.logsEmptyNoRecords,
                          style: AppTextStyles.mono.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF8A827D),
                          ),
                        ),
                      ],
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 13, 18, 18),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _LogLine(
                        entry: visible[index],
                        onCopy: () => _copyLine(visible[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogPaperPanel extends StatelessWidget {
  final String asset;
  final EdgeInsets padding;
  final Widget child;

  const _LogPaperPanel({
    required this.asset,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => TbPaperImageScope(
    asset: asset,
    builder: (context, imageProvider) => Stack(
      fit: StackFit.expand,
      children: [
        AssetShapeShadow(
          imageProvider: imageProvider,
          offset: const Offset(4, 5),
        ),
        Image(
          image: imageProvider,
          fit: BoxFit.fill,
          filterQuality: WindowResizePerformanceScope.largeImageQualityOf(
            context,
          ),
        ),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

class _FilterButton extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FilterButton({
    required this.label,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => TornPaperButton(
    onTap: onTap,
    seed: label.hashCode,
    fillColor: active ? AppColors.accentRed : AppColors.peachPaper,
    hoverFillColor: active
        ? AppColors.accentRedHover
        : AppColors.peachPaperHover,
    borderColor: AppColors.paperBorder,
    borderWidth: 1.6,
    roughness: 1.2,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!active) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: AppTextStyles.buttonText.copyWith(
            fontSize: 14,
            color: active ? Colors.white : AppColors.ink,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF7F1C1E) : AppColors.paperInnerBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.mono.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ToolbarButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final String? tooltip;
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = TornPaperButton(
      onTap: onTap,
      seed: label.hashCode + 509,
      fillColor: onTap == null ? AppColors.paperBg : AppColors.peachPaper,
      hoverFillColor:
          onTap == null ? AppColors.paperBg : AppColors.peachPaperHover,
      borderColor: onTap == null
          ? AppColors.paperBorder.withValues(alpha: 0.5)
          : AppColors.paperBorder,
      borderWidth: 1.8,
      roughness: 1.25,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (label.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 14,
                color: onTap == null ? AppColors.inkMuted : AppColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, preferBelow: false, child: btn);
    }
    return btn;
  }
}

class _DarkAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DarkAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => TornPaperButton(
    onTap: onTap,
    seed: label.hashCode,
    roughness: 1.15,
    borderWidth: 1.5,
    fillColor: const Color(0xFF2B2624),
    hoverFillColor: const Color(0xFF3B3532),
    borderColor: const Color(0xFF514843),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFFFFCF45)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.buttonTextOnAccent.copyWith(
            color: const Color(0xFFF2DFC4),
            fontSize: 13.5,
          ),
        ),
      ],
    ),
  );
}

class _ConsoleDot extends StatelessWidget {
  final Color color;
  const _ConsoleDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _LogLine extends StatelessWidget {
  final _LogEntry entry;
  final VoidCallback onCopy;

  const _LogLine({required this.entry, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.level) {
      _LogLevel.trace => const Color(0xFFB0A79B),
      _LogLevel.debug => const Color(0xFF7096FF),
      _LogLevel.info => const Color(0xFF58D88A),
      _LogLevel.warning => const Color(0xFFFFC84D),
      _LogLevel.error => const Color(0xFFFF6B6B),
    };
    return InkWell(
      onSecondaryTap: onCopy,
      borderRadius: BorderRadius.circular(4),
      hoverColor: Colors.white.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '[${entry.time}]',
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.mono.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF9E9895),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: color.withValues(alpha: .4),
                  width: 1.2,
                ),
              ),
              child: Text(
                entry.source,
                style: AppTextStyles.mono.copyWith(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(
                entry.message,
                style: AppTextStyles.mono.copyWith(
                  fontSize: 13.5,
                  color: const Color(0xFFE7DFD8),
                ),
                contextMenuBuilder: (context, editableTextState) {
                  final List<ContextMenuButtonItem> buttonItems =
                      editableTextState.contextMenuButtonItems;
                  buttonItems.insert(
                    0,
                    ContextMenuButtonItem(
                      label: context.l10n.logsCopyLine,
                      onPressed: () {
                        editableTextState.hideToolbar();
                        onCopy();
                      },
                    ),
                  );
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: buttonItems,
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: context.l10n.logsCopyLine,
              child: Tooltip(
                message: context.l10n.logsCopyLine,
                preferBelow: false,
                child: InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Color(0xFF6C6560),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
