import { AfterViewInit, Component, ElementRef, Input, OnDestroy, ViewChild } from '@angular/core';
import * as L from 'leaflet';
import { Listing } from '../../models/listing.model';

@Component({
  selector: 'app-property-map',
  standalone: true,
  templateUrl: './property-map.html',
  styleUrl: './property-map.scss',
})
export class PropertyMapComponent implements AfterViewInit, OnDestroy {
  @Input({ required: true }) listings: Listing[] = [];

  @ViewChild('mapContainer', { static: true }) private mapContainer!: ElementRef<HTMLDivElement>;

  private map?: L.Map;
  private readonly markersById = new Map<string, L.Marker>();
  private highlightedId: string | null = null;

  ngAfterViewInit(): void {
    const map = L.map(this.mapContainer.nativeElement, { scrollWheelZoom: true });
    this.map = map;

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19,
    }).addTo(map);

    const points: L.LatLng[] = [];

    for (const listing of this.listings) {
      const icon = L.divIcon({
        className: 'map-price-pin',
        html: `<span>${this.formatPrice(listing.price)}</span>`,
        iconSize: [0, 0],
      });

      const marker = L.marker([listing.lat, listing.lng], { icon }).addTo(map);
      marker.bindPopup(this.popupHtml(listing), { closeButton: false, offset: L.point(0, -8) });
      marker.on('mouseover', () => marker.openPopup());
      marker.on('mouseout', () => marker.closePopup());
      this.markersById.set(listing.id, marker);

      points.push(marker.getLatLng());
    }

    if (points.length) {
      map.fitBounds(L.latLngBounds(points), { padding: [48, 48] });
    } else {
      map.setView([39.5, -98.35], 4);
    }
  }

  ngOnDestroy(): void {
    this.map?.remove();
  }

  /** Called when a property card is hovered: highlights (or clears) its pin on the map. */
  highlightListing(listing: Listing | null): void {
    if (this.highlightedId) {
      const prev = this.markersById.get(this.highlightedId);
      prev?.getElement()?.classList.remove('map-price-pin--highlighted');
    }
    this.highlightedId = listing?.id ?? null;
    if (listing) {
      const marker = this.markersById.get(listing.id);
      marker?.getElement()?.classList.add('map-price-pin--highlighted');
    }
  }

  /** Called when a property card's map-pin action is clicked: pans/zooms to and opens that listing's pin. */
  focusListing(listing: Listing): void {
    const marker = this.markersById.get(listing.id);
    if (!marker || !this.map) {
      return;
    }
    this.map.setView(marker.getLatLng(), Math.max(this.map.getZoom(), 13), { animate: true });
    marker.openPopup();
  }

  /**
   * Called continuously while scrolling the mobile split-view list: pans to
   * and highlights whichever card has scrolled into view, without opening its
   * popup - that would fight the user for space and reopen on every card.
   */
  panToListing(listing: Listing): void {
    this.highlightListing(listing);
    const marker = this.markersById.get(listing.id);
    if (!marker || !this.map) {
      return;
    }
    this.map.panTo(marker.getLatLng(), { animate: true, duration: 0.45 });
  }

  /** Leaflet needs an explicit nudge after its container is resized (e.g. the split-view ratio changes). */
  invalidateSize(): void {
    this.map?.invalidateSize();
  }

  private formatPrice(price: number): string {
    return price >= 1000000
      ? `$${(price / 1000000).toFixed(price % 1000000 === 0 ? 0 : 1)}M`
      : `$${Math.round(price / 1000)}K`;
  }

  private popupHtml(listing: Listing): string {
    return `
      <div class="map-popup">
        <img src="${listing.images[0]}" alt="${listing.address}" />
        <div class="map-popup__body">
          <div class="map-popup__price">${this.formatPrice(listing.price)}</div>
          <div class="map-popup__stats">${listing.beds} bd &middot; ${listing.baths} ba &middot; ${listing.sqft.toLocaleString()} sqft</div>
          <div class="map-popup__address">${listing.address}</div>
          <a class="map-popup__link" href="/property/${listing.id}">View Details</a>
        </div>
      </div>
    `;
  }
}
