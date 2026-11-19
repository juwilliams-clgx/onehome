import { Component, inject, signal } from '@angular/core';
import { MOCK_LISTINGS } from '../../mock-listings';
import { Listing } from '../../models/listing.model';
import { CapacityLimitModalComponent } from '../capacity-limit-modal/capacity-limit-modal';
import { IconComponent } from '../icon/icon';

/**
 * Pixel-accurate recreation of the real UAT "Browse Properties" cards page
 * (aotf-uat.corelogic.com/en-US/properties/list), used purely as a realistic
 * staging ground for the AOTF-18942 capacity-limit modal. Do not add any
 * Future-state redesign work here - that belongs in the rest of the app.
 */
@Component({
  selector: 'app-uat-property-list',
  standalone: true,
  imports: [CapacityLimitModalComponent, IconComponent],
  templateUrl: './uat-property-list.html',
  styleUrl: './uat-property-list.scss',
})
export class UatPropertyListComponent {
  protected readonly listings = MOCK_LISTINGS;
  protected readonly activeCapacityList = signal<string | null>(null);

  propertyType(): string {
    return 'Single Family Residence';
  }

  onFavorite(listing: Listing, event: Event): void {
    event.stopPropagation();
    // Demo assumption: Favorites is already at its 20,000 item limit.
    this.activeCapacityList.set('Favorites');
  }

  onDislike(listing: Listing, event: Event): void {
    event.stopPropagation();
    // Demo assumption: Dislikes is already at its 20,000 item limit.
    this.activeCapacityList.set('Dislikes');
  }

  closeCapacityModal(): void {
    this.activeCapacityList.set(null);
  }

  formatPrice(price: number): string {
    return price.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
  }
}
