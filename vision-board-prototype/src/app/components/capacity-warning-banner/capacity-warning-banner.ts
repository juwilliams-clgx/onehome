import { Component, EventEmitter, Input, Output, signal } from '@angular/core';
import { IconComponent } from '../icon/icon';

/**
 * Persistent (non-auto-dismissing) page-level warning, distinct from ToastService's
 * transient success toasts. Shown on a list page (Favorites/Dislikes/etc.) whenever
 * that specific list is at its capacity limit, independent of how the user got there.
 */
@Component({
  selector: 'app-capacity-warning-banner',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './capacity-warning-banner.html',
  styleUrl: './capacity-warning-banner.scss',
})
export class CapacityWarningBannerComponent {
  @Input({ required: true }) listName!: string;
  @Input() limit = 20000;
  @Output() manage = new EventEmitter<void>();

  protected readonly dismissed = signal(false);
}
