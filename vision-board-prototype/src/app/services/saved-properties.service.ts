import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class SavedPropertiesService {
  private readonly favoriteIds = signal(new Set<string>());
  private readonly dislikedIds = signal(new Set<string>());

  isFavorited(id: string): boolean {
    return this.favoriteIds().has(id);
  }

  isDisliked(id: string): boolean {
    return this.dislikedIds().has(id);
  }

  toggleFavorite(id: string): void {
    this.favoriteIds.update((ids) => {
      const next = new Set(ids);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
    // A listing can't be both favorited and disliked at the same time.
    this.dislikedIds.update((ids) => {
      if (!ids.has(id)) {
        return ids;
      }
      const next = new Set(ids);
      next.delete(id);
      return next;
    });
  }

  toggleDislike(id: string): void {
    this.dislikedIds.update((ids) => {
      const next = new Set(ids);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
    this.favoriteIds.update((ids) => {
      if (!ids.has(id)) {
        return ids;
      }
      const next = new Set(ids);
      next.delete(id);
      return next;
    });
  }
}
