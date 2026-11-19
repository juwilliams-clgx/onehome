/**
 * Pure crop math shared by the live cropper UI and the default-thumbnail generator.
 * Framework-agnostic on purpose so the same model can be mirrored in native Swift.
 *
 * Model: a photo is cropped by scaling it to fill a fixed-aspect frame window (the
 * Instagram/Airbnb "pinch to fill" pattern, not a resizable selection box) and panning
 * it behind that frame. `CropState` is stored NORMALIZED — independent of any
 * particular frame's rendered pixel size — so the same saved crop renders identically
 * whether it's drawn into a 480px thumbnail, a responsive live-editing frame that's a
 * different size on phone vs. desktop, or a native view: `zoom` is relative to that
 * photo's own cover-fit scale (1 = default/untouched, up to MAX_ZOOM_MULTIPLIER), and
 * offsets are fractions of the frame's own width/height, not raw pixels.
 */
export interface CropState {
  /** 1 = default cover-fit (no extra zoom). Larger values zoom in further. */
  zoom: number;
  /** Pan as a fraction of frame width, e.g. 0.1 = shifted right by 10% of the frame. */
  offsetXFrac: number;
  /** Pan as a fraction of frame height. */
  offsetYFrac: number;
}

export const DEFAULT_CROP_STATE: CropState = { zoom: 1, offsetXFrac: 0, offsetYFrac: 0 };

export interface PixelCrop {
  scale: number;
  offsetX: number;
  offsetY: number;
}

export interface ZoomBounds {
  minZoom: number;
  maxZoom: number;
}

const MAX_ZOOM_MULTIPLIER = 4;

/** How far beyond the target ratio a photo's native aspect can be before it needs a visible nudge to adjust. */
export const NEAR_RATIO_TOLERANCE = 0.03;

export function isNearAspectRatio(naturalWidth: number, naturalHeight: number, targetRatio: number): boolean {
  if (!naturalWidth || !naturalHeight) return false;
  const ratio = naturalWidth / naturalHeight;
  return Math.abs(ratio / targetRatio - 1) <= NEAR_RATIO_TOLERANCE;
}

export function zoomBounds(): ZoomBounds {
  return { minZoom: 1, maxZoom: MAX_ZOOM_MULTIPLIER };
}

function coverFitScale(naturalWidth: number, naturalHeight: number, frameWidth: number, frameHeight: number): number {
  return Math.max(frameWidth / naturalWidth, frameHeight / naturalHeight);
}

/** Converts a normalized, frame-size-independent state into actual pixel values for one specific rendered frame. */
export function toPixelCrop(
  state: CropState,
  naturalWidth: number,
  naturalHeight: number,
  frameWidth: number,
  frameHeight: number,
): PixelCrop {
  const scale = coverFitScale(naturalWidth, naturalHeight, frameWidth, frameHeight) * state.zoom;
  return { scale, offsetX: state.offsetXFrac * frameWidth, offsetY: state.offsetYFrac * frameHeight };
}

function fromPixelCrop(
  px: PixelCrop,
  naturalWidth: number,
  naturalHeight: number,
  frameWidth: number,
  frameHeight: number,
): CropState {
  const minScale = coverFitScale(naturalWidth, naturalHeight, frameWidth, frameHeight);
  return {
    zoom: px.scale / minScale,
    offsetXFrac: frameWidth ? px.offsetX / frameWidth : 0,
    offsetYFrac: frameHeight ? px.offsetY / frameHeight : 0,
  };
}

function maxPixelOffset(naturalSize: number, frameSize: number, scale: number): number {
  return Math.max(0, (naturalSize * scale - frameSize) / 2);
}

