export interface Photo {
  id: string;
  url: string;
  room: string;
  caption: string;
  /** Defaults to 'photo' when omitted; 'floor-plan' photos are filtered into the Floor Plan tab. */
  kind?: 'photo' | 'floor-plan';
}
