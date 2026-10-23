// Parity with test/features/focus/strict_mode_test.dart.
import { afterEach, beforeAll, beforeEach, describe, expect, test, vi } from 'vitest';
import { db } from '../../../core/db/store';
import { defaultFocus } from '../domain/timerEngine';
import { FocusController, isLocked, useFocus } from './focusController';

describe('strict mode', () => {
  // Node test environment: the controller only needs timers and visibility.
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.stubGlobal('document', { hidden: false, addEventListener() {} });
  });
  beforeEach(() => db().wipe());
  afterEach(() => FocusController.discard());

  test('strict focus cannot be paused, skipped or ended early', () => {
    FocusController.start(defaultFocus, null, true);
    const s = () => useFocus.getState().session!;
    expect(isLocked(s())).toBe(true);
    FocusController.pause();
    expect(s().timer.pausedAt).toBeNull();
    FocusController.skip();
    expect(s().timer.phase).toBe('focus');
    FocusController.end();
    expect(useFocus.getState().session).not.toBeNull();
    expect(useFocus.getState().summary).toBeNull();
  });

  test('a locked session resumes by itself after the tab is closed', () => {
    FocusController.start(defaultFocus, null, true);
    expect(db().focusState?.strict).toBe(true);
    FocusController.discard(); // the tab closed: live state stays in storage
    FocusController.checkRecovery();
    expect(useFocus.getState().recovery).toBeNull();
    expect(isLocked(useFocus.getState().session)).toBe(true);
  });

  test('without strict mode, ending early works', () => {
    FocusController.start(defaultFocus, null, false);
    FocusController.end();
    expect(useFocus.getState().session).toBeNull();
    expect(useFocus.getState().summary?.endedEarly).toBe(true);
  });
});
