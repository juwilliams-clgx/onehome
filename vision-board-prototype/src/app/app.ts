import { Component, ElementRef, HostListener, ViewChild, computed, effect, inject, signal } from '@angular/core';
import { NavigationEnd, Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { filter } from 'rxjs/operators';
import { toSignal } from '@angular/core/rxjs-interop';
import { VisionBoardModalComponent } from './components/vision-board-modal/vision-board-modal';
import { ConfirmUnpinModalComponent } from './components/confirm-unpin-modal/confirm-unpin-modal';
import { LoveThisLookModalComponent } from './components/love-this-look-modal/love-this-look-modal';
import { ToastComponent } from './components/toast/toast';
import { IconComponent } from './components/icon/icon';

@Component({
  imports: [
    RouterLink,
    RouterLinkActive,
    RouterOutlet,
    VisionBoardModalComponent,
    ConfirmUnpinModalComponent,
    LoveThisLookModalComponent,
    ToastComponent,
    IconComponent,
  ],
  selector: 'app-root',
  styleUrl: './app.scss',
  templateUrl: './app.html',
})
export class App {
  private readonly router = inject(Router);

  @ViewChild('menuBtn') private menuBtn?: ElementRef<HTMLButtonElement>;

  private readonly url = toSignal(
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)),
    { initialValue: null },
  );

  /** Pixel-accurate replica pages (UAT + My Properties) and the agent-only tools render their own chrome; the Future app shell must not show. */
  protected readonly isUatRoute = computed(() => {
    this.url();
    return (
      this.router.url.startsWith('/uat') ||
      this.router.url.startsWith('/my-properties') ||
      this.router.url.startsWith('/agent')
    );
  });

  protected readonly mobileMenuOpen = signal(false);

  constructor() {
    // Navigating away is the clearest signal the menu's job is done.
    effect(() => {
      this.url();
      this.mobileMenuOpen.set(false);
    });

    // Own lock class (separate from property-grid's mobile split view) so the
    // two full-screen overlays can't clobber each other's scroll state.
    effect(() => {
      document.body.classList.toggle('nav-scroll-locked', this.mobileMenuOpen());
    });
  }

  toggleMobileMenu(): void {
    this.mobileMenuOpen.update((v) => !v);
  }

  closeMobileMenu(): void {
    // Hiding the panel with aria-hidden while it still holds focus (e.g. its
    // own Close button) traps focus from assistive tech; hand it back to the
    // control that opened the menu before marking the panel hidden.
    this.menuBtn?.nativeElement.focus();
    this.mobileMenuOpen.set(false);
  }

  @HostListener('document:keydown.escape')
  protected onEscape(): void {
    this.closeMobileMenu();
  }
}
