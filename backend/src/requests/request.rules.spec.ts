import {
  buildSlots,
  fingerprint,
  generateReference,
  isOfferedSlot,
  SlotRules,
  zonedTimeToUtc,
} from './request.rules';

const rules: SlotRules = {
  timeZone: 'Africa/Cairo',
  windows: [
    { startMinute: 9 * 60, endMinute: 12 * 60 },
    { startMinute: 18 * 60, endMinute: 21 * 60 },
  ],
  leadMinutes: 120,
  daysAhead: 2,
};

describe('zonedTimeToUtc', () => {
  it('converts Cairo wall-clock time in winter (UTC+2) and summer (UTC+3)', () => {
    expect(zonedTimeToUtc(2026, 1, 15, 9 * 60, 'Africa/Cairo').toISOString()).toBe(
      '2026-01-15T07:00:00.000Z',
    );
    expect(zonedTimeToUtc(2026, 7, 15, 9 * 60, 'Africa/Cairo').toISOString()).toBe(
      '2026-07-15T06:00:00.000Z',
    );
  });
});

describe('buildSlots', () => {
  it('offers windows from today through daysAhead, skipping those inside the lead time', () => {
    // 10:30 Cairo time on 15 Jan 2026: today's 09:00 slot is past, 18:00 is open.
    const now = new Date('2026-01-15T08:30:00Z');
    const slots = buildSlots(now, rules).map((s) => s.from.toISOString());
    expect(slots).toEqual([
      '2026-01-15T16:00:00.000Z',
      '2026-01-16T07:00:00.000Z',
      '2026-01-16T16:00:00.000Z',
      '2026-01-17T07:00:00.000Z',
      '2026-01-17T16:00:00.000Z',
    ]);
  });

  it('applies the lead time to a slot that starts soon', () => {
    const now = new Date('2026-01-15T14:30:00Z'); // 16:30 Cairo, 18:00 slot is 90 min away
    expect(buildSlots(now, rules)[0].from.toISOString()).toBe('2026-01-16T07:00:00.000Z');
  });
});

describe('isOfferedSlot', () => {
  const now = new Date('2026-01-15T08:30:00Z');

  it('accepts exactly an offered slot', () => {
    expect(
      isOfferedSlot(new Date('2026-01-16T07:00:00Z'), new Date('2026-01-16T10:00:00Z'), now, rules),
    ).toBe(true);
  });

  it.each([
    ['past', '2026-01-15T07:00:00Z', '2026-01-15T10:00:00Z'],
    ['beyond the booking horizon', '2026-01-20T07:00:00Z', '2026-01-20T10:00:00Z'],
    ['not aligned to a window', '2026-01-16T07:30:00Z', '2026-01-16T10:30:00Z'],
    ['wrong length', '2026-01-16T07:00:00Z', '2026-01-16T09:00:00Z'],
  ])('rejects a slot that is %s', (_label, from, to) => {
    expect(isOfferedSlot(new Date(from), new Date(to), now, rules)).toBe(false);
  });
});

describe('generateReference', () => {
  it('uses the local date and an unambiguous alphabet', () => {
    // 23:30 UTC on 23 Oct is already 24 Oct in Cairo (UTC+3 in summer time).
    let i = 0;
    const ref = generateReference(new Date('2026-10-23T22:30:00Z'), 'Africa/Cairo', () => i++);
    expect(ref).toMatch(/^SN-2610(23|24)-01234$/);
    expect(generateReference(new Date(), 'Africa/Cairo')).toMatch(
      /^SN-\d{6}-[0-9ABCDEFGHJKMNPQRSTVWXYZ]{5}$/,
    );
  });
});

describe('fingerprint', () => {
  it('ignores key order and undefined fields', () => {
    expect(fingerprint({ a: 1, b: { c: 2, d: undefined } })).toBe(
      fingerprint({ b: { c: 2 }, a: 1 }),
    );
    expect(fingerprint({ a: 1 })).not.toBe(fingerprint({ a: 2 }));
  });
});
