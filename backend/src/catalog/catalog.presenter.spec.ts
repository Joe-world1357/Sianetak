import { PricingType, Service } from './catalog.entities';
import { presentPricing } from './catalog.presenter';

const service = (overrides: Partial<Service>) =>
  ({
    pricingType: PricingType.InspectionRequired,
    priceMinMinor: null,
    priceMaxMinor: null,
    currency: 'EGP',
    ...overrides,
  }) as Service;

describe('presentPricing', () => {
  it('returns inspection-required guidance without amounts', () => {
    expect(presentPricing(service({}))).toEqual({
      type: 'inspection_required',
      currency: 'EGP',
    });
  });

  it('returns an approved indicative range in minor units', () => {
    expect(
      presentPricing(
        service({
          pricingType: PricingType.Indicative,
          priceMinMinor: 15000,
          priceMaxMinor: 30000,
        }),
      ),
    ).toEqual({ type: 'indicative', currency: 'EGP', minMinor: 15000, maxMinor: 30000 });
  });

  it.each([
    [null, 30000],
    [15000, null],
    [30000, 15000],
    [0, 100],
  ])('falls back to inspection-required for an inconsistent range (%p, %p)', (min, max) => {
    expect(
      presentPricing(
        service({ pricingType: PricingType.Indicative, priceMinMinor: min, priceMaxMinor: max }),
      ).type,
    ).toBe('inspection_required');
  });
});
