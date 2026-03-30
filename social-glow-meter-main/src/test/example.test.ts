import { describe, it, expect } from "vitest";
import { calculateBAC } from '@/lib/utils';

describe("example", () => {
  it("should pass", () => {
    expect(true).toBe(true);
  });
});

describe('calculateBAC', () => {
  it('calculates BAC for a male, 70kg, 182cm, 18 years old', () => {
    const drinks = [
      { alcohol_grams: 20, created_at: new Date(Date.now() - 5 * 60 * 1000).toISOString() }, // Bière 50cl à 5%
      { alcohol_grams: 14.4, created_at: new Date(Date.now() - 1 * 60 * 1000).toISOString() }, // Vin blanc 150ml à 12%
    ];
    const weight = 70; // kg
    const gender = 'male';

    const bac = calculateBAC(drinks, weight, gender);
    console.log('Calculated BAC:', bac);

    // Expected BAC: ~0.69 g/L
    expect(bac).toBeCloseTo(0.69, 2);
  });
});
