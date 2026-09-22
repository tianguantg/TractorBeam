import 'dart:async';
import 'package:flutter/material.dart';

import '../bridge/generated/api.dart' as bridge;
import '../l10n/bridge_message_localizer.dart';
import '../l10n/l10n.dart';
import '../locale/ui_locale_store.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/asset_shape_shadow.dart';
import '../widgets/custom_icons.dart';
import '../widgets/paper_image.dart';
import '../widgets/torn_paper.dart';

enum _TransportProtocol { automatic, udp, tcp }

enum _WorkMode { official, fallback, pure }

class SettingsScreen extends StatefulWidget {
  final ValueChanged<Locale>? onLocaleChanged;

  const SettingsScreen({super.key, this.onLocaleChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _TransportProtocol _protocol = _TransportProtocol.tcp;
  _WorkMode _workMode = _WorkMode.pure;
  double _inputLatency = 2;
  BigInt _lastSyncedRevision = BigInt.from(-1);
  BigInt _lastHandledEventRevision = BigInt.from(-1);
  bool _hasUserEditedDelay = false;
  int? _lastSyncedDelay;
  bool _wasSessionRunning = false;
  bool _isReadingDelay = false;
  bool _isWritingDelay = false;

  bool _isOfficialSession(TractorBeamController? app) {
    if (app != null && app.isSessionRunning) {
      final activeMode = app.snapshot?.session.activeMode;
      if (activeMode != null) {
        return activeMode == bridge.SessionModeDto.official;
      }
    }
    return _workMode == _WorkMode.official;
  }

  bool _canEditDelay(TractorBeamController? app) {
    final isGameRunning = app == null || app.isSessionRunning;
    return !_isOfficialSession(app) && isGameRunning;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = TractorBeamScope.maybeOf(context);
    final snapshot = app?.snapshot;
    if (app == null) return;

    // Reset draft flag when session starts or terminates so new sessions receive fresh truth
    if (app.isSessionRunning != _wasSessionRunning) {
      _wasSessionRunning = app.isSessionRunning;
      _hasUserEditedDelay = false;
      _isReadingDelay = false;
      _isWritingDelay = false;
    }

    // Handle asynchronous IPC events from backend
    if (app.revision > _lastHandledEventRevision) {
      _lastHandledEventRevision = app.revision;
      final event = app.latestEvent;
      if (event != null) {
        if (event.code == 'input_delay_read') {
          _isReadingDelay = false;
          if (event.success) {
            final readVal = int.tryParse(event.value ?? '');
            if (readVal != null) {
              _inputLatency = readVal.toDouble().clamp(0, 5).toDouble();
              _hasUserEditedDelay = false;
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _notice(
                  localizeBridgeEvent(
                    context,
                    event,
                    fallback: context.l10n.settingsInputDelayReadSuccess,
                  ),
                );
              }
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _notice(
                  localizeBridgeEvent(
                    context,
                    event,
                    fallback: context.l10n.errInputDelayGeneric,
                  ),
                );
              }
            });
          }
        } else if (event.code == 'input_delay_written') {
          _isWritingDelay = false;
          if (event.success) {
            _hasUserEditedDelay = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _notice(
                  localizeBridgeEvent(
                    context,
                    event,
                    fallback: context.l10n.settingsInputDelayWriteSuccess,
                  ),
                );
              }
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _notice(
                  localizeBridgeEvent(
                    context,
                    event,
                    fallback: context.l10n.errInputDelayGeneric,
                  ),
                );
              }
            });
          }
        }
      }
    }

    if (snapshot == null || app.revision == _lastSyncedRevision) return;
    _lastSyncedRevision = app.revision;
    _protocol = switch (snapshot.clientConfig.transport) {
      bridge.TransportSelection.udp => _TransportProtocol.udp,
      bridge.TransportSelection.tcp => _TransportProtocol.tcp,
      _ => _TransportProtocol.automatic,
    };
    _workMode = switch (snapshot.clientConfig.mode) {
      bridge.SessionModeDto.official => _WorkMode.official,
      bridge.SessionModeDto.fallback => _WorkMode.fallback,
      _ => _WorkMode.pure,
    };
    final delay = snapshot.hook.inputDelay;
    if (delay != null && delay != _lastSyncedDelay) {
      _lastSyncedDelay = delay;
      if (!_hasUserEditedDelay) {
        _inputLatency = delay.toDouble().clamp(0, 5).toDouble();
      }
    }
  }

  void _setLanguage(Locale locale) {
    if (Localizations.localeOf(context).languageCode == locale.languageCode) {
      return;
    }
    widget.onLocaleChanged?.call(locale);
    unawaited(UiLocaleStore.save(locale));
  }

  void _restoreDefaults() {
    final l10n = context.l10n;
    final app = TractorBeamScope.maybeOf(context);
    final receipt = app?.restoreDefaultPreferences();
    if (receipt != null && !receipt.accepted) {
      _notice(
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: l10n.settingsRestoreDefaults,
        ),
      );
      return;
    }
    setState(() {
      _protocol = _TransportProtocol.automatic;
      _workMode = _WorkMode.pure;
      if (app?.isSessionRunning ?? false) {
        final delay = app?.snapshot?.hook.inputDelay;
        if (delay != null) {
          _inputLatency = delay.toDouble().clamp(0, 5).toDouble();
        }
      } else {
        _inputLatency = 2;
      }
      _hasUserEditedDelay = false;
    });
    _notice(l10n.settingsRestoreDefaultsSuccess);
  }

  void _selectProtocol(_TransportProtocol protocol) {
    if (_protocol == protocol) return;
    final previous = _protocol;
    setState(() => _protocol = protocol);
    final value = switch (protocol) {
      _TransportProtocol.automatic => bridge.TransportSelection.relayDefault,
      _TransportProtocol.udp => bridge.TransportSelection.udp,
      _TransportProtocol.tcp => bridge.TransportSelection.tcp,
    };
    final receipt = TractorBeamScope.maybeOf(context)?.setTransport(value);
    if (receipt != null && !receipt.accepted) {
      setState(() => _protocol = previous);
      _notice(
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: context.l10n.genericError,
        ),
      );
    }
  }

  void _selectMode(_WorkMode mode) {
    final l10n = context.l10n;
    if (_workMode == mode) return;
    final previous = _workMode;
    setState(() => _workMode = mode);
    final value = switch (mode) {
      _WorkMode.official => bridge.SessionModeDto.official,
      _WorkMode.fallback => bridge.SessionModeDto.fallback,
      _WorkMode.pure => bridge.SessionModeDto.pure,
    };
    final app = TractorBeamScope.maybeOf(context);
    final receipt = app?.setMode(value);
    if (receipt != null && !receipt.accepted) {
      setState(() => _workMode = previous);
      _notice(
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: l10n.genericError,
        ),
      );
    } else if (app?.isSessionRunning ?? false) {
      _notice(l10n.settingsWorkModeSavedRestartHint);
    }
  }

  void _readInputDelay() {
    final l10n = context.l10n;
    final app = TractorBeamScope.maybeOf(context);
    if (_isOfficialSession(app)) {
      _notice(l10n.settingsInputDelayOfficialNotice);
      return;
    }
    if (app != null && !app.isSessionRunning) {
      _notice(l10n.settingsInputDelayNotRunningNotice);
      return;
    }
    if (_isReadingDelay || _isWritingDelay) return;
    final receipt = app?.readInputDelay();
    if (receipt != null && !receipt.accepted) {
      _notice(
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: l10n.errInputDelayGeneric,
        ),
      );
      return;
    }
    if (app == null || !app.isNative) {
      final currentDelay = app?.snapshot?.hook.inputDelay;
      if (currentDelay != null) {
        setState(() {
          _inputLatency = currentDelay.toDouble().clamp(0, 5).toDouble();
          _hasUserEditedDelay = false;
        });
      }
      _notice(l10n.settingsInputDelayReadSuccess);
      return;
    }
    setState(() => _isReadingDelay = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _isReadingDelay) {
        setState(() => _isReadingDelay = false);
      }
    });
  }

  void _writeInputDelay() {
    final l10n = context.l10n;
    final app = TractorBeamScope.maybeOf(context);
    if (_isOfficialSession(app)) {
      _notice(l10n.settingsInputDelayOfficialNotice);
      return;
    }
    if (app != null && !app.isSessionRunning) {
      _notice(l10n.settingsInputDelayNotRunningNotice);
      return;
    }
    if (_isReadingDelay || _isWritingDelay) return;
    final receipt = app?.writeInputDelay(_inputLatency.round());
    if (receipt != null && !receipt.accepted) {
      _notice(
        localizeBridgeRejection(
          context,
          receipt.rejection,
          fallback: l10n.errInputDelayGeneric,
        ),
      );
      return;
    }
    if (app == null || !app.isNative) {
      setState(() {
        _hasUserEditedDelay = false;
      });
      _notice(l10n.settingsInputDelayWriteSuccess);
      return;
    }
    setState(() => _isWritingDelay = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _isWritingDelay) {
        setState(() => _isWritingDelay = false);
      }
    });
  }

  void _notice(String text) {
    AppNotification.show(
      context,
      text,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: TbIcons.settingsTitle(width: 112)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AspectRatio(
                          // Keep close to the 820:382 artwork while reserving
                          // enough vertical room for the full-size controls.
                          aspectRatio: 2.03,
                          child: _protocolCard(l10n),
                        ),
                        const SizedBox(height: 14),
                        AspectRatio(
                          // The artwork is 820:350; this small allowance avoids
                          // compressing the three two-line choices.
                          aspectRatio: 2.18,
                          child: _workModeCard(l10n),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 828 / 628,
                          child: _latencyCard(l10n),
                        ),
                        const SizedBox(height: 14),
                        AspectRatio(
                          // Matches the 2.18 aspect ratio of _workModeCard
                          // so user can create the asset using the same 386x177 template.
                          aspectRatio: 2.18,
                          child: _languageCard(l10n, isZh),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 220,
              child: _ActionButton(
                key: const ValueKey('restore-default-settings'),
                icon: TbIcons.refreshAccount(
                  size: 18,
                  color: AppColors.accentRed,
                ),
                label: l10n.settingsRestoreDefaults,
                seed: 94,
                onTap: _restoreDefaults,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _languageCard(AppLocalizations l10n, bool isZh) => _SettingsPanel(
    key: const ValueKey('language-panel'),
    title: l10n.settingsLanguageTitle,
    backgroundAsset: 'assets/images/paper/settings_language_card.webp',
    tooltip: l10n.settingsLanguageHelpTooltip,
    child: TornPaperContainer(
      seed: 73,
      roughness: 1.25,
      borderWidth: 1.8,
      fillColor: AppColors.paperBg,
      showShadow: false,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _choice(
              title: l10n.settingsLanguageZh,
              subtitle: l10n.settingsLanguageZhSub,
              selected: isZh,
              seed: 71,
              onTap: () => _setLanguage(const Locale('zh', 'CN')),
            ),
          ),
          Expanded(
            child: _choice(
              title: l10n.settingsLanguageEn,
              subtitle: l10n.settingsLanguageEnSub,
              selected: !isZh,
              seed: 72,
              onTap: () => _setLanguage(const Locale('en', 'US')),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _protocolCard(AppLocalizations l10n) => _SettingsPanel(
    key: const ValueKey('protocol-panel'),
    title: l10n.settingsTransportProtocolTitle,
    backgroundAsset: 'assets/images/paper/settings_protocol_card.webp',
    tooltip: l10n.settingsProtocolHelpTooltip,
    child: TornPaperContainer(
      seed: 61,
      roughness: 1.25,
      borderWidth: 1.8,
      fillColor: AppColors.paperBg,
      showShadow: false,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _choice(
              title: l10n.settingsProtocolAuto,
              subtitle: l10n.settingsProtocolAutoSub,
              selected: _protocol == _TransportProtocol.automatic,
              seed: 11,
              onTap: () => _selectProtocol(_TransportProtocol.automatic),
            ),
          ),
          Expanded(
            child: _choice(
              title: l10n.settingsProtocolUdp,
              subtitle: l10n.settingsProtocolUdpSub,
              selected: _protocol == _TransportProtocol.udp,
              seed: 22,
              onTap: () => _selectProtocol(_TransportProtocol.udp),
            ),
          ),
          Expanded(
            child: _choice(
              title: l10n.settingsProtocolTcp,
              subtitle: l10n.settingsProtocolTcpSub,
              selected: _protocol == _TransportProtocol.tcp,
              seed: 33,
              onTap: () => _selectProtocol(_TransportProtocol.tcp),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _workModeCard(AppLocalizations l10n) => _SettingsPanel(
    key: const ValueKey('work-mode-panel'),
    title: l10n.settingsWorkModeTitle,
    backgroundAsset: 'assets/images/paper/settings_mode_card.webp',
    tooltip: l10n.settingsModeHelpTooltip,
    child: TornPaperContainer(
      seed: 62,
      roughness: 1.25,
      borderWidth: 1.8,
      fillColor: AppColors.paperBg,
      showShadow: false,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _choice(
              title: l10n.settingsModeOfficialTitle,
              subtitle: l10n.settingsModeOfficialSub,
              selected: _workMode == _WorkMode.official,
              seed: 44,
              onTap: () => _selectMode(_WorkMode.official),
            ),
          ),
          Expanded(
            child: _choice(
              title: l10n.settingsModeFallbackTitle,
              subtitle: l10n.settingsModeFallbackSub,
              selected: _workMode == _WorkMode.fallback,
              seed: 55,
              onTap: () => _selectMode(_WorkMode.fallback),
            ),
          ),
          Expanded(
            child: _choice(
              title: l10n.settingsModePureTitle,
              subtitle: l10n.settingsModePureSub,
              selected: _workMode == _WorkMode.pure,
              seed: 66,
              onTap: () => _selectMode(_WorkMode.pure),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _latencyCard(AppLocalizations l10n) {
    final app = TractorBeamScope.maybeOf(context);
    final isOfficial = _isOfficialSession(app);
    final isGameRunning = app == null || app.isSessionRunning;
    final canEditDelay = _canEditDelay(app);
    final appliedDelay = app?.snapshot?.hook.inputDelay;
    final hookError = app?.snapshot?.hook.inputDelayError;
    final hasHookError =
        canEditDelay && (hookError != null && hookError.isNotEmpty);

    final String hintText;
    if (canEditDelay && hookError != null && hookError.isNotEmpty) {
      hintText = hookError;
    } else if (isOfficial) {
      hintText = l10n.settingsInputDelayOfficialNotice;
    } else if (!isGameRunning) {
      hintText = l10n.settingsInputDelayNotRunningNotice;
    } else if (_isReadingDelay) {
      hintText = l10n.settingsInputDelayReading;
    } else if (_isWritingDelay) {
      hintText = l10n.settingsInputDelayWriting;
    } else {
      hintText = l10n.settingsInputDelayAdjustHint;
    }

    return _SettingsPanel(
      key: const ValueKey('latency-panel'),
      title: l10n.settingsInputDelayTitle,
      backgroundAsset: 'assets/images/paper/settings_latency_card.webp',
      tooltip: l10n.settingsInputDelayHelpTooltip,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (appliedDelay != null && canEditDelay) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.peachPaper,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.paperBorder, width: 1),
              ),
              child: Text(
                l10n.settingsInputDelayApplied(appliedDelay),
                style: AppTextStyles.metadataInk.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentRed,
                ),
              ),
            ),
          ],
          TbIcons.settingsLatencyLevel(
            level: isOfficial ? 0 : _inputLatency.round(),
            width: 64,
            height: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Opacity(
            opacity: canEditDelay ? 1.0 : 0.45,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: canEditDelay
                  ? null
                  : () => _notice(
                        isOfficial
                            ? l10n.settingsInputDelayOfficialNotice
                            : l10n.settingsInputDelayNotRunningNotice,
                      ),
              child: IgnorePointer(
                ignoring: !canEditDelay,
                child: TornPaperContainer(
                  seed: 63,
                  roughness: 1.25,
                  borderWidth: 1.8,
                  fillColor: AppColors.paperBg,
                  showShadow: false,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.canvasDarker,
                          inactiveTrackColor: AppColors.paperBorder.withValues(
                            alpha: 0.18,
                          ),
                          thumbColor: AppColors.canvasDarker,
                          overlayColor: AppColors.ink.withValues(alpha: .1),
                          trackHeight: 8,
                        ),
                        child: Slider(
                          key: const ValueKey('input-latency-slider'),
                          value: _inputLatency,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: '${_inputLatency.toInt()} 帧',
                          semanticFormatterCallback: (double value) =>
                              '${value.toInt()} 帧',
                          onChanged: canEditDelay &&
                                  !_isReadingDelay &&
                                  !_isWritingDelay
                              ? (value) => setState(() {
                                  _inputLatency = value;
                                  _hasUserEditedDelay = true;
                                })
                              : null,
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        width: double.infinity,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double totalWidth = constraints.maxWidth;
                            const double tickStart = 28.0;
                            final double usableWidth =
                                totalWidth - tickStart * 2;

                            return Stack(
                              clipBehavior: Clip.none,
                              children: List.generate(6, (index) {
                                final isSelected =
                                    !isOfficial &&
                                    _inputLatency.round() == index;
                                final double tickCenterX =
                                    tickStart + (index / 5.0) * usableWidth;

                                return Positioned(
                                  left: tickCenterX,
                                  top: 0,
                                  bottom: 0,
                                  child: FractionalTranslation(
                                    translation: const Offset(-0.5, 0.0),
                                    child: Semantics(
                                      button: true,
                                      selected: isSelected,
                                      label: '$index 帧',
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: canEditDelay &&
                                                !_isReadingDelay &&
                                                !_isWritingDelay
                                            ? () => setState(() {
                                                _inputLatency = index.toDouble();
                                                _hasUserEditedDelay = true;
                                              })
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: isSelected
                                              ? BoxDecoration(
                                                  color: AppColors.peachPaper,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: AppColors.paperBorder,
                                                    width: 1.2,
                                                  ),
                                                )
                                              : null,
                                          child: Center(
                                            child: Text(
                                              '$index',
                                              style: AppTextStyles.metadataInk
                                                  .copyWith(
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: isSelected
                                                        ? AppColors.accentRed
                                                        : AppColors.inkMuted,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (canEditDelay || hasHookError)
                    ? AppColors.warningBg
                    : AppColors.paperBg,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: (canEditDelay || hasHookError)
                    ? null
                    : Border.all(
                        color: AppColors.paperBorder.withValues(alpha: 0.5),
                      ),
              ),
              child: Text(
                hintText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: hasHookError
                    ? AppTextStyles.warning.copyWith(color: AppColors.accentRed)
                    : ((canEditDelay &&
                            !_isReadingDelay &&
                            !_isWritingDelay)
                        ? AppTextStyles.warning
                        : AppTextStyles.metadata.copyWith(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.inkMuted,
                          )),
              ),
            ),
          ),
          const Spacer(),
          Opacity(
            opacity: canEditDelay ? 1.0 : 0.45,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: canEditDelay
                  ? null
                  : () => _notice(
                        isOfficial
                            ? l10n.settingsInputDelayOfficialNotice
                            : l10n.settingsInputDelayNotRunningNotice,
                      ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: _isReadingDelay
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(AppColors.ink),
                              ),
                            )
                          : TbIcons.settingsReadGame(
                              size: 19,
                              color: AppColors.ink,
                            ),
                      label: l10n.settingsInputDelayRead,
                      seed: 11,
                      onTap: canEditDelay &&
                              !_isReadingDelay &&
                              !_isWritingDelay
                          ? _readInputDelay
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: _isWritingDelay
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.accentRedLight,
                                ),
                              ),
                            )
                          : TbIcons.settingsWriteGame(
                              size: 19,
                              color: AppColors.accentRedLight,
                            ),
                      label: l10n.settingsInputDelayWrite,
                      seed: 22,
                      onTap: canEditDelay &&
                              !_isReadingDelay &&
                              !_isWritingDelay
                          ? _writeInputDelay
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    int seed = 0,
  }) => TornPaperButton(
    onTap: onTap,
    isSelected: selected,
    seed: seed,
    roughness: 1.25,
    borderWidth: 1.8,
    showShadow: selected,
    fillColor: selected ? AppColors.peachPaper : Colors.transparent,
    hoverFillColor: selected
        ? AppColors.peachPaperHover
        : AppColors.paperBg.withValues(alpha: 0.6),
    borderColor: selected ? AppColors.paperBorder : Colors.transparent,
    hoverBorderColor: selected
        ? AppColors.paperBorder
        : AppColors.paperBorder.withValues(alpha: 0.35),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            maxLines: 1,
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 18,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.inkMuted,
            ),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            subtitle,
            maxLines: 1,
            style: AppTextStyles.metadata.copyWith(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              color: AppColors.accentRed,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SettingsPanel extends StatelessWidget {
  final String title;
  final String? backgroundAsset;
  final Widget child;
  final Widget? trailing;
  final String? tooltip;

  const _SettingsPanel({
    super.key,
    required this.title,
    this.backgroundAsset,
    required this.child,
    this.trailing,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final panelContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: TbIcons.sectionTriangle(size: 18),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        child: Text(title, style: AppTextStyles.cardHeader),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (tooltip != null)
                    Tooltip(
                      message: tooltip!,
                      triggerMode: TooltipTriggerMode.tap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvasDarker,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(
                          color: AppColors.paperBorder,
                          width: 1,
                        ),
                      ),
                      textStyle: AppTextStyles.metadata.copyWith(
                        color: AppColors.paperBg,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: TbIcons.infoCircle(
                          size: 16,
                          color: AppColors.inkMuted,
                        ),
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
        TbIcons.roomDashedLine(height: 6),
        const SizedBox(height: 11),
        Expanded(child: child),
      ],
    );

    if (backgroundAsset != null) {
      return TbPaperImageScope(
        asset: backgroundAsset!,
        builder: (context, imageProvider) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AssetShapeShadow(imageProvider: imageProvider),
            ),
            Container(
              key: ValueKey('settings-panel-background-$title'),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.fill,
                  filterQuality:
                      WindowResizePerformanceScope.largeImageQualityOf(context),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: panelContent,
            ),
          ],
        ),
      );
    }

    return TornPaperContainer(
      key: ValueKey('settings-panel-card-$title'),
      seed: title.hashCode,
      roughness: 1.25,
      borderWidth: 1.8,
      fillColor: AppColors.paperBg,
      borderColor: AppColors.paperBorder,
      showShadow: true,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: panelContent,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final int? seed;
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.seed,
  });

  @override
  Widget build(BuildContext context) => TornPaperButton(
    onTap: onTap,
    seed: seed ?? label.hashCode,
    roughness: 1.25,
    borderWidth: 1.8,
    borderColor: AppColors.paperBorder,
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
  );
}
