import { Component, inject } from '@angular/core';
import { VisionBoardService } from '../../services/vision-board.service';
import { IconComponent } from '../icon/icon';

@Component({
  selector: 'app-love-this-look-modal',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './love-this-look-modal.html',
  styleUrl: './love-this-look-modal.scss',
})
export class LoveThisLookModalComponent {
  protected readonly visionBoard = inject(VisionBoardService);
}
