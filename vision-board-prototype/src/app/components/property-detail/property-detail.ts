import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { MOCK_LISTINGS } from '../../mock-listings';
import { Listing } from '../../models/listing.model';
import { Photo } from '../../models/photo.model';
import { VisionBoardService } from '../../services/vision-board.service';
import { ToastService } from '../../services/toast.service';
import { IconComponent } from '../icon/icon';

@Component({
  selector: 'app-property-detail',
  standalone: true,
  imports: [IconComponent, RouterLink],
  templateUrl: './property-detail.html',
  styleUrl: './property-detail.scss',
})
export class PropertyDetailComponent {
  private readonly route = inject(ActivatedRoute);
  protected readonly visionBoard = inject(VisionBoardService);
  private readonly toast = inject(ToastService);

  protected readonly listing: Listing =
    MOCK_LISTINGS.find((l) => l.id === this.route.snapshot.paramMap.get('id')) ?? MOCK_LISTINGS[0];

  /** 6 per page: a clean 2-col x 3-row grid whose total height matches the hero (see .detail__mosaic). */
  private readonly setSize = 6;
  protected readonly totalThumbnailPages = Math.ceil(this.listing.images.length / this.setSize);
  protected readonly thumbnailPage = signal(0);

  /** The photo currently shown in the hero; stepped one at a time (no wraparound), unlike the thumbnail grid. */
  protected readonly activePhotoIndex = signal(0);
  protected readonly isFirstPhoto = computed(() => this.activePhotoIndex() === 0);
  protected readonly isLastPhoto = computed(
    () => this.activePhotoIndex() === this.listing.images.length - 1,
  );

  protected readonly pagedThumbnails = computed(() => {
    const start = this.thumbnailPage() * this.setSize;
    return this.listing.images.slice(start, start + this.setSize).map((url, i) => ({ url, index: start + i }));
  });

  /** Reveals the Reimagine/Search Similar/Pin buttons on the hero while pressed-and-held (touch) or hovered (mouse). */
  protected readonly actionsRevealed = signal(false);
  private pressTimer?: ReturnType<typeof setTimeout>;
  private touchStartX = 0;

  protected readonly descriptionExpanded = signal(false);

  /** First sentence of the agent's description, surfaced as a scannable hook above the full paragraph. */
  protected readonly whatsSpecial = computed(() => {
    const firstSentence = this.listing.description.split(/(?<=[.!?])\s+/)[0];
    return firstSentence;
  });

  /** Interactive payment estimator state (mirrors Zillow's adjustable calculator). */
  protected readonly downPaymentPercent = signal(20);
  protected readonly interestRate = signal(6.5);
  protected readonly loanTermYears = signal(30);

  protected readonly downPaymentAmount = computed(
    () => this.listing.price * (this.downPaymentPercent() / 100),
  );

  protected readonly monthlyPrincipalAndInterest = computed(() => {
    const principal = this.listing.price - this.downPaymentAmount();
    const monthlyRate = this.interestRate() / 100 / 12;
    const numPayments = this.loanTermYears() * 12;
    if (monthlyRate === 0) {
      return principal / numPayments;
    }
    return (principal * monthlyRate) / (1 - Math.pow(1 + monthlyRate, -numPayments));
  });

  /** Rough property tax + home insurance estimate, for a fuller "all-in" monthly total. */
  protected readonly monthlyTaxesAndInsurance = computed(() => (this.listing.price * 0.0125) / 12);

  protected readonly monthlyTotal = computed(
    () => this.monthlyPrincipalAndInterest() + this.monthlyTaxesAndInsurance(),
  );

  protected readonly agent = {
    name: 'Jordan Reyes',
    title: 'OneHome Future Concept',
    phone: '(555) 019-4420',
    email: 'jordan.reyes@onehome.example',
  };

