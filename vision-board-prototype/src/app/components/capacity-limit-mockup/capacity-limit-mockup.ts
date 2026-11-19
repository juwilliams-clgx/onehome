import { Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { MOCK_LISTINGS } from '../../mock-listings';
import { CapacityLimitModalComponent } from '../capacity-limit-modal/capacity-limit-modal';
import { CapacityWarningBannerComponent } from '../capacity-warning-banner/capacity-warning-banner';
import { PropertyCardComponent } from '../property-card/property-card';

@Component({
  selector: 'app-capacity-limit-mockup',
  standalone: true,
  imports: [CapacityLimitModalComponent, CapacityWarningBannerComponent, PropertyCardComponent],
  templateUrl: './capacity-limit-mockup.html',
  styleUrl: './capacity-limit-mockup.scss',
})
export class CapacityLimitMockupComponent {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  /** The modal and banner always show the same list, so the demo represents one coherent workflow. */
  private readonly listName: string = this.route.snapshot.data['listName'] ?? 'Favorites';

  protected readonly listings = MOCK_LISTINGS;
  protected readonly activeList = signal<string | null>(this.listName);
  protected readonly bannerList = signal<string | null>(this.listName);

  manageList(): void {
    this.activeList.set(null);
    this.router.navigate(['/my-properties', this.listName.toLowerCase()]);
  }
}
