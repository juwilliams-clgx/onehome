import { Photo } from './models/photo.model';

// Unsplash stock photography, used here as stand-ins for real MLS listing photos.
function unsplash(photoId: string): string {
  return `https://images.unsplash.com/${photoId}?auto=format&fit=crop&w=1200&q=80`;
}

export const MOCK_PHOTOS: Photo[] = [
  {
    id: 'p1',
    room: 'Living Room',
    caption: 'Open-concept living room with floating staircase and skylight.',
    url: unsplash('photo-1600210492486-724fe5c67fb0'),
  },
  {
    id: 'p2',
    room: 'Primary Bedroom',
    caption: 'Bright primary bedroom with patterned accent pillows.',
    url: unsplash('photo-1540518614846-7eded433c457'),
  },
  {
    id: 'p3',
    room: 'Kitchen',
    caption: 'Modern kitchen with waterfall island and pendant lighting.',
    url: unsplash('photo-1600585154340-be6161a56a0c'),
  },
  {
    id: 'p4',
    room: 'Primary Bathroom',
    caption: 'Spa-style bathroom with backlit mirror and soaking tub.',
    url: unsplash('photo-1620626011761-996317b8d101'),
  },
  {
    id: 'p5',
    room: 'Dining Room',
    caption: 'Formal dining room with glass table and statement chandelier.',
    url: unsplash('photo-1617104551722-3b2d51366400'),
  },
  {
    id: 'p6',
    room: 'Backyard',
    caption: 'Landscaped backyard with covered patio and fire pit.',
    url: unsplash('photo-1601760562234-9814eea6663a'),
  },
  {
    id: 'p7',
    room: 'Floor Plan',
    caption: 'Main level floor plan.',
    url: '/floor-plan.svg',
    kind: 'floor-plan',
  },
];
