import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'asset_shape_shadow.dart';
import 'custom_icons.dart';
import 'paper_image.dart';
import 'torn_paper.dart';

class SidebarItemData {
  final Widget Function(bool isSelected, bool isHovered) iconBuilder;

  SidebarItemData({required this.iconBuilder});
}

class PaperSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onToggleLocale;

  const PaperSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onToggleLocale,
  });

  @override
  State<PaperSidebar> createState() => _PaperSidebarState();
}

class _PaperSidebarState extends State<PaperSidebar> {
  final List<SidebarItemData> _items = [
    SidebarItemData(
      iconBuilder: (isSelected, isHovered) => TbIcons.homeNetwork(
        size: 26,
        color: isSelected ? AppColors.accentRed : AppColors.inkMuted,
      ),
    ),
    SidebarItemData(
      iconBuilder: (isSelected, isHovered) => TbIcons.roomBars(
        size: 24,
        color: isSelected ? AppColors.accentRed : AppColors.inkMuted,
      ),
    ),
    SidebarItemData(
      iconBuilder: (isSelected, isHovered) => TbIcons.settingsSliders(
        size: 24,
        color: isSelected ? AppColors.accentRed : AppColors.inkMuted,
      ),
    ),
    SidebarItemData(
      iconBuilder: (isSelected, isHovered) => TbIcons.statsChart(
        size: 24,
        color: isSelected ? AppColors.accentRed : AppColors.inkMuted,
      ),
    ),
    SidebarItemData(
      iconBuilder: (isSelected, isHovered) => TbIcons.logsTerminal(
        size: 24,
        color: isSelected ? AppColors.accentRed : AppColors.inkMuted,
      ),
    ),
    SidebarItemData(
      iconBuilder: (isSelected, isHovered) => TbIcons.infoCircle(
        size: 22,
        color: isSelected ? AppColors.accentRed : AppColors.inkMuted,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = <String>[
      l10n.navHome,
      l10n.navRoom,
      l10n.navSettings,
      l10n.navStatistics,
      l10n.navLogs,
      l10n.navAbout,
    ];
    return TbPaperImageScope(
      asset: 'assets/images/paper/sidebar_card.webp',
      logicalWidth: 84,
      logicalHeight: 760,
      builder: (context, sidebarProvider) => SizedBox(
        width: 84,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 18,
              child: AssetShapeShadow(imageProvider: sidebarProvider),
            ),
            Positioned.fill(
              top: 18,
              child: Image(
                image: sidebarProvider,
                key: const ValueKey('sidebar-card-image'),
                fit: BoxFit.fill,
                filterQuality: WindowResizePerformanceScope.largeImageQualityOf(
                  context,
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: TbPaperImageScope(
                asset: 'assets/images/paper/sidebar_pin.webp',
                logicalWidth: 32,
                logicalHeight: 32,
                builder: (context, pinProvider) => Image(
                  image: pinProvider,
                  key: const ValueKey('sidebar-pin-image'),
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),

            // Navigation content remains independent from both visual assets.
            Container(
              key: const ValueKey('sidebar-paper-surface'),
              padding: const EdgeInsets.only(
                top: 14,
                left: 3,
                right: 3,
                bottom: 3,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),

                  // Navigation Items
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(_items.length, (index) {
                          final item = _items[index];
                          final isSelected = widget.selectedIndex == index;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 6,
                            ),
                            child: TornPaperButton(
                              onTap: () => widget.onItemSelected(index),
                              isSelected: isSelected,
                              seed: index + 5,
                              roughness: 1.25,
                              fillColor: isSelected
                                  ? AppColors.peachPaper
                                  : Colors.transparent,
                              hoverFillColor: isSelected
                                  ? AppColors.peachPaperHover
                                  : AppColors.paperBg.withValues(alpha: 0.6),
                              borderColor: isSelected
                                  ? AppColors.paperBorder
                                  : Colors.transparent,
                              hoverBorderColor: isSelected
                                  ? AppColors.paperBorder
                                  : AppColors.paperBorder.withValues(
                                      alpha: 0.35,
                                    ),
                              borderWidth: 2.0,
                              showShadow: isSelected,
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: SizedBox(
                                width: 52,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    item.iconBuilder(isSelected, false),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        titles[index],
                                        maxLines: 1,
                                        softWrap: false,
                                        style: AppTextStyles.navLabel.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.ink
                                              : AppColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Language toggle button: "中/EN" in black button style
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TornPaperButton(
                      onTap: widget.onToggleLocale,
                      seed: 9,
                      roughness: 1.25,
                      borderWidth: 1.8,
                      fillColor: AppColors.canvasDarker,
                      hoverFillColor: const Color(0xFF383331),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Tooltip(
                        message: l10n.switchToEnglish,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TbIcons.language(
                                  key: const ValueKey('sidebar-language-icon'),
                                  size: 22,
                                  color: AppColors.paperBg,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '中/EN',
                                  style: AppTextStyles.buttonTextOnAccent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
