import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/widgets/mascot.dart';

/// Mascot + one calm line, used by every chart and list with no data.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.mood = MascotMood.sleepy,
    this.compact = false,
    this.color = Tokens.textSecondary,
    super.key,
  });

  final String message;
  final MascotMood mood;
  final bool compact;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mascot = Mascot(mood: mood, size: compact ? 40 : 64);
    final text = Text(
      message,
      style: AppText.body(14, color: color),
      textAlign: compact ? TextAlign.start : TextAlign.center,
    );
    if (compact) {
      return Row(
        children: [
          mascot,
          const SizedBox(width: Space.m),
          Expanded(child: text),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [mascot, const SizedBox(height: Space.m), text],
      ),
    );
  }
}

/// Small uppercase condensed section heading with an optional trailing.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.text, {
    this.trailing,
    this.color = Tokens.textPrimary,
    super.key,
  });

  final String text;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text.toUpperCase(), style: AppText.display(22, color: color)),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Grouped settings list (§4.5): dark card of rows with hairline dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: Space.s),
            child: Text(
              title.toUpperCase(),
              style: AppText.body(12, weight: FontWeight.w500, color: Tokens.textSecondary),
            ),
          ),
          Material(
            color: Tokens.surface,
            borderRadius: BorderRadius.circular(Radii.inner),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppText.body(15, weight: FontWeight.w500)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppText.bodyS),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SettingsRow(
        title: title,
        subtitle: subtitle,
        enabled: enabled,
        onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
        trailing: Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeTrackColor: Tokens.sageDeep,
        ),
      ),
    );
  }
}
