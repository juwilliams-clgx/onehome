import { Component, EventEmitter, HostListener, Input, Output } from '@angular/core';
import { IconComponent } from '../icon/icon';

export const SORT_OPTIONS = [
  'Newest',
  'Highest Price First',
  'Lowest Price First',
  'Status',
  'PropertyFit™ Score',
  'Open Houses',
] as const;

export type SortOption = (typeof SORT_OPTIONS)[number];

/**
 * Mobile bottom sheet consolidating Sort By and the filter pills that run
 * across the top of the desktop grid (vision-board-prototype/.../property-grid).
 * On a phone-width viewport those read as clutter next to the results count,
 * so they're collapsed behind one "Filter" pill that opens this sheet instead.
 */
@Component({
  selector: 'app-filter-sheet',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './filter-sheet.html',
  styleUrl: './filter-sheet.scss',
})
export class FilterSheetComponent {
  @Input() open = false;
  @Input() sort: SortOption = 'Newest';

  @Output() closed = new EventEmitter<void>();
  @Output() sortChange = new EventEmitter<SortOption>();

  protected readonly sortOptions = SORT_OPTIONS;

  selectSort(option: SortOption): void {
    this.sortChange.emit(option);
  }

  close(): void {
    this.closed.emit();
  }

  @HostListener('document:keydown.escape')
  protected onEscape(): void {
    if (this.open) {
      this.close();
    }
  }
}