  /** Mock down-payment-assistance program count, scaled loosely off price for variety across listings. */
  protected readonly downPaymentPrograms = computed(() => (this.listing.price < 700000 ? 11 : 6));
  protected readonly downPaymentMaxAmount = computed(() => (this.listing.price < 700000 ? 40000 : 25000));
  protected readonly galleryOpen = signal(false);

  private photoFor(index: number): Photo {
    const listing = this.listing;
    return {
      id: `${listing.id}-img-${index}`,
      url: listing.images[index],
      room: listing.address,
      caption: `Photo ${index + 1} of ${listing.images.length}`,
    };
  }

  isPinned(index: number): boolean {
    return this.visionBoard.isPinned(this.photoFor(index));
  }

  prevSet(event: Event): void {
    event.stopPropagation();
    this.thumbnailPage.update((i) => (i - 1 + this.totalThumbnailPages) % this.totalThumbnailPages);
  }

  nextSet(event: Event): void {
    event.stopPropagation();
    this.thumbnailPage.update((i) => (i + 1) % this.totalThumbnailPages);
  }

  prevPhoto(event: Event): void {
    event.stopPropagation();
    this.activePhotoIndex.update((i) => Math.max(0, i - 1));
  }

  nextPhoto(event: Event): void {
    event.stopPropagation();
    this.activePhotoIndex.update((i) => Math.min(this.listing.images.length - 1, i + 1));
  }

  onHeroTouchStart(event: TouchEvent): void {
    this.touchStartX = event.touches[0].clientX;
    this.startPressTimer();
  }

  onHeroTouchEnd(event: TouchEvent): void {
    this.cancelPressTimer();
    const deltaX = event.changedTouches[0].clientX - this.touchStartX;
    const SWIPE_THRESHOLD = 40;
    if (deltaX <= -SWIPE_THRESHOLD) {
      this.activePhotoIndex.update((i) => Math.min(this.listing.images.length - 1, i + 1));
    } else if (deltaX >= SWIPE_THRESHOLD) {
      this.activePhotoIndex.update((i) => Math.max(0, i - 1));
    }
  }

  onHeroPressStart(): void {
    this.startPressTimer();
  }

  onHeroPressEnd(): void {
    this.cancelPressTimer();
    this.actionsRevealed.set(false);
  }

  private startPressTimer(): void {
    this.cancelPressTimer();
    this.pressTimer = setTimeout(() => this.actionsRevealed.set(true), 400);
  }

  private cancelPressTimer(): void {
    clearTimeout(this.pressTimer);
  }

  toggleDescription(): void {
    this.descriptionExpanded.update((v) => !v);
  }

  openGallery(index: number, event?: Event): void {
    event?.stopPropagation();
    this.galleryOpen.set(true);
    // Let Angular finish rendering the overlay before scrolling, so the target photo element actually exists.
    setTimeout(() => {
      document.getElementById(`gallery-photo-${index}`)?.scrollIntoView({ block: 'start' });
    });
  }

  closeGallery(): void {
    this.galleryOpen.set(false);
  }

  pin(index: number, event: Event): void {
    event.stopPropagation();
    this.visionBoard.requestPin(this.photoFor(index));
  }

  searchSimilar(index: number, event: Event): void {
    event.stopPropagation();
    this.visionBoard.searchSimilarLook(this.photoFor(index));
  }

  reimagine(index: number, event: Event): void {
    event.stopPropagation();
    this.toast.show('Opening Reimagine Space for this photo...');
  }

  formatPrice(price: number): string {
    return price.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
  }

  setDownPaymentPercent(value: number): void {
    this.downPaymentPercent.set(value);
  }

  setInterestRate(value: number): void {
    this.interestRate.set(value);
  }

  setLoanTermYears(value: number): void {
    this.loanTermYears.set(value);
  }

  requestTour(): void {
    this.toast.show('Tour request sent to your agent.');
  }

  contactAgent(): void {
    this.toast.show(`Message sent to ${this.agent.name}.`);
  }
}
