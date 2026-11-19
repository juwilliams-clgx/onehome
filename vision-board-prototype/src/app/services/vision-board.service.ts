import { Injectable, computed, inject, signal } from '@angular/core';
import { Photo } from '../models/photo.model';
import { ToastService } from './toast.service';

export const MAX_PINNED_PHOTOS = 3;

@Injectable({ providedIn: 'root' })
export class VisionBoardService {
  private readonly toast = inject(ToastService);

  /** Photos currently pinned to the Vision Board (max MAX_PINNED_PHOTOS). */
  readonly pinnedPhotos = signal<Photo[]>([]);
  /** Photo awaiting unpin confirmation (from the gallery or the modal). */
  readonly unpinTarget = signal<Photo | null>(null);
  readonly isModalOpen = signal(false);
  /** Photo shown in the "Love This Look?" choice modal (Pin vs Search Similar). */
  readonly loveThisLookTarget = signal<Photo | null>(null);

  readonly isFull = computed(() => this.pinnedPhotos().length >= MAX_PINNED_PHOTOS);

  isPinned(photo: Photo): boolean {
    return this.pinnedPhotos().some((p) => p.id === photo.id);
  }

  /** Entry point for the pin/unpin button shown on a photo. */
  requestPin(photo: Photo): void {
    if (this.isPinned(photo)) {
      this.requestUnpin(photo);
      return;
    }
    if (this.isFull()) {
      // Board is full: surface the manage modal so the user can unpin, then re-pin manually.
      this.isModalOpen.set(true);
      return;
    }
    this.pin(photo);
  }

  closeModal(): void {
    this.isModalOpen.set(false);
  }

  /** Always confirm before removing a photo, whether triggered from the gallery or the modal. */
  requestUnpin(photo: Photo): void {
    this.unpinTarget.set(photo);
  }

  cancelUnpin(): void {
    this.unpinTarget.set(null);
  }

  /** Entry point for the "Search Similar Look" action: offer to pin or search instead. */
  openLoveThisLook(photo: Photo): void {
    this.loveThisLookTarget.set(photo);
  }

  closeLoveThisLook(): void {
    this.loveThisLookTarget.set(null);
  }

  pinFromLoveThisLook(): void {
    const photo = this.loveThisLookTarget();
    if (!photo) {
      return;
    }
    this.loveThisLookTarget.set(null);
    this.requestPin(photo);
  }

  /** Board is full: send them to the Vision Board itself to choose what to unpin, rather than guessing. */
  managePinsFromLoveThisLook(): void {
    this.loveThisLookTarget.set(null);
    this.isModalOpen.set(true);
  }

  searchSimilarFromLoveThisLook(): void {
    this.loveThisLookTarget.set(null);
    this.toast.show('Searching for more properties with a similar look...');
  }

  /**
   * "Search Similar Look" already has its own dedicated button next to Pin, so the intent is
   * unambiguous - perform the search immediately instead of asking the user to choose again.
   */
  searchSimilarLook(photo: Photo): void {
    this.toast.show(`Searching for more properties with a look similar to ${photo.room}...`);
    window.open('/', '_blank');
  }

  /** Pin a user-uploaded image (from the Vision Board's upload/drag-drop tile). */
  pinUpload(file: File): void {
    if (this.isFull()) {
      return;
    }
    const photo: Photo = {
      id: `upload-${Date.now()}`,
      room: file.name.replace(/\.[^./]+$/, '') || 'Uploaded photo',
      caption: 'Inspiration photo uploaded from your device.',
      url: URL.createObjectURL(file),
    };
    this.pin(photo);
  }

  confirmUnpin(): void {
    const photo = this.unpinTarget();
    if (!photo) {
      return;
    }
    this.unpinTarget.set(null);
    this.pinnedPhotos.update((list) => list.filter((p) => p.id !== photo.id));
    this.toast.show('Image removed from Vision Board.', () => this.pin(photo));
  }

  private pin(photo: Photo): void {
    this.pinnedPhotos.update((list) => [...list, photo]);
    this.toast.show('Image pinned to Vision Board!', () =>
      this.pinnedPhotos.update((list) => list.filter((p) => p.id !== photo.id)),
    );
  }
}
