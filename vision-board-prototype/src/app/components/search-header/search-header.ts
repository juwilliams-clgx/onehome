import { Component, ElementRef, ViewChild, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { IconComponent } from '../icon/icon';
import { CompareService } from '../../services/compare.service';
import { LocationService } from '../../services/location.service';
import { AiSearchService } from '../../services/ai-search.service';

interface SavedSearch {
  id: string;
  label: string;
}

const MOCK_AGENT_SEARCHES = ['AE Canopy UAT - mixed listings', 'AE 2', 'AE'];

const MOCK_MY_SEARCHES: SavedSearch[] = [
  { id: 's1', label: 'Canton OH Saved search Oct 13, 2026' },
  { id: 's2', label: 'Saved search Oct 9, 2026' },
  { id: 's3', label: 'Saved search Oct 7, 2026' },
  { id: 's4', label: 'Saved search Oct 5, 2026' },
  { id: 's5', label: 'Saved search Oct 1, 2026' },
];

/**
 * Mobile search header: a Compare tray (badge = count), the saved-search
 * picker pill (defaults to the buyer's IP-detected location), and a Search
 * icon that expands into a full text field - matching the production
 * OneHome app's own header pattern (see reference screenshots), not
 * something invented from scratch for this prototype.
 */
@Component({
  selector: 'app-search-header',
  standalone: true,
  imports: [IconComponent, FormsModule, RouterLink],
  templateUrl: './search-header.html',
  styleUrl: './search-header.scss',
})
export class SearchHeaderComponent {
  private readonly router = inject(Router);
  private readonly aiSearch = inject(AiSearchService);
  protected readonly compare = inject(CompareService);
  protected readonly location = inject(LocationService);

  @ViewChild('searchInput') private searchInputRef?: ElementRef<HTMLInputElement>;

  protected readonly agentSearches = MOCK_AGENT_SEARCHES;
  protected readonly mySearches = signal(MOCK_MY_SEARCHES);

  protected readonly dropdownOpen = signal(false);
  protected readonly searchExpanded = signal(false);
  protected readonly query = signal('');
  protected readonly selectedSearchLabel = signal<string | null>(null);

  /** What the collapsed pill shows: a chosen saved search, the detected
   *  location, or a neutral placeholder while that lookup is still pending. */
  protected readonly pillLabel = computed(() => {
    if (this.selectedSearchLabel()) {
      return this.selectedSearchLabel()!;
    }
    if (this.location.displayLocation()) {
      return this.location.displayLocation()!;
    }
    return this.location.isLoading() ? 'Finding your area…' : 'Search an address, city, zip…';
  });

  toggleDropdown(): void {
    this.dropdownOpen.update((v) => !v);
  }

  closeDropdown(): void {
    this.dropdownOpen.set(false);
  }

  selectSearch(label: string): void {
    this.selectedSearchLabel.set(label);
    this.closeDropdown();
  }

  removeSearch(id: string): void {
    this.mySearches.update((list) => list.filter((s) => s.id !== id));
  }

  expandSearch(): void {
    this.dropdownOpen.set(false);
    this.searchExpanded.set(true);
    setTimeout(() => this.searchInputRef?.nativeElement.focus(), 50);
  }

  collapseSearch(): void {
    this.searchExpanded.set(false);
    this.query.set('');
  }

  /** The camera chip searches by photo - the same job as Vision Board's
   *  "Search Similar Look," so it opens that flow rather than inventing a
   *  separate, disconnected photo-search feature. */
  searchByPhoto(): void {
    this.router.navigateByUrl('/vision-board');
  }

  searchWithAi(): void {
    this.aiSearch.open();
  }
}
