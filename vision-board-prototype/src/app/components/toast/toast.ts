import { Component, inject } from '@angular/core';
import { ToastService } from '../../services/toast.service';

@Component({
  selector: 'app-toast',
  standalone: true,
  templateUrl: './toast.html',
  styleUrl: './toast.scss',
})
export class ToastComponent {
  protected readonly toastService = inject(ToastService);

  onUndo(): void {
    const current = this.toastService.toast();
    current?.undo?.();
    this.toastService.dismiss();
  }
}
