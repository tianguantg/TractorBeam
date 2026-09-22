import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'asset_shape_shadow.dart';
import 'custom_icons.dart';
import 'paper_image.dart';
import 'tape_widget.dart';

class PaperCard extends StatelessWidget {
  final Widget? headerLeading;
  final String title;
  final Widget? headerTrailing;
  final Widget child;
  final bool showTape;
  final String? backgroundAsset;
  final Widget? divider;

  const PaperCard({
    super.key,
    this.headerLeading,
    required this.title,
    this.headerTrailing,
    required this.child,
    this.showTape = true,
    this.backgroundAsset,
    this.divider,
  });

  @override
  Widget build(BuildContext context) {
    final asset = backgroundAsset;
    if (asset != null) {
      return TbPaperImageScope(
        asset: asset,
        builder: (context, imageProvider) => _buildCard(context, imageProvider),
      );
    }
    return _buildCard(context, null);
  }

  Widget _buildCard(
    BuildContext context,
    ImageProvider<Object>? imageProvider,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Background stacked paper sheet shadow / secondary layer
        if (backgroundAsset == null)
          Positioned.fill(
            top: 4,
            left: 3,
            right: -3,
            bottom: -4,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.paperShadowLayer,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: AppColors.paperBorder.withValues(alpha: 0.3),
                  width: AppStrokes.control,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(2, 6),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),

        if (imageProvider != null)
          Positioned.fill(
            child: AssetShapeShadow(imageProvider: imageProvider),
          ),

        // Main Paper Sheet
        Container(
          decoration: imageProvider == null
              ? BoxDecoration(
                  color: AppColors.paperBg,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: AppColors.paperBorder,
                    width: AppStrokes.card,
                  ),
                )
              : BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.fill,
                    filterQuality:
                        WindowResizePerformanceScope.largeImageQualityOf(
                          context,
                        ),
                  ),
                ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (headerLeading != null) ...[
                    headerLeading!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(title, style: AppTextStyles.cardHeader),
                  if (headerTrailing != null) ...[
                    const SizedBox(width: 6),
                    headerTrailing!,
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Dotted/dashed separator line
              divider ??
                  TbIcons.dashedLine(
                    height: 12,
                    key: const ValueKey('paper-card-dashed-line'),
                  ),
              const SizedBox(height: AppSpacing.lg),

              // Main content
              child,
            ],
          ),
        ),

        // Masking tape pinned on top edge
        if (showTape && backgroundAsset == null)
          const Positioned(top: -9, child: TapeWidget(width: 115, height: 18)),
      ],
    );
  }
}
