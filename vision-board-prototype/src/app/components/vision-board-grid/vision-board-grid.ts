import { Component, inject, signal } from '@angular/core';
import { MAX_PINNED_PHOTOS, VisionBoardService } from '../../services/vision-board.service';
import { Photo } from '../../models/photo.model';
import { IconComponent } from '../icon/icon';

@Component({
  selector: 'app-vision-board-grid',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './vision-board-grid.html',
  styleUrl: './vision-board-grid.scss',
})
export class VisionBoardGridComponent {
  protected readonly visionBoard = inject(VisionBoardService);
  protected readonly maxPinned = MAX_PINNED_PHOTOS;
  protected readonly isDragging = signal(false);

  unpin(photo: Photo): void {
    this.visionBoard.requestUnpin(photo);
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (file) {
      this.visionBoard.pinUpload(file);
    }
    input.value = '';
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.isDragging.set(true);
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.isDragging.set(false);
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.isDragging.set(false);
    const file = event.dataTransfer?.files?.[0];
    if (file && file.type.startsWith('image/')) {
      this.visionBoard.pinUpload(file);
    }
  }
}
