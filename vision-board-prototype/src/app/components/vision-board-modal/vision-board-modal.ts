import { Component, inject } from '@angular/core';
import { MAX_PINNED_PHOTOS, VisionBoardService } from '../../services/vision-board.service';
import { VisionBoardGridComponent } from '../vision-board-grid/vision-board-grid';
import { IconComponent } from '../icon/icon';

@Component({
  selector: 'app-vision-board-modal',
  standalone: true,
  imports: [VisionBoardGridComponent, IconComponent],
  templateUrl: './vision-board-modal.html',
  styleUrl: './vision-board-modal.scss',
})
export class VisionBoardModalComponent {
  protected readonly visionBoard = inject(VisionBoardService);
  protected readonly maxPinned = MAX_PINNED_PHOTOS;
}
