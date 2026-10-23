import type { RegionBounds } from '../config/env.validation';

/** True when a coordinate pair is either fully absent or fully present. */
export function hasCompleteCoordinates(lat?: number | null, lng?: number | null) {
  return (lat === undefined || lat === null) === (lng === undefined || lng === null);
}

export function isWithinBounds(lat: number, lng: number, b: RegionBounds) {
  return lat >= b.minLat && lat <= b.maxLat && lng >= b.minLng && lng <= b.maxLng;
}

/**
 * Coordinates are stored at ~1 m precision (5 decimals): enough to find a building, without
 * keeping the device's full-precision fix.
 */
export function roundCoordinate(value: number) {
  return Math.round(value * 1e5) / 1e5;
}
