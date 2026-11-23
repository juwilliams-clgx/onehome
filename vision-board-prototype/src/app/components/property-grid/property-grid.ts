import { AfterViewInit, Component, ElementRef, OnDestroy, QueryList, ViewChild, ViewChildren, computed, effect, inject, signal } from '@angular/core';
import { MOCK_LISTINGS } from '../../mock-listings';
import { Listing } from '../../models/listing.model';
import { PropertyCardComponent } from '../property-card/property-card';
import { PropertyMapComponent } from '../property-map/property-map';
import { IconComponent, IconName } from '../icon/icon';
import { FilterSheetComponent, SortOption } from '../filter-sheet/filter-sheet';
import { SearchHeaderComponent } from '../search-header/search-header';
import { AiSearchPanelComponent } from '../ai-search-panel/ai-search-panel';
import { AiSearchService } from '../../services/ai-search.service';

export type GridLayout = 'split' | 'map' | 'grid' | 'table';
/** Three-step split-view ratio: default (2/3 list, 1/3 map) -> wide (1/3 list, 2/3 map) -> full (map only). */
export type MapSplitSize = 'default' | 'wide' | 'full';

interface LayoutOption {
  value: GridLayout;
  label: string;
  /** Mobile reads the grid layout as a plain "List" (single column), not "Grid". */
  mobileLabel: string;
  icon: IconName;
}

const LAYOUT_OPTIONS: LayoutOption[] = [
  { value: 'split', label: 'Split', mobileLabel: 'Split', icon: 'layout-split' },
  { value: 'map', label: 'Map', mobileLabel: 'Map', icon: 'layout-map' },
  { value: 'grid', label: 'Grid', mobileLabel: 'List', icon: 'layout-grid' },
  { value: 'table', label: 'Table', mobileLabel: 'Table', icon: 'layout-table' },
];

const MAP_TOOLS = ['Boundaries', 'Schools', 'Drive Time', 'Points of Interest'] as const;

const MOBILE_QUERY = '(max-width: 640px)';

@Component({
  selector: 'app-property-grid',
  standalone: true,
  imports: [
    PropertyCardComponent,
    PropertyMapComponent,
    IconComponent,
    FilterSheetComponent,
    SearchHeaderComponent,
    AiSearchPanelComponent,
  ],
  templateUrl: './property-grid.html',
  styleUrl: './property-grid.scss',
})
export class PropertyGridComponent implements AfterViewInit, OnDestroy {
  @ViewChild(PropertyMapComponent) private propertyMap?: PropertyMapComponent;
  /** The scrollable list pane in the mobile 50/50 split view; doubles as the IntersectionObserver root. */
  @ViewChild('splitListEl') private splitListEl?: ElementRef<HTMLDivElement>;
  @ViewChild('filterTriggerBtn') private filterTriggerBtn?: ElementRef<HTMLButtonElement>;
  /** One ref per rendered card, used to detect which listing has scrolled into view. */
  @ViewChildren('splitCard', { read: ElementRef }) private splitCardEls?: QueryList<ElementRef<HTMLElement>>;

  private readonly aiSearch = inject(AiSearchService);
  /** Every listing, narrowed to the AI search panel's result ids when a conversational filter is active. */
  protected readonly listings = computed(() => {
    const ids = this.aiSearch.visibleListingIds();
    return ids ? MOCK_LISTINGS.filter((l) => ids.includes(l.id)) : MOCK_LISTINGS;
  });
  protected readonly layoutOptions = LAYOUT_OPTIONS;
  protected readonly layoutMenuOpen = signal(false);
  protected readonly mapSplitSize = signal<MapSplitSize>('default');


  protected readonly mapTools = MAP_TOOLS;
  protected readonly activeMapTools = signal(new Set<string>());

  protected readonly filterSheetOpen = signal(false);
  protected readonly sort = signal<SortOption>('Newest');

  /** Phones default to the single-column list; everything else keeps the existing split default. */
  private readonly mobileQuery = typeof window !== 'undefined' ? window.matchMedia(MOBILE_QUERY) : null;
  protected readonly isMobile = signal(this.mobileQuery?.matches ?? false);
  protected readonly layout = signal<GridLayout>(this.isMobile() ? 'grid' : 'split');

  private intersectionObserver?: IntersectionObserver;
  private readonly handleMobileChange = (event: MediaQueryListEvent) => {
    this.isMobile.set(event.matches);
    this.setupSplitObserver();
  };

  protected readonly currentLayoutOption = () =>
    this.layoutOptions.find((o) => o.value === this.layout()) ?? this.layoutOptions[0];

