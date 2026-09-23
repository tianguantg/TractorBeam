import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bridge/generated/api.dart' as bridge;
import '../l10n/l10n.dart';
import '../models/tractor_beam_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/asset_shape_shadow.dart';
import '../widgets/custom_icons.dart';
import '../widgets/paper_image.dart';
import '../widgets/torn_paper.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  static const String forkRepoUrl = 'https://github.com/tianguantg/TractorBeam';
  static const String upstreamRepoUrl =
      'https://github.com/mcthesw/TractorBeam';

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isLaunchingUrl = false;

  void _notice(
    BuildContext context,
    String text, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    AppNotification.show(
      context,
      text,
      duration: duration,
    );
  }

  Future<bool> _safeCopy(
    BuildContext context, {
    required String text,
    required String successNotice,
    Duration duration = const Duration(milliseconds: 1500),
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        _notice(context, successNotice, duration: duration);
      }
      return true;
    } catch (_) {
      if (context.mounted) {
        AppNotification.show(
          context,
          context.l10n.logsCopyFailed,
          type: NotificationType.error,
        );
      }
      return false;
    }
  }

  Future<void> _openOrCopyLink(
    BuildContext context, {
    required String title,
    required String url,
  }) async {
    if (_isLaunchingUrl) return;
    _isLaunchingUrl = true;
    try {
      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        if (context.mounted) {
          await _safeCopy(
            context,
            text: url,
            successNotice: context.l10n.aboutLinkCopiedNotice(title),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        await _safeCopy(
          context,
          text: url,
          successNotice: context.l10n.aboutLinkCopiedNotice(title),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _isLaunchingUrl = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TbIcons.aboutTitle(
            width: 112,
            key: const ValueKey('about-page-title'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 246,
          child: Row(
            children: [
              Expanded(
                child: _PaperPanel(
                  asset: 'assets/images/paper/about_identity_card.webp',
                  child: _identity(context),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _PaperPanel(
                  asset: 'assets/images/paper/about_links_card.webp',
                  child: _links(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 356,
          child: _PaperPanel(
            asset: 'assets/images/paper/about_thanks_card.webp',
            child: _thanks(context),
          ),
        ),
      ],
    ),
  );

  Widget _identity(BuildContext context) {
    final l10n = context.l10n;
    final controller = TractorBeamScope.maybeOf(context);
    final info = controller?.snapshot?.buildInfo;
    final releaseVersion =
        info?.releaseVersion ?? controller?.releaseVersion ?? '0.5.2-tb.1';
    final rawVersion = info?.versionLabel.trim();
    final version = (rawVersion != null && rawVersion.isNotEmpty) ? rawVersion : '0.5.2';
    final cleanVersion = version.startsWith('v') || version.startsWith('V')
        ? version.substring(1)
        : version;

    final relayProto = (info != null && info.relayProtocol.trim().isNotEmpty)
        ? info.relayProtocol.trim()
        : 'v5';
    final directProto = (info != null && info.directProtocol.trim().isNotEmpty)
        ? info.directProtocol.trim()
        : 'v6';
    final protocol = 'Relay $relayProto / LAN $directProto';

    final gitHash = info?.gitHash?.trim();
    final fullDiagText =
        'Tractor Beam v$releaseVersion (core:$cleanVersion${gitHash != null && gitHash.isNotEmpty ? ", git:$gitHash" : ""}), ${l10n.aboutCoreProtocol}: $protocol';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TbIcons.sectionTriangle(size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tractor Beam',
                    style: AppTextStyles.cardHeader.copyWith(fontSize: 21),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: l10n.aboutIdentityHelp,
              preferBelow: false,
              child: TbIcons.infoCircle(size: 16, color: AppColors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: 3),
        TbIcons.roomDashedLine(height: 6),
        const SizedBox(height: 3),
        Text(
          l10n.aboutIdentitySlogan,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: _InfoRow(
                label: l10n.aboutAuthor,
                value: 'Sworld',
                tooltip: 'Sworld (GitHub: https://github.com/mcthesw)',
                trailing: TbIcons.externalLink(
                  size: 12,
                  color: AppColors.inkMuted,
                ),
                onTap: () => _openOrCopyLink(
                  context,
                  title: 'Sworld',
                  url: 'https://github.com/mcthesw',
                ),
                onSecondaryTap: () => _safeCopy(
                  context,
                  text: 'https://github.com/mcthesw',
                  successNotice: l10n.aboutLinkCopiedDirect('Sworld'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoRow(
                label: l10n.aboutUiDesigner,
                value: 'tgw',
                tooltip: 'tgw (GitHub: https://github.com/tianguantg)',
                trailing: TbIcons.externalLink(
                  size: 12,
                  color: AppColors.inkMuted,
                ),
                onTap: () => _openOrCopyLink(
                  context,
                  title: 'tgw',
                  url: 'https://github.com/tianguantg',
                ),
                onSecondaryTap: () => _safeCopy(
                  context,
                  text: 'https://github.com/tianguantg',
                  successNotice: l10n.aboutLinkCopiedDirect('tgw'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        InkWell(
          onTap: () => _safeCopy(
            context,
            text: fullDiagText,
            successNotice: l10n.aboutCopiedVersionNotice,
          ),
          borderRadius: BorderRadius.circular(5),
          child: Tooltip(
            message: l10n.aboutVersionHelp,
            preferBelow: false,
            child: _InfoRow(
              label: l10n.aboutVersionLabel,
              value: releaseVersion,
            ),
          ),
        ),
        const SizedBox(height: 3),
        _buildUpdateRow(context),
        const SizedBox(height: 3),
        _InfoRow(label: l10n.aboutCoreProtocol, value: protocol, accent: true),
      ],
    );
  }

  Widget _buildUpdateRow(BuildContext context) {
    final l10n = context.l10n;
    final controller = TractorBeamScope.maybeOf(context);
    final status = controller?.updateStatus ?? bridge.UpdateStatusDto.idle;
    final available = controller?.availableUpdate;
    final channelUrl = controller?.updateChannelUrl ?? AboutScreen.forkRepoUrl;

    String statusText;
    Color statusColor = AppColors.ink;
    Widget actionButton;

    switch (status) {
      case bridge.UpdateStatusDto.checking:
        statusText = l10n.aboutUpdateChecking;
        actionButton = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
          ),
        );
        break;
      case bridge.UpdateStatusDto.available:
        final ver = available?.version ?? '';
        statusText = l10n.aboutUpdateAvailable(ver);
        statusColor = AppColors.accentRed;
        final targetUrl = available?.url ?? channelUrl;
        actionButton = TornPaperButton(
          onTap: () => _openOrCopyLink(
            context,
            title: l10n.aboutViewUpdateBtn,
            url: targetUrl,
          ),
          seed: 'view-update'.hashCode,
          roughness: 1.0,
          borderWidth: 1.2,
          fillColor: AppColors.peachPaper,
          hoverFillColor: AppColors.peachPaperHover,
          borderColor: AppColors.paperBorder,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            l10n.aboutViewUpdateBtn,
            style: AppTextStyles.buttonText.copyWith(fontSize: 12),
          ),
        );
        break;
      case bridge.UpdateStatusDto.upToDate:
        statusText = l10n.aboutUpdateUpToDate;
        statusColor = AppColors.latencyExcellent;
        actionButton = TornPaperButton(
          onTap: () => controller?.checkUpdate(),
          seed: 'check-update'.hashCode,
          roughness: 1.0,
          borderWidth: 1.2,
          fillColor: AppColors.peachPaper,
          hoverFillColor: AppColors.peachPaperHover,
          borderColor: AppColors.paperBorder,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            l10n.aboutCheckUpdateBtn,
            style: AppTextStyles.buttonText.copyWith(fontSize: 12),
          ),
        );
        break;
      case bridge.UpdateStatusDto.failed:
        statusText = l10n.aboutUpdateFailed;
        statusColor = AppColors.accentRed;
        actionButton = TornPaperButton(
          onTap: () => controller?.checkUpdate(),
          seed: 'retry-update'.hashCode,
          roughness: 1.0,
          borderWidth: 1.2,
          fillColor: AppColors.peachPaper,
          hoverFillColor: AppColors.peachPaperHover,
          borderColor: AppColors.paperBorder,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            l10n.aboutRetryUpdateBtn,
            style: AppTextStyles.buttonText.copyWith(fontSize: 12),
          ),
        );
        break;
      case bridge.UpdateStatusDto.idle:
        statusText = l10n.aboutUpdateStatusLabel;
        actionButton = TornPaperButton(
          onTap: () => controller?.checkUpdate(),
          seed: 'check-update'.hashCode,
          roughness: 1.0,
          borderWidth: 1.2,
          fillColor: AppColors.peachPaper,
          hoverFillColor: AppColors.peachPaperHover,
          borderColor: AppColors.paperBorder,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            l10n.aboutCheckUpdateBtn,
            style: AppTextStyles.buttonText.copyWith(fontSize: 12),
          ),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paperInnerBg,
        border: Border.all(
          color: AppColors.paperBorder.withValues(alpha: .35),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  statusText,
                  maxLines: 1,
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 13.5,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          actionButton,
        ],
      ),
    );
  }

  Widget _links(BuildContext context) {
    final l10n = context.l10n;
    final repoUrl =
        TractorBeamScope.maybeOf(context)?.snapshot?.buildInfo.sourceUrl ??
        AboutScreen.forkRepoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TbIcons.sectionTriangle(size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.aboutLinksTitle,
                    style: AppTextStyles.cardHeader.copyWith(fontSize: 21),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: l10n.aboutLinksHelp,
              preferBelow: false,
              child: TbIcons.infoCircle(size: 16, color: AppColors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TbIcons.roomDashedLine(height: 6),
        const SizedBox(height: 8),
        _LinkRow(
          title: l10n.aboutSourceRepo,
          trailing: TbIcons.externalLink(size: 16, color: AppColors.ink),
          tooltip: 'GitHub: $repoUrl',
          onTap: () => _openOrCopyLink(
            context,
            title: l10n.aboutSourceRepo,
            url: repoUrl,
          ),
          onSecondaryTap: () => _safeCopy(
            context,
            text: repoUrl,
            successNotice: l10n.aboutLinkCopiedDirect(l10n.aboutSourceRepo),
          ),
        ),
        const SizedBox(height: 8),
        _LinkRow(
          title: l10n.aboutRefactorRepo,
          tooltip: 'GitHub: ${AboutScreen.upstreamRepoUrl}',
          trailing: TbIcons.externalLink(size: 16, color: AppColors.ink),
          onTap: () => _openOrCopyLink(
            context,
            title: l10n.aboutRefactorRepo,
            url: AboutScreen.upstreamRepoUrl,
          ),
          onSecondaryTap: () => _safeCopy(
            context,
            text: AboutScreen.upstreamRepoUrl,
            successNotice: l10n.aboutLinkCopiedDirect(l10n.aboutRefactorRepo),
          ),
        ),
      ],
    );
  }

  Widget _thanks(BuildContext context) {
    final l10n = context.l10n;
    final testers = [
      const _TesterEntry(
        'Summerraim',
        url: 'https://github.com/Summerraim',
      ),
      const _TesterEntry('勺子c'),
      const _TesterEntry('土拨鼠'),
      const _TesterEntry('老吴'),
      const _TesterEntry('細'),
      const _TesterEntry('空弦弦娴'),
      const _TesterEntry(
        '舟飏',
        url: 'https://github.com/LLIittleFish',
        tooltip: '舟飏 (LLIittleFish)',
      ),
      const _TesterEntry('扣1跟科比打复活赛'),
      const _TesterEntry('闲舒'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TbIcons.sectionTriangle(size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.aboutThanksTitle,
                    style: AppTextStyles.cardHeader.copyWith(fontSize: 21),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: l10n.aboutThanksHelp,
              preferBelow: false,
              child: TbIcons.infoCircle(size: 16, color: AppColors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TbIcons.roomDashedLine(height: 6),
        const SizedBox(height: 5),
        Text(
          l10n.aboutThanksIntro,
          style: AppTextStyles.body.copyWith(fontSize: 13.5),
        ),
        const SizedBox(height: 5),
        Text(
          l10n.aboutContributors,
          style: AppTextStyles.bodyBold.copyWith(
            fontSize: 13.5,
            color: AppColors.accentRed,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _Contributor(
                name: 'Sworld',
                url: 'https://github.com/mcthesw',
                tooltip: 'Sworld (GitHub: https://github.com/mcthesw)',
                onTap: () => _openOrCopyLink(
                  context,
                  title: 'Sworld',
                  url: 'https://github.com/mcthesw',
                ),
                onSecondaryTap: () => _safeCopy(
                  context,
                  text: 'https://github.com/mcthesw',
                  successNotice: l10n.aboutLinkCopiedDirect('Sworld'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: _Contributor(name: '北国无人')),
            const SizedBox(width: 8),
            Expanded(child: _Contributor(name: l10n.aboutOtherAnonymous)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          l10n.aboutEarlyTesters,
          style: AppTextStyles.bodyBold.copyWith(
            fontSize: 13.5,
            color: AppColors.greenBadgeText,
          ),
        ),
        const SizedBox(height: 4),
        for (int row = 0; row < 3; row++) ...[
          SizedBox(
            height: 33,
            child: Row(
              children: [
                Expanded(
                  child: _TesterTile(
                    tester: testers[row * 3],
                    onOpenLink: (title, url) => _openOrCopyLink(
                      context,
                      title: title,
                      url: url,
                    ),
                    onCopyLink: (title, url) => _safeCopy(
                      context,
                      text: url,
                      successNotice: l10n.aboutLinkCopiedDirect(title),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TesterTile(
                    tester: testers[row * 3 + 1],
                    onOpenLink: (title, url) => _openOrCopyLink(
                      context,
                      title: title,
                      url: url,
                    ),
                    onCopyLink: (title, url) => _safeCopy(
                      context,
                      text: url,
                      successNotice: l10n.aboutLinkCopiedDirect(title),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TesterTile(
                    tester: testers[row * 3 + 2],
                    onOpenLink: (title, url) => _openOrCopyLink(
                      context,
                      title: title,
                      url: url,
                    ),
                    onCopyLink: (title, url) => _safeCopy(
                      context,
                      text: url,
                      successNotice: l10n.aboutLinkCopiedDirect(title),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (row < 2) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _TesterEntry {
  final String name;
  final String? url;
  final String? tooltip;

  const _TesterEntry(this.name, {this.url, this.tooltip});
}

class _TesterTile extends StatelessWidget {
  final _TesterEntry tester;
  final void Function(String title, String url)? onOpenLink;
  final void Function(String title, String url)? onCopyLink;

  const _TesterTile({
    required this.tester,
    this.onOpenLink,
    this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final hasLink = tester.url != null;
    final tooltipText = tester.tooltip != null
        ? (tester.url != null ? '${tester.tooltip}: ${tester.url}' : tester.tooltip!)
        : (tester.url != null ? '${tester.name}: ${tester.url}' : tester.name);

    final tileContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.peachPaper,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.paperBorder, width: 1.3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    tester.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5),
                  ),
                ),
                if (hasLink) ...[
                  const SizedBox(width: 3),
                  TbIcons.externalLink(size: 11, color: AppColors.inkMuted),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.greenBadgeBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.greenBadgeBorder, width: 1.0),
            ),
            child: Text(
              context.l10n.aboutTagTester,
              style: AppTextStyles.metadata.copyWith(
                fontSize: 11.5,
                color: AppColors.greenBadgeText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (!hasLink) {
      return Tooltip(
        message: tooltipText,
        preferBelow: false,
        child: tileContent,
      );
    }

    final clickable = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () =>
            onOpenLink?.call(tester.tooltip ?? tester.name, tester.url!),
        onSecondaryTap: () =>
            onCopyLink?.call(tester.tooltip ?? tester.name, tester.url!),
        child: tileContent,
      ),
    );

    return Tooltip(
      message: tooltipText,
      preferBelow: false,
      child: clickable,
    );
  }
}

class _PaperPanel extends StatelessWidget {
  final String asset;
  final Widget child;
  const _PaperPanel({required this.asset, required this.child});
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
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 13),
          child: child,
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final Widget? trailing;
  final String? tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;

  const _InfoRow({
    required this.label,
    required this.value,
    this.accent = false,
    this.trailing,
    this.tooltip,
    this.onTap,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paperInnerBg,
        border: Border.all(
          color: AppColors.paperBorder.withValues(alpha: .35),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.metadataInk.copyWith(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: AppTextStyles.mono.copyWith(
                          fontSize: 14.5,
                          color: accent ? AppColors.accentRed : AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onSecondaryTap: onSecondaryTap,
          child: content,
        ),
      );
    }

    if (tooltip != null) {
      content = Tooltip(
        message: tooltip!,
        preferBelow: false,
        child: content,
      );
    }

    return content;
  }
}

class _LinkRow extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final String? tooltip;
  final VoidCallback onTap;
  final VoidCallback? onSecondaryTap;

  const _LinkRow({
    required this.title,
    required this.onTap,
    this.onSecondaryTap,
    this.trailing,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = TornPaperButton(
      onTap: onTap,
      seed: title.hashCode,
      roughness: 1.2,
      borderWidth: 1.5,
      fillColor: AppColors.peachPaper,
      hoverFillColor: AppColors.peachPaperHover,
      borderColor: AppColors.paperBorder,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.buttonText.copyWith(fontSize: 14),
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (onSecondaryTap != null) {
      button = GestureDetector(onSecondaryTap: onSecondaryTap, child: button);
    }
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        preferBelow: false,
        child: button,
      );
    }
    return button;
  }
}

class _Contributor extends StatelessWidget {
  final String name;
  final String? url;
  final String? tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;

  const _Contributor({
    required this.name,
    this.url,
    this.tooltip,
    this.onTap,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLink = url != null;
    Widget child = TornPaperContainer(
      seed: name.hashCode,
      roughness: 1.15,
      borderWidth: 1.5,
      fillColor: AppColors.peachPaper,
      borderColor: AppColors.paperBorder,
      showShadow: false,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                  ),
                ),
              ),
              if (hasLink) ...[
                const SizedBox(width: 3),
                TbIcons.externalLink(size: 12, color: AppColors.accentRed),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.paperInnerBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.accentRed.withValues(alpha: .5),
                width: 1.2,
              ),
            ),
            child: Text(
              context.l10n.aboutTagContributor,
              style: AppTextStyles.metadata.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.accentRed,
              ),
            ),
          ),
        ],
      ),
    );

    if (hasLink && onTap != null) {
      child = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onSecondaryTap: onSecondaryTap,
          child: child,
        ),
      );
    }

    if (tooltip != null) {
      child = Tooltip(
        message: tooltip!,
        preferBelow: false,
        child: child,
      );
    }

    return child;
  }
}
