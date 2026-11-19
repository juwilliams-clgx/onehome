import { Injectable, signal } from '@angular/core';

/**
 * Detects the buyer's approximate location from their IP address so the
 * search bar can default to it ("Lakewood, CO 80227") instead of a generic
 * placeholder, the way the collapsed saved-search pill does in production.
 * Best-effort: a blocked/offline/rate-limited lookup just leaves
 * `displayLocation` null and the search header falls back to a placeholder.
 */
@Injectable({ providedIn: 'root' })
export class LocationService {
  readonly displayLocation = signal<string | null>(null);
  readonly isLoading = signal(true);

  constructor() {
    this.detect();
  }

  private async detect(): Promise<void> {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 4000);
      const response = await fetch('https://ipapi.co/json/', { signal: controller.signal });
      clearTimeout(timeout);
      if (!response.ok) {
        throw new Error(`Geolocation lookup failed: ${response.status}`);
      }
      const data: { city?: string; region_code?: string; postal?: string } = await response.json();
      if (data.city && data.region_code) {
        const zip = data.postal ? ` ${data.postal}` : '';
        this.displayLocation.set(`${data.city}, ${data.region_code}${zip}`);
      }
    } catch {
      // Network blocked, API down, or rate-limited - the header just shows
      // its placeholder instead; this is a nice-to-have default, not a
      // required feature.
      this.displayLocation.set(null);
    } finally {
      this.isLoading.set(false);
    }
  }
}
