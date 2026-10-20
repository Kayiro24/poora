import 'package:flutter/material.dart';
import 'package:poora/core/theme/tokens.dart';
import 'package:poora/core/theme/typography.dart';
import 'package:poora/core/time/format.dart';

/// One card placed on the rail by start time and duration.
class TimelineItem {
  const TimelineItem({
    required this.id,
    required this.column,
    required this.startMinute,
    required this.durationMin,
    required this.child,
    this.draggable = true,
  });

  final String id;
  final int column;
  final int startMinute;
  final int durationMin;
  final Widget child;
  final bool draggable;

  int get endMinute => startMinute + durationMin;
}

/// Side-by-side placement for overlapping items: (lane, laneCount) per id.
Map<String, (int, int)> assignLanes(List<TimelineItem> items) {
  final out = <String, (int, int)>{};
  final byCol = <int, List<TimelineItem>>{};
  for (final i in items) {
    (byCol[i.column] ??= []).add(i);
  }
  for (final col in byCol.values) {
    col.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    var cluster = <TimelineItem>[];
    var lanesEnd = <int>[];
    var clusterEnd = -1;
    void flush() {
      for (final i in cluster) {
        out[i.id] = (out[i.id]!.$1, lanesEnd.length);
      }
      cluster = [];
      lanesEnd = [];
    }

    for (final i in col) {
      final end = i.startMinute + (i.durationMin < 15 ? 15 : i.durationMin);
      if (i.startMinute >= clusterEnd) flush();
      var lane = lanesEnd.indexWhere((e) => e <= i.startMinute);
      if (lane < 0) {
        lane = lanesEnd.length;
        lanesEnd.add(end);
      } else {
        lanesEnd[lane] = end;
      }
      out[i.id] = (lane, 0);
      cluster.add(i);
      if (end > clusterEnd) clusterEnd = end;
    }
    flush();
  }
  return out;
}

/// Vertical 00:00–24:00 rail: time labels on the left, cards placed by time,
/// an ice "now" line with a mono time pill. Supports long-press-drag on empty
/// space to create (start + duration) and long-press-drag on cards to move.
class TimelineRail extends StatefulWidget {
  const TimelineRail({
    required this.items,
    this.columns = 1,
    this.hourHeight = 64,
    this.now,
    this.nowColumn,
    this.use24h = false,
    this.onCreate,
    this.onMove,
    super.key,
  });

  final List<TimelineItem> items;
  final int columns;
  final double hourHeight;
  final DateTime? now;

  /// Column that shows the "now" line; null hides it.
  final int? nowColumn;
  final bool use24h;

  /// (column, startMinute, durationMin) after a long-press-drag on empty space.
  final void Function(int column, int startMinute, int durationMin)? onCreate;

  /// (item, newColumn, newStartMinute) after dragging a card.
  final void Function(TimelineItem item, int column, int startMinute)? onMove;

  static const labelWidth = 52.0;
  static const snap = 15;

  @override
  State<TimelineRail> createState() => _TimelineRailState();
}

class _TimelineRailState extends State<TimelineRail> {
  // Create ghost.
  int? _createCol;
  int? _createStart;
  int? _createEnd;

  // Move preview.
  String? _dragId;
  Offset _dragDelta = Offset.zero;

  double get _minuteHeight => widget.hourHeight / 60;

