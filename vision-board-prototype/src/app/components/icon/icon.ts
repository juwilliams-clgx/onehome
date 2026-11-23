import { Component, Input } from '@angular/core';

export type IconName =
  | 'pin'
  | 'unpin'
  | 'pin-bw'
  | 'unpin-bw'
  | 'reimagine'
  | 'camera'
  | 'upload'
  | 'plus'
  | 'info'
  | 'sparkle'
  | 'close'
  | 'chevron-left'
  | 'chevron-right'
  | 'heart'
  | 'heart-filled'
  | 'dislike'
  | 'dislike-filled'
  | 'layout-split'
  | 'layout-map'
  | 'layout-grid'
  | 'layout-table'
  | 'alert'
  | 'menu'
  | 'bell'
  | 'sliders'
  | 'chevron-down'
  | 'user'
  | 'search'
  | 'compare-swap'
  | 'check'
  | 'crop'
  | 'rotate'
  | 'zoom-in'
  | 'zoom-out'
  | 'star'
  | 'star-filled'
  | 'mic';

let nextId = 0;

@Component({
  selector: 'app-icon',
  standalone: true,
  templateUrl: './icon.html',
  styleUrl: './icon.scss',
})
export class IconComponent {
  @Input({ required: true }) name!: IconName;
  /** Overrides the default gradient fill/stroke with a solid color (e.g. for icons on dark backgrounds). */
  @Input() color?: string;

  // Unique suffix so multiple icon instances don't collide on gradient def ids.
  protected readonly uid = `icon-${nextId++}`;

  protected paint(): string {
    return this.color ?? `url(#paint-${this.uid})`;
  }
}

