import { Injectable, signal } from '@angular/core';

export interface ToastState {
  message: string;
  undo?: () => void;
}

@Injectable({ providedIn: 'root' })
export class ToastService {
  readonly toast = signal<ToastState | null>(null);
  private timer?: ReturnType<typeof setTimeout>;

  show(message: string, undo?: () => void): void {
    clearTimeout(this.timer);
    this.toast.set({ message, undo });
    this.timer = setTimeout(() => this.dismiss(), 5000);
  }

  dismiss(): void {
    clearTimeout(this.timer);
    this.toast.set(null);
  }
}
