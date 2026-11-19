import {
  AfterViewInit,
  Component,
  ElementRef,
  EventEmitter,
  HostListener,
  Input,
  OnChanges,
  OnDestroy,
  Output,
  SimpleChanges,
  ViewChild,
  signal,
} from '@angular/core';
import { IconComponent } from '../icon/icon';
import {
  CropState,
  DEFAULT_CROP_STATE,
  clampCrop,
  exportCrop,
  panByPixels,
  toPixelCrop,
  zoomAnchored,
  zoomBounds,
} from './crop-math';

export interface CropResult {
  dataUrl: string;
  state: CropState;
}

interface Pointer {
  x: number;
  y: number;
}

/**
 * Full-screen "pinch to fill" photo cropper, locked to a fixed aspect ratio (4:3 by
 * default for listing photos). One instance is reused across a batch by updating
 * @Input()s; `ngOnChanges` reloads the image and restores that photo's saved crop.
 */
@Component({
  selector: 'app-photo-cropper',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './photo-cropper.html',
  styleUrl: './photo-cropper.scss',
})
export class PhotoCropperComponent implements OnChanges, AfterViewInit, OnDestroy {
  @Input({ required: true }) imageUrl!: string;
  @Input() aspectRatio = 4 / 3;
  @Input() initialState?: CropState;
  @Input() stepLabel = '';
  @Input() canPrev = false;
  @Input() canNext = false;
  @Input() title = 'Adjust photo';

  @Output() apply = new EventEmitter<CropResult>();
  @Output() cancelled = new EventEmitter<void>();
  @Output() prevPhoto = new EventEmitter<void>();
  @Output() nextPhoto = new EventEmitter<void>();

  @ViewChild('frame', { static: true }) frameRef!: ElementRef<HTMLDivElement>;

  protected readonly state = signal<CropState>(DEFAULT_CROP_STATE);
  protected readonly gridVisible = signal(false);
  protected readonly ready = signal(false);
  protected readonly workingSrc = signal('');
  protected readonly isPanning = signal(false);

  private naturalW = 0;
  private naturalH = 0;
  private frameW = 0;
  private frameH = 0;
  private frameMeasured = false;
  private sourceEl: HTMLImageElement | null = null;
  private resizeObserver?: ResizeObserver;
  private pointers = new Map<number, Pointer>();
  private lastPinchDist = 0;
  private gridFadeTimer?: ReturnType<typeof setTimeout>;

  ngOnChanges(changes: SimpleChanges): void {
    // The frame's pixel size isn't known until it's measured in ngAfterViewInit; on the
    // very first change (component just created), defer loading until that measurement lands.
    if (changes['imageUrl'] && this.frameMeasured) {
      this.loadImage(this.imageUrl, this.initialState);
    }
  }

  ngAfterViewInit(): void {
    const el = this.frameRef.nativeElement;
    // Measure synchronously up front rather than relying solely on ResizeObserver's
    // initial callback: some environments (and some older engines) don't reliably
    // deliver that first observation, which would otherwise leave the cropper stuck
    // showing "Loading…" forever. ResizeObserver still drives later size changes
    // (e.g. rotating the device, resizing the window).
    const box = el.getBoundingClientRect();
    this.frameW = box.width;
    this.frameH = box.height;
    this.frameMeasured = true;
    this.loadImage(this.imageUrl, this.initialState);

    this.resizeObserver = new ResizeObserver((entries) => {
      const rect = entries[0].contentRect;
      this.frameW = rect.width;
      this.frameH = rect.height;
      // No reclamping needed on resize: CropState is normalized (frame-size
      // independent), so the same stored state still renders the same crop at any size.
    });
    this.resizeObserver.observe(el);
  }

  ngOnDestroy(): void {
    this.resizeObserver?.disconnect();
    clearTimeout(this.gridFadeTimer);
  }

