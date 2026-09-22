import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class AppColors {
  // Main background (dark warm charcoal)
  static const Color canvasBg = Color(0xFFDCD2CF);
  static const Color canvasDarker = Color(0xFF221F1E);

  // Paper colors
  static const Color paperBg = Color(0xFFF7F2E8);
  static const Color paperBorder = Color(0xFF2E2927);
  static const Color paperInnerBg = Color(0xFFEBE4D6);
  static const Color paperInnerBorder = Color(0xFF332E2B);
  static const Color paperShadow = Color(0x38000000);
  static const Color paperShadowLayer = Color(0xFFE5DDD0);

  // Action button / Selected tab peach paper: rgb(236, 209, 196)
  static const Color peachPaper = Color(0xFFECD1C4);
  static const Color peachPaperHover = Color(0xFFF4DDD2);

  // Dialog paper (Category 4: matches the card image tone rgb(237, 226, 230) / #EDE2E6)
  static const Color dialogPaper = Color(0xFFEDE2E6);

  // Masking tape & ribbon
  static const Color tapeBg = Color(0xFFD6C8AF);
  static const Color tapeBorder = Color(0xFFB8A78D);
  static const Color ribbonTab = Color(0xFFD4C5AB);
  static const Color ribbonTabBorder = Color(0xFF9E8E75);

  // Ink & Text colors
  static const Color ink = Color(0xFF2B2625);
  static const Color inkMuted = Color(0xFF6B635B);
  static const Color inkLight = Color(0xFF8C8379);

  // Status & Accent colors
  static const Color accentRed = Color(0xFF8F2826);
  static const Color accentRedHover = Color(0xFFA53230);
  static const Color accentRedLight = Color(0xFFC0392B);
  static const Color warningBg = Color(0xFFF2DFC7);
  static const Color warningText = Color(0xFFB53E2B);

  // Green badges
  static const Color greenDot = Color(0xFF389E48);
  static const Color greenBadgeBg = Color(0xFFD7EED8);
  static const Color greenBadgeText = Color(0xFF267332);
  static const Color greenBadgeBorder = Color(0xFFB7DFB9);

  // Yellow latency
  static const Color latencyYellow = Color(0xFFE5B022);

  // Latency rating color tokens (优秀, 一般, 差, 严重)
  static const Color latencyExcellent = Color(0xFF267332);
  static const Color latencyExcellentBg = Color(0xFFD7EED8);
  static const Color latencyExcellentBorder = Color(0xFFB7DFB9);
  static const Color latencyExcellentStatus = Color(0xFF5CD668);

  static const Color latencyFair = Color(0xFF9A6E00);
  static const Color latencyFairBg = Color(0xFFFDF3D8);
  static const Color latencyFairBorder = Color(0xFFEEDAA2);
  static const Color latencyFairStatus = Color(0xFFE5B022);

  static const Color latencyPoor = Color(0xFFC0392B);
  static const Color latencyPoorBg = Color(0xFFFDECE6);
  static const Color latencyPoorBorder = Color(0xFFF5C6B8);
  static const Color latencyPoorStatus = Color(0xFFE67E22);

  static const Color latencySevere = Color(0xFF8F2826);
  static const Color latencySevereBg = Color(0xFFF8D7DA);
  static const Color latencySevereBorder = Color(0xFFE57373);
  static const Color latencySevereStatus = Color(0xFFFF4D4F);

  // Bottom Status Bar
  static const Color statusBarBg = Color(0xFF1F1C1B);
  static const Color statusBarBorder = Color(0xFF3D3734);
  static const Color statusIndicatorBg = Color(0xFF1B2E1F);
  static const Color statusIndicatorBorder = Color(0xFF2C5E35);
  static const Color statusRunningText = Color(0xFF5CD668);
  static const Color statusText = Color(0xFFB0A79B);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class AppRadii {
  static const double compact = 4;
  static const double control = 6;
  static const double inner = 8;
  static const double bar = 10;
  static const double card = 12;
}

class AppStrokes {
  static const double subtle = 1.2;
  static const double control = 1.5;
  static const double selected = 1.8;
  static const double card = 2;

  /// Outer ink ring shared by raster paper cards, dialogs and notifications.
  static const double paperOutline = 4;
}

class AppTextStyles {
  static const TextStyle windowTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: AppColors.ink,
  );

  static const TextStyle brandTitle = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.8,
    color: AppColors.ink,
  );

  static const TextStyle brandVersion = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.inkMuted,
  );

  static const TextStyle cardHeader = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.inkMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const TextStyle buttonTextOnAccent = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const TextStyle warning = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.warningText,
  );

  static const TextStyle controlLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.inkMuted,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.inkMuted,
  );

  static const TextStyle metadata = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.inkMuted,
  );

  static const TextStyle metadataInk = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle statusText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.statusText,
  );

  static const TextStyle statusRunning = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: AppColors.statusRunningText,
  );

  static const TextStyle statusLatency = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.latencyYellow,
  );

  static const TextStyle statusAction = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}

