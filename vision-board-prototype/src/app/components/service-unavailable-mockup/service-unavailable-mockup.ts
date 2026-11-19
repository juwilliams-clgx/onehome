import { Component, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { IconComponent } from '../icon/icon';
import { ToastService } from '../../services/toast.service';

type Context = 'splash' | 'login';

/**
 * Reviewable concept for the "orchestration layer is down, no MLS data" fallback -
 * the same designed state covers both the splash and login touchpoints (nothing
 * meaningful can render on either without listing data, so there's one design, not
 * two). Not wired to a real splash/login flow or backend; this app has neither yet.
 * Retry is a believable two-step demo (still down, then recovers) so a reviewer can
 * see both outcomes without a real backend to fail against.
 */
@Component({
  selector: 'app-service-unavailable-mockup',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './service-unavailable-mockup.html',
  styleUrl: './service-unavailable-mockup.scss',
})
export class ServiceUnavailableMockupComponent {
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  protected readonly context = signal<Context>('splash');
  protected readonly retrying = signal(false);
  protected readonly stillDown = signal(false);
  private attempts = 0;

  setContext(context: Context): void {
    this.context.set(context);
    this.stillDown.set(false);
  }

  retry(): void {
    if (this.retrying()) return;
    this.retrying.set(true);
    this.stillDown.set(false);
    this.attempts++;
    setTimeout(() => {
      this.retrying.set(false);
      if (this.attempts >= 2) {
        this.router.navigate(['/']);
      } else {
        this.stillDown.set(true);
      }
    }, 1100);
  }

  contactSupport(): void {
    this.toast.show('support@onehome.com · (800) 555-0199');
  }
}
