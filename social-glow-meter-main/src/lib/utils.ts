import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Calculate Blood Alcohol Concentration (BAC) based on official formula.
 * @param drinks - Array of drinks consumed.
 * @param weight - Weight of the user in kilograms.
 * @param gender - Gender of the user ('male' or 'female').
 * @param atTime - Optional timestamp to calculate BAC at a specific time.
 * @returns The calculated BAC value.
 */
export function calculateBAC(
  drinks: { alcohol_grams: number; created_at: string }[],
  weight: number,
  gender: 'male' | 'female',
  atTime?: number
): number {
  const now = atTime || Date.now();
  const k = gender === 'female' ? 0.6 : 0.7;
  const alcoholDrinks = drinks.filter(d => d.alcohol_grams > 0);
  if (alcoholDrinks.length === 0) return 0;

  const firstDrinkTime = Math.min(...alcoholDrinks.map(d => new Date(d.created_at).getTime()));
  const hoursSinceFirst = (now - firstDrinkTime) / (1000 * 60 * 60);
  const totalAlcoholGrams = alcoholDrinks.reduce((sum, d) => sum + d.alcohol_grams, 0);
  const rawBAC = totalAlcoholGrams / (weight * k);
  return Math.max(0, parseFloat((rawBAC - 0.15 * hoursSinceFirst).toFixed(2)));
}
