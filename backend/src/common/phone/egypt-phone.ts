/**
 * Egyptian mobile number handling.
 *
 * Accepts the common ways people type a number — `01012345678`, `+201012345678`,
 * `00201012345678`, `201012345678`, with spaces/dashes, and Arabic-Indic or Persian digits —
 * and normalizes to E.164 (`+201XXXXXXXXX`). Egyptian mobile prefixes are 010, 011, 012, 015.
 */

const ARABIC_INDIC = '٠١٢٣٤٥٦٧٨٩';
const EXTENDED_ARABIC_INDIC = '۰۱۲۳۴۵۶۷۸۹';

/** Converts Arabic-Indic / Persian digits to ASCII digits; other characters are kept. */
export function toAsciiDigits(input: string): string {
  return input.replace(/[٠-٩۰-۹]/g, (ch) => {
    const i = ARABIC_INDIC.indexOf(ch);
    return String(i >= 0 ? i : EXTENDED_ARABIC_INDIC.indexOf(ch));
  });
}

const E164_EGYPT_MOBILE = /^\+201[0125]\d{8}$/;

/** Returns the E.164 form, or `null` if the input is not a valid Egyptian mobile number. */
export function normalizeEgyptMobile(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  let s = toAsciiDigits(input).replace(/[\s\-().]/g, '');
  if (s.startsWith('00')) s = `+${s.slice(2)}`;
  if (s.startsWith('20') && s.length === 12) s = `+${s}`;
  if (s.startsWith('01') && s.length === 11) s = `+2${s}`;
  return E164_EGYPT_MOBILE.test(s) ? s : null;
}

/** Masks a phone for display or diagnostics: `+2010*****678`. Never log the full number. */
export function maskPhone(e164: string): string {
  if (e164.length < 8) return '***';
  return `${e164.slice(0, 5)}${'*'.repeat(e164.length - 8)}${e164.slice(-3)}`;
}