  constructor() {
    this.mobileQuery?.addEventListener('change', this.handleMobileChange);

    // The mobile split view is a fixed, full-viewport overlay (see property-grid.scss);
    // the page behind it must stop scrolling while it's up, or the two panes
    // drift out of sync with the rest of the layout.
    effect(() => {
      const immersive = this.layout() === 'split' && this.isMobile();
      document.body.classList.toggle('scroll-locked', immersive);
    });
  }

  ngAfterViewInit(): void {
    this.splitCardEls?.changes.subscribe(() => this.setupSplitObserver());
    this.setupSplitObserver();
  }

  ngOnDestroy(): void {
    this.intersectionObserver?.disconnect();
    this.mobileQuery?.removeEventListener('change', this.handleMobileChange);
    document.body.classList.remove('scroll-locked');
  }

  toggleLayoutMenu(): void {
    this.layoutMenuOpen.update((v) => !v);
  }

  openLayoutMenu(): void {
    this.layoutMenuOpen.set(true);
  }

  closeLayoutMenu(): void {
    this.layoutMenuOpen.set(false);
  }

  selectLayout(layout: GridLayout): void {
    this.layout.set(layout);
    this.layoutMenuOpen.set(false);
    setTimeout(() => this.setupSplitObserver());
    if (layout === 'split' || layout === 'map') {
      // The map component is freshly mounted by the @if switch above, so it
      // can measure a zero-size container before the new CSS layout (e.g.
      // mobile's fixed 50/50 panes) has actually been painted.
      this.refreshMapSize();
    }
  }

  toggleMapTool(tool: string): void {
    this.activeMapTools.update((tools) => {
      const next = new Set(tools);
      if (next.has(tool)) {
        next.delete(tool);
      } else {
        next.add(tool);
      }
      return next;
    });
  }

  isMapToolActive(tool: string): boolean {
    return this.activeMapTools().has(tool);
  }

  formatPrice(price: number): string {
    return price.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
  }

  /** Steps the split view one notch toward a wider map / narrower list. */
  expandMap(): void {
    const order: MapSplitSize[] = ['default', 'wide', 'full'];
    const next = order[Math.min(order.indexOf(this.mapSplitSize()) + 1, order.length - 1)];
    this.mapSplitSize.set(next);
    this.refreshMapSize();
  }

  /** Steps the split view one notch toward a narrower map / wider list. */
  shrinkMap(): void {
    const order: MapSplitSize[] = ['default', 'wide', 'full'];
    const next = order[Math.max(order.indexOf(this.mapSplitSize()) - 1, 0)];
    this.mapSplitSize.set(next);
    this.refreshMapSize();
  }

  onMapHover(listing: Listing | null): void {
    this.propertyMap?.highlightListing(listing);
  }

  onMapFocus(listing: Listing): void {
    this.propertyMap?.focusListing(listing);
  }

  openFilterSheet(): void {
    this.filterSheetOpen.set(true);
  }

  closeFilterSheet(): void {
    // Same focus-return reasoning as the nav menu: don't let aria-hidden land
    // on a panel that still holds focus.
    this.filterTriggerBtn?.nativeElement.focus();
    this.filterSheetOpen.set(false);
  }

  selectSort(option: SortOption): void {
    this.sort.set(option);
  }

  private refreshMapSize(): void {
    // Leaflet renders to a fixed-size canvas; give the CSS transition a beat to finish before resizing.
    setTimeout(() => this.propertyMap?.invalidateSize(), 220);
  }

  /**
   * (Re)wires the IntersectionObserver that drives the mobile split view: as
   * the list pane scrolls, whichever card is most visible pans the map to its
   * pin, so the buyer can always see where the home they're looking at falls
   * on the map - the one deliberate departure from the Zillow reference,
   * which lets the list cover the map entirely on scroll.
   */
  private setupSplitObserver(): void {
    this.intersectionObserver?.disconnect();
    this.intersectionObserver = undefined;

    if (this.layout() !== 'split' || !this.isMobile() || !this.splitCardEls || !this.splitListEl) {
      return;
    }

    const cardEls = this.splitCardEls;
    const observer = new IntersectionObserver(
      (entries) => {
        const mostVisible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
        if (!mostVisible) {
          return;
        }
        const id = (mostVisible.target as HTMLElement).dataset['listingId'];
        const listing = this.listings().find((l) => l.id === id);
        if (listing) {
          this.propertyMap?.panToListing(listing);
        }
      },
      { root: this.splitListEl.nativeElement, threshold: [0.5, 0.75, 1] },
    );

    cardEls.forEach((el) => observer.observe(el.nativeElement));
    this.intersectionObserver = observer;
  }
}
