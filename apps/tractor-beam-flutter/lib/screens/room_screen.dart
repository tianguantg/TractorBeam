import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/generated/api.dart' as bridge;
import '../l10n/bridge_message_localizer.dart';
import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_notification.dart';
import '../widgets/asset_shape_shadow.dart';
import '../widgets/custom_icons.dart';
import '../widgets/paper_image.dart';
import '../widgets/paper_dropdown.dart';
import '../widgets/torn_paper.dart';

class RoomScreenController {
  VoidCallback? _joinRoom;

  void requestJoinRoom() => _joinRoom?.call();
}

class RoomScreen extends StatefulWidget {
  final int previewPartySize;
  final RoomScreenController? controller;

  const RoomScreen({super.key, this.previewPartySize = 7, this.controller});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen>
    with SingleTickerProviderStateMixin {
  bool _isInRoom = false;
  String _roomCode = 'T2QZXZ4vpibifhUA4';
  String _steamUsername = 'GamerPro 2024';
  String _steamId64 = '76561198000000000';
  int _partyPage = 0;
  int _partySlideDirection = 1;
  late final AnimationController _partyJellyController;
  late final VoidCallback _joinRoomRequestHandler;
  bool? _lastCoreRoomState;
  BigInt? _lastRoomGeneration;
  BigInt _handledLanSelectionRevision = BigInt.from(-1);
  int _handledEventSerial = -1;
  String? _lastJoinFailedCode;
  String? _lastJoinErrorMessage;
  bool _isDialogOpen = false;

  TractorBeamController? get _app => TractorBeamScope.maybeOf(context);
  bool get _inRoom => _app?.snapshot != null ? _app!.isInRoom : _isInRoom;
  String get _activeRoomCode => _app?.isNative != true && _app?.snapshot == null
      ? _roomCode
      : _app?.snapshot?.room.joinCode ?? '';
  String get _activeSteamUsername =>
      _app?.isNative != true && _app?.snapshot == null
      ? _steamUsername
      : _app?.selectedAccount?.displayName ??
            context.l10n.roomSteamAccountUnconfigured;
  String get _activeSteamId64 =>
      _app?.isNative != true && _app?.snapshot == null
      ? _steamId64
      : _app?.selectedAccount?.steamId64 ??
            context.l10n.roomSteamAccountUnconfigured;
  bool get _roomBusy => switch (_app?.snapshot?.room.status.name) {
    'creating' || 'joining' || 'leaving' => true,
    _ => false,
  };
  String get _emptyRoomText => switch (_app?.snapshot?.room.status.name) {
    'creating' => context.l10n.roomCreating,
    'joining' => context.l10n.roomJoining,
    'leaving' => context.l10n.roomLeaving,
    'failed' => context.l10n.roomFailed,
    _ => context.l10n.roomNotJoined,
  };

  @override
  void initState() {
    super.initState();
    _partyJellyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _joinRoomRequestHandler = () => _onJoinRoom();
    widget.controller?._joinRoom = _joinRoomRequestHandler;
  }

  @override
  void didUpdateWidget(covariant RoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._joinRoom = null;
      widget.controller?._joinRoom = _joinRoomRequestHandler;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = _app;
    final coreState = _app?.snapshot?.room.active;
    final generation = _app?.snapshot?.room.generation;
    if (coreState != null &&
        _lastCoreRoomState != null &&
        (coreState != _lastCoreRoomState ||
            (coreState && generation != _lastRoomGeneration)) &&
        !MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _partyJellyController
          ..stop()
          ..forward(from: 0).whenComplete(() {
            if (mounted) _partyJellyController.value = 0;
          });
      });
    }
    _lastCoreRoomState = coreState;
    if (generation != _lastRoomGeneration) {
      _partyPage = 0;
      _lastRoomGeneration = generation;
    } else {
      final safeCount = math.max(
        1,
        _app?.snapshot?.room.members.length ?? widget.previewPartySize,
      );
      final maxPage = (safeCount / 6).ceil() - 1;
      if (_partyPage > maxPage) {
        _partyPage = maxPage;
      }
    }

