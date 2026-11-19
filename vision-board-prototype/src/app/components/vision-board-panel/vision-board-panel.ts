import { Component, inject } from '@angular/core';
import { MAX_PINNED_PHOTOS, VisionBoardService } from '../../services/vision-board.service';
import { VisionBoardGridComponent } from '../vision-board-grid/vision-board-grid';
import { IconComponent } from '../icon/icon';

@Component({
  selector: 'app-vision-board-panel',
  standalone: true,
  imports: [VisionBoardGridComponent, IconComponent],
  templateUrl: './vision-board-panel.html',
  styleUrl: './vision-board-panel.scss',
})
export class VisionBoardPanelComponent {
  protected readonly visionBoard = inject(VisionBoardService);
  protected readonly maxPinned = MAX_PINNED_PHOTOS;
}
