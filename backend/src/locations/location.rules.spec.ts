import { hasCompleteCoordinates, isWithinBounds, roundCoordinate } from './location.rules';

const aswan = { minLat: 22.0, minLng: 31.3, maxLat: 24.8, maxLng: 33.7 };

describe('location rules', () => {
  it('requires coordinates as a pair', () => {
    expect(hasCompleteCoordinates(undefined, undefined)).toBe(true);
    expect(hasCompleteCoordinates(24.09, 32.9)).toBe(true);
    expect(hasCompleteCoordinates(24.09, undefined)).toBe(false);
    expect(hasCompleteCoordinates(null, 32.9)).toBe(false);
  });

  it('accepts Aswan and rejects Cairo with the default bounds', () => {
    expect(isWithinBounds(24.0889, 32.8998, aswan)).toBe(true);
    expect(isWithinBounds(30.0444, 31.2357, aswan)).toBe(false);
  });

  it('rounds coordinates to about one metre', () => {
    expect(roundCoordinate(24.088912345)).toBe(24.08891);
  });
});
