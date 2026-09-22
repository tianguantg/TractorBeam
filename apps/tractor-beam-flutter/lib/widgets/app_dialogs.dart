import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bridge/generated/api.dart' as bridge;
import '../l10n/bridge_message_localizer.dart';
import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import 'app_notification.dart';
import 'asset_shape_shadow.dart';
import 'custom_icons.dart';
import 'torn_paper.dart';

/// Standardized typography tokens for all dialogs to ensure visual consistency.
abstract class DialogTextStyles {
  /// Dialog header title (22px, w800)
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );

  /// Dialog body / explanatory prompt text (15px, w600, height 1.4)
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );

  /// Field labels, checkbox, and radio button text (14px, w800)
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  /// Standard input text (15px, w600)
  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// Monospace / code / number input text (15px, w700)
  static const TextStyle inputMono = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: 0.5,
  );

  /// Placeholder / hint text (14px, w600)
  static const TextStyle inputHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B635B),
  );

  /// Action button text (18px, w800)
  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );
}

Future<T?> _showAnimatedPaperDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    _PaperDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, _, _) => RepaintBoundary(
        key: const ValueKey('paper-dialog-transition-boundary'),
        child: builder(dialogContext),
      ),
      transitionBuilder: (dialogContext, animation, _, child) {
        if (MediaQuery.disableAnimationsOf(dialogContext)) return child;

        final progress = animation.value;
        if (animation.status == AnimationStatus.reverse) {
          final exitProgress = 1.0 - progress;
          final exitSlide = TweenSequence<double>([
            TweenSequenceItem(tween: ConstantTween(0.0), weight: 14),
            TweenSequenceItem(
              tween: Tween(
                begin: 0.0,
                end: 1.35,
              ).chain(CurveTween(curve: Curves.easeInCubic)),
              weight: 62,
            ),
            TweenSequenceItem(tween: ConstantTween(1.35), weight: 24),
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
            child: Transform.translate(
              offset: Offset(
                MediaQuery.sizeOf(dialogContext).width * exitSlide,
                0,
              ),
              child: Transform.scale(
                alignment: Alignment.centerLeft,
                scaleX: exitScaleX,
                child: child,
              ),
            ),
          );
        }

        final slide = TweenSequence<double>([
          TweenSequenceItem(
            // Keep the approach almost uniform: the dialog should hit the
            // centre and stop, rather than visibly easing into place.
            tween: Tween(begin: -1.35, end: 0.0),
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
          child: Transform.translate(
            offset: Offset(MediaQuery.sizeOf(dialogContext).width * slide, 0),
            child: Transform.scale(
              alignment: Alignment.centerRight,
              scaleX: squeezeX,
              scaleY: squeezeY,
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

/// Dialog transitions only transform an already isolated paper layer. Route
/// snapshotting would introduce another full-window texture and has triggered
/// a repeatable access violation in flutter_windows.dll while the snapshot is
/// released at the end of a reverse transition on Windows.
class _PaperDialogRoute<T> extends RawDialogRoute<T> {
  _PaperDialogRoute({
    required super.pageBuilder,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.transitionDuration,
    super.transitionBuilder,
  });

  @override
  bool get allowSnapshotting => false;
}

/// Reusable paper dialog shell matching Category 4 visual specifications:
/// High-irregularity torn paper container in [AppColors.dialogPaper] (#EDE2E6).
class PaperDialogShell extends StatelessWidget {
  final Widget icon;
  final String title;
  final Widget content;
  final List<Widget> actions;
  final Widget? leadingAction;
  final double maxWidth;
  final int seed;

  const PaperDialogShell({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.actions,
    this.leadingAction,
    this.maxWidth = 440,
    this.seed = 58,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: WindowResizeSnapshot(
        key: ValueKey('paper-dialog-resize-snapshot-$seed'),
        activationDelay: const Duration(milliseconds: 16),
        child: Semantics(
          namesRoute: true,
          scopesRoute: true,
          explicitChildNodes: true,
          label: title,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TornPaperContainer(
                key: ValueKey('paper-dialog-background-$seed'),
                seed: seed,
                roughness: 2.2,
                borderWidth: AppStrokes.paperOutline,
                fillColor: AppColors.dialogPaper,
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        ExcludeSemantics(child: icon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(title, style: DialogTextStyles.title),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ExcludeSemantics(child: TbIcons.roomDashedLine(height: 6)),
                    const SizedBox(height: 8),

                    // Form content (Flexible + SingleChildScrollView prevents RenderFlex overflow on small window heights)
                    Flexible(child: SingleChildScrollView(child: content)),
                    const SizedBox(height: 12),

                    // Action buttons row (all Category 1 peach buttons, with optional leadingAction at bottom-left)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (leadingAction != null) ...[
                          leadingAction!,
                          const Spacer(),
                        ],
                        for (int i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Flexible(child: actions[i]),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Category 1 Peach Paper Button for Dialog Actions.
Widget _buildDialogButton({
  required String label,
  required VoidCallback? onTap,
  Color? textColor,
  int seed = 71,
}) {
  return TornPaperButton(
    onTap: onTap,
    seed: seed,
    roughness: 1.25,
    borderWidth: 1.8,
    fillColor: AppColors.peachPaper,
    hoverFillColor: AppColors.peachPaperHover,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        style: DialogTextStyles.button.copyWith(
          color: textColor ?? AppColors.ink,
        ),
      ),
    ),
  );
}

/// Retro paper-styled text input field.
Widget _buildPaperTextField({
  required String label,
  required TextEditingController controller,
  String? hintText,
  TextInputType? keyboardType,
  bool isMono = false,
  TextCapitalization textCapitalization = TextCapitalization.none,
  List<TextInputFormatter>? inputFormatters,
  ValueChanged<String>? onSubmitted,
  ValueChanged<String>? onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: DialogTextStyles.label),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.paperBorder, width: 1.4),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          style: isMono
              ? DialogTextStyles.inputMono
              : DialogTextStyles.inputText,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            hintText: hintText,
            hintStyle: DialogTextStyles.inputHint,
            border: InputBorder.none,
          ),
        ),
      ),
    ],
  );
}

/// Retro styled checkbox for transport protocols.
Widget _buildPaperCheckbox({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Semantics(
    checked: value,
    label: label,
    child: InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: TbIcons.relayCheckbox(selected: value, size: 20),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(child: Text(label, style: DialogTextStyles.label)),
          ],
        ),
      ),
    ),
  );
}

/// Retro styled radio option for default transport.
Widget _buildPaperRadio({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: TbIcons.relayRadio(selected: selected, size: 20),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(child: Text(label, style: DialogTextStyles.label)),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 1. 添加 Relay 弹窗 (Add Relay Dialog)
// ---------------------------------------------------------------------------

class AddRelayData {
  final String name;
  final String address;
  final String port;
  final bool tcp;
  final bool udp;
  final String defaultTransport;

  const AddRelayData({
    required this.name,
    required this.address,
    required this.port,
    required this.tcp,
    required this.udp,
    required this.defaultTransport,
  });
}

Future<AddRelayData?> showAddRelayDialog(BuildContext context) {
  return _showAnimatedPaperDialog<AddRelayData>(
    context,
    builder: (context) => const _AddRelayDialogWidget(),
  );
}

class _AddRelayDialogWidget extends StatefulWidget {
  const _AddRelayDialogWidget();

  @override
  State<_AddRelayDialogWidget> createState() => _AddRelayDialogWidgetState();
}

class _AddRelayDialogWidgetState extends State<_AddRelayDialogWidget> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _portController = TextEditingController(text: '25910');
  bool _tcp = true;
  bool _udp = true;
  String _defaultTransport = 'UDP';
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    var address = _addressController.text.trim();
    var port = _portController.text.trim();

    // 智能清洗可能误粘的协议前缀 (http://, https://, tcp://, udp://, ws://, wss://)
    final protocolRegex = RegExp(
      r'^(https?|tcps?|udps?|wss?)://',
      caseSensitive: false,
    );
    if (protocolRegex.hasMatch(address)) {
      address = address.replaceFirst(protocolRegex, '').trim();
      _addressController.text = address;
    }
    while (address.endsWith('/')) {
      address = address.substring(0, address.length - 1).trim();
      _addressController.text = address;
    }

    // 智能解析用户粘贴 host:port 的情况（支持带端口的方括号 IPv6 和单冒号 IPv4/域名，保护裸 IPv6）
    if (address.startsWith('[') && address.contains(']:')) {
      final closeIdx = address.indexOf(']:');
      final hostPart = address.substring(1, closeIdx).trim();
      final portPart = address.substring(closeIdx + 2).trim();
      if (hostPart.isNotEmpty && int.tryParse(portPart) != null) {
        address = hostPart;
        port = portPart;
        _addressController.text = address;
        _portController.text = port;
      }
    } else if (address.startsWith('[') && address.endsWith(']')) {
      address = address.substring(1, address.length - 1).trim();
      _addressController.text = address;
    } else if (address.contains(':') &&
        address.indexOf(':') == address.lastIndexOf(':')) {
      final colonIdx = address.indexOf(':');
      final hostPart = address.substring(0, colonIdx).trim();
      final portPart = address.substring(colonIdx + 1).trim();
      if (hostPart.isNotEmpty && int.tryParse(portPart) != null) {
        address = hostPart;
        port = portPart;
        _addressController.text = address;
        _portController.text = port;
      }
    }

    final l10n = context.l10n;
    if (name.isEmpty) {
      setState(() => _errorMessage = l10n.errRelayNameRequired);
      return;
    }
    if (address.isEmpty) {
      setState(() => _errorMessage = l10n.errRelayHostRequired);
      return;
    }

    final portNum = int.tryParse(port.isEmpty ? '25910' : port);
    if (portNum == null || portNum < 1 || portNum > 65535) {
      setState(() => _errorMessage = l10n.errRelayPortRange);
      return;
    }

    if (!_tcp && !_udp) {
      setState(() => _errorMessage = l10n.errRelayProtocolRequired);
      return;
    }

    Navigator.pop(
      context,
      AddRelayData(
        name: name,
        address: address,
        port: '$portNum',
        tcp: _tcp,
        udp: _udp,
        defaultTransport: _defaultTransport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PaperDialogShell(
      seed: 62,
      maxWidth: 420,
      icon: TbIcons.add(size: 20, color: AppColors.accentRed),
      title: l10n.dialogAddRelayTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPaperTextField(
            label: l10n.dialogRelayNameLabel,
            controller: _nameController,
            hintText: l10n.dialogRelayNameHint,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            onSubmitted: (_) => _onSave(),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _buildPaperTextField(
                  label: l10n.dialogRelayHostLabel,
                  controller: _addressController,
                  hintText: l10n.dialogRelayHostHint,
                  isMono: true,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  onSubmitted: (_) => _onSave(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildPaperTextField(
                  label: l10n.dialogRelayPortLabel,
                  controller: _portController,
                  hintText: '25910',
                  keyboardType: TextInputType.number,
                  isMono: true,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  onSubmitted: (_) => _onSave(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 支持的传输 (TCP / UDP checkboxes)
          Text(l10n.dialogRelayTransportLabel, style: DialogTextStyles.label),
          const SizedBox(height: 3),
          Row(
            children: [
              _buildPaperCheckbox(
                label: 'TCP',
                value: _tcp,
                onChanged: (val) => setState(() {
                  _tcp = val;
                  if (!_tcp && !_udp) {
                    _udp = true;
                  }
                  if (!_tcp && _defaultTransport == 'TCP') {
                    _defaultTransport = 'UDP';
                  }
                  if (_errorMessage != null) {
                    _errorMessage = null;
                  }
                }),
              ),
              const SizedBox(width: 20),
              _buildPaperCheckbox(
                label: 'UDP',
                value: _udp,
                onChanged: (val) => setState(() {
                  _udp = val;
                  if (!_tcp && !_udp) {
                    _tcp = true;
                  }
                  if (!_udp && _defaultTransport == 'UDP') {
                    _defaultTransport = 'TCP';
                  }
                  if (_errorMessage != null) {
                    _errorMessage = null;
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 默认传输 (TCP / UDP radio)
          Text(
            l10n.dialogRelayDefaultTransportLabel,
            style: DialogTextStyles.label,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              _buildPaperRadio(
                label: 'TCP',
                selected: _defaultTransport == 'TCP',
                onTap: () => setState(() {
                  _tcp = true;
                  _defaultTransport = 'TCP';
                }),
              ),
              const SizedBox(width: 20),
              _buildPaperRadio(
                label: 'UDP',
                selected: _defaultTransport == 'UDP',
                onTap: () => setState(() {
                  _udp = true;
                  _defaultTransport = 'UDP';
                }),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.accentRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  TbIcons.noticeAlert(size: 16, color: AppColors.accentRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: DialogTextStyles.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        _buildDialogButton(
          label: l10n.dialogCancel,
          seed: 41,
          onTap: () => Navigator.pop(context),
        ),
        _buildDialogButton(label: l10n.dialogSave, seed: 52, onTap: _onSave),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. 编辑 Relay 弹窗 (Edit Relay Dialog)
// ---------------------------------------------------------------------------

enum EditRelayAction { save, delete }

class EditRelayResult {
  final EditRelayAction action;
  final AddRelayData? data;

  const EditRelayResult.save(this.data) : action = EditRelayAction.save;
  const EditRelayResult.delete() : action = EditRelayAction.delete, data = null;
}

Future<EditRelayResult?> showEditRelayDialog(
  BuildContext context, {
  required String initialName,
  required String initialAddress,
  String initialPort = '25910',
  bool initialTcp = true,
  bool initialUdp = true,
  String initialDefaultTransport = 'UDP',
}) {
  return _showAnimatedPaperDialog<EditRelayResult>(
    context,
    builder: (context) => _EditRelayDialogWidget(
      initialName: initialName,
      initialAddress: initialAddress,
      initialPort: initialPort,
      initialTcp: initialTcp,
      initialUdp: initialUdp,
      initialDefaultTransport: initialDefaultTransport,
    ),
  );
}

class _EditRelayDialogWidget extends StatefulWidget {
  final String initialName;
  final String initialAddress;
  final String initialPort;
  final bool initialTcp;
  final bool initialUdp;
  final String initialDefaultTransport;

  const _EditRelayDialogWidget({
    required this.initialName,
    required this.initialAddress,
    required this.initialPort,
    required this.initialTcp,
    required this.initialUdp,
    required this.initialDefaultTransport,
  });

  @override
  State<_EditRelayDialogWidget> createState() => _EditRelayDialogWidgetState();
}

class _EditRelayDialogWidgetState extends State<_EditRelayDialogWidget> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _portController;
  late bool _tcp;
  late bool _udp;
  late String _defaultTransport;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _addressController = TextEditingController(text: widget.initialAddress);
    _portController = TextEditingController(text: widget.initialPort);
    _tcp = widget.initialTcp;
    _udp = widget.initialUdp;
    _defaultTransport =
        (widget.initialDefaultTransport == 'TCP' ||
            widget.initialDefaultTransport == 'UDP')
        ? widget.initialDefaultTransport
        : 'UDP';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    var address = _addressController.text.trim();
    var port = _portController.text.trim();

    // 智能清洗可能误粘的协议前缀 (http://, https://, tcp://, udp://, ws://, wss://)
    final protocolRegex = RegExp(
      r'^(https?|tcps?|udps?|wss?)://',
      caseSensitive: false,
    );
    if (protocolRegex.hasMatch(address)) {
      address = address.replaceFirst(protocolRegex, '').trim();
      _addressController.text = address;
    }
    while (address.endsWith('/')) {
      address = address.substring(0, address.length - 1).trim();
      _addressController.text = address;
    }

    // 智能解析用户粘贴 host:port 的情况（支持带端口的方括号 IPv6 和单冒号 IPv4/域名，保护裸 IPv6）
    if (address.startsWith('[') && address.contains(']:')) {
      final closeIdx = address.indexOf(']:');
      final hostPart = address.substring(1, closeIdx).trim();
      final portPart = address.substring(closeIdx + 2).trim();
      if (hostPart.isNotEmpty && int.tryParse(portPart) != null) {
        address = hostPart;
        port = portPart;
        _addressController.text = address;
        _portController.text = port;
      }
    } else if (address.startsWith('[') && address.endsWith(']')) {
      address = address.substring(1, address.length - 1).trim();
      _addressController.text = address;
    } else if (address.contains(':') &&
        address.indexOf(':') == address.lastIndexOf(':')) {
      final colonIdx = address.indexOf(':');
      final hostPart = address.substring(0, colonIdx).trim();
      final portPart = address.substring(colonIdx + 1).trim();
      if (hostPart.isNotEmpty && int.tryParse(portPart) != null) {
        address = hostPart;
        port = portPart;
        _addressController.text = address;
        _portController.text = port;
      }
    }

    final l10n = context.l10n;
    if (name.isEmpty) {
      setState(() => _errorMessage = l10n.errRelayNameRequired);
      return;
    }
    if (address.isEmpty) {
      setState(() => _errorMessage = l10n.errRelayHostRequired);
      return;
    }

    final portNum = int.tryParse(port.isEmpty ? '25910' : port);
    if (portNum == null || portNum < 1 || portNum > 65535) {
      setState(() => _errorMessage = l10n.errRelayPortRange);
      return;
    }

    if (!_tcp && !_udp) {
      setState(() => _errorMessage = l10n.errRelayProtocolRequired);
      return;
    }

    Navigator.pop(
      context,
      EditRelayResult.save(
        AddRelayData(
          name: name,
          address: address,
          port: '$portNum',
          tcp: _tcp,
          udp: _udp,
          defaultTransport: _defaultTransport,
        ),
      ),
    );
  }

  Future<void> _onDelete() async {
    final confirmed = await showDeleteRelayConfirmDialog(
      context,
      relayName: widget.initialName,
    );
    if (!confirmed || !mounted) return;
    Navigator.pop(context, const EditRelayResult.delete());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PaperDialogShell(
      seed: 83,
      maxWidth: 440,
      icon: TbIcons.edit(size: 20),
      title: l10n.dialogEditRelayTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPaperTextField(
            label: l10n.dialogRelayNameLabel,
            controller: _nameController,
            hintText: l10n.dialogRelayNameHint,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            onSubmitted: (_) => _onSave(),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _buildPaperTextField(
                  label: l10n.dialogRelayHostLabel,
                  controller: _addressController,
                  hintText: l10n.dialogRelayHostHint,
                  isMono: true,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  onSubmitted: (_) => _onSave(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildPaperTextField(
                  label: l10n.dialogRelayPortLabel,
                  controller: _portController,
                  hintText: '25910',
                  keyboardType: TextInputType.number,
                  isMono: true,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  onSubmitted: (_) => _onSave(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 支持的传输 (TCP / UDP checkboxes)
          Text(l10n.dialogRelayTransportLabel, style: DialogTextStyles.label),
          const SizedBox(height: 3),
          Row(
            children: [
              _buildPaperCheckbox(
                label: 'TCP',
                value: _tcp,
                onChanged: (val) => setState(() {
                  _tcp = val;
                  if (!_tcp && !_udp) {
                    _udp = true;
                  }
                  if (!_tcp && _defaultTransport == 'TCP') {
                    _defaultTransport = 'UDP';
                  }
                  if (_errorMessage != null) {
                    _errorMessage = null;
                  }
                }),
              ),
              const SizedBox(width: 20),
              _buildPaperCheckbox(
                label: 'UDP',
                value: _udp,
                onChanged: (val) => setState(() {
                  _udp = val;
                  if (!_tcp && !_udp) {
                    _tcp = true;
                  }
                  if (!_udp && _defaultTransport == 'UDP') {
                    _defaultTransport = 'TCP';
                  }
                  if (_errorMessage != null) {
                    _errorMessage = null;
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 默认传输 (TCP / UDP radio)
          Text(
            l10n.dialogRelayDefaultTransportLabel,
            style: DialogTextStyles.label,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              _buildPaperRadio(
                label: 'TCP',
                selected: _defaultTransport == 'TCP',
                onTap: () => setState(() {
                  _tcp = true;
                  _defaultTransport = 'TCP';
                }),
              ),
              const SizedBox(width: 20),
              _buildPaperRadio(
                label: 'UDP',
                selected: _defaultTransport == 'UDP',
                onTap: () => setState(() {
                  _udp = true;
                  _defaultTransport = 'UDP';
                }),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.accentRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  TbIcons.noticeAlert(size: 16, color: AppColors.accentRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: DialogTextStyles.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        _buildDialogButton(
          label: l10n.dialogDelete,
          seed: 19,
          textColor: AppColors.accentRed,
          onTap: _onDelete,
        ),
        _buildDialogButton(
          label: l10n.dialogCancel,
          seed: 38,
          onTap: () => Navigator.pop(context),
        ),
        _buildDialogButton(label: l10n.dialogSave, seed: 57, onTap: _onSave),
      ],
    );
  }
}

Widget _wrapWithConfirmShortcuts({
  required BuildContext dialogContext,
  required Widget child,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  return Focus(
    autofocus: true,
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          onConfirm();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (onCancel != null) {
            onCancel();
          } else {
            Navigator.pop(dialogContext, false);
          }
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    },
    child: child,
  );
}

Future<bool> showDeleteRelayConfirmDialog(
  BuildContext context, {
  required String relayName,
}) async {
  final l10n = context.l10n;
  return await _showAnimatedPaperDialog<bool>(
        context,
        builder: (dialogContext) => _wrapWithConfirmShortcuts(
          dialogContext: dialogContext,
          onConfirm: () => Navigator.pop(dialogContext, true),
          child: PaperDialogShell(
            seed: 49,
            maxWidth: 400,
            icon: TbIcons.noticeAlert(size: 20, color: AppColors.accentRed),
            title: l10n.dialogRelayDeleteConfirmTitle,
            content: Text(
              l10n.dialogRelayDeletePrompt(relayName),
              style: DialogTextStyles.body,
            ),
            actions: [
              _buildDialogButton(
                label: l10n.dialogCancel,
                seed: 50,
                onTap: () => Navigator.pop(dialogContext, false),
              ),
              _buildDialogButton(
                label: l10n.dialogConfirmDelete,
                seed: 51,
                textColor: AppColors.accentRed,
                onTap: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<bool> showClearLogsConfirmDialog(BuildContext context) async {
  final l10n = context.l10n;
  return await _showAnimatedPaperDialog<bool>(
        context,
        builder: (dialogContext) => _wrapWithConfirmShortcuts(
          dialogContext: dialogContext,
          onConfirm: () => Navigator.pop(dialogContext, true),
          child: PaperDialogShell(
            seed: 99,
            maxWidth: 400,
            icon: TbIcons.noticeAlert(size: 20, color: AppColors.accentRed),
            title: l10n.dialogClearLogsTitle,
            content: Text(
              l10n.dialogClearLogsPromptDetailed,
              style: DialogTextStyles.body,
            ),
            actions: [
              _buildDialogButton(
                label: l10n.dialogCancel,
                seed: 100,
                onTap: () => Navigator.pop(dialogContext, false),
              ),
              _buildDialogButton(
                label: l10n.dialogClearLogsConfirm,
                seed: 101,
                textColor: AppColors.accentRed,
                onTap: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

enum CloseApplicationChoice { exit, hideToTray }

Future<CloseApplicationChoice?> showCloseApplicationDialog(
  BuildContext context, {
  bool isInRoom = false,
  bool isSessionRunning = false,
  bool hasTray = true,
}) {
  final l10n = context.l10n;
  final String title;
  final Widget contentWidget;
  final bool hasWarning = isSessionRunning || isInRoom;

  if (!hasTray) {
    title = l10n.dialogExitAppTitle;
    final String warningText;
    if (isSessionRunning) {
      warningText = l10n.dialogExitSessionRunningWarning;
    } else if (isInRoom) {
      warningText = l10n.dialogExitRoomWarning;
    } else {
      warningText = l10n.dialogExitPrompt;
    }
    contentWidget = Text(
      warningText,
      style: DialogTextStyles.body.copyWith(
        fontWeight: hasWarning ? FontWeight.w700 : FontWeight.w500,
        color: hasWarning ? AppColors.accentRed : null,
      ),
    );
  } else {
    title = l10n.dialogCloseAppTitle;
    final String promptText;
    if (isSessionRunning) {
      promptText = l10n.dialogCloseAppSessionWarning;
    } else if (isInRoom) {
      promptText = l10n.dialogCloseAppRoomWarning;
    } else {
      promptText = l10n.dialogCloseAppPrompt;
    }
    contentWidget = Text(
      promptText,
      style: DialogTextStyles.body.copyWith(
        fontWeight: FontWeight.w700,
        color: hasWarning ? AppColors.accentRed : null,
      ),
    );
  }

  return _showAnimatedPaperDialog<CloseApplicationChoice>(
    context,
    barrierDismissible: true,
    builder: (dialogContext) => PaperDialogShell(
      seed: 118,
      maxWidth: 460,
      icon: TbIcons.noticeAlert(size: 22, color: AppColors.accentRed),
      title: title,
      content: contentWidget,
      actions: [
        if (!hasTray) ...[
          _buildDialogButton(
            label: l10n.dialogCancel,
            seed: 119,
            onTap: () => Navigator.pop(dialogContext, null),
          ),
          _buildDialogButton(
            label: l10n.dialogExitButton,
            seed: 120,
            textColor: hasWarning ? AppColors.accentRed : null,
            onTap: () =>
                Navigator.pop(dialogContext, CloseApplicationChoice.exit),
          ),
        ] else ...[
          _buildDialogButton(
            label: l10n.dialogCancel,
            seed: 118,
            onTap: () => Navigator.pop(dialogContext, null),
          ),
          _buildDialogButton(
            label: l10n.dialogCloseAppHideToTray,
            seed: 119,
            onTap: () =>
                Navigator.pop(dialogContext, CloseApplicationChoice.hideToTray),
          ),
          _buildDialogButton(
            label: l10n.dialogCloseAppFullExit,
            seed: 120,
            textColor: hasWarning ? AppColors.accentRed : null,
            onTap: () =>
                Navigator.pop(dialogContext, CloseApplicationChoice.exit),
          ),
        ],
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// 3. 输入联机码加入弹窗 (Join Room by Code Dialog)
// ---------------------------------------------------------------------------

Future<String?> showJoinRoomDialog(BuildContext context) {
  return _showAnimatedPaperDialog<String>(
    context,
    builder: (context) => const _JoinRoomDialogWidget(),
  );
}

enum UdpFallbackChoice { retryTcp, openSettings, cancel }

Future<UdpFallbackChoice> showUdpFallbackDialog(BuildContext context) async {
  final l10n = context.l10n;
  return await _showAnimatedPaperDialog<UdpFallbackChoice>(
        context,
        builder: (dialogContext) => PaperDialogShell(
          seed: 93,
          maxWidth: 480,
          icon: TbIcons.relayNodes(size: 24, color: AppColors.accentRed),
          title: l10n.dialogUdpFallbackTitle,
          content: Text(
            l10n.dialogUdpFallbackBody,
            style: DialogTextStyles.body,
          ),
          actions: [
            _buildDialogButton(
              label: l10n.dialogCancel,
              seed: 91,
              onTap: () =>
                  Navigator.pop(dialogContext, UdpFallbackChoice.cancel),
            ),
            _buildDialogButton(
              label: l10n.dialogUdpFallbackSettings,
              seed: 92,
              onTap: () =>
                  Navigator.pop(dialogContext, UdpFallbackChoice.openSettings),
            ),
            _buildDialogButton(
              label: l10n.dialogUdpFallbackRetry,
              seed: 93,
              textColor: AppColors.accentRed,
              onTap: () =>
                  Navigator.pop(dialogContext, UdpFallbackChoice.retryTcp),
            ),
          ],
        ),
      ) ??
      UdpFallbackChoice.cancel;
}

Future<bool> showReplaceRoomByCodeDialog(
  BuildContext context,
  String joinCode,
) async {
  final l10n = context.l10n;
  return await _showAnimatedPaperDialog<bool>(
        context,
        builder: (dialogContext) => _wrapWithConfirmShortcuts(
          dialogContext: dialogContext,
          onConfirm: () => Navigator.pop(dialogContext, true),
          child: PaperDialogShell(
            seed: 88,
            maxWidth: 420,
            icon: TbIcons.joinRoom(size: 24, color: AppColors.accentRed),
            title: l10n.dialogReplaceRoomTitle,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  joinCode,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.mono.copyWith(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.dialogReplaceRoomPrompt,
                  textAlign: TextAlign.center,
                  style: DialogTextStyles.body,
                ),
              ],
            ),
            actions: [
              _buildDialogButton(
                label: l10n.dialogCancel,
                seed: 85,
                onTap: () => Navigator.pop(dialogContext, false),
              ),
              _buildDialogButton(
                label: l10n.dialogReplaceRoomExitAndJoin,
                seed: 88,
                textColor: AppColors.accentRed,
                onTap: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<bool> showSwitchHistoryRoomDialog(BuildContext context) async {
  final l10n = context.l10n;
  return await _showAnimatedPaperDialog<bool>(
        context,
        builder: (dialogContext) => _wrapWithConfirmShortcuts(
          dialogContext: dialogContext,
          onConfirm: () => Navigator.pop(dialogContext, true),
          child: PaperDialogShell(
            seed: 86,
            maxWidth: 460,
            icon: TbIcons.roomHistory(size: 24, color: AppColors.accentRed),
            title: l10n.dialogSwitchHistoryTitle,
            content: Text(
              l10n.dialogSwitchHistoryPrompt,
              style: DialogTextStyles.body,
            ),
            actions: [
              _buildDialogButton(
                label: l10n.dialogCancel,
                seed: 85,
                onTap: () => Navigator.pop(dialogContext, false),
              ),
              _buildDialogButton(
                label: l10n.dialogSwitchRoomConfirm,
                seed: 86,
                textColor: AppColors.accentRed,
                onTap: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<bool> showSwitchSteamAccountInRoomDialog(
  BuildContext context, {
  required bool isLan,
}) async {
  final l10n = context.l10n;
  return await _showAnimatedPaperDialog<bool>(
        context,
        builder: (dialogContext) => _wrapWithConfirmShortcuts(
          dialogContext: dialogContext,
          onConfirm: () => Navigator.pop(dialogContext, true),
          child: PaperDialogShell(
            seed: 87,
            maxWidth: 460,
            icon: TbIcons.switchDirection(size: 22, color: AppColors.accentRed),
            title: l10n.dialogSwitchSteamInRoomTitle,
            content: Text(
              isLan
                  ? l10n.dialogSwitchSteamLanPrompt
                  : l10n.dialogSwitchSteamRelayPrompt,
              style: DialogTextStyles.body,
            ),
            actions: [
              _buildDialogButton(
                label: l10n.dialogCancel,
                seed: 85,
                onTap: () => Navigator.pop(dialogContext, false),
              ),
              _buildDialogButton(
                label: l10n.dialogSwitchSteamConfirm,
                seed: 87,
                textColor: AppColors.accentRed,
                onTap: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<bool> showLeaveRoomInGameDialog(BuildContext context) async {
  final l10n = context.l10n;
  return await _showAnimatedPaperDialog<bool>(
        context,
        builder: (dialogContext) => _wrapWithConfirmShortcuts(
          dialogContext: dialogContext,
          onConfirm: () => Navigator.pop(dialogContext, true),
          child: PaperDialogShell(
            seed: 92,
            maxWidth: 460,
            icon: TbIcons.leaveRoom(size: 22, color: AppColors.accentRed),
            title: l10n.dialogLeaveRoomInGameTitle,
            content: Text(
              l10n.dialogLeaveRoomInGameWarning,
              style: DialogTextStyles.body.copyWith(
                color: AppColors.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              _buildDialogButton(
                label: l10n.dialogCancel,
                seed: 85,
                onTap: () => Navigator.pop(dialogContext, false),
              ),
              _buildDialogButton(
                label: l10n.confirmLeave,
                seed: 87,
                textColor: AppColors.accentRed,
                onTap: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

class _JoinRoomDialogWidget extends StatefulWidget {
  const _JoinRoomDialogWidget();

  @override
  State<_JoinRoomDialogWidget> createState() => _JoinRoomDialogWidgetState();
}

class _JoinRoomDialogWidgetState extends State<_JoinRoomDialogWidget> {
  final _codeController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onJoin() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = context.l10n.dialogJoinRoomHint;
      });
      return;
    }
    Navigator.pop(context, code.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PaperDialogShell(
      seed: 94,
      maxWidth: 380,
      icon: TbIcons.joinRoom(size: 20, color: AppColors.accentRedLight),
      title: l10n.dialogJoinRoomTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.dialogJoinRoomByCodePrompt, style: DialogTextStyles.body),
          const SizedBox(height: 10),
          _buildPaperTextField(
            label: l10n.dialogJoinRoomCodeLabel,
            controller: _codeController,
            isMono: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            onSubmitted: (_) => _onJoin(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.accentRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  TbIcons.noticeAlert(size: 16, color: AppColors.accentRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: DialogTextStyles.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        _buildDialogButton(
          label: l10n.dialogCancel,
          seed: 27,
          onTap: () => Navigator.pop(context),
        ),
        _buildDialogButton(
          label: l10n.dialogJoinRoomConfirm,
          seed: 49,
          onTap: _onJoin,
        ),
      ],
    );
  }
}

Future<String?> showLanEndpointSelectionDialog(
  BuildContext context,
  List<String> endpoints,
) {
  if (endpoints.isEmpty) return Future.value(null);
  final l10n = context.l10n;
  var selected = endpoints.first;
  return _showAnimatedPaperDialog<String>(
    context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => PaperDialogShell(
        seed: 103,
        maxWidth: 520,
        icon: TbIcons.lanRadar(size: 24, color: AppColors.accentRed),
        title: l10n.dialogLanEndpointTitle,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dialogLanEndpointPrompt, style: DialogTextStyles.body),
            const SizedBox(height: 10),
            for (final endpoint in endpoints) ...[
              InkWell(
                onTap: () => setDialogState(() => selected = endpoint),
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected == endpoint
                        ? AppColors.peachPaper
                        : Colors.white.withValues(alpha: 0.48),
                    border: Border.all(
                      color: AppColors.paperBorder,
                      width: 1.4,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      TbIcons.relayRadio(
                        selected: selected == endpoint,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          endpoint,
                          style: DialogTextStyles.inputMono,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
        actions: [
          _buildDialogButton(
            label: l10n.dialogCancel,
            seed: 104,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
          _buildDialogButton(
            label: l10n.dialogLanEndpointConnect,
            seed: 105,
            textColor: AppColors.accentRed,
            onTap: () => Navigator.of(dialogContext).pop(selected),
          ),
        ],
      ),
    ),
  );
}

class LanAdapterInfo {
  final String name;
  final String addresses;
  final String? id;
  final bool recommended;

  const LanAdapterInfo(
    this.name,
    this.addresses, [
    this.id,
    this.recommended = false,
  ]);
}

const _lanAdapters = <LanAdapterInfo>[
  LanAdapterInfo('Radmin VPN', '10.44.24.119 · fdfd:1a2c:1877 · fe80:819a:ba'),
  LanAdapterInfo('Ethernet 2', '192.168.0.104 · fe80:4840:10ff:1260:e91'),
  LanAdapterInfo('Ethernet 6', '169.254.134.167 · fe80:624e:ca74:c13b:8594'),
  LanAdapterInfo(
    'Local Area Connection* 1',
    '169.254.12.12 · fe80:f8c7:8f4:5ca8:cfa7',
  ),
  LanAdapterInfo(
    'Bluetooth Network Connection',
    '169.254.163.235 · fe80:bbaa:1cda:8285:e277',
  ),
  LanAdapterInfo(
    'Local Area Connection* 10',
    '169.254.123.33 · fe80:a098:56c3:c141:11b1',
  ),
  LanAdapterInfo('Teredo Tunneling Pseudo-Interface', '2001:0:c612:4:ce4:3f5:'),
  LanAdapterInfo('WLAN', '169.254.13.147 · fe80:4ff9:124c:7ff2:2ff1'),
  LanAdapterInfo('VMware Network Adapter VMnet1', '192.168.42.1 · fe80:42'),
  LanAdapterInfo('VMware Network Adapter VMnet8', '192.168.158.1 · fe80::c'),
  LanAdapterInfo(
    'vEthernet (Default Switch)',
    '172.25.80.1 · fe80:2930:492b:d',
  ),
];

Future<List<LanAdapterInfo>?> showCreateLanRoomDialog(
  BuildContext context, {
  List<LanAdapterInfo>? adapters,
}) {
  final available = adapters ?? _lanAdapters;
  return _showAnimatedPaperDialog<List<LanAdapterInfo>>(
    context,
    builder: (dialogContext) => _CreateLanRoomDialogWidget(
      available: available,
      usePrototypeDefaults: adapters == null,
    ),
  );
}

/// Builds the real LAN creation surface for the offscreen startup raster pass.
/// It is deliberately detached from navigation and business state.
Widget buildLanDialogWarmupScene() => _CreateLanRoomDialogWidget(
  available: _lanAdapters,
  usePrototypeDefaults: true,
);

class _CreateLanRoomDialogWidget extends StatefulWidget {
  final List<LanAdapterInfo> available;
  final bool usePrototypeDefaults;

  const _CreateLanRoomDialogWidget({
    required this.available,
    required this.usePrototypeDefaults,
  });

  @override
  State<_CreateLanRoomDialogWidget> createState() =>
      _CreateLanRoomDialogWidgetState();
}

class _CreateLanRoomDialogWidgetState
    extends State<_CreateLanRoomDialogWidget> {
  static const double _adapterExtent = 55;
  static const double _maxAdapterListHeight = 360;

  final _scrollController = ScrollController();
  late final List<ValueNotifier<bool>> _selection;
  late final ValueNotifier<int> _selectedCount;

  @override
  void initState() {
    super.initState();
    _selection = List<ValueNotifier<bool>>.generate(widget.available.length, (
      index,
    ) {
      final selected =
          index < 8 &&
          (widget.usePrototypeDefaults
              ? index < 7
              : widget.available[index].recommended);
      return ValueNotifier<bool>(selected);
    });
    if (_selection.isNotEmpty && !_selection.any((value) => value.value)) {
      _selection.first.value = true;
    }
    _selectedCount = ValueNotifier<int>(
      _selection.where((value) => value.value).length,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final selection in _selection) {
      selection.dispose();
    }
    _selectedCount.dispose();
    super.dispose();
  }

  void _setSelected(int index, bool selected) {
    final notifier = _selection[index];
    if (notifier.value == selected) return;
    if (selected && _selectedCount.value >= 8) {
      AppNotification.show(
        context,
        context.l10n.errTooManyLanAdapters,
        type: NotificationType.warning,
      );
      return;
    }
    notifier.value = selected;
    _selectedCount.value += selected ? 1 : -1;
  }

  List<LanAdapterInfo> _selectedAdapters() => [
    for (var index = 0; index < widget.available.length; index++)
      if (_selection[index].value) widget.available[index],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listHeight = math.min(
      _maxAdapterListHeight,
      widget.available.length * _adapterExtent,
    );

    return PaperDialogShell(
      key: const ValueKey('create-lan-room-dialog'),
      maxWidth: 660,
      seed: 96,
      icon: TbIcons.lanRadar(size: 24, color: AppColors.accentRed),
      title: l10n.dialogCreateLanTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.dialogLanAdaptersPrompt, style: DialogTextStyles.body),
          const SizedBox(height: 8),
          if (widget.available.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  l10n.dialogLanNoAdapters,
                  style: DialogTextStyles.body,
                ),
              ),
            )
          else
            SizedBox(
              height: listHeight,
              child: RepaintBoundary(
                key: const ValueKey('lan-adapter-list-boundary'),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: listHeight >= _maxAdapterListHeight,
                  child: ListView.separated(
                    controller: _scrollController,
                    key: const ValueKey('lan-adapter-list'),
                    primary: false,
                    cacheExtent: 0,
                    padding: EdgeInsets.zero,
                    itemCount: widget.available.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 5),
                    itemBuilder: (context, index) => RepaintBoundary(
                      key: ValueKey('lan-adapter-boundary-$index'),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _selection[index],
                        builder: (context, selected, _) => _LanAdapterTile(
                          key: ValueKey('lan-adapter-$index'),
                          adapter: widget.available[index],
                          selected: selected,
                          onChanged: (value) => _setSelected(index, value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      leadingAction: RepaintBoundary(
        child: ValueListenableBuilder<int>(
          valueListenable: _selectedCount,
          builder: (context, count, _) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              l10n.dialogLanSelectedCount(count),
              key: const ValueKey('lan-adapter-selection-count'),
              style: DialogTextStyles.label.copyWith(
                color: count == 8 ? AppColors.accentRed : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
      actions: [
        _buildDialogButton(
          label: l10n.dialogCancel,
          seed: 97,
          onTap: () => Navigator.of(context).pop(),
        ),
        RepaintBoundary(
          child: ValueListenableBuilder<int>(
            valueListenable: _selectedCount,
            builder: (context, count, _) => Opacity(
              opacity: count == 0 ? 0.5 : 1,
              child: _buildDialogButton(
                label: l10n.dialogCreateButton,
                seed: 98,
                textColor: AppColors.accentRed,
                onTap: count == 0
                    ? null
                    : () => Navigator.of(context).pop(_selectedAdapters()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanAdapterTile extends StatelessWidget {
  final LanAdapterInfo adapter;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _LanAdapterTile({
    super.key,
    required this.adapter,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    label: '${adapter.name}, ${adapter.addresses}',
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(!selected),
      hoverColor: AppColors.peachPaperHover.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: AppColors.paperBorder.withValues(alpha: 0.35),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: TbIcons.relayCheckbox(selected: selected, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(adapter.name, style: DialogTextStyles.label),
                  const SizedBox(height: 1),
                  Text(
                    adapter.addresses,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DialogTextStyles.inputMono.copyWith(
                      fontSize: 12.5,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 4. 手动填写 Steam 账号弹窗 (Manual Steam Account Dialog)
// ---------------------------------------------------------------------------

class SteamAccountData {
  final String username;
  final String steamId64;

  const SteamAccountData({required this.username, required this.steamId64});
}

Future<bool> showDeleteSteamAccountConfirmDialog(
  BuildContext context, {
  required String username,
  required String steamId64,
}) async {
  final l10n = context.l10n;
  return await _showAnimatedPaperDialog<bool>(
        context,
        builder: (dialogContext) => _wrapWithConfirmShortcuts(
          dialogContext: dialogContext,
          onConfirm: () => Navigator.pop(dialogContext, true),
          child: PaperDialogShell(
            seed: 52,
            maxWidth: 400,
            icon: TbIcons.noticeAlert(size: 20, color: AppColors.accentRed),
            title: l10n.dialogDeleteSteamAccountTitle,
            content: Text(
              l10n.dialogDeleteSteamAccountPrompt(username, steamId64),
              style: DialogTextStyles.body,
            ),
            actions: [
              _buildDialogButton(
                label: l10n.dialogCancel,
                seed: 53,
                onTap: () => Navigator.pop(dialogContext, false),
              ),
              _buildDialogButton(
                label: l10n.dialogConfirmDelete,
                seed: 54,
                textColor: AppColors.accentRed,
                onTap: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<SteamAccountData?> showManualSteamAccountDialog(
  BuildContext context, {
  required String initialUsername,
  required String initialSteamId64,
  List<SteamAccountData>? manualAccounts,
  ValueChanged<String>? onDeleteManualAccount,
}) {
  return _showAnimatedPaperDialog<SteamAccountData>(
    context,
    builder: (context) => _ManualSteamAccountDialogWidget(
      initialUsername: initialUsername,
      initialSteamId64: initialSteamId64,
      manualAccounts: manualAccounts,
      onDeleteManualAccount: onDeleteManualAccount,
    ),
  );
}

class _ManualSteamAccountDialogWidget extends StatefulWidget {
  final String initialUsername;
  final String initialSteamId64;
  final List<SteamAccountData>? manualAccounts;
  final ValueChanged<String>? onDeleteManualAccount;

  const _ManualSteamAccountDialogWidget({
    required this.initialUsername,
    required this.initialSteamId64,
    this.manualAccounts,
    this.onDeleteManualAccount,
  });

  @override
  State<_ManualSteamAccountDialogWidget> createState() =>
      _ManualSteamAccountDialogWidgetState();
}

class _ManualSteamAccountDialogWidgetState
    extends State<_ManualSteamAccountDialogWidget> {
  final _accountsScrollController = ScrollController();
  late final TextEditingController _usernameController;
  late final TextEditingController _id64Controller;
  late List<SteamAccountData> _manualAccounts;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _id64Controller = TextEditingController(text: widget.initialSteamId64);
    _manualAccounts = List.of(widget.manualAccounts ?? const []);
  }

  @override
  void dispose() {
    _accountsScrollController.dispose();
    _usernameController.dispose();
    _id64Controller.dispose();
    super.dispose();
  }

  void _onSave() {
    final l10n = context.l10n;
    final username = _usernameController.text.trim();
    final id64 = _id64Controller.text.trim();

    if (id64.isEmpty) {
      setState(() => _errorMessage = l10n.errSteamIdRequired);
      return;
    }
    if (id64.length != 17 ||
        BigInt.tryParse(id64) == null ||
        BigInt.parse(id64) == BigInt.zero) {
      setState(() => _errorMessage = l10n.errSteamIdInvalid);
      return;
    }
    if (username.isEmpty) {
      setState(() => _errorMessage = l10n.errSteamUsernameRequired);
      return;
    }

    Navigator.pop(
      context,
      SteamAccountData(username: username, steamId64: id64),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PaperDialogShell(
      seed: 73,
      maxWidth: 420,
      icon: TbIcons.edit(size: 20, color: AppColors.accentRed),
      title: l10n.dialogManualSteamTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_manualAccounts.isNotEmpty) ...[
            Text(
              l10n.dialogManualSteamSavedAccounts,
              style: DialogTextStyles.label.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.paperBorder, width: 1.4),
              ),
              child: Scrollbar(
                controller: _accountsScrollController,
                thumbVisibility: _manualAccounts.length > 2,
                child: ListView.separated(
                  controller: _accountsScrollController,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _manualAccounts.length,
                  separatorBuilder: (context, index) => Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: AppColors.paperBorder.withValues(alpha: 0.25),
                  ),
                  itemBuilder: (context, index) {
                    final acc = _manualAccounts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              key: ValueKey(
                                'select-manual-account-${acc.steamId64}',
                              ),
                              borderRadius: BorderRadius.circular(4),
                              hoverColor: AppColors.peachPaperHover.withValues(
                                alpha: 0.5,
                              ),
                              onTap: () {
                                setState(() {
                                  _usernameController.text = acc.username;
                                  _id64Controller.text = acc.steamId64;
                                  _errorMessage = null;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.username,
                                      style: DialogTextStyles.inputText
                                          .copyWith(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'ID64: ${acc.steamId64}',
                                      style: DialogTextStyles.inputMono
                                          .copyWith(
                                            fontSize: 12.5,
                                            color: AppColors.inkMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            key: ValueKey(
                              'delete-manual-account-${acc.steamId64}',
                            ),
                            borderRadius: BorderRadius.circular(4),
                            onTap: () async {
                              final confirmed =
                                  await showDeleteSteamAccountConfirmDialog(
                                    context,
                                    username: acc.username,
                                    steamId64: acc.steamId64,
                                  );
                              if (!confirmed || !mounted) return;
                              widget.onDeleteManualAccount?.call(acc.steamId64);
                              setState(() {
                                _manualAccounts.removeAt(index);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: TbIcons.clearLogs(
                                size: 16,
                                color: AppColors.accentRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildPaperTextField(
            label: l10n.dialogManualSteamIdLabel,
            controller: _id64Controller,
            hintText: l10n.dialogManualSteamIdInputHint,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(17),
            ],
            isMono: true,
            onSubmitted: (_) => _onSave(),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
          ),
          const SizedBox(height: 8),
          _buildPaperTextField(
            label: l10n.dialogManualSteamNameLabel,
            controller: _usernameController,
            hintText: l10n.dialogManualSteamNameInputHint,
            onSubmitted: (_) => _onSave(),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.accentRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  TbIcons.noticeAlert(size: 16, color: AppColors.accentRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: DialogTextStyles.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        _buildDialogButton(
          label: l10n.dialogCancel,
          seed: 64,
          onTap: () => Navigator.pop(context),
        ),
        _buildDialogButton(label: l10n.dialogSave, seed: 85, onTap: _onSave),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. 启动游戏确认弹窗 (Launch Game Confirmation Dialog)
// ---------------------------------------------------------------------------

Future<void> showLaunchGameDialog(
  BuildContext context, {
  TractorBeamController? controller,
  VoidCallback? onOpenLogs,
}) {
  return _showAnimatedPaperDialog<void>(
    context,
    barrierDismissible: false,
    builder: (context) =>
        _LaunchProgressDialog(controller: controller, onOpenLogs: onOpenLogs),
  );
}

class _LaunchProgressDialog extends StatefulWidget {
  const _LaunchProgressDialog({this.controller, this.onOpenLogs});

  final TractorBeamController? controller;
  final VoidCallback? onOpenLogs;

  @override
  State<_LaunchProgressDialog> createState() => _LaunchProgressDialogState();
}

class _LaunchProgressDialogState extends State<_LaunchProgressDialog> {
  bool _autoDismissScheduled = false;
  String? _cancelError;
  bool _forceCloseAvailable = false;
  Timer? _cancellingTimeoutTimer;

  @override
  void dispose() {
    _cancellingTimeoutTimer?.cancel();
    super.dispose();
  }

  void _requestCancel() {
    final app = widget.controller;
    if (app == null) return;
    final receipt = app.cancelLaunch();
    if (!mounted) return;
    setState(() {
      _cancelError = receipt.accepted
          ? null
          : (localizeBridgeMessage(context, receipt.rejection?.displayText) ??
                context.l10n.dialogLaunchCancelFailed);
    });
    if (receipt.accepted &&
        !_forceCloseAvailable &&
        _cancellingTimeoutTimer == null) {
      _cancellingTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _forceCloseAvailable = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.controller;
    if (app != null) {
      return AnimatedBuilder(
        animation: app,
        builder: (context, _) => _buildDialog(context, app.launchProgress),
      );
    }
    return _buildDialog(
      context,
      TractorBeamScope.maybeOf(context)?.snapshot?.launch,
    );
  }

  String _resolveLaunchProgressText(
    BuildContext context,
    bridge.LaunchProgressDto? launch,
    bridge.LaunchStatusDto current,
  ) {
    final l10n = context.l10n;
    final rawText = launch?.displayText.trim();
    if (rawText != null && rawText.isNotEmpty) {
      final localized = localizeBridgeMessage(context, rawText);
      if (localized != null && localized.isNotEmpty) {
        return localized;
      }
    }
    return _statusFallback(l10n, current);
  }

  String _statusFallback(AppLocalizations l10n, bridge.LaunchStatusDto current) {
    return switch (current) {
      bridge.LaunchStatusDto.starting => l10n.dialogLaunchStepStarting,
      bridge.LaunchStatusDto.waitingForGame =>
        l10n.dialogLaunchStepWaitingForGame,
      bridge.LaunchStatusDto.injecting => l10n.dialogLaunchStepInjecting,
      bridge.LaunchStatusDto.waitingForHook =>
        l10n.dialogLaunchStepWaitingForHook,
      bridge.LaunchStatusDto.ready => l10n.dialogLaunchStepReady,
      bridge.LaunchStatusDto.cancelling => l10n.dialogLaunchCancelling,
      bridge.LaunchStatusDto.cancelled => l10n.dialogLaunchCancelled,
      bridge.LaunchStatusDto.failed => l10n.dialogLaunchFailedGeneric,
      _ => l10n.dialogLaunchPreparing,
    };
  }

  Widget _buildDialog(BuildContext context, bridge.LaunchProgressDto? launch) {
    final l10n = context.l10n;
    final terminal = launch?.terminal ?? false;
    final current = launch?.status ?? bridge.LaunchStatusDto.starting;
    final cancelled = current == bridge.LaunchStatusDto.cancelled;
    final failed = terminal && launch?.success != true && !cancelled;

    if (current == bridge.LaunchStatusDto.cancelling &&
        !_forceCloseAvailable &&
        _cancellingTimeoutTimer == null) {
      _cancellingTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _forceCloseAvailable = true;
          });
        }
      });
    } else if (current != bridge.LaunchStatusDto.cancelling &&
        _cancellingTimeoutTimer != null) {
      _cancellingTimeoutTimer?.cancel();
      _cancellingTimeoutTimer = null;
    }

    if ((current == bridge.LaunchStatusDto.ready && launch?.success == true) ||
        cancelled) {
      if (!_autoDismissScheduled) {
        _autoDismissScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    }
    if (failed) {
      final rawError = launch?.errorText?.trim();
      final errorDetail = rawError != null && rawError.isNotEmpty
          ? (localizeBridgeMessage(context, rawError) ?? rawError)
          : null;
      final hasError = errorDetail != null && errorDetail.isNotEmpty;
      return PopScope(
        canPop: true,
        child: PaperDialogShell(
          seed: 59,
          maxWidth: 470,
          icon: TbIcons.noticeAlert(size: 23, color: AppColors.accentRed),
          title: l10n.dialogLaunchFailureTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizeBridgeMessage(context, launch?.displayText) ??
                    l10n.dialogLaunchFailedGeneric,
                style: DialogTextStyles.body.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.accentRed.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: TbIcons.noticeAlert(
                          size: 16,
                          color: AppColors.accentRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          errorDetail,
                          style: DialogTextStyles.body.copyWith(
                            fontSize: 13,
                            color: AppColors.accentRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (widget.onOpenLogs != null)
              _buildDialogButton(
                label: l10n.dialogLaunchGoToLogs,
                seed: 42,
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenLogs?.call();
                },
              ),
            _buildDialogButton(
              label: l10n.dialogClose,
              seed: 71,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    final steps = <(bridge.LaunchStatusDto, String)>[
      (bridge.LaunchStatusDto.starting, l10n.dialogLaunchStepStarting),
      (
        bridge.LaunchStatusDto.waitingForGame,
        l10n.dialogLaunchStepWaitingForGame,
      ),
      (bridge.LaunchStatusDto.injecting, l10n.dialogLaunchStepInjecting),
      (
        bridge.LaunchStatusDto.waitingForHook,
        l10n.dialogLaunchStepWaitingForHook,
      ),
      (bridge.LaunchStatusDto.ready, l10n.dialogLaunchStepReady),
    ];
    final currentIndex = steps.indexWhere((step) => step.$1 == current);

    final canPopNow =
        terminal ||
        (current == bridge.LaunchStatusDto.cancelling && _forceCloseAvailable);

    return PopScope(
      canPop: canPopNow,
      child: PaperDialogShell(
        seed: 58,
        maxWidth: 470,
        icon: TbIcons.gamepad(size: 22, color: AppColors.accentRed),
        title: switch (current) {
          bridge.LaunchStatusDto.cancelling => l10n.dialogLaunchCancelling,
          bridge.LaunchStatusDto.cancelled => l10n.dialogLaunchCancelled,
          _ when terminal =>
            launch?.success == true
                ? l10n.dialogLaunchSuccess
                : l10n.dialogLaunchFailureTitle,
          _ => l10n.dialogLaunchProgressTitle,
        },
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < steps.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Semantics(
                  label:
                      (index < currentIndex ||
                          current == bridge.LaunchStatusDto.ready)
                      ? '${l10n.dialogLaunchStepCompleted}: ${steps[index].$2}'
                      : (index == currentIndex
                            ? '${l10n.dialogLaunchStepInProgress}: ${steps[index].$2}'
                            : '${l10n.dialogLaunchStepPending}: ${steps[index].$2}'),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: TbIcons.relayCheckbox(
                          selected:
                              index < currentIndex ||
                              current == bridge.LaunchStatusDto.ready,
                          size: 18,
                          color: index <= currentIndex
                              ? AppColors.accentRed
                              : AppColors.inkLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(steps[index].$2, style: DialogTextStyles.body),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              _resolveLaunchProgressText(context, launch, current),
              style: DialogTextStyles.body.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (launch?.errorText case final errorText?
                when errorText.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                localizeBridgeMessage(context, errorText) ?? errorText,
                style: DialogTextStyles.body.copyWith(
                  color: AppColors.accentRed,
                ),
              ),
            ],
            if (_cancelError != null) ...[
              const SizedBox(height: 8),
              Text(
                _cancelError!,
                style: DialogTextStyles.body.copyWith(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        actions: terminal
            ? [
                if (launch?.success != true && widget.onOpenLogs != null)
                  _buildDialogButton(
                    label: l10n.dialogLaunchGoToLogs,
                    seed: 42,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onOpenLogs?.call();
                    },
                  ),
                _buildDialogButton(
                  label: l10n.dialogClose,
                  seed: 71,
                  onTap: () => Navigator.pop(context),
                ),
              ]
            : (current == bridge.LaunchStatusDto.cancelling &&
                  _forceCloseAvailable)
            ? [
                _buildDialogButton(
                  label: l10n.dialogClose,
                  seed: 71,
                  onTap: () => Navigator.pop(context),
                ),
              ]
            : [
                _buildDialogButton(
                  label: current == bridge.LaunchStatusDto.cancelling
                      ? l10n.dialogLaunchCancellingButton
                      : l10n.dialogLaunchCancelButton,
                  seed: 70,
                  textColor: current == bridge.LaunchStatusDto.cancelling
                      ? AppColors.inkLight
                      : AppColors.accentRed,
                  onTap:
                      current == bridge.LaunchStatusDto.cancelling ||
                          widget.controller == null
                      ? null
                      : _requestCancel,
                ),
              ],
      ),
    );
  }
}
