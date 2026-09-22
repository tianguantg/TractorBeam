import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Generates an organic, cartoon-style torn paper path with rich edge jitters,
/// pronounced paper-fiber roughness, and distinct micro-tears/notches.
/// When roughness > 1.4, generates deeply irregular, ragged torn paper edges.
Path buildTornPaperPath(
  Size size, {
  double radius = 5.0,
  int seed = 0,
  double roughness = 1.0,
}) {
  final w = size.width;
  final h = size.height;
  if (w <= 0 || h <= 0) return Path();

  final r = radius.clamp(2.0, (h / 3).clamp(2.0, 7.0));

  double rand(int step) {
    final x = (seed * 1103515245 + step * 12345 + 54321) & 0x7fffffff;
    return (x % 1000) / 1000.0;
  }

  final path = Path();
  path.moveTo(r, 0.5);

  if (roughness <= 1.4) {
    // --- STANDARD MILD ROUGHNESS (used by small buttons, tabs, tags) ---
    final topSteps = ((w - 2 * r) / 9).clamp(6, 28).toInt();
    final tear1Idx = (topSteps * 0.32).toInt().clamp(1, topSteps - 2);
    final tear2Idx = (topSteps * 0.72).toInt().clamp(
      tear1Idx + 2,
      topSteps - 1,
    );

    for (int i = 1; i <= topSteps; i++) {
      final t = i / (topSteps + 1);
      final x = r + t * (w - 2 * r);
      final fiber = (rand(i) - 0.5) * 2.4 * roughness;

      if (i == tear1Idx) {
        path.lineTo(x - 3.5, fiber);
        path.lineTo(x - 0.5, fiber + 3.8 * roughness);
        path.lineTo(x + 2.5, fiber + 1.2 * roughness);
      } else if (i == tear2Idx) {
        path.lineTo(x - 2.5, fiber - 0.8 * roughness);
        path.lineTo(x, fiber - 2.8 * roughness);
        path.lineTo(x + 2.5, fiber + 0.4 * roughness);
      } else {
        path.lineTo(x, fiber);
      }
    }

    path.lineTo(w - r, 0.5);
    path.quadraticBezierTo(w - 0.5, 0.8, w - 0.5, r * 0.7);

    final rightSteps = ((h - 2 * r) / 7).clamp(3, 10).toInt();
    final tearRightIdx = (rightSteps * 0.5).toInt().clamp(1, rightSteps - 1);

    for (int i = 1; i <= rightSteps; i++) {
      final t = i / (rightSteps + 1);
      final y = r + t * (h - 2 * r);
      final fiber = (rand(i + 50) - 0.5) * 2.2 * roughness;

      if (i == tearRightIdx) {
        path.lineTo(w + fiber - 3.2 * roughness, y - 1.5);
        path.lineTo(w + fiber, y + 2.0);
      } else {
        path.lineTo(w + fiber, y);
      }
    }

    path.lineTo(w - 0.5, h - r * 0.7);
    path.quadraticBezierTo(w - 0.8, h - 0.5, w - r, h - 0.5);

    final bottomSteps = topSteps;
    final tear3Idx = (bottomSteps * 0.36).toInt().clamp(1, bottomSteps - 2);
    final tear4Idx = (bottomSteps * 0.78).toInt().clamp(
      tear3Idx + 2,
      bottomSteps - 1,
    );

    for (int i = 1; i <= bottomSteps; i++) {
      final t = i / (bottomSteps + 1);
      final x = (w - r) - t * (w - 2 * r);
      final fiber = (rand(i + 100) - 0.5) * 2.4 * roughness;

      if (i == tear3Idx) {
        path.lineTo(x + 3.5, h + fiber);
        path.lineTo(x + 0.5, h + fiber - 4.2 * roughness);
        path.lineTo(x - 2.5, h + fiber - 1.0 * roughness);
      } else if (i == tear4Idx) {
        path.lineTo(x + 2.5, h + fiber + 1.0 * roughness);
        path.lineTo(x - 0.5, h + fiber + 2.8 * roughness);
        path.lineTo(x - 2.5, h + fiber);
      } else {
        path.lineTo(x, h + fiber);
      }
    }

    path.lineTo(r, h - 0.5);
    path.quadraticBezierTo(0.8, h - 0.8, 0.5, h - r * 0.7);

    final leftSteps = rightSteps;
    final tearLeftIdx = (leftSteps * 0.5).toInt().clamp(1, leftSteps - 1);

    for (int i = 1; i <= leftSteps; i++) {
      final t = i / (leftSteps + 1);
      final y = (h - r) - t * (h - 2 * r);
      final fiber = (rand(i + 160) - 0.5) * 2.2 * roughness;

      if (i == tearLeftIdx) {
        path.lineTo(fiber + 3.2 * roughness, y + 1.5);
        path.lineTo(fiber, y - 2.0);
      } else {
        path.lineTo(fiber, y);
      }
    }

    path.lineTo(0.5, r * 0.7);
    path.quadraticBezierTo(0.8, 0.8, r, 0.5);
    path.close();
    return path;
  }

  // --- HIGH IRREGULARITY ORGANIC TORN EDGES (for prominent irregular dialogs/containers) ---
  final topSteps = ((w - 2 * r) / 8).clamp(8, 48).toInt();
  final t1 = (topSteps * 0.22).toInt().clamp(1, topSteps - 5);
  final t2 = (topSteps * 0.38).toInt().clamp(t1 + 2, topSteps - 4);
  final t3 = (topSteps * 0.55).toInt().clamp(t2 + 2, topSteps - 3);
  final t4 = (topSteps * 0.70).toInt().clamp(t3 + 2, topSteps - 2);
  final t5 = (topSteps * 0.84).toInt().clamp(t4 + 2, topSteps - 1);

  for (int i = 1; i <= topSteps; i++) {
    final t = i / (topSteps + 1);
    final x = r + t * (w - 2 * r);
    final fiber = (rand(i) - 0.5) * 3.0 * roughness;
    final wave = math.sin(t * math.pi * 3 + (seed % 7)) * 1.3 * roughness;
    final y = fiber + wave;

    if (i == t1) {
      path.lineTo(x - 3.5, y);
      path.lineTo(x, y + 4.5 * roughness);
      path.lineTo(x + 3.5, y + 1.2 * roughness);
    } else if (i == t2) {
      path.lineTo(x - 2.5, y);
      path.lineTo(x, y - 3.2 * roughness);
      path.lineTo(x + 2.5, y);
    } else if (i == t3) {
      path.lineTo(x - 4.0, y);
      path.lineTo(x - 0.5, y + 5.5 * roughness);
      path.lineTo(x + 3.0, y + 2.0 * roughness);
    } else if (i == t4) {
      path.lineTo(x - 3.0, y);
      path.lineTo(x + 0.5, y - 3.8 * roughness);
      path.lineTo(x + 2.5, y);
    } else if (i == t5) {
      path.lineTo(x - 2.5, y);
      path.lineTo(x + 0.5, y + 4.0 * roughness);
      path.lineTo(x + 3.0, y);
    } else {
      path.lineTo(x, y);
    }
  }

  // Top-right corner
  path.lineTo(w - r, 0.5 + (rand(90) - 0.5) * 2.0 * roughness);
  path.quadraticBezierTo(
    w - 0.5,
    0.8,
    w - 0.5 + (rand(91) - 0.5) * 1.5 * roughness,
    r * 0.7,
  );

  // Right edge
  final rightSteps = ((h - 2 * r) / 8).clamp(4, 24).toInt();
  final tr1 = (rightSteps * 0.35).toInt().clamp(1, rightSteps - 2);
  final tr2 = (rightSteps * 0.72).toInt().clamp(tr1 + 2, rightSteps - 1);

  for (int i = 1; i <= rightSteps; i++) {
    final t = i / (rightSteps + 1);
    final y = r + t * (h - 2 * r);
    final fiber = (rand(i + 50) - 0.5) * 2.8 * roughness;
    final wave = math.sin(t * math.pi * 2 + (seed % 5)) * 1.2 * roughness;
    final x = w + fiber + wave;

    if (i == tr1) {
      path.lineTo(x, y - 3.0);
      path.lineTo(x - 4.5 * roughness, y);
      path.lineTo(x, y + 3.0);
    } else if (i == tr2) {
      path.lineTo(x, y - 2.5);
      path.lineTo(x + 3.2 * roughness, y);
      path.lineTo(x, y + 2.5);
    } else {
      path.lineTo(x, y);
    }
  }

  // Bottom-right corner
  path.lineTo(w - 0.5 + (rand(92) - 0.5) * 1.5 * roughness, h - r * 0.7);
  path.quadraticBezierTo(
    w - 0.8,
    h - 0.5,
    w - r,
    h - 0.5 + (rand(93) - 0.5) * 2.0 * roughness,
  );

  // Bottom edge
  final bottomSteps = topSteps;
  final b1 = (bottomSteps * 0.25).toInt().clamp(1, bottomSteps - 5);
  final b2 = (bottomSteps * 0.42).toInt().clamp(b1 + 2, bottomSteps - 4);
  final b3 = (bottomSteps * 0.60).toInt().clamp(b2 + 2, bottomSteps - 3);
  final b4 = (bottomSteps * 0.75).toInt().clamp(b3 + 2, bottomSteps - 2);
  final b5 = (bottomSteps * 0.88).toInt().clamp(b4 + 2, bottomSteps - 1);

  for (int i = 1; i <= bottomSteps; i++) {
    final t = i / (bottomSteps + 1);
    final x = (w - r) - t * (w - 2 * r);
    final fiber = (rand(i + 100) - 0.5) * 3.0 * roughness;
    final wave = math.sin(t * math.pi * 3 + (seed % 9)) * 1.3 * roughness;
    final y = h + fiber + wave;

    if (i == b1) {
      path.lineTo(x + 3.5, y);
      path.lineTo(x, y - 5.0 * roughness);
      path.lineTo(x - 3.5, y - 1.5 * roughness);
    } else if (i == b2) {
      path.lineTo(x + 2.5, y);
      path.lineTo(x, y + 3.5 * roughness);
      path.lineTo(x - 2.5, y);
    } else if (i == b3) {
      path.lineTo(x + 4.0, y);
      path.lineTo(x + 0.5, y - 5.8 * roughness);
      path.lineTo(x - 3.0, y - 2.0 * roughness);
    } else if (i == b4) {
      path.lineTo(x + 2.5, y);
      path.lineTo(x, y + 3.2 * roughness);
      path.lineTo(x - 2.5, y);
    } else if (i == b5) {
      path.lineTo(x + 3.0, y);
      path.lineTo(x - 0.5, y - 4.2 * roughness);
      path.lineTo(x - 2.5, y);
    } else {
      path.lineTo(x, y);
    }
  }

  // Bottom-left corner
  path.lineTo(r, h - 0.5 + (rand(94) - 0.5) * 2.0 * roughness);
  path.quadraticBezierTo(
    0.8,
    h - 0.8,
    0.5 + (rand(95) - 0.5) * 1.5 * roughness,
    h - r * 0.7,
  );

  // Left edge
  final leftSteps = rightSteps;
  final tl1 = (leftSteps * 0.38).toInt().clamp(1, leftSteps - 2);
  final tl2 = (leftSteps * 0.75).toInt().clamp(tl1 + 2, leftSteps - 1);

  for (int i = 1; i <= leftSteps; i++) {
    final t = i / (leftSteps + 1);
    final y = (h - r) - t * (h - 2 * r);
    final fiber = (rand(i + 160) - 0.5) * 2.8 * roughness;
    final wave = math.sin(t * math.pi * 2 + (seed % 6)) * 1.2 * roughness;
    final x = fiber + wave;

    if (i == tl1) {
      path.lineTo(x, y + 3.0);
      path.lineTo(x + 4.5 * roughness, y);
      path.lineTo(x, y - 3.0);
    } else if (i == tl2) {
      path.lineTo(x, y + 2.5);
      path.lineTo(x - 3.2 * roughness, y);
      path.lineTo(x, y - 2.5);
    } else {
      path.lineTo(x, y);
    }
  }

  // Top-left corner to close
  path.lineTo(0.5 + (rand(96) - 0.5) * 1.5 * roughness, r * 0.7);
  path.quadraticBezierTo(0.8, 0.8, r, 0.5 + (rand(97) - 0.5) * 2.0 * roughness);
  path.close();

  return path;
}

class TornPaperPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
  final int seed;
  final double roughness;
  final bool showShadow;
  final Color shadowColor;
  final Offset shadowOffset;

  TornPaperPainter({
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 1.8,
    this.cornerRadius = 5.0,
    this.seed = 0,
    this.roughness = 1.0,
    this.showShadow = true,
    this.shadowColor = const Color(0x28000000),
    this.shadowOffset = const Offset(1.5, 2.0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final path = buildTornPaperPath(
      size,
      radius: cornerRadius,
      seed: seed,
      roughness: roughness,
    );

    // 1. Draw paper drop shadow if enabled
    if (showShadow && shadowColor.a > 0) {
      final shadowPath = path.shift(shadowOffset);
      final shadowPaint = Paint()
        ..color = shadowColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // 2. Draw paper fill
    if (fillColor.a > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    // 3. Draw ink border with hand-drawn cap and join
    if (borderWidth > 0 && borderColor.a > 0) {
      final strokePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TornPaperPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.seed != seed ||
        oldDelegate.roughness != roughness ||
        oldDelegate.showShadow != showShadow ||
        oldDelegate.shadowColor != shadowColor;
  }
}

/// Clipper that conforms to the torn-paper path.
class TornPaperClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final int seed;
  final double roughness;

  const TornPaperClipper({
    this.cornerRadius = 5.0,
    this.seed = 0,
    this.roughness = 1.0,
  });

  @override
  Path getClip(Size size) => buildTornPaperPath(
    size,
    radius: cornerRadius,
    seed: seed,
    roughness: roughness,
  );

  @override
  bool shouldReclip(covariant TornPaperClipper oldClipper) =>
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.seed != seed ||
      oldClipper.roughness != roughness;
}

/// A container widget that renders with organic cartoon torn-paper edges.
class TornPaperContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
  final int seed;
  final double roughness;
  final bool showShadow;
  final Color shadowColor;
  final Offset shadowOffset;
  final bool clipChild;

  const TornPaperContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.fillColor = AppColors.paperBg,
    this.borderColor = AppColors.paperBorder,
    this.borderWidth = 1.8,
    this.cornerRadius = 5.0,
    this.seed = 0,
    this.roughness = 1.0,
    this.showShadow = true,
    this.shadowColor = const Color(0x28000000),
    this.shadowOffset = const Offset(1.5, 2.0),
    this.clipChild = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);
    if (clipChild) {
      content = ClipPath(
        clipper: TornPaperClipper(
          cornerRadius: cornerRadius,
          seed: seed,
          roughness: roughness,
        ),
        child: content,
      );
    }
    return CustomPaint(
      painter: TornPaperPainter(
        fillColor: fillColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        cornerRadius: cornerRadius,
        seed: seed,
        roughness: roughness,
        showShadow: showShadow,
        shadowColor: shadowColor,
        shadowOffset: shadowOffset,
      ),
      child: content,
    );
  }
}

