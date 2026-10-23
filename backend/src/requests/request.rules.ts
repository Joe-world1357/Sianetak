/**
 * Pure request rules: references, appointment slots in the service time zone, and the
 * fingerprint used to recognise a retried submission.
 */
import { createHash, randomInt } from 'node:crypto';
import type { SlotWindow } from '../config/env.validation';

export const DESCRIPTION_MIN_LENGTH = 10;
export const DESCRIPTION_MAX_LENGTH = 1000;

/** Crockford base32 without I, L, O, U: unambiguous when read aloud or typed. */
const REFERENCE_ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

export interface ZonedParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
}

export function zonedParts(instant: Date, timeZone: string): ZonedParts {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).formatToParts(instant);
  const get = (type: string) => Number(parts.find((p) => p.type === type)?.value);
  return {
    year: get('year'),
    month: get('month'),
    day: get('day'),
    hour: get('hour'),
    minute: get('minute'),
  };
}

/** Offset of `timeZone` from UTC at `instant`, in milliseconds. */
function zoneOffsetMs(instant: number, timeZone: string) {
  const p = zonedParts(new Date(instant), timeZone);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute);
  return asUtc - Math.floor(instant / 60_000) * 60_000;
}

/** The UTC instant of a local wall-clock time in `timeZone` (DST-aware). */
export function zonedTimeToUtc(
  year: number,
  month: number,
  day: number,
  minuteOfDay: number,
  timeZone: string,
): Date {
  const wall = Date.UTC(year, month - 1, day, 0, minuteOfDay);
  let guess = wall - zoneOffsetMs(wall, timeZone);
  // A second pass settles instants that cross a DST change.
  guess = wall - zoneOffsetMs(guess, timeZone);
  return new Date(guess);
}

export interface Slot {
  from: Date;
  to: Date;
}

export interface SlotRules {
  timeZone: string;
  windows: SlotWindow[];
  leadMinutes: number;
  daysAhead: number;
}

/** Bookable windows from today (local) through `daysAhead` days, starting after the lead time. */
export function buildSlots(now: Date, rules: SlotRules): Slot[] {
  const today = zonedParts(now, rules.timeZone);
  const earliest = now.getTime() + rules.leadMinutes * 60_000;
  const slots: Slot[] = [];
  for (let i = 0; i <= rules.daysAhead; i++) {
    const date = new Date(Date.UTC(today.year, today.month - 1, today.day + i));
    const [y, m, d] = [date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate()];
    for (const w of rules.windows) {
      const from = zonedTimeToUtc(y, m, d, w.startMinute, rules.timeZone);
      if (from.getTime() < earliest) continue;
      slots.push({ from, to: zonedTimeToUtc(y, m, d, w.endMinute, rules.timeZone) });
    }
  }
  return slots;
}

/** True only for a slot the server currently offers; anything else is INVALID_SCHEDULE. */
export function isOfferedSlot(from: Date, to: Date, now: Date, rules: SlotRules) {
  return buildSlots(now, rules).some(
    (s) => s.from.getTime() === from.getTime() && s.to.getTime() === to.getTime(),
  );
}

/** `SN-YYMMDD-XXXXX` using the service-local date, e.g. `SN-261023-7K4QZ`. */
export function generateReference(now: Date, timeZone: string, random = randomInt) {
  const p = zonedParts(now, timeZone);
  const date = `${String(p.year % 100).padStart(2, '0')}${String(p.month).padStart(2, '0')}${String(p.day).padStart(2, '0')}`;
  let suffix = '';
  for (let i = 0; i < 5; i++) suffix += REFERENCE_ALPHABET[random(REFERENCE_ALPHABET.length)];
  return `SN-${date}-${suffix}`;
}

/** Stable JSON (sorted keys) so equal payloads always hash equally. */
function canonical(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .filter(([, v]) => v !== undefined)
        .sort(([a], [b]) => (a < b ? -1 : 1))
        .map(([k, v]) => [k, canonical(v)]),
    );
  }
  return value;
}

export function fingerprint(payload: unknown) {
  return createHash('sha256')
    .update(JSON.stringify(canonical(payload)))
    .digest('hex');
}
