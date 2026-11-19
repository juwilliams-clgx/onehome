export interface Listing {
  id: string;
  address: string;
  cityStateZip: string;
  price: number;
  beds: number;
  baths: number;
  sqft: number;
  status: 'For Sale' | 'Pending' | 'Sold';
  images: string[];
  /** Days since the listing went live; drives the freshness badge. */
  daysOnMarket: number;
  priceDropped?: boolean;
  isAgentPick?: boolean;
  /** MLS "Listing Visibility" field. Drives the AOTF-18112 "Limited Exposure" badge. */
  visibility?: 'PUBLIC' | 'LMTD';
  mlsNumber: string;
  description: string;
  yearBuilt: number;
  lotSizeAcres: number;
  garageSpaces: number;
  county: string;
  subdivision: string;
  lat: number;
  lng: number;
  schools: {
    elementary: string;
    middle: string;
    high: string;
  };
}