/// Latency rating grades specified by business requirements.
enum LatencyGrade {
  excellent('优秀'),
  fair('一般'),
  poor('差'),
  severe('严重');

  final String label;
  const LatencyGrade(this.label);

  String localizedLabel(BuildContext context) => switch (this) {
    LatencyGrade.excellent => context.l10n.latencyGradeExcellent,
    LatencyGrade.fair => context.l10n.latencyGradeFair,
    LatencyGrade.poor => context.l10n.latencyGradePoor,
    LatencyGrade.severe => context.l10n.latencyGradeSevere,
  };
}

/// Visual theme and threshold evaluator for latency values:
/// - Server Latency (底部的延迟和 Relay 服务器处的延迟):
///   0-30 为优秀，30-60 为一般，60-100 为差，100 以上为严重
/// - P2P Latency (房间队伍端到端延迟):
///   0-60 为优秀，60-100 为一般，100-150 为差，150 以上为严重
class LatencyTheme {
  final LatencyGrade grade;
  final Color textColor;
  final Color badgeBg;
  final Color badgeBorder;
  final Color statusColor;

  const LatencyTheme({
    required this.grade,
    required this.textColor,
    required this.badgeBg,
    required this.badgeBorder,
    required this.statusColor,
  });

  /// Evaluates server latency (client-to-server / relay node):
  /// 0-30 为优秀，30-60 为一般，60-100 为差，100 以上为严重
  static LatencyGrade evaluateServer(int ms) {
    if (ms <= 30) return LatencyGrade.excellent;
    if (ms <= 60) return LatencyGrade.fair;
    if (ms <= 100) return LatencyGrade.poor;
    return LatencyGrade.severe;
  }

  /// Evaluates P2P end-to-end latency between teammates in room:
  /// 0-60 为优秀，60-100 为一般，100-150 为差，150 以上为严重
  static LatencyGrade evaluateP2p(int ms) {
    if (ms <= 60) return LatencyGrade.excellent;
    if (ms <= 100) return LatencyGrade.fair;
    if (ms <= 150) return LatencyGrade.poor;
    return LatencyGrade.severe;
  }

  static LatencyTheme ofServer(int ms) => of(evaluateServer(ms));
  static LatencyTheme ofP2p(int ms) => of(evaluateP2p(ms));

  static LatencyTheme of(LatencyGrade grade) {
    switch (grade) {
      case LatencyGrade.excellent:
        return const LatencyTheme(
          grade: LatencyGrade.excellent,
          textColor: AppColors.latencyExcellent,
          badgeBg: AppColors.latencyExcellentBg,
          badgeBorder: AppColors.latencyExcellentBorder,
          statusColor: AppColors.latencyExcellentStatus,
        );
      case LatencyGrade.fair:
        return const LatencyTheme(
          grade: LatencyGrade.fair,
          textColor: AppColors.latencyFair,
          badgeBg: AppColors.latencyFairBg,
          badgeBorder: AppColors.latencyFairBorder,
          statusColor: AppColors.latencyFairStatus,
        );
      case LatencyGrade.poor:
        return const LatencyTheme(
          grade: LatencyGrade.poor,
          textColor: AppColors.latencyPoor,
          badgeBg: AppColors.latencyPoorBg,
          badgeBorder: AppColors.latencyPoorBorder,
          statusColor: AppColors.latencyPoorStatus,
        );
      case LatencyGrade.severe:
        return const LatencyTheme(
          grade: LatencyGrade.severe,
          textColor: AppColors.latencySevere,
          badgeBg: AppColors.latencySevereBg,
          badgeBorder: AppColors.latencySevereBorder,
          statusColor: AppColors.latencySevereStatus,
        );
    }
  }
}