/** Clamps a normalized state so the image never shows a gap or an edge inside the frame. */
export function clampCrop(
  state: CropState,
  naturalWidth: number,
  naturalHeight: number,
  frameWidth: number,
  frameHeight: number,
): CropState {
  const { minZoom, maxZoom } = zoomBounds();
  const zoom = Math.min(maxZoom, Math.max(minZoom, state.zoom));
  const px = toPixelCrop({ ...state, zoom }, naturalWidth, naturalHeight, frameWidth, frameHeight);
  const maxX = maxPixelOffset(naturalWidth, frameWidth, px.scale);
  const maxY = maxPixelOffset(naturalHeight, frameHeight, px.scale);
  const clampedPx = {
    scale: px.scale,
    offsetX: Math.min(maxX, Math.max(-maxX, px.offsetX)),
    offsetY: Math.min(maxY, Math.max(-maxY, px.offsetY)),
  };
  return fromPixelCrop(clampedPx, naturalWidth, naturalHeight, frameWidth, frameHeight);
}

/**
 * Zooms to `newZoom`, keeping the image point under focal point `d` (frame-local
 * pixels, relative to frame center, for THIS frame's current render size) fixed on
 * screen — the standard pinch/scroll-wheel zoom anchor. Returns a normalized state.
 */
export function zoomAnchored(
  state: CropState,
  newZoom: number,
  focalX: number,
  focalY: number,
  naturalWidth: number,
  naturalHeight: number,
  frameWidth: number,
  frameHeight: number,
): CropState {
  const px = toPixelCrop(state, naturalWidth, naturalHeight, frameWidth, frameHeight);
  const newScale = coverFitScale(naturalWidth, naturalHeight, frameWidth, frameHeight) * newZoom;
  const ratio = newScale / px.scale;
  const offsetX = focalX * (1 - ratio) + px.offsetX * ratio;
  const offsetY = focalY * (1 - ratio) + px.offsetY * ratio;
  const normalized = fromPixelCrop({ scale: newScale, offsetX, offsetY }, naturalWidth, naturalHeight, frameWidth, frameHeight);
  return clampCrop(normalized, naturalWidth, naturalHeight, frameWidth, frameHeight);
}

/** Pans by a raw pixel delta measured against this frame's current render size. */
export function panByPixels(
  state: CropState,
  dx: number,
  dy: number,
  naturalWidth: number,
  naturalHeight: number,
  frameWidth: number,
  frameHeight: number,
): CropState {
  const px = toPixelCrop(state, naturalWidth, naturalHeight, frameWidth, frameHeight);
  const moved = { scale: px.scale, offsetX: px.offsetX + dx, offsetY: px.offsetY + dy };
  return clampCrop(
    fromPixelCrop(moved, naturalWidth, naturalHeight, frameWidth, frameHeight),
    naturalWidth,
    naturalHeight,
    frameWidth,
    frameHeight,
  );
}

export interface SourceRect {
  sx: number;
  sy: number;
  sw: number;
  sh: number;
}

/** Natural-image-space rectangle currently visible inside the frame, for canvas export. */
export function sourceRectFor(
  state: CropState,
  naturalWidth: number,
  naturalHeight: number,
  frameWidth: number,
  frameHeight: number,
): SourceRect {
  const { scale, offsetX, offsetY } = toPixelCrop(state, naturalWidth, naturalHeight, frameWidth, frameHeight);
  const sw = frameWidth / scale;
  const sh = frameHeight / scale;
  const sx = naturalWidth / 2 - (offsetX + frameWidth / 2) / scale;
  const sy = naturalHeight / 2 - (offsetY + frameHeight / 2) / scale;
  return { sx, sy, sw, sh };
}

/**
 * Renders the final cropped raster. Frame width/height here only need to share the
 * frame's aspect ratio (any reference size works, e.g. the output size itself) since
 * the state is normalized.
 */
export function exportCrop(
  image: CanvasImageSource,
  state: CropState,
  naturalWidth: number,
  naturalHeight: number,
  outputWidth = 1200,
  outputHeight = 900,
  mimeType = 'image/jpeg',
  quality = 0.92,
): string {
  const { sx, sy, sw, sh } = sourceRectFor(state, naturalWidth, naturalHeight, outputWidth, outputHeight);
  const canvas = document.createElement('canvas');
  canvas.width = outputWidth;
  canvas.height = outputHeight;
  const ctx = canvas.getContext('2d')!;
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(image, sx, sy, sw, sh, 0, 0, outputWidth, outputHeight);
  return canvas.toDataURL(mimeType, quality);
}