  private loadImage(url: string, restoreState?: CropState): void {
    this.ready.set(false);
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      this.sourceEl = img;
      this.naturalW = img.naturalWidth;
      this.naturalH = img.naturalHeight;
      this.workingSrc.set(url);
      const state = restoreState ?? DEFAULT_CROP_STATE;
      this.state.set(clampCrop(state, this.naturalW, this.naturalH, this.frameW, this.frameH));
      this.ready.set(true);
    };
    img.src = url;
  }

  /** The live CSS transform for the current state, resolved against this frame's actual render size. */
  protected transform(): string {
    if (!this.frameW || !this.naturalW) return '';
    const px = toPixelCrop(this.state(), this.naturalW, this.naturalH, this.frameW, this.frameH);
    return `translate(${px.offsetX}px, ${px.offsetY}px) scale(${px.scale})`;
  }

  protected zoomPercent(): number {
    const { minZoom, maxZoom } = zoomBounds();
    return ((this.state().zoom - minZoom) / (maxZoom - minZoom)) * 100;
  }

  protected onZoomSlider(value: number): void {
    const { minZoom, maxZoom } = zoomBounds();
    const newZoom = minZoom + (value / 100) * (maxZoom - minZoom);
    this.state.set(zoomAnchored(this.state(), newZoom, 0, 0, this.naturalW, this.naturalH, this.frameW, this.frameH));
    this.flashGrid();
  }

  protected nudgeZoom(delta: number): void {
    this.onZoomSlider(Math.min(100, Math.max(0, this.zoomPercent() + delta)));
  }

  protected resetCrop(): void {
    this.state.set(DEFAULT_CROP_STATE);
  }

  protected rotate(): void {
    if (!this.sourceEl) return;
    const w = this.naturalH;
    const h = this.naturalW;
    const canvas = document.createElement('canvas');
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext('2d')!;
    ctx.translate(w / 2, h / 2);
    ctx.rotate(Math.PI / 2);
    ctx.drawImage(this.sourceEl, -this.naturalW / 2, -this.naturalH / 2);
    const dataUrl = canvas.toDataURL('image/png');
    const rotated = new Image();
    rotated.onload = () => {
      this.sourceEl = rotated;
      this.naturalW = w;
      this.naturalH = h;
      this.workingSrc.set(dataUrl);
      this.state.set(DEFAULT_CROP_STATE);
    };
    rotated.src = dataUrl;
  }

  private flashGrid(): void {
    this.gridVisible.set(true);
    clearTimeout(this.gridFadeTimer);
    this.gridFadeTimer = setTimeout(() => this.gridVisible.set(false), 500);
  }

  private frameLocalPoint(clientX: number, clientY: number): Pointer {
    const rect = this.frameRef.nativeElement.getBoundingClientRect();
    return { x: clientX - (rect.left + rect.width / 2), y: clientY - (rect.top + rect.height / 2) };
  }

  protected onPointerDown(ev: PointerEvent): void {
    // Capture failures (e.g. a non-native/synthetic pointer id) shouldn't prevent
    // tracking the gesture — capture only makes dragging past the frame's edge keep
    // working, it isn't required for the rest of the pan/zoom logic below.
    try {
      (ev.target as HTMLElement).setPointerCapture(ev.pointerId);
    } catch {
      /* ignore */
    }
    this.pointers.set(ev.pointerId, { x: ev.clientX, y: ev.clientY });
    this.lastPinchDist = 0;
    this.isPanning.set(true);
    this.flashGrid();
  }

  protected onPointerMove(ev: PointerEvent): void {
    if (!this.pointers.has(ev.pointerId)) return;
    ev.preventDefault();
    const prev = this.pointers.get(ev.pointerId)!;
    this.pointers.set(ev.pointerId, { x: ev.clientX, y: ev.clientY });

    if (this.pointers.size === 1) {
      const dx = ev.clientX - prev.x;
      const dy = ev.clientY - prev.y;
      this.state.set(panByPixels(this.state(), dx, dy, this.naturalW, this.naturalH, this.frameW, this.frameH));
      this.flashGrid();
      return;
    }

    // Pinch: two active pointers drive combined zoom + pan, anchored at their live midpoint.
    const [a, b] = [...this.pointers.values()];
    const dist = Math.hypot(a.x - b.x, a.y - b.y);
    const midClient = { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 };
    const mid = this.frameLocalPoint(midClient.x, midClient.y);

    if (this.lastPinchDist > 0) {
      const { minZoom, maxZoom } = zoomBounds();
      const targetZoom = Math.min(maxZoom, Math.max(minZoom, this.state().zoom * (dist / this.lastPinchDist)));
      this.state.set(
        zoomAnchored(this.state(), targetZoom, mid.x, mid.y, this.naturalW, this.naturalH, this.frameW, this.frameH),
      );
    }
    this.lastPinchDist = dist;
    this.flashGrid();
  }

  protected onPointerUp(ev: PointerEvent): void {
    this.pointers.delete(ev.pointerId);
    this.lastPinchDist = 0;
    if (this.pointers.size === 0) this.isPanning.set(false);
  }

  protected onWheel(ev: WheelEvent): void {
    ev.preventDefault();
    const { minZoom, maxZoom } = zoomBounds();
    const targetZoom = Math.min(maxZoom, Math.max(minZoom, this.state().zoom * (1 - ev.deltaY * 0.0015)));
    const focal = this.frameLocalPoint(ev.clientX, ev.clientY);
    this.state.set(
      zoomAnchored(this.state(), targetZoom, focal.x, focal.y, this.naturalW, this.naturalH, this.frameW, this.frameH),
    );
    this.flashGrid();
  }

  protected onDoubleClick(ev: MouseEvent): void {
    const { minZoom, maxZoom } = zoomBounds();
    const mid = (minZoom + maxZoom) / 2;
    const targetZoom = this.state().zoom > mid ? minZoom : mid;
    const focal = this.frameLocalPoint(ev.clientX, ev.clientY);
    this.state.set(
      zoomAnchored(this.state(), targetZoom, focal.x, focal.y, this.naturalW, this.naturalH, this.frameW, this.frameH),
    );
    this.flashGrid();
  }

  protected confirm(): void {
    if (!this.sourceEl) return;
    const dataUrl = exportCrop(this.sourceEl, this.state(), this.naturalW, this.naturalH);
    this.apply.emit({ dataUrl, state: this.state() });
  }

  protected goPrev(): void {
    this.confirm();
    this.prevPhoto.emit();
  }

  protected goNext(): void {
    this.confirm();
    this.nextPhoto.emit();
  }

  protected close(): void {
    this.confirm();
    this.cancelled.emit();
  }

  @HostListener('document:keydown.escape')
  protected onEscape(): void {
    this.close();
  }

  @HostListener('document:keydown.arrowleft')
  protected onArrowLeft(): void {
    if (this.canPrev) this.goPrev();
  }

  @HostListener('document:keydown.arrowright')
  protected onArrowRight(): void {
    if (this.canNext) this.goNext();
  }
}
