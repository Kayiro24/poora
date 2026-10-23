/** Colour tokens (spec §2.2) — same values as the app; CSS mirrors them as variables. */
export const T = {
  bg: '#151517',
  surface: '#212124',
  surfaceHigh: '#2B2B2F',
  outline: '#39393F',
  textPrimary: '#F3F0EA',
  textSecondary: '#A4A19C',
  textInverse: '#151517',
  sage: '#C6DAD2',
  sageDeep: '#86AD9E',
  coral: '#EF7867',
  coralSoft: '#F4AA9E',
  periwinkle: '#7679F0',
  periSoft: '#BDBFF8',
  ice: '#C3E7EF',
  sun: '#F2CA58',
  mint: '#A2DDC0',
  white: '#FFFFFF',
  /** Warm off-white of the focus clock face. */
  paper: '#F7F4EE',
  dayPerfect: '#4ADE80',
  dayHigh: '#A3E635',
  dayMid: '#F2CA58',
  dayLow: '#FB923C',
  dayMissed: '#F25555',
  dayEmpty: '#2B2B2F',
} as const;

/** Task colours, picker order (ARGB ints, identical to the app). */
export const TaskColors = {
  all: [0xffef7867, 0xfff2ca58, 0xffa2ddc0, 0xffc3e7ef, 0xff7679f0, 0xffc6dad2, 0xffc9abee, 0xffe7d6ba],
  names: ['Coral', 'Sun', 'Mint', 'Ice', 'Periwinkle', 'Sage', 'Lilac', 'Sand'],
  /** The palette before its shade shift → today's swatch (applied on load and import). */
  legacy: new Map<number, number>([
    [0xfff2705e, 0xffef7867], // coral
    [0xfff6c945, 0xfff2ca58], // sun
    [0xff9edfb8, 0xffa2ddc0], // mint
    [0xffbfeaf2, 0xffc3e7ef], // ice
    [0xff6e72f6, 0xff7679f0], // periwinkle
    [0xffc9d9cf, 0xffc6dad2], // sage
    [0xffc7a6f2, 0xffc9abee], // lilac
    [0xffe6d3b3, 0xffe7d6ba], // sand
  ]),
  migrate: (argb: number) => TaskColors.legacy.get(argb >>> 0) ?? argb,
  nameOf(argb: number) {
    const i = TaskColors.all.indexOf(argb >>> 0);
    return i < 0 ? 'Custom' : TaskColors.names[i];
  },
};

/** ARGB int → CSS hex. */
export const css = (argb: number) => `#${((argb >>> 0) & 0xffffff).toString(16).padStart(6, '0')}`;

/** Translucent version of a hex colour. */
export const alpha = (hex: string, a: number) =>
  `${hex}${Math.round(a * 255).toString(16).padStart(2, '0')}`;

/**
 * Category donut palette: deeper steps of the brand hues, validated on the
 * dark surface (same as the app). Fixed order; 7+ categories fold to Other.
 */
export const categoryPalette = ['#E8604E', '#2E8CB0', '#B8861A', '#8A5FD0', '#2F9C6E', '#5C66E8'];
export const otherColor = '#6B6B66';
