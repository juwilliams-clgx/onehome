import { Component, computed, inject, signal } from '@angular/core';
import { MAX_PINNED_PHOTOS, VisionBoardService } from '../../services/vision-board.service';
import { MOCK_PHOTOS } from '../../mock-photos';
import { Photo } from '../../models/photo.model';
import { VisionBoardPanelComponent } from '../vision-board-panel/vision-board-panel';
import { IconComponent } from '../icon/icon';
import { PhotoGridComponent } from '../photo-grid/photo-grid';

export type ViewerTab = 'gallery' | 'photos' | 'reimagine' | 'floorplan' | 'visionboard';

export interface ReimagineStyle {
  id: string;
  label: string;
}

const REIMAGINE_STYLES: ReimagineStyle[] = [
  { id: 'modern', label: 'Modern' },
  { id: 'cozy', label: 'Cozy' },
  { id: 'minimalist', label: 'Minimalist' },
];

@Component({
  selector: 'app-photo-viewer',
  standalone: true,
  imports: [VisionBoardPanelComponent, IconComponent, PhotoGridComponent],
  templateUrl: './photo-viewer.html',
  styleUrl: './photo-viewer.scss',
})
export class PhotoViewerComponent {
  protected readonly visionBoard = inject(VisionBoardService);
  protected readonly maxPinned = MAX_PINNED_PHOTOS;
  /** All gallery media, including the floor plan. */
  protected readonly galleryPhotos = MOCK_PHOTOS;
  /** Just the walkthrough photos (excludes the floor plan) for the Photos carousel. */
  protected readonly photos = MOCK_PHOTOS.filter((p) => p.kind !== 'floor-plan');
  protected readonly floorPlanPhotos = MOCK_PHOTOS.filter((p) => p.kind === 'floor-plan');
  protected readonly reimagineStyles = REIMAGINE_STYLES;

  protected readonly index = signal(0);
  protected readonly activeTab = signal<ViewerTab>('photos');

  protected readonly currentPhoto = computed(() => this.photos[this.index()]);

  protected readonly reimagineRoom = signal<Photo | null>(null);
  protected readonly reimagineStyleId = signal<string | null>(null);
  protected readonly reimagineLoading = signal(false);

  /** Mock "after" image: the next room's photo, used to simulate an AI-reimagined result. */
  protected readonly reimaginedUrl = computed(() => {
    const room = this.reimagineRoom();
    if (!room) {
      return '';
    }
    const idx = this.photos.findIndex((p) => p.id === room.id);
    return this.photos[(idx + 1) % this.photos.length].url;
  });

  selectTab(tab: ViewerTab): void {
    this.activeTab.set(tab);
  }

  viewPhoto(photo: Photo): void {
    if (photo.kind === 'floor-plan') {
      this.activeTab.set('floorplan');
      return;
    }
    const idx = this.photos.findIndex((p) => p.id === photo.id);
    if (idx >= 0) {
      this.index.set(idx);
    }
    this.activeTab.set('photos');
  }

  startReimagine(photo: Photo): void {
    this.reimagineRoom.set(photo);
    this.reimagineStyleId.set(null);
    this.activeTab.set('reimagine');
  }

  selectReimagineRoom(photo: Photo): void {
    this.reimagineRoom.set(photo);
    this.reimagineStyleId.set(null);
  }

  selectReimagineStyle(style: ReimagineStyle): void {
    this.reimagineStyleId.set(style.id);
    this.reimagineLoading.set(true);
    setTimeout(() => this.reimagineLoading.set(false), 900);
  }

  changeReimagineRoom(): void {
    this.reimagineRoom.set(null);
    this.reimagineStyleId.set(null);
  }

  changeReimagineStyle(): void {
    this.reimagineStyleId.set(null);
  }

  pinReimagined(): void {
    const room = this.reimagineRoom();
    const style = this.reimagineStyles.find((s) => s.id === this.reimagineStyleId());
    if (!room || !style) {
      return;
    }
    this.visionBoard.requestPin({
      id: `${room.id}-reimagined-${style.id}`,
      room: `${room.room} (${style.label} Reimagine)`,
      caption: `AI-reimagined ${style.label.toLowerCase()} version of the ${room.room.toLowerCase()}.`,
      url: this.reimaginedUrl(),
    });
  }

  prev(): void {
    this.index.update((i) => (i - 1 + this.photos.length) % this.photos.length);
  }

  next(): void {
    this.index.update((i) => (i + 1) % this.photos.length);
  }

  togglePin(): void {
    this.visionBoard.requestPin(this.currentPhoto());
  }
}

