import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { IconComponent } from '../icon/icon';
import { PhotoCropperComponent, CropResult } from '../photo-cropper/photo-cropper';
import { CropState, DEFAULT_CROP_STATE, exportCrop, isNearAspectRatio } from '../photo-cropper/crop-math';
import { ToastService } from '../../services/toast.service';
import { MOCK_LISTINGS } from '../../mock-listings';
import { Listing } from '../../models/listing.model';

const ASPECT_RATIO = 4 / 3;
/** Cap how many of a listing's existing MLS photos preload into the demo batch, so the page opens fast. */
const EXISTING_PHOTO_LIMIT = 6;

export interface WorkingPhoto {
  id: string;
  originalUrl: string;
  naturalWidth: number;
  naturalHeight: number;
  state: CropState;
  preview: string;
  /** True once the agent has opened this photo in the cropper and confirmed a crop (even the untouched default). */
  reviewed: boolean;
  /** True when the original aspect ratio was far enough from 4:3 that it was auto-cropped and deserves a look. */
  needsReview: boolean;
  isCover: boolean;
  /** Original upload order; photos load async and out of order, so the grid sorts by this rather than arrival order. */
  sortIndex: number;
}

@Component({
  selector: 'app-agent-photo-upload',
  standalone: true,
  imports: [CommonModule, RouterLink, IconComponent, PhotoCropperComponent],
  templateUrl: './agent-photo-upload.html',
  styleUrl: './agent-photo-upload.scss',
})
export class AgentPhotoUploadComponent {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private toast = inject(ToastService);

  protected readonly listing = signal<Listing | undefined>(undefined);
  protected readonly photos = signal<WorkingPhoto[]>([]);
  protected readonly activeIndex = signal<number | null>(null);
  protected readonly dragActive = signal(false);
  protected readonly saving = signal(false);
  protected readonly loadingCount = signal(0);
  private nextSortIndex = 0;

  protected readonly readyCount = computed(() => this.photos().filter((p) => !p.needsReview || p.reviewed).length);
  protected readonly needsReviewCount = computed(
    () => this.photos().filter((p) => p.needsReview && !p.reviewed).length,
  );
  protected readonly activePhoto = computed(() => {
    const i = this.activeIndex();
    return i === null ? null : this.photos()[i];
  });

  constructor() {
    const id = this.route.snapshot.paramMap.get('id');
    const listing = MOCK_LISTINGS.find((l) => l.id === id);
    this.listing.set(listing);
    if (listing) {
      for (const url of listing.images.slice(0, EXISTING_PHOTO_LIMIT)) {
        this.ingestUrl(url);
      }
    }
  }

  private ingestUrl(url: string): void {
    const sortIndex = this.nextSortIndex++;
    this.loadingCount.update((n) => n + 1);
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      const needsReview = !isNearAspectRatio(img.naturalWidth, img.naturalHeight, ASPECT_RATIO);
      const state = DEFAULT_CROP_STATE;
      const preview = exportCrop(img, state, img.naturalWidth, img.naturalHeight, 400, 300);
      const photo: WorkingPhoto = {
        id: `p-${Math.random().toString(36).slice(2, 10)}`,
        originalUrl: url,
        naturalWidth: img.naturalWidth,
        naturalHeight: img.naturalHeight,
        state,
        preview,
        reviewed: !needsReview,
        needsReview,
        // Photos load async and can resolve out of order; only the first position in the
        // original upload order becomes cover, and only if nothing already claimed it.
        isCover: sortIndex === 0,
        sortIndex,
      };
      this.photos.update((list) => {
        const hasCover = list.some((p) => p.isCover);
        const next = [...list, { ...photo, isCover: photo.isCover && !hasCover }];
        next.sort((a, b) => a.sortIndex - b.sortIndex);
        return next;
      });
      this.loadingCount.update((n) => n - 1);
    };
    img.onerror = () => this.loadingCount.update((n) => n - 1);
    img.src = url;
  }

  protected onFilesSelected(ev: Event): void {
    const input = ev.target as HTMLInputElement;
    const files = input.files;
    if (!files) return;
    for (const file of Array.from(files)) {
      if (!file.type.startsWith('image/')) continue;
      this.ingestUrl(URL.createObjectURL(file));
    }
    input.value = '';
  }

  protected onDrop(ev: DragEvent): void {
    ev.preventDefault();
    this.dragActive.set(false);
    const files = ev.dataTransfer?.files;
    if (!files) return;
    for (const file of Array.from(files)) {
      if (!file.type.startsWith('image/')) continue;
      this.ingestUrl(URL.createObjectURL(file));
    }
  }

  protected onDragOver(ev: DragEvent): void {
    ev.preventDefault();
    this.dragActive.set(true);
  }

  protected onDragLeave(): void {
    this.dragActive.set(false);
  }

  protected openCropper(index: number): void {
    this.activeIndex.set(index);
  }

  protected closeCropper(): void {
    this.activeIndex.set(null);
  }

  protected onCropApply(result: CropResult): void {
    const index = this.activeIndex();
    if (index === null) return;
    this.photos.update((list) =>
      list.map((p, i) => (i === index ? { ...p, state: result.state, preview: result.dataUrl, reviewed: true } : p)),
    );
  }

  protected canGoPrev(): boolean {
    const i = this.activeIndex();
    return i !== null && i > 0;
  }

  protected canGoNext(): boolean {
    const i = this.activeIndex();
    return i !== null && i < this.photos().length - 1;
  }

  protected goPrevPhoto(): void {
    const i = this.activeIndex();
    if (i !== null && i > 0) this.activeIndex.set(i - 1);
  }

  protected goNextPhoto(): void {
    const i = this.activeIndex();
    if (i !== null && i < this.photos().length - 1) this.activeIndex.set(i + 1);
  }

  protected removePhoto(index: number, ev: Event): void {
    ev.stopPropagation();
    this.photos.update((list) => {
      const next = list.filter((_, i) => i !== index);
      if (next.length && !next.some((p) => p.isCover)) next[0] = { ...next[0], isCover: true };
      return next;
    });
  }

  protected setCover(index: number, ev: Event): void {
    ev.stopPropagation();
    this.photos.update((list) => list.map((p, i) => ({ ...p, isCover: i === index })));
  }

  protected stepLabel(): string {
    const i = this.activeIndex();
    return i === null ? '' : `Photo ${i + 1} of ${this.photos().length}`;
  }

  protected loadingPlaceholders(): number[] {
    return Array(this.loadingCount()).fill(0);
  }

  protected save(): void {
    this.saving.set(true);
    const listing = this.listing();
    setTimeout(() => {
      this.saving.set(false);
      this.toast.show(`${this.photos().length} photo${this.photos().length === 1 ? '' : 's'} saved to ${listing?.address ?? 'this listing'}`);
      this.router.navigate(['/agent/listings']);
    }, 700);
  }
}
