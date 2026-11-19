import { Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { MOCK_LISTINGS } from '../../mock-listings';
import { CompareService } from '../../services/compare.service';
import { IconComponent } from '../icon/icon';

/**
 * Dedicated comparison screen, opened from the search header's Compare tray.
 * Analytics showed Compare getting heavy use while the button itself did
 * nothing (vision-board-prototype/.../property-card had no handler) - this
 * is the real destination that was missing.
 */
@Component({
  selector: 'app-compare-view',
  standalone: true,
  imports: [IconComponent, RouterLink],
  templateUrl: './compare-view.html',
  styleUrl: './compare-view.scss',
})
export class CompareViewComponent {
  protected readonly compare = inject(CompareService);

  protected readonly listings = computed(() =>
    this.compare
      .comparedIds()
      .map((id) => MOCK_LISTINGS.find((l) => l.id === id))
      .filter((l) => !!l),
  );

  formatPrice(price: number): string {
    return price.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
  }

  remove(id: string): void {
    this.compare.remove(id);
  }

  clearAll(): void {
    this.compare.clear();
  }
}
