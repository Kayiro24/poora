import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/date_utils.dart';
import 'package:poora/core/widgets/accent_panel.dart';
import 'package:poora/core/widgets/arrow_circle_button.dart';
import 'package:poora/core/widgets/common.dart';
import 'package:poora/core/widgets/completion_ring.dart';
import 'package:poora/core/widgets/coral_fab.dart';
import 'package:poora/core/widgets/day_rate_pills.dart';
import 'package:poora/core/widgets/floating_nav_bar.dart';
import 'package:poora/core/widgets/mascot.dart';
import 'package:poora/core/widgets/mono_badge.dart';
import 'package:poora/core/widgets/pill_chip.dart';
import 'package:poora/core/widgets/screen_header.dart';
import 'package:poora/core/widgets/stat_tile.dart';
import 'package:poora/core/widgets/timeline_rail.dart';

/// Debug route (/gallery) showing every signature component (milestone 1).
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _nav = 0;

  @override
  Widget build(BuildContext context) {
    final today = Days.of(DateTime.now());
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        index: _nav,
        onTap: (i) => setState(() => _nav = i),
        items: const [
          NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
          NavItem(Icons.timer_outlined, Icons.timer_rounded, 'Focus'),
          NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Tasks'),
          NavItem(Icons.insights_outlined, Icons.insights_rounded, 'Insights'),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.side, Space.m, Space.side, 140),
          children: [
            ScreenHeader(
              title: 'Gallery',
              onBack: () => Navigator.pop(context),
              trailing: const [PillChip(label: 'all', trailingIcon: Icons.expand_more_rounded)],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Type'),
            Text('DISPLAY 40', style: AppText.h1),
            Text('DISPLAY 24', style: AppText.h3),
            Text('Body 16 — Inter', style: AppText.bodyL),
            Text('Body 12 secondary', style: AppText.bodyS),
            Text('24:59.87', style: AppText.mono(48)),
            const SizedBox(height: 24),
            const SectionTitle('Colour'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in [
                  Tokens.sage, Tokens.sageDeep, Tokens.coral, Tokens.coralSoft, Tokens.periwinkle,
                  Tokens.periSoft, Tokens.ice, Tokens.sun, Tokens.mint, Tokens.dayPerfect,
                  Tokens.dayHigh, Tokens.dayMid, Tokens.dayLow, Tokens.dayMissed, Tokens.dayEmpty,
                ])
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(12))),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Chips & badges'),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillChip(label: 'Peak', dot: Tokens.coral),
                PillChip(label: 'Completion', filled: true, color: Tokens.ice),
                PillChip(label: 'Health', icon: Icons.favorite_border_rounded),
                PillChip(label: 'dense', dense: true, dot: Tokens.mint),
                MonoBadge('2:59:12'),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Stat tiles'),
            const Row(
              children: [
                StatTile(value: '64', label: 'tasks\ncompleted'),
                SizedBox(width: 24),
                StatTile(value: '82%', label: 'rate', color: Tokens.mint),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Panels'),
            AccentPanel(
              color: Tokens.sage,
              child: Row(
                children: [
                  Expanded(child: Text('ACCENT PANEL', style: AppText.display(28, color: Tokens.textInverse))),
                  ArrowCircleButton(onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AccentPanel(
              color: Tokens.periwinkle,
              child: DayRatePills(
                days: [
                  for (var i = 0; i < 7; i++)
                    DayPill(
                      date: Days.add(today, i - 3),
                      label: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                      percent: i < 3 ? 78 + i * 4 : (i == 3 ? 40 : null),
                      isToday: i == 3,
                      isFuture: i > 3,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Buttons, rings, mascots'),
            Row(
              children: [
                CoralFab(onPressed: () {}),
                const SizedBox(width: 16),
                const CompletionRing(value: 0.83, color: Tokens.dayHigh, child: Text('19')),
                const SizedBox(width: 8),
                const CompletionRing(value: 1, color: Tokens.dayPerfect, glow: true, fill: Color(0x594ADE80), child: Text('20')),
                const SizedBox(width: 8),
                for (final m in MascotMood.values) Mascot(mood: m, size: 40),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Empty state'),
            const EmptyState(message: 'Complete a few tasks and your week will show up here'),
            const SectionTitle('Timeline rail'),
            SizedBox(
              height: 360,
              child: SingleChildScrollView(
                child: TimelineRail(
                  now: DateTime.now(),
                  nowColumn: 0,
                  items: [
                    for (final (id, start, dur, color) in [
                      ('a', 9 * 60, 60, Tokens.coral),
                      ('b', 9 * 60 + 30, 45, Tokens.mint),
                      ('c', 12 * 60, 30, Tokens.ice),
                    ])
                      TimelineItem(
                        id: id,
                        column: 0,
                        startMinute: start,
                        durationMin: dur,
                        child: Container(
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(6),
                          child: Text('TASK $id'.toUpperCase(), style: AppText.display(14, color: Tokens.textInverse)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
