/** Colour tokens (spec §2.2) — same values as the app; CSS mirrors them as variables. */
export const T = {
  bg: '#161616',
  surface: '#222222',
  surfaceHigh: '#2C2C2C',
  outline: '#3A3A3A',
  textPrimary: '#F4F1EA',
  textSecondary: '#A3A09A',
  textInverse: '#161616',
  sage: '#C9D9CF',
  sageDeep: '#8FAF9C',
  coral: '#F2705E',
  coralSoft: '#F7A497',
  periwinkle: '#6E72F6',
  periSoft: '#B9BBFB',
  ice: '#BFEAF2',
  sun: '#F6C945',
  mint: '#9EDFB8',
  white: '#FFFFFF',
  dayPerfect: '#4ADE80',
  dayHigh: '#A3E635',
  dayMid: '#F6C945',
  dayLow: '#FB923C',
  dayMissed: '#F25555',
  dayEmpty: '#2C2C2C',
} as const;

/** Task colours, picker order (ARGB ints, identical to the app). */
export const TaskColors = {
  all: [0xfff2705e, 0xfff6c945, 0xff9edfb8, 0xffbfeaf2, 0xff6e72f6, 0xffc9d9cf, 0xffc7a6f2, 0xffe6d3b3],
  names: ['Coral', 'Sun', 'Mint', 'Ice', 'Periwinkle', 'Sage', 'Lilac', 'Sand'],
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
