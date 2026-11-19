import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { MOCK_LISTINGS } from '../../mock-listings';
import { Listing } from '../../models/listing.model';
import { CapacityWarningBannerComponent } from '../capacity-warning-banner/capacity-warning-banner';
import { IconComponent } from '../icon/icon';

interface TabDef {
  key: 'favorites' | 'agent-picks' | 'dislikes' | 'agent-discards';
  label: string;
  count: number;
}

/** Pixel-accurate recreation of the real "My Properties" favorites/dislikes tab (portal.onehome.com). */
@Component({
  selector: 'app-manage-list',
  standalone: true,
  imports: [IconComponent, CapacityWarningBannerComponent],
  templateUrl: './manage-list.html',
  styleUrl: './manage-list.scss',
})
export class ManageListComponent {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  protected readonly statusOptions: Listing['status'][] = ['For Sale', 'Pending', 'Sold'];

  protected readonly listName: string = this.route.snapshot.data['listName'] ?? 'Favorites';
  protected readonly items = signal<Listing[]>(MOCK_LISTINGS);
  protected readonly count = computed(() => this.items().length);
  /** Removing even one item resolves the capacity problem, so the warning can clear itself. */
  protected readonly isUnderLimit = signal(false);

  /** Empty set = no status filter applied (show everything). */
  protected readonly statusFilter = signal<Set<Listing['status']>>(new Set());
  protected readonly filterPanelOpen = signal(false);
  protected readonly activeFilterCount = computed(() => this.statusFilter().size);

  /** What the grid actually renders - the full saved list narrowed by the status filter, if any is active. */
  protected readonly filteredItems = computed(() => {
    const filter = this.statusFilter();
    if (filter.size === 0) return this.items();
    return this.items().filter((listing) => filter.has(listing.status));
  });

  protected readonly selectionMode = signal(false);
  protected readonly selectedIds = signal<Set<string>>(new Set());
  protected readonly selectedCount = computed(() => this.selectedIds().size);
  protected readonly allSelected = computed(
    () => this.filteredItems().length > 0 && this.selectedCount() === this.filteredItems().length,
  );
  protected readonly confirmBulkRemoveOpen = signal(false);

  protected readonly tabs = computed<TabDef[]>(() => [
    { key: 'favorites', label: 'Favorites', count: this.listName === 'Favorites' ? this.count() : 0 },
    { key: 'agent-picks', label: 'Agent Picks', count: 0 },
    { key: 'dislikes', label: 'Dislikes', count: this.listName === 'Dislikes' ? this.count() : 0 },
    { key: 'agent-discards', label: 'Agent Discards', count: 0 },
  ]);

  isActiveTab(tab: TabDef): boolean {
    return tab.label === this.listName;
  }

  selectTab(tab: TabDef): void {
    if (tab.key === 'favorites' || tab.key === 'dislikes') {
      this.router.navigate(['/my-properties', tab.key]);
    }
  }

  statusLabel(listing: Listing): string {
    return listing.status;
  }

  remove(listing: Listing): void {
    this.items.update((list) => list.filter((l) => l.id !== listing.id));
    this.isUnderLimit.set(true);
  }

  formatPrice(price: number): string {
    return price.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
  }

  toggleFilterPanel(): void {
    this.filterPanelOpen.update((v) => !v);
  }

  closeFilterPanel(): void {
    this.filterPanelOpen.set(false);
  }

  isStatusFilterActive(status: Listing['status']): boolean {
    return this.statusFilter().has(status);
  }

  toggleStatusFilter(status: Listing['status']): void {
    this.statusFilter.update((current) => {
      const next = new Set(current);
      if (next.has(status)) {
        next.delete(status);
      } else {
        next.add(status);
      }
      return next;
    });
  }

  clearStatusFilter(): void {
    this.statusFilter.set(new Set());
  }

  /** Entry point for the "Select" link in the filters row. */
  toggleSelectionMode(): void {
    this.selectionMode.update((v) => !v);
    this.selectedIds.set(new Set());
  }

  isSelected(listing: Listing): boolean {
    return this.selectedIds().has(listing.id);
  }

  toggleSelect(listing: Listing): void {
    this.selectedIds.update((ids) => {
      const next = new Set(ids);
      if (next.has(listing.id)) {
        next.delete(listing.id);
      } else {
        next.add(listing.id);
      }
      return next;
    });
  }

  /** Selects everything currently visible (post-filter) if nothing or only some of it is selected; otherwise clears the selection. */
  toggleSelectAll(): void {
    if (this.allSelected()) {
      this.selectedIds.set(new Set());
    } else {
      this.selectedIds.set(new Set(this.filteredItems().map((l) => l.id)));
    }
  }

  requestBulkRemove(): void {
    if (this.selectedCount() > 0) {
      this.confirmBulkRemoveOpen.set(true);
    }
  }

  cancelBulkRemove(): void {
    this.confirmBulkRemoveOpen.set(false);
  }

  confirmBulkRemove(): void {
    const ids = this.selectedIds();
    this.items.update((list) => list.filter((l) => !ids.has(l.id)));
    this.isUnderLimit.set(true);
    this.confirmBulkRemoveOpen.set(false);
    this.selectionMode.set(false);
    this.selectedIds.set(new Set());
  }
}
