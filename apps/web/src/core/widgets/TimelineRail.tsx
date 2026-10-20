import { useEffect, useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import { Fmt } from '../time/format';
import { T } from '../theme/tokens';

export interface TimelineItem {
  id: string;
  column: number;
  startMinute: number;
  durationMin: number;
  content: ReactNode;
  draggable?: boolean;
}

const LABEL_W = 52;
const SNAP = 15;
const TOP = 8;
const LONG_PRESS = 400;

/** Side-by-side placement for overlapping items: id → [lane, laneCount]. */
export function assignLanes(items: TimelineItem[]): Map<string, [number, number]> {
  const out = new Map<string, [number, number]>();
  const byCol = new Map<number, TimelineItem[]>();
  for (const i of items) byCol.set(i.column, [...(byCol.get(i.column) ?? []), i]);
  for (const col of byCol.values()) {
    col.sort((a, b) => a.startMinute - b.startMinute);
    let cluster: TimelineItem[] = [];
    let lanesEnd: number[] = [];
    let clusterEnd = -1;
    const flush = () => {
      for (const i of cluster) out.set(i.id, [out.get(i.id)![0], lanesEnd.length]);
      cluster = [];
      lanesEnd = [];
    };
    for (const i of col) {
      const end = i.startMinute + Math.max(i.durationMin, 15);
      if (i.startMinute >= clusterEnd) flush();
      let lane = lanesEnd.findIndex((e) => e <= i.startMinute);
      if (lane < 0) {
        lane = lanesEnd.length;
        lanesEnd.push(end);
      } else lanesEnd[lane] = end;
      out.set(i.id, [lane, 0]);
      cluster.push(i);
      clusterEnd = Math.max(clusterEnd, end);
    }
    flush();
  }
  return out;
}

type Gesture =
  | { kind: 'none' }
  | { kind: 'pending'; pointer: string; pointerId: number; x: number; y: number; target: 'empty' | string; timer?: number }
  | { kind: 'create'; col: number; start: number; end: number }
  | { kind: 'move'; id: string; dx: number; dy: number; x: number; y: number };

/**
 * 24h rail: hour labels, cards placed by time, ice "now" line.
 * Touch: long-press empty space to create (drag for duration), long-press a
 * card to move it. Mouse: click or drag empty space to create, drag a card.
 */
export function TimelineRail(p: {
  items: TimelineItem[];
  columns?: number;
  hourHeight?: number;
  now?: Date | null;
  nowColumn?: number | null;
  use24h: boolean;
  /** Minute to scroll into view (marked with data-rail-anchor). */
  anchorMinute?: number;
  onCreate?: (column: number, startMinute: number, durationMin: number) => void;
  onMove?: (id: string, column: number, startMinute: number) => void;
}) {
  const columns = p.columns ?? 1;
  const hh = p.hourHeight ?? 64;
  const mh = hh / 60;
  const box = useRef<HTMLDivElement>(null);
  const [g, setGState] = useState<Gesture>({ kind: 'none' });
  const gRef = useRef(g);
  useLayoutEffect(() => {
    gRef.current = g;
  });
  // Handlers read the latest gesture synchronously between renders.
  const setG = (next: Gesture) => {
    gRef.current = next;
    setGState(next);
  };
  const suppressClick = useRef(false);

  const geom = () => {
    const r = box.current!.getBoundingClientRect();
    return { r, colW: (r.width - LABEL_W) / columns };
  };
  const snap = (m: number) => Math.min(Math.max(Math.round(m / SNAP) * SNAP, 0), 24 * 60 - SNAP);
  const toCell = (x: number, y: number) => {
    const { r, colW } = geom();
    return {
      col: Math.min(Math.max(Math.floor((x - r.left - LABEL_W) / colW), 0), columns - 1),
      minute: (y - r.top - TOP) / mh,
    };
  };

  // Block page scrolling only while a touch gesture is creating or moving.
  useEffect(() => {
    const el = box.current;
    if (!el) return;
    const stop = (e: TouchEvent) => {
      const k = gRef.current.kind;
      if (k === 'create' || k === 'move') e.preventDefault();
    };
    el.addEventListener('touchmove', stop, { passive: false });
    return () => el.removeEventListener('touchmove', stop);
  }, []);

  const begin = (e: React.PointerEvent, target: 'empty' | string) => {
    if (e.button !== 0) return;
    const pending: Gesture = { kind: 'pending', pointer: e.pointerType, pointerId: e.pointerId, x: e.clientX, y: e.clientY, target };
    if (e.pointerType !== 'mouse') {
      pending.timer = window.setTimeout(() => activate(pending), LONG_PRESS);
    }
    setG(pending);
  };

  const activate = (pg: Extract<Gesture, { kind: 'pending' }>) => {
    // Capture only once a gesture starts, so plain clicks still reach cards.
    try {
      box.current?.setPointerCapture(pg.pointerId);
    } catch {
      /* pointer already released */
    }
    if (pg.target === 'empty') {
      if (!p.onCreate) return setG({ kind: 'none' });
      const { col, minute } = toCell(pg.x, pg.y);
      const start = snap(minute - 15);
      setG({ kind: 'create', col, start, end: start + 30 });
    } else {
      if (!p.onMove) return setG({ kind: 'none' });
      setG({ kind: 'move', id: pg.target, dx: 0, dy: 0, x: pg.x, y: pg.y });
    }
    navigator.vibrate?.(8);
  };

  const onMove = (e: React.PointerEvent) => {
    const cur = gRef.current;
    if (cur.kind === 'pending') {
      const moved = Math.hypot(e.clientX - cur.x, e.clientY - cur.y) > 6;
      if (!moved) return;
      if (cur.pointer === 'mouse') activate(cur);
      else {
        clearTimeout(cur.timer); // a scroll, not a long-press
        setG({ kind: 'none' });
      }
    } else if (cur.kind === 'create') {
      const end = snap(toCell(e.clientX, e.clientY).minute);
      setG({ ...cur, end: end <= cur.start ? cur.start + SNAP : end });
    } else if (cur.kind === 'move') {
      setG({ ...cur, dx: e.clientX - cur.x, dy: e.clientY - cur.y });
    }
  };

  const onUp = (e: React.PointerEvent) => {
    const cur = gRef.current;
    if (cur.kind === 'pending') {
      clearTimeout(cur.timer);
      // Mouse click on empty space → create a 30 min task there.
      if (cur.pointer === 'mouse' && cur.target === 'empty' && p.onCreate) {
        const { col, minute } = toCell(e.clientX, e.clientY);
        p.onCreate(col, snap(minute - 15), 30);
      }
    } else if (cur.kind === 'create') {
      p.onCreate?.(cur.col, cur.start, cur.end - cur.start);
    } else if (cur.kind === 'move') {
      const item = p.items.find((i) => i.id === cur.id);
      suppressClick.current = true;
      if (item) {
        const { colW } = geom();
        const col = Math.min(Math.max(item.column + Math.round(cur.dx / colW), 0), columns - 1);
        const start = snap(item.startMinute + cur.dy / mh);
        if (col !== item.column || start !== item.startMinute) p.onMove?.(item.id, col, start);
      }
    }
    setG({ kind: 'none' });
  };

  const lanes = assignLanes(p.items);
  const nowMin = p.now ? p.now.getHours() * 60 + p.now.getMinutes() : 0;
  const colPct = (c: number) => `calc(${LABEL_W}px + (100% - ${LABEL_W}px) * ${c / columns})`;
  const colW = `calc((100% - ${LABEL_W}px) / ${columns})`;

  return (
    <div
      ref={box}
      style={{ position: 'relative', height: 24 * hh + 16, userSelect: 'none', touchAction: 'pan-y' }}
      onPointerMove={onMove}
      onPointerUp={onUp}
      onPointerCancel={() => setG({ kind: 'none' })}
      onClickCapture={(e) => {
        if (suppressClick.current) {
          suppressClick.current = false;
          e.stopPropagation();
          e.preventDefault();
        }
      }}
    >
      {/* Grid */}
      {Array.from({ length: 25 }, (_, h) => (
        <div key={h}>
          <div style={{ position: 'absolute', left: LABEL_W, right: 0, top: TOP + h * hh, borderTop: `0.5px solid ${T.outline}` }} />
          {h < 24 && (
            <span className="mono" style={{ position: 'absolute', left: 0, width: LABEL_W - 8, top: TOP + h * hh - 6, textAlign: 'right', fontSize: 10, color: T.textSecondary }}>
              {Fmt.hour(h, p.use24h)}
            </span>
          )}
        </div>
      ))}
      {columns > 1 &&
        Array.from({ length: columns + 1 }, (_, c) => (
          <div key={`c${c}`} style={{ position: 'absolute', top: TOP, height: 24 * hh, left: colPct(c), borderLeft: `0.5px solid ${T.outline}` }} />
        ))}

      {/* Empty-space gesture layer */}
      <div
        aria-hidden
        style={{ position: 'absolute', left: LABEL_W, right: 0, top: TOP, height: 24 * hh, cursor: p.onCreate ? 'cell' : undefined }}
        onPointerDown={(e) => begin(e, 'empty')}
      />

      {g.kind === 'create' && (
        <div
          className="mono"
          style={{
            position: 'absolute', left: `calc(${colPct(g.col)} + 2px)`, width: `calc(${colW} - 4px)`,
            top: TOP + g.start * mh, height: (g.end - g.start) * mh, borderRadius: 12, padding: 6, fontSize: 11,
            background: `${T.coral}40`, border: `1px solid ${T.coral}`, pointerEvents: 'none',
          }}
        >
          {Fmt.minute(g.start, p.use24h)} – {Fmt.minute(g.end, p.use24h)}
        </div>
      )}

      {p.items.map((it) => {
        const [lane, count] = lanes.get(it.id) ?? [0, 1];
        const n = Math.max(count, 1);
        const moving = g.kind === 'move' && g.id === it.id;
        return (
          <div
            key={it.id}
            style={{
              position: 'absolute',
              left: `calc(${colPct(it.column)} + ${colW} * ${lane / n} + 2px)`,
              width: `calc(${colW} / ${n} - 4px)`,
              top: TOP + it.startMinute * mh + 1,
              height: Math.max(it.durationMin, 15) * mh - 2,
              transform: moving ? `translate(${g.dx}px, ${g.dy}px)` : undefined,
              opacity: moving ? 0.85 : 1,
              zIndex: moving ? 5 : 1,
              cursor: p.onMove && it.draggable !== false ? 'grab' : undefined,
              touchAction: moving ? 'none' : 'pan-y',
            }}
            onPointerDown={it.draggable === false ? undefined : (e) => begin(e, it.id)}
          >
            {it.content}
          </div>
        );
      })}

      {p.now && p.nowColumn != null && (
        <div aria-hidden style={{ position: 'absolute', left: 0, right: 0, top: TOP + nowMin * mh - 10, height: 20, pointerEvents: 'none', zIndex: 6 }}>
          <div style={{ position: 'absolute', top: 9, height: 2, background: T.ice, left: colPct(p.nowColumn), width: columns === 1 ? undefined : colW, right: columns === 1 ? 0 : undefined }} />
          <span className="mono" style={{ position: 'absolute', left: 0, top: 0, padding: '3px 5px', borderRadius: 999, background: T.ice, color: T.textInverse, fontSize: 10 }}>
            {Fmt.time(p.now, p.use24h)}
          </span>
        </div>
      )}

      <div data-rail-anchor style={{ position: 'absolute', left: 0, top: TOP + (p.anchorMinute ?? 480) * mh, width: 1, height: 1 }} />
    </div>
  );
}
