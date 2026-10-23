import { maskPhone, normalizeEgyptMobile, toAsciiDigits } from './egypt-phone';

describe('normalizeEgyptMobile', () => {
  it.each([
    ['01012345678', '+201012345678'],
    ['+201112345678', '+201112345678'],
    ['00201212345678', '+201212345678'],
    ['201512345678', '+201512345678'],
    ['010 1234 5678', '+201012345678'],
    ['010-1234-5678', '+201012345678'],
    ['٠١٠١٢٣٤٥٦٧٨', '+201012345678'],
    ['۰۱۰۱۲۳۴۵۶۷۸', '+201012345678'],
  ])('normalizes %s', (input, expected) => {
    expect(normalizeEgyptMobile(input)).toBe(expected);
  });

  it.each([
    '',
    '0101234567', // too short
    '010123456789', // too long
    '01312345678', // 013 is not a mobile prefix
    '0221234567', // Cairo landline
    '+966512345678', // non-Egyptian
    'abcdefghijk',
    '+20 10 1234 567a',
  ])('rejects %s', (input) => {
    expect(normalizeEgyptMobile(input)).toBeNull();
  });

  it('rejects non-string input', () => {
    expect(normalizeEgyptMobile(1012345678)).toBeNull();
    expect(normalizeEgyptMobile(undefined)).toBeNull();
  });
});

describe('toAsciiDigits', () => {
  it('converts Arabic-Indic digits and leaves others', () => {
    expect(toAsciiDigits('رمز ١٢٣٤٥٦')).toBe('رمز 123456');
  });
});

describe('maskPhone', () => {
  it('hides the middle digits', () => {
    expect(maskPhone('+201012345678')).toBe('+2010*****678');
  });
});
