import { Component, EventEmitter, Input, Output } from '@angular/core';
import { IconComponent } from '../icon/icon';

@Component({
  selector: 'app-capacity-limit-modal',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './capacity-limit-modal.html',
  styleUrl: './capacity-limit-modal.scss',
})
export class CapacityLimitModalComponent {
  @Input({ required: true }) listName!: string;
  @Input() limit = 20000;
  @Output() closed = new EventEmitter<void>();
  @Output() manage = new EventEmitter<void>();

  close(): void {
    this.closed.emit();
  }

  manageList(): void {
    this.manage.emit();
  }
}