/// An interactive button styled as a cartoon torn-paper slip with hover/press feedback.
class TornPaperButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color fillColor;
  final Color hoverFillColor;
  final Color borderColor;
  final Color hoverBorderColor;
  final double borderWidth;
  final double cornerRadius;
  final int seed;
  final double roughness;
  final bool showShadow;
  final bool isSelected;
  final Color? selectedFillColor;
  final Color? selectedBorderColor;
  final double? selectedBorderWidth;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  const TornPaperButton({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.fillColor = AppColors.paperBg,
    this.hoverFillColor = Colors.white,
    this.borderColor = AppColors.paperBorder,
    this.hoverBorderColor = AppColors.paperBorder,
    this.borderWidth = 1.8,
    this.cornerRadius = 5.0,
    this.seed = 0,
    this.roughness = 1.0,
    this.showShadow = true,
    this.isSelected = false,
    this.selectedFillColor,
    this.selectedBorderColor,
    this.selectedBorderWidth,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<TornPaperButton> createState() => _TornPaperButtonState();
}

class _TornPaperButtonState extends State<TornPaperButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveFill = widget.isSelected
        ? (widget.selectedFillColor ?? widget.fillColor)
        : (_isPressed
              ? widget.fillColor.withValues(alpha: 0.85)
              : (_isHovered ? widget.hoverFillColor : widget.fillColor));

    final effectiveBorder = _isFocused
        ? AppColors.accentRed
        : (widget.isSelected
            ? (widget.selectedBorderColor ?? widget.borderColor)
            : (_isHovered ? widget.hoverBorderColor : widget.borderColor));

    final effectiveBorderWidth = _isFocused
        ? widget.borderWidth + 1.0
        : (widget.isSelected
            ? (widget.selectedBorderWidth ?? widget.borderWidth + 0.4)
            : widget.borderWidth);

    final shadowOffset = _isPressed
        ? const Offset(0.6, 1.0)
        : (_isHovered ? const Offset(2.0, 3.0) : const Offset(1.5, 2.0));

    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      selected: widget.isSelected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (val) => setState(() => _isFocused = val),
        onShowHoverHighlight: (val) => setState(() => _isHovered = val),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap?.call(),
          ),
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: MouseRegion(
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() {
            _isHovered = false;
            _isPressed = false;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(
                0,
                _isPressed ? 1.0 : (_isHovered ? -1.0 : 0.0),
                0,
              ),
              child: CustomPaint(
                painter: TornPaperPainter(
                  fillColor: effectiveFill,
                  borderColor: effectiveBorder,
                  borderWidth: effectiveBorderWidth,
                  cornerRadius: widget.cornerRadius,
                  seed: widget.seed,
                  roughness: widget.roughness,
                  showShadow: widget.showShadow,
                  shadowColor: Colors.black.withValues(
                    alpha: _isHovered ? 0.22 : 0.14,
                  ),
                  shadowOffset: shadowOffset,
                ),
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