  int _snap(double minute) {
    final m = (minute / TimelineRail.snap).round() * TimelineRail.snap;
    return m.clamp(0, 24 * 60 - TimelineRail.snap);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.hourHeight * 24;
    return LayoutBuilder(
      builder: (context, c) {
        final colWidth = (c.maxWidth - TimelineRail.labelWidth) / widget.columns;
        final lanes = assignLanes(widget.items);
        return SizedBox(
          height: total + 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 8,
                child: CustomPaint(
                  painter: _GridPainter(
                    hourHeight: widget.hourHeight,
                    columns: widget.columns,
                    labelWidth: TimelineRail.labelWidth,
                  ),
                ),
              ),
              for (var h = 0; h <= 24; h++)
                Positioned(
                  left: 0,
                  top: 8 + h * widget.hourHeight - 7,
                  width: TimelineRail.labelWidth - 8,
                  child: Text(
                    h == 24 ? '' : Fmt.hour(h, use24h: widget.use24h),
                    textAlign: TextAlign.right,
                    style: AppText.mono(10, color: Tokens.textSecondary),
                  ),
                ),
              // Empty-space gestures for create.
              Positioned(
                left: TimelineRail.labelWidth,
                right: 0,
                top: 8,
                height: total,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: widget.onCreate == null
                      ? null
                      : (d) {
                          final col = (d.localPosition.dx / colWidth).floor().clamp(0, widget.columns - 1);
                          final start = _snap(d.localPosition.dy / _minuteHeight - 15);
                          setState(() {
                            _createCol = col;
                            _createStart = start;
                            _createEnd = start + 30;
                          });
                        },
                  onLongPressMoveUpdate: widget.onCreate == null
                      ? null
                      : (d) {
                          final end = _snap(d.localPosition.dy / _minuteHeight);
                          setState(() => _createEnd = end <= _createStart! ? _createStart! + 15 : end);
                        },
                  onLongPressEnd: widget.onCreate == null
                      ? null
                      : (_) {
                          final col = _createCol, start = _createStart, end = _createEnd;
                          setState(() => _createCol = _createStart = _createEnd = null);
                          if (col != null && start != null && end != null) {
                            widget.onCreate!(col, start, end - start);
                          }
                        },
                ),
              ),
              if (_createCol != null)
                Positioned(
                  left: TimelineRail.labelWidth + _createCol! * colWidth + 2,
                  width: colWidth - 4,
                  top: 8 + _createStart! * _minuteHeight,
                  height: (_createEnd! - _createStart!) * _minuteHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Tokens.coral.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Tokens.coral),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      '${Fmt.minute(_createStart!, use24h: widget.use24h)} – '
                      '${Fmt.minute(_createEnd!, use24h: widget.use24h)}',
                      style: AppText.mono(11),
                    ),
                  ),
                ),
              for (final item in widget.items)
                _positioned(item, lanes[item.id] ?? (0, 1), colWidth),
              if (widget.now != null && widget.nowColumn != null)
                _nowLine(colWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _positioned(TimelineItem item, (int, int) lane, double colWidth) {
    final (index, count) = lane;
    final laneWidth = colWidth / (count == 0 ? 1 : count);
    final dragging = _dragId == item.id;
    final height = (item.durationMin < 15 ? 15 : item.durationMin) * _minuteHeight;
    return Positioned(
      left: TimelineRail.labelWidth + item.column * colWidth + index * laneWidth + 2,
      width: laneWidth - 4,
      top: 8 + item.startMinute * _minuteHeight + 1,
      height: height - 2,
      child: Transform.translate(
        offset: dragging ? _dragDelta : Offset.zero,
        child: GestureDetector(
          onLongPressStart: !item.draggable || widget.onMove == null
              ? null
              : (_) => setState(() {
                  _dragId = item.id;
                  _dragDelta = Offset.zero;
                }),
          onLongPressMoveUpdate: !item.draggable || widget.onMove == null
              ? null
              : (d) => setState(() => _dragDelta = d.offsetFromOrigin),
          onLongPressEnd: !item.draggable || widget.onMove == null
              ? null
              : (_) {
                  final dCol = (_dragDelta.dx / colWidth).round();
                  final newCol = (item.column + dCol).clamp(0, widget.columns - 1);
                  final newStart = _snap(item.startMinute + _dragDelta.dy / _minuteHeight);
                  setState(() {
                    _dragId = null;
                    _dragDelta = Offset.zero;
                  });
                  if (newCol != item.column || newStart != item.startMinute) {
                    widget.onMove!(item, newCol, newStart);
                  }
                },
          child: AnimatedOpacity(
            opacity: dragging ? 0.85 : 1,
            duration: const Duration(milliseconds: 150),
            child: item.child,
          ),
        ),
      ),
    );
  }

  Widget _nowLine(double colWidth) {
    final now = widget.now!;
    final minute = now.hour * 60 + now.minute;
    final top = 8 + minute * _minuteHeight;
    final left = TimelineRail.labelWidth + widget.nowColumn! * colWidth;
    return Positioned(
      left: 0,
      right: 0,
      top: top - 10,
      height: 20,
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: left,
              width: widget.columns == 1 ? null : colWidth,
              right: widget.columns == 1 ? 0 : null,
              top: 9,
              child: Container(height: 2, color: Tokens.ice),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: Tokens.ice,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  Fmt.time(now, use24h: widget.use24h),
                  style: AppText.mono(10, color: Tokens.textInverse),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.hourHeight,
    required this.columns,
    required this.labelWidth,
  });

  final double hourHeight;
  final int columns;
  final double labelWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Tokens.outline
      ..strokeWidth = 0.5;
    for (var h = 0; h <= 24; h++) {
      final y = h * hourHeight;
      canvas.drawLine(Offset(labelWidth, y), Offset(size.width, y), line);
    }
    if (columns > 1) {
      final colWidth = (size.width - labelWidth) / columns;
      for (var c = 0; c <= columns; c++) {
        final x = labelWidth + c * colWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, hourHeight * 24), line);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.hourHeight != hourHeight || old.columns != columns;
}
