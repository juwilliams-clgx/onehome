import { Component, inject } from '@angular/core';
import { VisionBoardService } from '../../services/vision-board.service';
import { IconComponent } from '../icon/icon';

@Component({
  selector: 'app-confirm-unpin-modal',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './confirm-unpin-modal.html',
  styleUrl: './confirm-unpin-modal.scss',
})
export class ConfirmUnpinModalComponent {
  protected readonly visionBoard = inject(VisionBoardService);
}
