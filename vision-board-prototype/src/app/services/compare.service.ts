import { Injectable, computed, signal } from '@angular/core';

/**
 * Tracks which listings the buyer has added to Compare. Real analytics
 * showed Compare getting heavy use while the button itself was a visual stub
 * (vision-board-prototype/.../property-card has no handler on it) - this
 * makes it a real, working feature: toggle from any card, badge count in the
 * header, and a dedicated comparison view (see CompareViewComponent).
 */
@Injectable({ providedIn: 'root' })
export class CompareService {
  private readonly ids = signal<Set<string>>(new Set());

  readonly count = computed(() => this.ids().size);

  isCompared(listingId: string): boolean {
    return this.ids().has(listingId);
  }

  toggle(listingId: string): void {
    this.ids.update((set) => {
      const next = new Set(set);
      if (next.has(listingId)) {
        next.delete(listingId);
      } else {
        next.add(listingId);
      }
      return next;
    });
  }

  remove(listingId: string): void {
    this.ids.update((set) => {
      const next = new Set(set);
      next.delete(listingId);
      return next;
    });
  }

  clear(): void {
    this.ids.set(new Set());
  }

  readonly comparedIds = computed(() => Array.from(this.ids()));
}