    if (app?.latestEvent?.code == 'lan_endpoint_selection_required' &&
        app!.revision > _handledLanSelectionRevision &&
        app.snapshot!.lanJoinEndpoints.isNotEmpty) {
      _handledLanSelectionRevision = app.revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectLanEndpoint(app.snapshot!.lanJoinEndpoints);
      });
    }

    final currentEventSerial = app?.eventSerial ?? 0;
    if (currentEventSerial != _handledEventSerial) {
      _handledEventSerial = currentEventSerial;
      final event = app?.latestEvent;
      if (event != null &&
          (event.code == 'relay_room_joined' ||
              event.code == 'lan_room_joined')) {
        if (event.success) {
          _lastJoinFailedCode = null;
          _lastJoinErrorMessage = null;
        } else {
          _lastJoinFailedCode = event.value;
          _lastJoinErrorMessage = localizeBridgeEvent(context, event);
        }
      }
    }
    if (_inRoom) {
      _lastJoinFailedCode = null;
      _lastJoinErrorMessage = null;
    }
  }

  @override
  void dispose() {
    widget.controller?._joinRoom = null;
    _partyJellyController.dispose();
    super.dispose();
  }

  String get _avatarInitials {
    final trimmed = _activeSteamUsername.trim();
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      final first = parts[0].characters.firstOrNull ?? '';
      final second = parts[1].characters.firstOrNull ?? '';
      if (first.isNotEmpty && second.isNotEmpty) {
        return '$first$second'.toUpperCase();
      }
    }
    if (trimmed.isNotEmpty) {
      return trimmed.characters.take(2).toString().toUpperCase();
    }
    return 'GP';
  }

  void _notice(String text) {
    AppNotification.show(
      context,
      text,
      duration: const Duration(milliseconds: 1400),
    );
  }

  Future<void> _onJoinRoom() async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    try {
      final l10n = context.l10n;
      final code = await showJoinRoomDialog(context);
      if (code != null && mounted) {
        if (_inRoom && code == _activeRoomCode) {
          _notice(l10n.roomAlreadyInTarget);
          return;
        }
        final replacingCurrentRoom = _inRoom;
        if (replacingCurrentRoom &&
            !await showReplaceRoomByCodeDialog(context, code)) {
          return;
        }
        if (!mounted) return;
        if (_app?.snapshot != null) {
          setState(() {
            _lastJoinFailedCode = null;
            _lastJoinErrorMessage = null;
          });
          final receipt = replacingCurrentRoom
              ? _app!.switchRoom(code, reportRejection: false)
              : _app!.joinRoom(code, reportRejection: false);
          if (!receipt.accepted) {
            final errorText = localizeBridgeRejection(
              context,
              receipt.rejection,
              fallback: replacingCurrentRoom
                  ? l10n.roomSwitchFailed
                  : l10n.roomJoinFailed,
            );
            setState(() {
              _lastJoinFailedCode = code;
              _lastJoinErrorMessage = errorText;
            });
            _notice(errorText);
          }
          return;
        }
        if (replacingCurrentRoom) {
          setState(() {
            _roomCode = code;
            _partyPage = 0;
          });
          _notice(l10n.roomSwitchedSuccess(code));
          return;
        }
        await _enterRoom(code: code);
        if (!mounted) return;
        _notice(l10n.roomJoinedSuccess(code));
      }
    } finally {
      if (mounted) _isDialogOpen = false;
    }
  }

  Future<void> _retryJoinRoom(String code) async {
    final app = _app;
    if (app == null || _roomBusy) return;
    setState(() {
      _lastJoinFailedCode = null;
      _lastJoinErrorMessage = null;
    });
    final receipt = app.joinRoom(code, reportRejection: false);
    if (!receipt.accepted) {
      final errorText = localizeBridgeRejection(
        context,
        receipt.rejection,
        fallback: context.l10n.roomJoinFailed,
      );
      setState(() {
        _lastJoinFailedCode = code;
        _lastJoinErrorMessage = errorText;
      });
      _notice(errorText);
    }
  }

  Future<void> _selectLanEndpoint(List<String> endpoints) async {
    if (endpoints.isEmpty || _isDialogOpen) return;
    _isDialogOpen = true;
    final String? endpoint;
    try {
      endpoint = await showLanEndpointSelectionDialog(context, endpoints);
    } finally {
      if (mounted) _isDialogOpen = false;
    }
    if (!mounted) return;
    if (endpoint == null) {
      _app?.leaveRoom();
      return;
    }
    final receipt = _app!.continueLanJoin(endpoint);
    if (!receipt.accepted) {
      _notice(
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: context.l10n.roomJoinFailed,
        ),
      );
      return;
    }
  }

  Future<void> _onCreateRoom() async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    try {
      final l10n = context.l10n;
      setState(() {
        _lastJoinFailedCode = null;
        _lastJoinErrorMessage = null;
      });
      final isLan =
          TractorBeamScope.maybeOf(context)?.connectionMode == ConnectionMode.lan;
      if (isLan) {
        final liveAdapters = _app?.snapshot == null
            ? null
            : await _app!.loadLanAdapters();
        if (!mounted) return;
        if (_app?.snapshot != null && liveAdapters == null) {
          _notice(
            localizeBridgeEvent(
              context,
              _app?.latestEvent,
              fallback: l10n.roomAdapterReadFailed,
            ),
          );
          return;
        }
        final adapters = await showCreateLanRoomDialog(
          context,
          adapters: liveAdapters
              ?.map(
                (adapter) => LanAdapterInfo(
                  adapter.name,
                  adapter.addresses.join(' · '),
                  adapter.id,
                  adapter.recommended,
                ),
              )
              .toList(),
        );
        if (adapters == null || !mounted) return;
        if (_app?.snapshot != null) {
          final receipt = _app!.createLanRoom(
            adapters.map((adapter) => adapter.id).whereType<String>().toList(),
          );
          if (!receipt.accepted) {
            _notice(
              localizeBridgeRejection(
                context,
                receipt.rejection,
                fallback: l10n.roomCreateFailed,
              ),
            );
          }
          return;
        }
        await _enterRoom();
        if (!mounted) return;
        _notice(l10n.roomLanCreatedSuccess(adapters.length));
        return;
      }

      if (_app?.snapshot != null) {
        final receipt = _app!.createRoom();
        if (!receipt.accepted) {
          _notice(
            localizeBridgeRejection(
              context,
              receipt.rejection,
              fallback: l10n.roomCreateFailed,
            ),
          );
        }
        return;
      }
      await _enterRoom();
      if (!mounted) return;
      _notice(l10n.roomCreatedSuccess);
    } finally {
      if (mounted) _isDialogOpen = false;
    }
  }

  Future<void> _enterRoom({String? code}) async {
    if (_inRoom || _partyJellyController.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        if (code != null) _roomCode = code;
        _isInRoom = true;
      });
      return;
    }

    try {
      _partyJellyController.value = 0;
      await _partyJellyController.animateTo(
        0.32,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      setState(() {
        if (code != null) _roomCode = code;
        _isInRoom = true;
      });
      await _partyJellyController.animateTo(
        1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
      if (mounted) _partyJellyController.value = 0;
    } on TickerCanceled {
      // Handled cleanly when screen unmounts mid-animation
    }
  }

  Future<void> _leaveRoom() async {
    final l10n = context.l10n;
    if (!_inRoom || _partyJellyController.isAnimating) return;

    if (_app?.isSessionRunning == true) {
      if (_isDialogOpen) return;
      _isDialogOpen = true;
      final bool confirmed;
      try {
        confirmed = await showLeaveRoomInGameDialog(context);
      } finally {
        if (mounted) _isDialogOpen = false;
      }
      if (!confirmed || !mounted) return;
    }

    if (_app?.snapshot != null) {
      setState(() {
        _lastJoinFailedCode = null;
        _lastJoinErrorMessage = null;
      });
      final receipt = _app!.leaveRoom();
      if (!receipt.accepted) {
        _notice(
          localizeBridgeRejection(
            context,
            receipt.rejection,
            fallback: l10n.roomLeaveFailed,
          ),
        );
      }
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _isInRoom = false;
        _partyPage = 0;
      });
      _notice(l10n.roomLeftSuccess);
      return;
    }

    try {
      _partyJellyController.value = 0;
      await _partyJellyController.animateTo(
        0.32,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      setState(() {
        _isInRoom = false;
        _partyPage = 0;
      });
      await _partyJellyController.animateTo(
        1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      _partyJellyController.value = 0;
      _notice(l10n.roomLeftSuccess);
    } on TickerCanceled {
      // Handled cleanly when screen unmounts mid-animation
    }
  }

  Future<void> _onManualSteamAccount() async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    try {
      final l10n = context.l10n;
      final unconfigured = l10n.roomSteamAccountUnconfigured;
      final manualAccounts = _app?.accounts
          .where((a) => a.isManual)
          .map(
            (a) =>
                SteamAccountData(username: a.displayName, steamId64: a.steamId64),
          )
          .toList();
      final result = await showManualSteamAccountDialog(
        context,
        initialUsername: _activeSteamUsername == unconfigured
            ? ''
            : _activeSteamUsername,
        initialSteamId64: _activeSteamId64 == unconfigured ? '' : _activeSteamId64,
        manualAccounts: manualAccounts,
        onDeleteManualAccount: (id64) {
          if (_app?.snapshot != null) {
            final receipt = _app!.deleteManualSteamAccount(id64);
            if (mounted) {
              _notice(
                receipt.accepted
                    ? l10n.steamManualAccountDeleted
                    : localizeBridgeRejection(
                        context,
                        receipt.rejection,
                        fallback: l10n.delete,
                      ),
              );
            }
          }
        },
      );
      if (result != null && mounted) {
        bool wasLanInRoom = false;
        if (_app?.isInRoom == true && result.steamId64 != _activeSteamId64) {
          final isLan = _app?.snapshot?.room.route == bridge.RoomRouteDto.lan;
          final confirmed = await showSwitchSteamAccountInRoomDialog(
            context,
            isLan: isLan,
          );
          if (!confirmed || !mounted) return;
          if (isLan) {
            wasLanInRoom = true;
            _app?.leaveRoom();
          }
        }

        if (_app?.snapshot != null) {
          final receipt = _app!.saveManualSteamAccount(
            steamId64: result.steamId64,
            displayName: result.username,
          );
          final successMsg = wasLanInRoom
              ? l10n.steamAccountUpdated(result.username)
              : (_inRoom && result.steamId64 != _activeSteamId64
                  ? l10n.steamSwitchedAndReconnected
                  : l10n.steamAccountUpdated(result.username));
          _notice(
            receipt.accepted
                ? successMsg
                : localizeBridgeRejection(
                    context,
                    receipt.rejection,
                    fallback: l10n.steamSwitchFailed,
                  ),
          );
          return;
        }
        setState(() {
          _steamUsername = result.username;
          _steamId64 = result.steamId64;
        });
        _notice(l10n.steamAccountUpdated(result.username));
      }
    } finally {
      if (mounted) _isDialogOpen = false;
    }
  }

  Future<void> _selectRoomHistory(BigInt historyId) async {
    if (_isDialogOpen) return;
    final app = _app;
    if (app == null || _roomBusy) return;
    final selected = app.roomHistory
        .where((entry) => entry.id == historyId)
        .firstOrNull;
    if (selected == null || selected.isCurrent) return;
    if (_inRoom) {
      _isDialogOpen = true;
      try {
        final confirm = await showSwitchHistoryRoomDialog(context);
        if (!confirm) return;
      } finally {
        if (mounted) _isDialogOpen = false;
      }
    }
    if (!mounted) return;
    final receipt = app.switchToHistoryRoom(historyId);
    if (!receipt.accepted) {
      _notice(
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: context.l10n.roomSwitchFailed,
        ),
      );
    }
  }

  Future<void> _selectSteamAccount(String steamId64) async {
    if (_isDialogOpen) return;
    final l10n = context.l10n;
    if (steamId64 == _activeSteamId64) return;
    bool wasLanInRoom = false;
    if (_app?.isInRoom == true) {
      final isLan = _app?.snapshot?.room.route == bridge.RoomRouteDto.lan;
      _isDialogOpen = true;
      bool confirmed;
      try {
        confirmed = await showSwitchSteamAccountInRoomDialog(
          context,
          isLan: isLan,
        );
      } finally {
        if (mounted) _isDialogOpen = false;
      }
      if (!confirmed || !mounted) return;
      if (isLan) {
        wasLanInRoom = true;
        _app?.leaveRoom();
      }
    }

    if (_app?.snapshot != null) {
      final receipt = _app!.selectSteamAccount(steamId64);
      final successMsg = wasLanInRoom
          ? l10n.steamSwitched
          : (_inRoom ? l10n.steamSwitchedAndReconnected : l10n.steamSwitched);
      _notice(
        receipt.accepted
            ? successMsg
            : localizeBridgeRejection(
                context,
                receipt.rejection,
                fallback: l10n.steamSwitchFailed,
              ),
      );
      return;
    }
    const accounts = {
      '76561198000000000': 'GamerPro 2024',
      '76561198123456789': 'Alex Wolf',
      '76561198987654321': 'Sakura99',
    };
    final username = accounts[steamId64];
    if (username == null || steamId64 == _steamId64) return;
    setState(() {
      _steamUsername = username;
      _steamId64 = steamId64;
    });
    _notice(l10n.steamSwitchedTo(username));
  }

  @override
  Widget build(BuildContext context) {
    final mismatch = _app?.steamIdentityMismatch;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: TbIcons.roomTitle(width: 112)),
          const SizedBox(height: 16),
          if (mismatch != null) ...[
            _steamMismatchBanner(mismatch),
            const SizedBox(height: 14),
          ],
          SizedBox(
            height: 252,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _roomCodePanel(context)),
                const SizedBox(width: 18),
                Expanded(child: _steamPanel(context)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: _buildPartyArea()),
        ],
      ),
    );
  }

  Widget _steamMismatchBanner(bridge.SteamIdentityMismatchDto mismatch) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accentRed.withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          TbIcons.noticeAlert(size: 24, color: AppColors.accentRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.roomSteamMismatchTitle}：${l10n.roomSteamMismatchMessage(mismatch.gameSteamId64, mismatch.roomSteamId64)}',
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 13.5,
                    color: AppColors.accentRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.roomSteamMismatchDesc,
                  style: AppTextStyles.metadata.copyWith(
                    fontSize: 13,
                    color: AppColors.accentRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SmallButton(
            icon: TbIcons.switchDirection(size: 14, color: AppColors.paperBg),
            label: l10n.roomSteamSyncNow,
            onTap: () {
              final receipt = _app?.useGameSteamAccount();
              if (receipt != null) {
                _notice(
                  receipt.accepted
                      ? l10n.roomSteamSyncSuccess
                      : localizeBridgeRejection(
                          context,
                          receipt.rejection,
                          fallback: l10n.roomSteamSyncFailed,
                        ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _roomCodePanel(BuildContext context) {
    final l10n = context.l10n;
    return _RoomPanel(
      key: const ValueKey('room-code-panel'),
      title: l10n.roomJoinCodeTitle,
      tooltip: l10n.roomJoinCodeHelp,
      trailing: _roomHistoryMenu(),
      backgroundAsset: 'assets/images/paper/room_code_card.webp',
      smallDivider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_inRoom)
            TornPaperContainer(
              seed: 31,
              roughness: 1.25,
              fillColor: AppColors.paperBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.roomCurrentCode, style: AppTextStyles.metadataInk),
                  const SizedBox(height: 7),
                  TornPaperContainer(
                    seed: 32,
                    roughness: 1.1,
                    showShadow: false,
                    fillColor: Colors.white.withValues(alpha: 0.65),
                    padding: const EdgeInsets.fromLTRB(13, 6, 6, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _activeRoomCode,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: AppTextStyles.mono.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.accentRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _DarkButton(
                          icon: TbIcons.copyRoomCode(
                            size: 18,
                            color: AppColors.paperBg,
                          ),
                          label: l10n.copy,
                          enabled: _activeRoomCode.isNotEmpty,
                          onTap: () async {
                            if (_activeRoomCode.isEmpty) return;
                            await Clipboard.setData(
                              ClipboardData(text: _activeRoomCode),
                            );
                            if (context.mounted) _notice(l10n.roomCodeCopied);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_app?.snapshot?.room.status == bridge.RoomStatusDto.joining)
            Expanded(
              child: TornPaperContainer(
                seed: 31,
                roughness: 1.25,
                fillColor: AppColors.paperBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.roomJoinJoining,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_lastJoinErrorMessage != null)
            Expanded(
              child: TornPaperContainer(
                seed: 31,
                roughness: 1.25,
                fillColor: AppColors.paperBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TbIcons.noticeAlert(
                            size: 15,
                            color: AppColors.accentRed,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.roomJoinFailedTitle,
                            style: AppTextStyles.bodyBold.copyWith(
                              fontSize: 13,
                              color: AppColors.accentRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _lastJoinErrorMessage!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.metadata.copyWith(
                          fontSize: 12,
                          color: AppColors.accentRed,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_lastJoinFailedCode != null &&
                              _lastJoinFailedCode!.isNotEmpty) ...[
                            _SmallButton(
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 13,
                                color: AppColors.paperBg,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              label: l10n.roomJoinRetry,
                              onTap: _roomBusy
                                  ? () => _notice(l10n.roomProcessingWait)
                                  : () => _retryJoinRoom(_lastJoinFailedCode!),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _SmallButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: AppColors.paperBg,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            label: l10n.roomJoinClear,
                            onTap: () {
                              setState(() {
                                _lastJoinFailedCode = null;
                                _lastJoinErrorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: TornPaperContainer(
                seed: 31,
                roughness: 1.25,
                fillColor: AppColors.paperBg,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: Text(
                    l10n.roomEmptySubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 17),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (_inRoom)
            _ActionButton(
              icon: TbIcons.leaveRoom(size: 18, color: AppColors.accentRed),
              label: l10n.leaveCurrentRoom,
              seed: 35,
              enabled: !_roomBusy,
              onTap: _roomBusy ? () => _notice(l10n.roomProcessingWait) : _leaveRoom,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: TbIcons.add(size: 15, color: AppColors.greenDot),
                    label: l10n.createStandaloneRoom,
                    seed: 11,
                    enabled: !_roomBusy,
                    onTap: _roomBusy
                        ? () => _notice(l10n.roomProcessingWait)
                        : _onCreateRoom,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: TbIcons.joinRoom(
                      size: 16,
                      color: AppColors.accentRedLight,
                    ),
                    label: l10n.inputCodeToJoin,
                    seed: 22,
                    enabled: !_roomBusy,
                    onTap: _roomBusy
                        ? () => _notice(l10n.roomProcessingWait)
                        : _onJoinRoom,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _roomHistoryMenu() {
    final l10n = context.l10n;
    final history = _app?.roomHistory ?? const <bridge.RoomHistoryEntryDto>[];
    BigInt? currentId;
    for (final entry in history) {
      if (entry.isCurrent) {
        currentId = entry.id;
        break;
      }
    }
    return PaperDropdown<BigInt>(
      selectedValue: currentId,
      seed: 87,
      menuWidth: 330,
      enabled: history.isNotEmpty && !_roomBusy,
      items: history
          .map(
            (entry) => PaperDropdownItem<BigInt>(
              value: entry.id,
              label: entry.joinCode,
              detail: entry.route == bridge.RoomRouteDto.lan
                  ? l10n.lanRoute
                  : l10n.relayConnectionRoute,
            ),
          )
          .toList(),
      onSelected: _selectRoomHistory,
      triggerBuilder: (openMenu) => _DarkButton(
        icon: TbIcons.roomHistory(size: 17, color: AppColors.paperBg),
        label: l10n.history,
        enabled: history.isNotEmpty && !_roomBusy,
        onTap: _roomBusy
            ? () => _notice(l10n.roomProcessingWait)
            : (history.isEmpty ? () => _notice(l10n.roomHistoryEmpty) : openMenu),
      ),
    );
  }

  Widget _steamPanel(BuildContext context) {
    final l10n = context.l10n;
    final hasQuickSwitch = _app?.mostRecentAccount != null &&
        _app!.mostRecentAccount!.steamId64 != _activeSteamId64;
    return _RoomPanel(
      key: const ValueKey('steam-account-panel'),
      title: l10n.roomSteamAccountTitle,
      tooltip: l10n.roomSteamAccountHelp,
      backgroundAsset: 'assets/images/paper/steam_account_card.webp',
      smallDivider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TornPaperContainer(
            seed: 41,
            roughness: 1.25,
            fillColor: AppColors.paperBg,
            padding: EdgeInsets.symmetric(
              horizontal: 13,
              vertical: hasQuickSwitch ? 10 : 24,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.canvasDarker,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    _avatarInitials,
                    style: AppTextStyles.buttonTextOnAccent.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeSteamUsername,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 19),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: double.infinity,
                        height: 18,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ID64：$_activeSteamId64',
                            maxLines: 1,
                            softWrap: false,
                            style: AppTextStyles.metadata,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                PaperDropdown<String>(
                  selectedValue: _activeSteamId64,
                  seed: 83,
                  menuWidth: 240,
                  items:
                      _app?.isNative == true || _app?.accounts.isNotEmpty == true
                      ? _app!.accounts
                            .map(
                              (account) => PaperDropdownItem(
                                value: account.steamId64,
                                label:
                                    '${account.displayName}${account.mostRecent ? " [${l10n.steamAccountActiveTag}]" : ""}${account.isManual ? " [${l10n.steamAccountManualTag}]" : ""}',
                                detail:
                                    'ID64: ${account.steamId64}${account.mostRecent ? " · ${l10n.steamAccountCurrentLogin}" : ""}',
                              ),
                            )
                            .toList()
                      : [
                          PaperDropdownItem(
                            value: _activeSteamId64,
                            label: _activeSteamUsername,
                            detail: 'ID64: $_activeSteamId64',
                          ),
                          if (_steamId64 != '76561198123456789')
                            const PaperDropdownItem(
                              value: '76561198123456789',
                              label: 'Alex Wolf',
                              detail: 'ID64: 76561198123456789',
                            ),
                          if (_steamId64 != '76561198987654321')
                            const PaperDropdownItem(
                              value: '76561198987654321',
                              label: 'Sakura99',
                              detail: 'ID64: 76561198987654321',
                            ),
                          if (_steamId64 != '76561198000000000')
                            const PaperDropdownItem(
                              value: '76561198000000000',
                              label: 'GamerPro 2024',
                              detail: 'ID64: 76561198000000000',
                            ),
                        ],
                  enabled: _app?.snapshot == null || _app!.accounts.isNotEmpty,
                  onSelected: _selectSteamAccount,
                  triggerBuilder: (openMenu) => _SmallButton(
                    icon: TbIcons.switchDirection(
                      size: 16,
                      color: AppColors.paperBg,
                    ),
                    label: l10n.switchAction,
                    onTap: openMenu,
                  ),
                ),
              ],
            ),
          ),
          if (_app?.mostRecentAccount != null &&
              _app!.mostRecentAccount!.steamId64 != _activeSteamId64) ...[
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: l10n.steamActiveQuickSwitch(
                _app!.mostRecentAccount!.displayName,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () =>
                    _selectSteamAccount(_app!.mostRecentAccount!.steamId64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: TbIcons.infoCircle(
                          size: 14,
                          color: AppColors.accentRed,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.steamActiveQuickSwitch(
                            _app!.mostRecentAccount!.displayName,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.metadata.copyWith(
                            fontSize: 12.5,
                            color: AppColors.accentRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: TbIcons.refreshAccount(
                    size: 16,
                    color: AppColors.greenDot,
                  ),
                  label: l10n.steamRefreshAccounts,
                  seed: 33,
                  onTap: () {
                    final receipt = _app?.refreshAccounts();
                    _notice(
                      receipt == null || receipt.accepted
                          ? l10n.steamRefreshStarted
                          : localizeBridgeRejection(
                              context,
                              receipt.rejection,
                              fallback: l10n.steamSwitchFailed,
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: TbIcons.edit(size: 14),
                  label: l10n.steamManualInput,
                  seed: 44,
                  onTap: _onManualSteamAccount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partyPanel() {
    final l10n = context.l10n;
    const pageSize = 6;
    final room = _app?.snapshot?.room;
    final coreMembers = room?.members;
    final localRoute = switch (room?.route) {
      bridge.RoomRouteDto.relay => l10n.routeRelay,
      bridge.RoomRouteDto.lan => l10n.routeLan,
      _ => '—',
    };
    final localTransport = switch (room?.transport) {
      bridge.TransportSelection.udp => l10n.transportUdp,
      bridge.TransportSelection.tcp => l10n.transportTcp,
      _ => '—',
    };
    final memberCount =
        coreMembers?.length ?? widget.previewPartySize.clamp(1, 8);
    final safeMemberCount = math.max(1, memberCount);
    final pageCount = (safeMemberCount / pageSize).ceil();
    final currentPage = _partyPage.clamp(0, pageCount - 1);

    final panel = _RoomPanel(
      key: const ValueKey('party-panel'),
      title: l10n.roomPartyTitle,
      tooltip: l10n.roomPartyHelp,
      backgroundAsset: 'assets/images/paper/party_card.webp',
      trailing: _Badge(
        text: pageCount > 1
            ? l10n.roomOnlineCountWithPage(memberCount, currentPage + 1, pageCount)
            : l10n.roomOnlineCount(memberCount),
        fontSize: 24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final cardWidth = constraints.maxWidth * 0.44;
          final isLan =
              TractorBeamScope.maybeOf(context)?.connectionMode ==
              ConnectionMode.lan;
          final demoMembers = <Widget>[
            _partyMember(
              cardWidth,
              _PlayerCard(
                initials: 'GP',
                name: 'GamerPro 2024',
                status: _formatMemberConnection(context, 'connected'),
                tag: l10n.memberTagLocal,
                footer: isLan
                    ? l10n.memberLocalFooter(l10n.routeLan, l10n.transportUdp)
                    : l10n.memberLocalFooter(l10n.routeRelay, l10n.transportUdp),
                seed: 51,
              ),
            ),
            _partyMember(
              cardWidth,
              _PlayerCard(
                initials: 'AW',
                name: 'Alex Wolf',
                status: _formatMemberConnection(context, 'playing'),
                latencyMs: 32,
                footer: l10n.memberPeerFooter('2.8', '0.1'),
                seed: 52,
                avatarColor: const Color(0xFFD9E8F5),
                textColor: const Color(0xFF345D83),
              ),
            ),
            _partyMember(
              cardWidth,
              _PlayerCard(
                initials: 'S9',
                name: 'Sakura99',
                status: _formatMemberConnection(context, 'playing'),
                latencyMs: 78,
                footer: l10n.memberPeerFooter('3.5', '0.0'),
                seed: 53,
              ),
            ),
            _partyMember(
              cardWidth,
              _PlayerCard(
                initials: 'MK',
                name: 'Miko',
                status: _formatMemberConnection(context, 'connected'),
                latencyMs: 46,
                footer: l10n.memberPeerFooter('3.1', '0.0'),
                seed: 54,
                avatarColor: const Color(0xFFF1E1D7),
              ),
            ),
            _partyMember(
              cardWidth,
              _PlayerCard(
                initials: 'NL',
                name: 'Nora Lee',
                status: _formatMemberConnection(context, 'playing'),
                latencyMs: 118,
                footer: l10n.memberPeerFooter('6.2', '0.4'),
                seed: 55,
                avatarColor: const Color(0xFFE5DDF0),
              ),
            ),
            _partyMember(
              cardWidth,
              _PlayerCard(
                initials: 'RY',
                name: 'Rin Yamada',
                status: _formatMemberConnection(context, 'connected'),
                latencyMs: 55,
                footer: l10n.memberPeerFooter('3.8', '0.1'),
                seed: 56,
              ),
            ),
            _partyMember(
              cardWidth,
              _PlayerCard(
                initials: 'KT',
                name: 'Kaito',
                status: _formatMemberConnection(context, 'playing'),
                latencyMs: 67,
                footer: l10n.memberPeerFooter('4.2', '0.2'),
                seed: 57,
                avatarColor: const Color(0xFFDDEBD8),
              ),
            ),
            _partyMember(
              cardWidth,
              _PlayerCard(
                initials: 'LU',
                name: 'Luna',
                status: _formatMemberConnection(context, 'connected'),
                latencyMs: 91,
                footer: l10n.memberPeerFooter('5.0', '0.3'),
                seed: 58,
                avatarColor: const Color(0xFFF2DFE8),
              ),
            ),
          ].take(memberCount).toList();
          final members = coreMembers == null
              ? demoMembers
              : coreMembers.asMap().entries.map((entry) {
                  final member = entry.value;
                  final name = member.displayName;
                  final initials = name.isEmpty
                      ? 'TB'
                      : name.characters.take(2).toString().toUpperCase();
                  final jitter = member.jitterMs?.toString() ?? '—';
                  final loss = member.lossBasisPoints == null
                      ? '—'
                      : (member.lossBasisPoints!.toInt() / 100).toStringAsFixed(
                          1,
                        );
                  return _partyMember(
                    cardWidth,
                    _PlayerCard(
                      key: ValueKey('party-member-${member.steamId64}'),
                      initials: initials,
                      name: name,
                      status: _formatMemberConnection(
                        context,
                        member.connection,
                      ),
                      tag: member.isLocal ? l10n.memberTagLocal : null,
                      latencyMs: member.isLocal
                          ? null
                          : member.latencyMs?.toInt(),
                      footer: member.isLocal
                          ? l10n.memberLocalFooter(localRoute, localTransport)
                          : l10n.memberPeerFooter(jitter, loss),
                      seed: 80 + entry.key,
                    ),
                  );
                }).toList();
          final visibleMembers = members
              .skip(currentPage * pageSize)
              .take(pageSize)
              .toList();

          return Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: pageCount > 1
                      ? const EdgeInsets.symmetric(horizontal: 30)
                      : EdgeInsets.zero,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: gap,
                      runSpacing: gap,
                      children: visibleMembers,
                    ),
                  ),
                ),
              ),
              if (currentPage > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _PartyPageButton(
                    key: const ValueKey('party-previous-page'),
                    icon: TbIcons.partyPagePrevious(color: Colors.white),
                    tooltip:
                        Localizations.localeOf(context).languageCode == 'zh'
                        ? '上一页'
                        : 'Previous page',
                    onTap: () => setState(() {
                      _partySlideDirection = -1;
                      _partyPage = (currentPage - 1).clamp(0, pageCount - 1);
                    }),
                  ),
                ),
              if (currentPage < pageCount - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: _PartyPageButton(
                    key: const ValueKey('party-next-page'),
                    icon: TbIcons.partyPageNext(color: Colors.white),
                    tooltip:
                        Localizations.localeOf(context).languageCode == 'zh'
                        ? '下一页'
                        : 'Next page',
                    onTap: () => setState(() {
                      _partySlideDirection = 1;
                      _partyPage = (currentPage + 1).clamp(0, pageCount - 1);
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 250),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) => _buildPartyPageTransition(
        child: child,
        animation: animation,
        incoming: child.key == ValueKey<int>(currentPage),
      ),
      child: KeyedSubtree(key: ValueKey<int>(currentPage), child: panel),
    );
  }

  Widget _buildPartyPageTransition({
    required Widget child,
    required Animation<double> animation,
    required bool incoming,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final direction = _partySlideDirection.toDouble();
        final impactAlignment = direction > 0
            ? Alignment.centerLeft
            : Alignment.centerRight;
        final exitAlignment = direction > 0
            ? Alignment.centerRight
            : Alignment.centerLeft;

        if (!incoming) {
          final exitProgress = 1.0 - animation.value;
          final exitSlide = TweenSequence<double>([
            TweenSequenceItem(tween: ConstantTween(0.0), weight: 14),
            TweenSequenceItem(
              tween: Tween(
                begin: 0.0,
                end: -1.35 * direction,
              ).chain(CurveTween(curve: Curves.easeInCubic)),
              weight: 62,
            ),
            TweenSequenceItem(
              tween: ConstantTween(-1.35 * direction),
              weight: 24,
            ),
          ]).transform(exitProgress);

          final exitScaleX = TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween(
                begin: 1.0,
                end: 0.94,
              ).chain(CurveTween(curve: Curves.easeOut)),
              weight: 14,
            ),
            TweenSequenceItem(
              tween: Tween(
                begin: 0.94,
                end: 1.035,
              ).chain(CurveTween(curve: Curves.easeIn)),
              weight: 23,
            ),
            TweenSequenceItem(tween: Tween(begin: 1.035, end: 1.0), weight: 39),
            TweenSequenceItem(tween: ConstantTween(1.0), weight: 24),
          ]).transform(exitProgress);

          return Opacity(
            opacity: (1.0 - ((exitProgress - 0.62) / 0.14)).clamp(0.0, 1.0),
            child: FractionalTranslation(
              translation: Offset(exitSlide, 0),
              child: Transform.scale(
                alignment: exitAlignment,
                scaleX: exitScaleX,
                child: child,
              ),
            ),
          );
        }

        final progress = animation.value;
        final slide = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 1.35 * direction, end: 0.0),
            weight: 40,
          ),
          TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
        ]).transform(progress);

        final squeezeX = TweenSequence<double>([
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.0,
              end: 0.84,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 11,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 0.84,
              end: 1.045,
            ).chain(CurveTween(curve: Curves.easeOutBack)),
            weight: 20,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.045,
              end: 0.985,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 15,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 0.985,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 14,
          ),
        ]).transform(progress);

        final squeezeY = TweenSequence<double>([
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 11),
          TweenSequenceItem(tween: Tween(begin: 1.04, end: 0.99), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 0.99, end: 1.008), weight: 15),
          TweenSequenceItem(tween: Tween(begin: 1.008, end: 1.0), weight: 14),
        ]).transform(progress);

        return Opacity(
          opacity: (progress / 0.08).clamp(0.0, 1.0),
          child: FractionalTranslation(
            translation: Offset(slide, 0),
            child: Transform.scale(
              alignment: impactAlignment,
              scaleX: squeezeX,
              scaleY: squeezeY,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _partyMember(double width, Widget child) =>
      SizedBox(width: width, height: 92, child: child);

  Widget _buildPartyArea() => AnimatedBuilder(
    animation: _partyJellyController,
    builder: (context, _) {
      final progress = _partyJellyController.value;
      final scaleX = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.96), weight: 32),
        TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.025), weight: 28),
        TweenSequenceItem(tween: Tween(begin: 1.025, end: 0.99), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.99, end: 1.0), weight: 20),
      ]).transform(progress);
      final scaleY = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.035), weight: 32),
        TweenSequenceItem(tween: Tween(begin: 1.035, end: 0.985), weight: 28),
        TweenSequenceItem(tween: Tween(begin: 0.985, end: 1.008), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.008, end: 1.0), weight: 20),
      ]).transform(progress);
      final child = KeyedSubtree(
        key: ValueKey(
          '${_app?.snapshot?.room.status.name}:${_app?.snapshot?.room.generation}',
        ),
        child: _inRoom ? _partyPanel() : _collapsedPartyPanel(),
      );
      return Transform.scale(scaleX: scaleX, scaleY: scaleY, child: child);
    },
  );

  Widget _collapsedPartyPanel() => Center(
    child: AspectRatio(
      aspectRatio: 1660 / 178,
      child: TbPaperImageScope(
        asset: 'assets/images/paper/party_card_collapsed.webp',
        builder: (context, imageProvider) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AssetShapeShadow(imageProvider: imageProvider),
            ),
            Container(
              key: const ValueKey('empty-room-panel'),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.fill,
                  filterQuality:
                      WindowResizePerformanceScope.largeImageQualityOf(context),
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(90, 8, 90, 4),
              child: Text(
                _emptyRoomText,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardHeader.copyWith(
                  fontSize: 20,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RoomPanel extends StatelessWidget {
  final String title;
  final String backgroundAsset;
  final Widget child;
  final Widget? trailing;
  final bool smallDivider;
  final String? tooltip;
  const _RoomPanel({
    super.key,
    required this.title,
    required this.backgroundAsset,
    required this.child,
    this.trailing,
    this.smallDivider = false,
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
          key: ValueKey('room-panel-background-$title'),
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
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TbIcons.sectionTriangle(size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(title, style: AppTextStyles.cardHeader),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (tooltip != null && tooltip!.isNotEmpty)
                          Tooltip(
                            message: tooltip!,
                            child: TbIcons.infoCircle(
                              size: 16,
                              color: AppColors.inkMuted,
                            ),
                          )
                        else
                          TbIcons.infoCircle(size: 16, color: AppColors.inkMuted),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 8),
              smallDivider
                  ? TbIcons.roomDashedLine(height: 6)
                  : TbIcons.dashedLine(height: 11),
              const SizedBox(height: 11),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final int? seed;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.seed,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1.0 : 0.48,
    child: TornPaperButton(
      onTap: enabled ? onTap : () {},
      seed: seed ?? label.hashCode,
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

class _DarkButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  const _DarkButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1.0 : 0.48,
    child: TornPaperButton(
      onTap: enabled ? onTap : () {},
      seed: 6,
      roughness: 1.15,
      borderWidth: 1.8,
      fillColor: AppColors.canvasDarker,
      hoverFillColor: const Color(0xFF383331),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.buttonTextOnAccent.copyWith(fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

class _SmallButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const _SmallButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });
  @override
  Widget build(BuildContext context) => TornPaperButton(
    onTap: onTap ?? () {},
    seed: 8,
    roughness: 1.2,
    borderWidth: 1.8,
    fillColor: AppColors.canvasDarker,
    hoverFillColor: const Color(0xFF383331),
    padding: padding,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.buttonTextOnAccent),
      ],
    ),
  );
}

class _PartyPageButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _PartyPageButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: 28,
      height: 104,
      child: TornPaperButton(
        onTap: onTap,
        semanticLabel: tooltip,
        seed: 73,
        roughness: 1.15,
        borderWidth: 1.8,
        fillColor: AppColors.canvasDarker,
        hoverFillColor: const Color(0xFF383331),
        padding: EdgeInsets.zero,
        child: Center(child: icon),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final int seed;
  final Color? fillColor;
  final Color? borderColor;
  final Color? textColor;
  final Widget? icon;
  final double fontSize;

  const _Badge({
    required this.text,
    this.seed = 81,
    this.fillColor,
    this.borderColor,
    this.textColor,
    this.icon,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) => TornPaperContainer(
    seed: seed,
    roughness: 1.15,
    borderWidth: 1.4,
    showShadow: false,
    fillColor: fillColor ?? AppColors.paperBg,
    borderColor: borderColor ?? AppColors.paperBorder,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 4)],
        Text(
          text,
          style: AppTextStyles.metadataInk.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: textColor ?? AppColors.ink,
          ),
        ),
      ],
    ),
  );
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();
  @override
  Widget build(BuildContext context) {
    final label = context.l10n.memberStatusConnected;
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFF7DA685),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String initials, name, status, footer;
  final String? tag;
  final int? latencyMs;
  final int seed;
  final Color avatarColor;
  final Color? textColor;
  const _PlayerCard({
    super.key,
    required this.initials,
    required this.name,
    required this.status,
    this.tag,
    this.latencyMs,
    required this.footer,
    required this.seed,
    this.avatarColor = AppColors.paperBg,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) => TornPaperContainer(
    seed: seed,
    roughness: 1.25,
    fillColor: AppColors.paperBg,
    padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.rotate(
                  angle: -.05,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        border: Border.all(
                          color: AppColors.paperBorder,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        initials,
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: initials.length > 1 ? 15 : 18,
                          fontWeight: FontWeight.w900,
                          color: textColor ?? AppColors.accentRed,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(right: -2, bottom: -2, child: _OnlineDot()),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.metadata,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            latencyMs == null
                ? (tag != null
                      ? _Badge(
                          text: tag!,
                          seed: seed + 7,
                          fillColor: AppColors.paperBg,
                        )
                      : const SizedBox.shrink())
                : () {
                    // P2P end-to-end latency: 0-60 优秀, 60-100 一般, 100-150 差, >150 严重
                    final theme = LatencyTheme.ofP2p(latencyMs!);
                    return _Badge(
                      text: '${latencyMs}ms',
                      seed: seed + 7,
                      fillColor: theme.badgeBg,
                      borderColor: theme.badgeBorder,
                      textColor: theme.textColor,
                      icon: TbIcons.latencyIconForGrade(theme.grade, size: 14),
                    );
                  }(),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(footer, style: AppTextStyles.metadata),
          ),
        ),
      ],
    ),
  );
}

String _formatMemberConnection(BuildContext context, String connection) {
  final l10n = context.l10n;
  return switch (connection.toLowerCase()) {
    'connected' || '已连接' => l10n.memberStatusConnected,
    'connecting' || '连接中' => l10n.memberStatusConnecting,
    'reconnecting' || '重连中' => l10n.memberStatusReconnecting,
    'disconnected' || '已断开' => l10n.memberStatusDisconnected,
    'discovered' || '已发现' => l10n.memberStatusConnected,
    'playing' || 'ingame' || '游戏中' => l10n.memberStatusPlaying,
    'inactive' || '未连接' => l10n.memberStatusInactive,
    _ => connection,
  };
}
