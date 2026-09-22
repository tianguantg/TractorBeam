import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'custom_icons.dart';
import 'torn_paper.dart';

class PaperDropdownItem<T> {
  final T value;
  final String label;
  final String? detail;
  final Widget? trailing;

  const PaperDropdownItem({
    required this.value,
    required this.label,
    this.detail,
    this.trailing,
  });
}

/// Theme-aligned dropdown anchored to an existing hand-drawn trigger button,
/// wrapped in a torn-paper container with organic edges and ink stroke.
class PaperDropdown<T> extends StatelessWidget {
  final T? selectedValue;
  final List<PaperDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget Function(VoidCallback openMenu) triggerBuilder;
  final double menuWidth;
  final int seed;
  final double roughness;
  final bool enabled;

  const PaperDropdown({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    required this.triggerBuilder,
    this.menuWidth = 270,
    this.seed = 73,
    this.roughness = 1.25,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || items.isEmpty) {
      return triggerBuilder(() {});
    }
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide.none),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        TornPaperContainer(
          seed: seed,
          roughness: roughness,
          borderWidth: 1.8,
          showShadow: true,
          shadowOffset: const Offset(2.0, 3.5),
          shadowColor: const Color(0x3D000000),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          fillColor: AppColors.paperBg,
          borderColor: AppColors.paperBorder,
          clipChild: true,
          child: SizedBox(
            width: menuWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items.map((item) {
                final selected = item.value == selectedValue;
                return MenuItemButton(
                  onPressed: () => onSelected(item.value),
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.hovered)
                          ? AppColors.peachPaperHover
                          : selected
                          ? AppColors.peachPaper
                          : Colors.transparent,
                    ),
                    foregroundColor: const WidgetStatePropertyAll(
                      AppColors.ink,
                    ),
                  ),
                  child: Row(
                    children: [
                      TbIcons.relayRadio(selected: selected, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.controlLabel.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (item.detail != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.detail!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.metadata,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (item.trailing != null) ...[
                        const SizedBox(width: 8),
                        item.trailing!,
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
      builder: (context, controller, child) => triggerBuilder(
        controller.isOpen ? controller.close : controller.open,
      ),
    );
  }
}
