import { Component, EventEmitter, Input, Output, computed, inject, signal } from '@angular/core';
import { Listing } from '../../models/listing.model';
import { IconComponent } from '../icon/icon';
import { SavedPropertiesService } from '../../services/saved-properties.service';
import { CompareService } from '../../services/compare.service';

@Component({
  selector: 'app-property-card',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './property-card.html',
  styleUrl: './property-card.scss',
})
export class PropertyCardComponent {
  @Input({ required: true }) listing!: Listing;
  /** Emitted on hover so the map can highlight this listing's pin. */
  @Output() mapHover = new EventEmitter<Listing | null>();
  /** Emitted on click of the map-pin action so the map can center/open this listing's pin. */
  @Output() mapFocus = new EventEmitter<Listing>();

  private readonly saved = inject(SavedPropertiesService);
  protected readonly compare = inject(CompareService);

  protected readonly activeImage = signal(0);

  protected readonly isFavorited = computed(() => this.saved.isFavorited(this.listing.id));
  protected readonly isDisliked = computed(() => this.saved.isDisliked(this.listing.id));
  protected readonly isCompared = computed(() => this.compare.isCompared(this.listing.id));

  protected readonly freshnessLabel = computed(() => {
    const { priceDropped, daysOnMarket } = this.listing;
    if (priceDropped) {
      return 'PRICE DROP';
    }
    if (daysOnMarket <= 2) {
      return 'NEW';
    }
    return null;
  });

  onMouseEnter(): void {
    // Netflix-style preview: jump straight to the second photo on hover.
    if (this.listing.images.length > 1) {
      this.activeImage.set(1);
    }
  }

  onMouseLeave(): void {
    this.activeImage.set(0);
  }

  prevImage(event: Event): void {
    event.stopPropagation();
    const len = this.listing.images.length;
    this.activeImage.update((i) => (i - 1 + len) % len);
  }

  nextImage(event: Event): void {
    event.stopPropagation();
    const len = this.listing.images.length;
    this.activeImage.update((i) => (i + 1) % len);
  }

  toggleFavorite(event: Event): void {
    event.stopPropagation();
    this.saved.toggleFavorite(this.listing.id);
  }

  toggleDislike(event: Event): void {
    event.stopPropagation();
    this.saved.toggleDislike(this.listing.id);
  }

  toggleCompare(event: Event): void {
    event.stopPropagation();
    this.compare.toggle(this.listing.id);
  }

  onMapIconEnter(): void {
    this.mapHover.emit(this.listing);
  }

  onMapIconLeave(): void {
    this.mapHover.emit(null);
  }

  showOnMap(event: Event): void {
    event.stopPropagation();
    this.mapFocus.emit(this.listing);
  }

  openDetail(): void {
    window.open(`/property/${this.listing.id}`, '_blank');
  }

  formatPrice(price: number): string {
    return price.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
  }
}
