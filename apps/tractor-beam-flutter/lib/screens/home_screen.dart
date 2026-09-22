import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/bridge_message_localizer.dart';
import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_notification.dart';
import '../widgets/custom_icons.dart';
import '../widgets/paper_card.dart';
import '../widgets/paper_dropdown.dart';
import '../widgets/torn_paper.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onJoinRoom;
  final VoidCallback? onLaunchGame;

  const HomeScreen({super.key, this.onJoinRoom, this.onLaunchGame});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Local fallbacks when no TbNetworkScope is in context (e.g. isolated tests)
  ConnectionMode _connectionMode = ConnectionMode.relay;
  String _selectedNode = '上海 BGP 极速节点 01';
  String _selectedNodeHost = 'relay.sh.net:19842';
  int? _nodeLatency = 24;
  bool _isTestingLatency = false;
  String _nodePort = '19842';
  bool _nodeTcp = true;
  bool _nodeUdp = true;
  String _nodeDefaultTransport = 'UDP';
  late final AnimationController _modeJellyController;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _modeJellyController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _modeJellyController.dispose();
    super.dispose();
  }

  TractorBeamController? get _netState => TractorBeamScope.maybeOf(context);

  bool get _canModifyRelay {
    final app = _netState;
    if (app == null) return true;
    if (app.isInRoom || app.isSessionRunning) return false;
    if (app.snapshot == null) return true;
    return app.canMutate;
  }

  ConnectionMode get _activeMode =>
      _netState?.connectionMode ?? _connectionMode;
  String get _activeNode {
    final app = _netState;
    if (app == null) return _selectedNode;
    if (app.snapshot == null) return app.selectedNode;
    return app.selectedRelay?.name ?? context.l10n.noRelayConfigured;
  }
  String get _activeHost => _netState?.selectedNodeHost ?? _selectedNodeHost;
  int? get _activeLatency => _netState?.isNative == true
      ? _netState!.serverLatency
      : _netState?.serverLatency ?? _nodeLatency;
  bool get _activeIsTesting => _netState?.isTestingLatency ?? _isTestingLatency;
  String get _activePort => _netState?.nodePort ?? _nodePort;
  bool get _activeTcp => _netState?.nodeTcp ?? _nodeTcp;
  bool get _activeUdp => _netState?.nodeUdp ?? _nodeUdp;
  String get _activeDefaultTransport =>
      _netState?.nodeDefaultTransport ?? _nodeDefaultTransport;

  List<PaperDropdownItem<String>> get _relayDropdownItems {
    final app = _netState;
    if (app?.snapshot != null) {
      return app!.relays.map((relay) {
        final latency = app.relayLatency(relay.id);
        return PaperDropdownItem<String>(
          value: relay.id,
          label: relay.name,
          detail: '${relay.host}:${relay.port}',
          trailing: _buildServerLatencyBadge(
            latency,
            isTesting: app.isTestingLatency,
          ),
        );
      }).toList();
    }
    return [
      if (_activeNode != '上海 BGP 极速节点 01' && _activeNode != '北京 BGP 低延迟节点 02')
        PaperDropdownItem(
          value: _activeNode,
          label: _activeNode,
          detail: _activeHost,
          trailing: _buildServerLatencyBadge(_activeLatency),
        ),
      PaperDropdownItem(
        value: '上海 BGP 极速节点 01',
        label: '上海 BGP 极速节点 01',
        detail: 'relay.sh.net:19842',
        trailing: _buildServerLatencyBadge(24),
      ),
      PaperDropdownItem(
        value: '北京 BGP 低延迟节点 02',
        label: '北京 BGP 低延迟节点 02',
        detail: 'relay.bj.net:19842',
        trailing: _buildServerLatencyBadge(31),
      ),
    ];
  }

  void _notice(String text) {
    AppNotification.info(
      context,
      text,
      duration: const Duration(milliseconds: 1600),
    );
  }

  String _blockReason({required String action}) {
    final l10n = context.l10n;
    final session = _netState?.isSessionRunning ?? false;
    final inRoom = _netState?.isInRoom ?? false;
    if (session && inRoom) {
      return l10n.blockSessionAndRoom(action);
    } else if (session) {
      return l10n.blockSession(action);
    } else if (inRoom) {
      return l10n.blockRoom(action);
    }
    return l10n.blockCurrentState(action);
  }

  Future<void> _setConnectionMode(ConnectionMode mode) async {
    if (mode == _activeMode || _modeJellyController.isAnimating) return;
    if (_netState?.isInRoom == true || _netState?.isSessionRunning == true) {
      _notice(_blockReason(action: context.l10n.actionSwitchConnection));
      return;
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      if (_netState != null) {
        _netState!.setConnectionMode(mode);
      } else {
        setState(() => _connectionMode = mode);
      }
      return;
    }

    try {
      _modeJellyController.value = 0;
      await _modeJellyController.animateTo(
        0.32,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
      );
      if (!mounted) return;

      if (_netState != null) {
        _netState!.setConnectionMode(mode);
      } else {
        setState(() => _connectionMode = mode);
      }

      await _modeJellyController.animateTo(
        1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
      if (mounted) _modeJellyController.value = 0;
    } on TickerCanceled {
      // Handled cleanly when screen unmounts mid-animation
    }
  }

  void _selectRelayNode(String value) {
    if (!_canModifyRelay) {
      _notice(_blockReason(action: context.l10n.actionSwitchRelay));
      return;
    }
    if (_netState?.snapshot != null) {
      if (value == _netState!.selectedRelay?.id) return;
      _netState!.selectRelay(value);
      return;
    }
    final name = value;
    if (name == _activeNode) return;
    final isShanghai = name == '上海 BGP 极速节点 01';
    final host = isShanghai ? 'relay.sh.net' : 'relay.bj.net';
    final latency = isShanghai ? 24 : 31;
    if (_netState != null) {
      _netState!.updateRelayNode(
        name: name,
        address: host,
        port: '19842',
        tcp: true,
        udp: true,
        defaultTransport: 'UDP',
        latency: latency,
      );
    } else {
      setState(() {
        _selectedNode = name;
        _selectedNodeHost = '$host:19842';
        _nodePort = '19842';
        _nodeLatency = latency;
      });
    }
  }

  void _testLatency() async {
    if (_activeIsTesting) {
      _notice(context.l10n.busy);
      return;
    }
    if (_netState != null) {
      if (_netState!.selectedRelay == null) {
        _notice(context.l10n.selectRelayFirst);
        return;
      }
      final receipt = _netState!.testRelayLatency();
      if (!receipt.accepted) {
        AppNotification.error(
          context,
          receipt.rejection?.displayText ?? context.l10n.latencyTestUnavailable,
        );
      }
      return;
    } else {
      setState(() => _isTestingLatency = true);
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    // Vary between excellent, fair, poor, severe
    final newLatency = 18 + (DateTime.now().millisecond % 50);
    if (_netState != null) {
      _netState!.setServerLatency(newLatency);
      _netState!.setIsTestingLatency(false);
    } else {
      setState(() {
        _nodeLatency = newLatency;
        _isTestingLatency = false;
      });
    }
    final grade = LatencyTheme.evaluateServer(
      newLatency,
    ).localizedLabel(context);
    AppNotification.success(
      context,
      context.l10n.latencyTestComplete(newLatency, grade),
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> _onAddRelay() async {
    if (_isDialogOpen) return;
    if (!_canModifyRelay) {
      _notice(_blockReason(action: context.l10n.actionAddRelay));
      return;
    }
    _isDialogOpen = true;
    final AddRelayData? result;
    try {
      result = await showAddRelayDialog(context);
    } finally {
      _isDialogOpen = false;
    }
    if (result == null || !mounted) return;
    if (!_canModifyRelay) {
      _notice(_blockReason(action: context.l10n.actionAddRelay));
      return;
    }
    final data = result;
    final portNumber = int.tryParse(data.port) ?? 25910;
    if (_netState != null) {
      final receipt = _netState!.addRelay(
        name: data.name,
        host: data.address,
        port: portNumber,
        tcp: data.tcp,
        udp: data.udp,
        defaultUdp: data.defaultTransport == 'UDP',
      );
      if (!receipt.accepted) {
        _notice(
          localizeBridgeRejection(
            context,
            receipt.rejection,
            fallback: context.l10n.relayAddFailed,
          ),
        );
        return;
      }
    } else {
      final latency = 20 + (DateTime.now().millisecond % 15);
      setState(() {
        _selectedNode = data.name;
        _selectedNodeHost = '${data.address}:$portNumber';
        _nodePort = '$portNumber';
        _nodeTcp = data.tcp;
        _nodeUdp = data.udp;
        _nodeDefaultTransport = data.defaultTransport;
        _nodeLatency = latency;
      });
      AppNotification.success(
        context,
        context.l10n.relayAddedAndSwitched(data.name),
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _onEditRelay() async {
    if (_isDialogOpen) return;
    if (!_canModifyRelay) {
      _notice(_blockReason(action: context.l10n.actionEditRelay));
      return;
    }
    if (_netState?.snapshot != null && _netState!.selectedRelay == null) {
      _notice(context.l10n.selectRelayFirst);
      return;
    }

    final targetRelay = _netState?.selectedRelay;
    final targetRelayId = targetRelay?.id;

    final String initialHost;
    final String initialPort;
    if (targetRelay != null) {
      initialHost = targetRelay.host;
      initialPort = targetRelay.port.toString();
    } else {
      final parsed = _safeExtractHostPort(_activeHost, _activePort);
      initialHost = parsed.$1;
      initialPort = parsed.$2;
    }

    _isDialogOpen = true;
    final EditRelayResult? result;
    try {
      result = await showEditRelayDialog(
        context,
        initialName: _activeNode,
        initialAddress: initialHost,
        initialPort: initialPort,
        initialTcp: _activeTcp,
        initialUdp: _activeUdp,
        initialDefaultTransport: _activeDefaultTransport,
      );
    } finally {
      _isDialogOpen = false;
    }

    if (result == null || !mounted) return;

    if (!_canModifyRelay) {
      _notice(_blockReason(action: context.l10n.actionEditRelay));
      return;
    }

    if (result.action == EditRelayAction.save && result.data != null) {
      final data = result.data!;
      final portNumber = int.tryParse(data.port) ?? 25910;
      if (_netState != null) {
        if (targetRelayId == null) return;
        final targetExists =
            _netState!.relays.any((r) => r.id == targetRelayId);
        if (!targetExists) {
          _notice(context.l10n.selectRelayFirst);
          return;
        }
        final receipt = _netState!.updateRelay(
          id: targetRelayId,
          name: data.name,
          host: data.address,
          port: portNumber,
          tcp: data.tcp,
          udp: data.udp,
          defaultUdp: data.defaultTransport == 'UDP',
        );
        if (!receipt.accepted) {
          _notice(
            localizeBridgeRejection(
              context,
              receipt.rejection,
              fallback: context.l10n.relayUpdateFailed,
            ),
          );
          return;
        }
      } else {
        setState(() {
          _selectedNode = data.name;
          _selectedNodeHost = '${data.address}:$portNumber';
          _nodePort = '$portNumber';
          _nodeTcp = data.tcp;
          _nodeUdp = data.udp;
          _nodeDefaultTransport = data.defaultTransport;
        });
        AppNotification.success(
          context,
          context.l10n.relayUpdatedNotice(data.name),
          duration: const Duration(seconds: 2),
        );
      }
    } else if (result.action == EditRelayAction.delete) {
      if (_netState != null) {
        if (targetRelayId == null) return;
        final receipt = _netState!.deleteRelay(targetRelayId);
        if (!receipt.accepted) {
          _notice(
            localizeBridgeRejection(
              context,
              receipt.rejection,
              fallback: context.l10n.relayDeleteFailed,
            ),
          );
          return;
        }
      } else {
        setState(() {
          _selectedNode = context.l10n.noRelayConfigured;
          _selectedNodeHost = '—';
          _nodePort = '—';
          _nodeLatency = null;
        });
        AppNotification.info(
          context,
          context.l10n.relayDeleted,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  (String, String) _safeExtractHostPort(String input, String defaultPort) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed == '—') {
      return ('', defaultPort);
    }
    if (trimmed.startsWith('[') && trimmed.contains(']:')) {
      final closeIdx = trimmed.indexOf(']:');
      final host = trimmed.substring(1, closeIdx);
      final port = trimmed.substring(closeIdx + 2);
      return (host, port.isNotEmpty ? port : defaultPort);
    }
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      return (trimmed.substring(1, trimmed.length - 1), defaultPort);
    }
    if (trimmed.contains(':') &&
        trimmed.indexOf(':') == trimmed.lastIndexOf(':')) {
      final parts = trimmed.split(':');
      return (parts[0], parts.length > 1 ? parts[1] : defaultPort);
    }
    return (trimmed, defaultPort);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handwritten homepage title supplied as an image asset.
          Center(
            child: const TbPngAsset(
              asset: 'assets/icons/ui/home_title.png',
              key: ValueKey('home-title-image'),
              width: 104,
              height: 57,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 6),

          // Card 1: 联机游玩须知
          PaperCard(
            key: const ValueKey('notice-paper-card'),
            backgroundAsset: 'assets/images/paper/notice_paper.webp',
            showTape: false,
            headerLeading: TbIcons.noticeAlert(
              size: 24,
              color: AppColors.accentRedLight,
            ),
            title: l10n.homeNoticeTitle,
            headerTrailing: Tooltip(
              message: l10n.homeNoticeHelp,
              preferBelow: false,
              child: TbIcons.infoCircle(size: 15, color: AppColors.inkMuted),
            ),
            child: _buildNoticeCardContent(),
          ),
          const SizedBox(height: 20),

          // Card 2: 联机方式
          AnimatedBuilder(
            animation: _modeJellyController,
            builder: (context, child) {
              final progress = _modeJellyController.value;
              final scaleX = TweenSequence<double>([
                TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 0.96),
                  weight: 32,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 0.96, end: 1.025),
                  weight: 28,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.025, end: 0.99),
                  weight: 20,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 0.99, end: 1.0),
                  weight: 20,
                ),
              ]).transform(progress);
              final scaleY = TweenSequence<double>([
                TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 1.025),
                  weight: 32,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.025, end: 0.99),
                  weight: 28,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 0.99, end: 1.006),
                  weight: 20,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.006, end: 1.0),
                  weight: 20,
                ),
              ]).transform(progress);
              return Transform.scale(
                scaleX: scaleX,
                scaleY: scaleY,
                child: child,
              );
            },
            child: PaperCard(
              key: const ValueKey('connection-paper-card'),
              backgroundAsset: _activeMode == ConnectionMode.lan
                  ? 'assets/images/paper/connection_lan_torn.webp'
                  : 'assets/images/paper/connection_paper.webp',
              showTape: false,
              headerLeading: TbIcons.sectionTriangle(size: 16),
              title: l10n.connectionMode,
              headerTrailing: Tooltip(
                message: l10n.connectionModeHelp,
                preferBelow: false,
                child: TbIcons.infoCircle(size: 15, color: AppColors.inkMuted),
              ),
              child: _buildConnectionModeCardContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCardContent() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction Line 1
          Text(l10n.hostInstruction, style: AppTextStyles.body),
          const SizedBox(height: 10),

          // Instruction Line 2 with inline [加入房间] button
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.memberInstructionBefore, style: AppTextStyles.body),
              _buildInlineButton(
                icon: TbIcons.doorJoin(size: 14, color: AppColors.accentRed),
                label: l10n.joinRoom,
                onTap: widget.onJoinRoom ?? () {},
              ),
              Text(l10n.memberInstructionAfter, style: AppTextStyles.body),
            ],
          ),
          const SizedBox(height: 10),

          // Instruction Line 3 with inline [启动游戏] button
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.launchInstructionBefore, style: AppTextStyles.body),
              _buildInlineRedButton(
                icon: TbIcons.gamepad(size: 20, color: Colors.white),
                label: l10n.launchGame,
                onTap: widget.onLaunchGame ?? () {},
              ),
              Text(l10n.launchInstructionAfter, style: AppTextStyles.body),
            ],
          ),
          const SizedBox(height: 14),

          // Warning badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Text(l10n.launchWarning, style: AppTextStyles.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TornPaperButton(
        onTap: onTap,
        seed: 7,
        roughness: 1.25,
        borderWidth: 1.8,
        fillColor: AppColors.peachPaper,
        hoverFillColor: AppColors.peachPaperHover,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.buttonText),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineRedButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => onTap(),
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Semantics(
                button: true,
                label: label,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    borderRadius: BorderRadius.circular(AppRadii.compact),
                    border: isFocused
                        ? Border.all(color: Colors.white, width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(child: icon),
                      const SizedBox(width: 4),
                      Text(label, style: AppTextStyles.buttonTextOnAccent),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionModeCardContent() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabs Selection Row
        Row(
          children: [
            // Tab 1: 外部 Relay 中继
            Expanded(
              child: _buildModeTab(
                mode: ConnectionMode.relay,
                title: l10n.externalRelay,
                icon: TbIcons.relayNodes(
                  size: 16,
                  color: _activeMode == ConnectionMode.relay
                      ? AppColors.accentRed
                      : AppColors.inkMuted,
                ),
                isSelected: _activeMode == ConnectionMode.relay,
              ),
            ),
            const SizedBox(width: 12),
            // Tab 2: 局域网直连
            Expanded(
              child: _buildModeTab(
                mode: ConnectionMode.lan,
                title: l10n.lanDirect,
                icon: TbIcons.lanRadar(
                  size: 16,
                  color: _activeMode == ConnectionMode.lan
                      ? AppColors.accentRed
                      : AppColors.inkMuted,
                ),
                isSelected: _activeMode == ConnectionMode.lan,
              ),
            ),
          ],
        ),
        if (_activeMode == ConnectionMode.relay) ...[
          const SizedBox(height: 14),
          _buildRelaySection(),
        ] else ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: widget.onJoinRoom != null
                ? FocusableActionDetector(
                    actions: {
                      ActivateIntent: CallbackAction<ActivateIntent>(
                        onInvoke: (_) => widget.onJoinRoom?.call(),
                      ),
                    },
                    shortcuts: const {
                      SingleActivator(LogicalKeyboardKey.enter):
                          ActivateIntent(),
                      SingleActivator(LogicalKeyboardKey.space):
                          ActivateIntent(),
                    },
                    child: Builder(
                      builder: (context) {
                        final isFocused = Focus.of(context).hasFocus;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: widget.onJoinRoom,
                            child: Semantics(
                              button: true,
                              label: l10n.lanSelectedHint,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warningBg,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.card,
                                  ),
                                  border: isFocused
                                      ? Border.all(
                                          color: AppColors.accentRed,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Text(
                                  l10n.lanSelectedHint,
                                  style: AppTextStyles.warning,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Text(
                      l10n.lanSelectedHint,
                      style: AppTextStyles.warning,
                    ),
                  ),
          ),
          const SizedBox(height: 38),
        ],
      ],
    );
  }

  /// Relay Configuration Section with server latency badge
  Widget _buildRelaySection() {
    final l10n = context.l10n;
    final hasNoRelays =
        (_netState?.snapshot != null && _netState!.relays.isEmpty) ||
        (_netState == null &&
            (_selectedNodeHost == '—' ||
                _selectedNode == l10n.noRelayConfigured));
    if (hasNoRelays) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TbIcons.routingBoxes(size: 14, color: AppColors.accentRed),
              const SizedBox(width: 6),
              Text(l10n.relayConfiguration, style: AppTextStyles.sectionLabel),
            ],
          ),
          const SizedBox(height: 10),
          TornPaperContainer(
            seed: 44,
            roughness: 1.25,
            borderWidth: 1.8,
            fillColor: AppColors.paperBg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TbIcons.infoCircle(size: 16, color: AppColors.inkMuted),
                    const SizedBox(width: 6),
                    Text(l10n.noRelayConfigured, style: AppTextStyles.bodyBold),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.addRelayHint, style: AppTextStyles.metadata),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildBottomButton(
            icon: TbIcons.add(size: 15, color: AppColors.accentRed),
            label: l10n.addRelay,
            enabled: _canModifyRelay,
            onTap: _onAddRelay,
            seed: 11,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subtitle row: [Icon] Relay 中继路由配置
        Row(
          children: [
            TbIcons.routingBoxes(size: 14, color: AppColors.accentRed),
            const SizedBox(width: 6),
            Text(l10n.relayConfiguration, style: AppTextStyles.sectionLabel),
          ],
        ),
        const SizedBox(height: 10),

        // Node display uses the same torn-paper style as the relay actions.
        TornPaperContainer(
          seed: 44,
          roughness: 1.25,
          borderWidth: 1.8,
          fillColor: AppColors.paperBg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Node details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _activeNode,
                            style: AppTextStyles.bodyBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Server latency badge evaluated: 0-30 优秀, 30-60 一般, 60-100 差, >100 严重
                        _buildServerLatencyBadge(_activeLatency),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeHost,
                      style: AppTextStyles.mono,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Switch button [ ⇄ 切换 ]
              PaperDropdown<String>(
                selectedValue: _netState?.snapshot == null
                    ? _activeNode
                    : _netState?.selectedRelay?.id,
                seed: 71,
                menuWidth: 340,
                items: _relayDropdownItems,
                enabled: _canModifyRelay && _relayDropdownItems.isNotEmpty,
                onSelected: _selectRelayNode,
                triggerBuilder: (openMenu) => _buildActionButton(
                  icon: TbIcons.switchDirection(
                    size: 16,
                    color: _canModifyRelay
                        ? AppColors.paperBg
                        : AppColors.inkMuted,
                  ),
                  label: l10n.switchRelay,
                  onTap: () {
                    if (!_canModifyRelay) {
                      _notice(
                        _blockReason(action: l10n.actionSwitchRelay),
                      );
                      return;
                    }
                    if (_relayDropdownItems.isEmpty) {
                      _notice(l10n.noOtherRelayToSwitch);
                      return;
                    }
                    openMenu();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Bottom 3 action buttons
        Row(
          children: [
            Expanded(
              child: _buildBottomButton(
                icon: TbIcons.add(size: 15, color: AppColors.accentRed),
                label: l10n.addRelay,
                enabled: _canModifyRelay,
                onTap: _onAddRelay,
                seed: 11,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBottomButton(
                icon: TbIcons.edit(size: 14),
                label: l10n.editRelay,
                enabled:
                    _canModifyRelay &&
                    !(_netState?.snapshot != null &&
                        _netState?.selectedRelay == null),
                onTap: _onEditRelay,
                seed: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBottomButton(
                icon: _activeIsTesting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.greenDot,
                        ),
                      )
                    : TbIcons.speedGauge(size: 15),
                label: l10n.testLatency,
                enabled:
                    !_activeIsTesting &&
                    !(_netState?.snapshot != null &&
                        _netState?.selectedRelay == null),
                onTap: _testLatency,
                seed: 33,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Server latency badge:
  /// Evaluated with 0-30 优秀, 30-60 一般, 60-100 差, >100 严重
  Widget _buildServerLatencyBadge(int? latency, {bool isTesting = false}) {
    if (isTesting) {
      return Text(
        context.l10n.statsSpeedtesting,
        style: AppTextStyles.metadata,
      );
    }
    if (latency == null) {
      return Text('—', style: AppTextStyles.metadata);
    }
    final theme = LatencyTheme.ofServer(latency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.badgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.badgeBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TbIcons.latencyIconForGrade(theme.grade, size: 11),
          const SizedBox(width: 4),
          Text(
            '${latency}ms',
            style: AppTextStyles.metadata.copyWith(color: theme.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required ConnectionMode mode,
    required String title,
    required Widget icon,
    required bool isSelected,
  }) {
    final seed = mode == ConnectionMode.relay ? 1 : 2;
    return TornPaperButton(
      onTap: () => _setConnectionMode(mode),
      isSelected: isSelected,
      seed: seed,
      roughness: 1.25,
      fillColor: isSelected ? AppColors.peachPaper : Colors.transparent,
      hoverFillColor: isSelected
          ? AppColors.peachPaperHover
          : AppColors.paperBg.withValues(alpha: 0.6),
      borderColor: isSelected ? AppColors.paperBorder : Colors.transparent,
      hoverBorderColor: isSelected
          ? AppColors.paperBorder
          : AppColors.paperBorder.withValues(alpha: 0.35),
      borderWidth: 2.0,
      showShadow: isSelected,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.controlLabel.copyWith(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: _canModifyRelay ? 1.0 : 0.48,
      child: TornPaperButton(
        onTap: onTap,
        seed: 8,
        roughness: 1.2,
        borderWidth: 1.8,
        fillColor: AppColors.canvasDarker,
        hoverFillColor: const Color(0xFF383331),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.buttonTextOnAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
    int seed = 0,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.48,
      child: TornPaperButton(
        onTap: onTap,
        seed: seed,
        roughness: 1.25,
        borderWidth: 1.8,
        fillColor: AppColors.peachPaper,
        hoverFillColor: AppColors.peachPaperHover,
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 5),
              Text(label, style: AppTextStyles.buttonText),
            ],
          ),
        ),
      ),
    );
  }
}
