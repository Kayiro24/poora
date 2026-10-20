import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poora/core/theme/motion.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/format.dart';
import 'package:poora/core/widgets/arrow_circle_button.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/features/settings/settings_controller.dart';
import 'package:poora/features/tasks/domain/models.dart';
import 'package:poora/features/tasks/domain/recurrence.dart';
import 'package:poora/features/tasks/ui/task_actions.dart';

String occurrenceTimeLabel(Occurrence o, {required bool use24h}) {
  if (!o.isTimed) return 'All day';
  return '${Fmt.minute(o.startMinute!, use24h: use24h)} – '
      '${Fmt.minute(o.endMinute!, use24h: use24h)}';
}

/// Round checkbox that fills on completion.
class RoundCheck extends StatelessWidget {
  const RoundCheck({
    required this.checked,
    required this.onTap,
    this.color = Tokens.mint,
    this.size = 28,
    this.skipped = false,
    super.key,
  });

  final bool checked;
  final bool skipped;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      button: true,
      label: checked ? 'Completed. Tap to undo' : 'Mark done',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              curve: Motion.curve,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? color : Colors.transparent,
                border: Border.all(
                  color: checked ? color : Tokens.textSecondary,
                  width: 1.6,
                ),
              ),
              child: checked
                  ? Icon(Icons.check_rounded, size: size * 0.65, color: Tokens.textInverse)
                  : skipped
                  ? Icon(Icons.remove_rounded, size: size * 0.6, color: Tokens.textSecondary)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Text with a strike-through that draws left → right when [struck].
class StrikeText extends StatelessWidget {
  const StrikeText(this.text, {required this.style, required this.struck, this.maxLines = 1, super.key});

  final String text;
  final TextStyle style;
  final bool struck;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: struck ? 1 : 0),
      duration: Motion.of(context, Motion.slow),
      curve: Motion.curve,
      builder: (context, v, child) => CustomPaint(
        foregroundPainter: _StrikePainter(v, style.color ?? Tokens.textPrimary),
        child: child,
      ),
      child: Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis),
    );
  }
}

class _StrikePainter extends CustomPainter {
  _StrikePainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final y = size.height * 0.52;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress, y),
      Paint()
        ..color = color
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.progress != progress;
}

/// List card (Schedule view, Home, day sheet): checkbox, condensed title, tag
/// chip, time · repeat line, ↗ button. Swipe right completes, left skips or
/// deletes.
class TaskCard extends ConsumerWidget {
  const TaskCard({required this.occurrence, this.swipe = true, super.key});

  final Occurrence occurrence;
  final bool swipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final use24h = ref.watch(settingsProvider.select((s) => s.use24h));
    final done = o.isDone;
    final skipped = o.status == OccurrenceStatus.skipped;
    final color = Color(o.task.color);
    final card = AnimatedOpacity(
      opacity: done || skipped ? 0.6 : 1,
      duration: Motion.of(context),
      curve: Motion.curve,
      child: Material(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(Radii.inner),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openEditor(context, occurrence: o),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: color),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: RoundCheck(
                      checked: done,
                      skipped: skipped,
                      onTap: () => toggleDone(ref, o),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (o.task.priority == Priority.high) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Tokens.sun, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: StrikeText(
                                o.title.toUpperCase(),
                                style: AppText.display(20),
                                struck: done,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (o.task.tag != null && o.task.tag!.trim().isNotEmpty)
                              PillChip(label: o.task.tag!, dense: true, dot: color),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  occurrenceTimeLabel(o, use24h: use24h),
                                  style: AppText.mono(12, color: Tokens.textSecondary),
                                ),
                                if (o.task.isRecurring) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.repeat_rounded,
                                    size: 14,
                                    color: Tokens.textSecondary,
                                    semanticLabel: RepeatRule.fromTask(o.task).summary(o.task.startDate),
                                  ),
                                ],
                                if (o.status == OccurrenceStatus.missed) ...[
                                  const SizedBox(width: 8),
                                  Text('missed', style: AppText.body(12, color: Tokens.coralSoft)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: ArrowCircleButton(
                      semanticLabel: 'Open ${o.title}',
                      onTap: () => openEditor(context, occurrence: o),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!swipe) return card;
    return Dismissible(
      key: ValueKey('swipe-${o.key}'),
      background: _SwipeBg(
        color: Tokens.mint,
        icon: done ? Icons.undo_rounded : Icons.check_rounded,
        label: done ? 'Undo' : 'Done',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBg(
        color: Tokens.coralSoft,
        icon: o.task.isRecurring ? Icons.redo_rounded : Icons.delete_outline_rounded,
        label: o.task.isRecurring ? (skipped ? 'Restore' : 'Skip') : 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await toggleDone(ref, o);
        } else {
          await skipOrDelete(context, ref, o);
        }
        return false; // the list re-renders from data, never removes locally
      },
      child: card,
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Radii.inner)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Tokens.textInverse),
          const SizedBox(width: 8),
          Text(label, style: AppText.label.copyWith(color: Tokens.textInverse)),
        ],
      ),
    );
  }
}

/// Compact card on the timeline rail. [highlight] = the next upcoming task,
/// drawn with a full pastel fill.
class RailCard extends ConsumerWidget {
  const RailCard({required this.occurrence, this.highlight = false, super.key});

  final Occurrence occurrence;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final use24h = ref.watch(settingsProvider.select((s) => s.use24h));
    final color = Color(o.task.color);
    final fg = highlight ? TaskColors.onColor(color) : Tokens.textPrimary;
    final done = o.isDone;
    return Semantics(
      button: true,
      label: '${o.title}, ${occurrenceTimeLabel(o, use24h: use24h)}${done ? ', done' : ''}',
      child: AnimatedOpacity(
        opacity: done || o.status == OccurrenceStatus.skipped ? 0.6 : 1,
        duration: Motion.of(context),
        child: Material(
          color: highlight ? color : Tokens.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openEditor(context, occurrence: o),
            onDoubleTap: () => toggleDone(ref, o),
            child: LayoutBuilder(
              builder: (context, c) {
                final tall = c.maxHeight >= 44;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!highlight) Container(width: 4, color: color),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(8, tall ? 6 : 2, 6, 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StrikeText(
                              o.title.toUpperCase(),
                              style: AppText.display(c.maxWidth < 80 ? 13 : 16, color: fg),
                              struck: done,
                            ),
                            if (tall && c.maxWidth >= 80)
                              Text(
                                occurrenceTimeLabel(o, use24h: use24h),
                                style: AppText.mono(10, color: fg.withValues(alpha: 0.75)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (c.maxWidth >= 120 && tall)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: RoundCheck(
                            checked: done,
                            size: 20,
                            color: highlight ? Tokens.bg : Tokens.mint,
                            onTap: () => toggleDone(ref, o),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// All-day item chip for the strip above the rail.
class AllDayChip extends ConsumerWidget {
  const AllDayChip({required this.occurrence, super.key});
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final color = Color(o.task.color);
    return Opacity(
      opacity: o.isDone || o.status == OccurrenceStatus.skipped ? 0.6 : 1,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => openEditor(context, occurrence: o),
          onLongPress: () => toggleDone(ref, o),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (o.isDone)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_rounded, size: 14, color: TaskColors.onColor(color)),
                  ),
                Flexible(
                  child: Text(
                    o.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(12, weight: FontWeight.w500, color: TaskColors.onColor(color)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
