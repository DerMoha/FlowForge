import 'dart:ui';

import 'package:flutter/material.dart';

import 'ambient_gradient_background.dart';

export 'flow_sheet_frame.dart';

class FlowUiTokens {
  const FlowUiTokens._();

  static const double maxPageWidth = 1080;
  static const double widePageWidth = 1220;
  static const double desktopBreakpoint = 900;

  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 28;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 16, 16, 32);
  static const EdgeInsets pagePaddingWithNav = EdgeInsets.fromLTRB(
    16,
    16,
    16,
    136,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(18);
}

class FlowPageScaffold extends StatelessWidget {
  const FlowPageScaffold({
    super.key,
    required this.energy,
    required this.child,
    this.maxWidth = FlowUiTokens.maxPageWidth,
    this.padding,
    this.resizeToAvoidBottomInset = true,
  });

  final double energy;
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return AmbientGradientBackground(
      energy: energy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal =
                  constraints.maxWidth >= FlowUiTokens.desktopBreakpoint
                  ? 24.0
                  : 16.0;
              final resolvedPadding =
                  padding ??
                  EdgeInsets.fromLTRB(
                    horizontal,
                    16,
                    horizontal,
                    constraints.maxWidth >= FlowUiTokens.desktopBreakpoint
                        ? 36
                        : 136,
                  );

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Padding(padding: resolvedPadding, child: child),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FlowSurfaceCard extends StatelessWidget {
  const FlowSurfaceCard({
    super.key,
    required this.child,
    this.padding = FlowUiTokens.cardPadding,
    this.margin,
    this.radius = FlowUiTokens.radiusLg,
    this.opacity,
    this.borderOpacity = 0.34,
    this.blurSigma = 16,
    this.tint,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double? opacity;
  final double borderOpacity;
  final double blurSigma;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseOpacity = opacity ?? (isDark ? 0.72 : 0.84);
    final borderRadius = BorderRadius.circular(radius);
    final surface = tint ?? scheme.surfaceContainerHigh;

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: borderOpacity),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface.withValues(alpha: baseOpacity),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.07 : 0.24),
                  Colors.white.withValues(alpha: isDark ? 0.025 : 0.08),
                  scheme.surfaceContainer.withValues(alpha: 0.02),
                ],
                stops: const [0, 0.34, 1],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    if (onTap == null) return card;

    return GestureDetector(onTap: onTap, child: card);
  }
}

class FlowPageHeader extends StatelessWidget {
  const FlowPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.icon,
    this.actions = const [],
    this.badges = const [],
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final IconData? icon;
  final List<Widget> actions;
  final List<Widget> badges;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final titleBlock = Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(FlowUiTokens.radiusMd),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.26)),
            ),
            child: Icon(icon, color: scheme.primary, size: 25),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return FlowSurfaceCard(
      radius: FlowUiTokens.radiusXl,
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          final controls = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [...badges, ...actions],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                if (badges.isNotEmpty || actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  controls,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 18),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class FlowStatPill extends StatelessWidget {
  const FlowStatPill({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return FlowMetaChip(
      icon: icon,
      label: '$value $label',
      color: accent,
      filled: true,
    );
  }
}

class FlowMetaChip extends StatelessWidget {
  const FlowMetaChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled
            ? accent.withValues(alpha: 0.14)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: filled ? 0.22 : 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: filled ? accent : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class FlowEmptyState extends StatelessWidget {
  const FlowEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FlowSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class FlowScopeBanner extends StatelessWidget {
  const FlowScopeBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return FlowSurfaceCard(
      tint: accent,
      opacity: 0.12,
      borderOpacity: 0.24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}
