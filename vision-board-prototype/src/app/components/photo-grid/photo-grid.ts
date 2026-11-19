import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { Photo } from '../../models/photo.model';
import { VisionBoardService } from '../../services/vision-board.service';
import { IconComponent } from '../icon/icon';

@Component({
  selector: 'app-photo-grid',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './photo-grid.html',
  styleUrl: './photo-grid.scss',
})
export class PhotoGridComponent {
  @Input({ required: true }) photos: Photo[] = [];
  @Output() photoSelected = new EventEmitter<Photo>();

  protected readonly visionBoard = inject(VisionBoardService);

  togglePin(photo: Photo, event: Event): void {
    event.stopPropagation();
    this.visionBoard.requestPin(photo);
  }

  searchSimilar(photo: Photo, event: Event): void {
    event.stopPropagation();
    this.visionBoard.searchSimilarLook(photo);
  }
}
