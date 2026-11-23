/**
 * Server-side copy of the mock listings dataset, trimmed to the fields the AI
 * search filter cares about. Mirrors vision-board-prototype's mock-listings.ts
 * and vision-board-ios's MockListings.swift (same ids, same values) - this
 * project already accepts one dataset duplicated per target rather than a
 * shared package, so a third copy here follows existing precedent instead of
 * introducing a new pattern.
 */
const LISTINGS = [
  { id: 'l1', address: '890 Park Lane', city: 'San Francisco', state: 'CA', county: 'San Francisco', price: 2450000, beds: 4, baths: 3, sqft: 3200, status: 'For Sale', yearBuilt: 2019 },
  { id: 'l2', address: '214 Cardinal Drive', city: 'Charlotte', state: 'NC', county: 'Mecklenburg', price: 610000, beds: 3, baths: 2, sqft: 2164, status: 'Sold', yearBuilt: 2022 },
  { id: 'l3', address: '48 Harborview Terrace', city: 'Seattle', state: 'WA', county: 'King', price: 985000, beds: 3, baths: 2, sqft: 1980, status: 'For Sale', yearBuilt: 2008 },
  { id: 'l4', address: '1200 Maplewood Court', city: 'Austin', state: 'TX', county: 'Travis', price: 745000, beds: 4, baths: 3, sqft: 2890, status: 'For Sale', yearBuilt: 2017 },
  { id: 'l5', address: '77 Lakeshore Drive', city: 'Chicago', state: 'IL', county: 'Cook', price: 1325000, beds: 5, baths: 4, sqft: 4100, status: 'Pending', yearBuilt: 2012 },
  { id: 'l6', address: '365 Willow Bend', city: 'Denver', state: 'CO', county: 'Denver', price: 560000, beds: 2, baths: 2, sqft: 1450, status: 'For Sale', yearBuilt: 2005 },
  { id: 'l7', address: '920 Sunset Ridge', city: 'Phoenix', state: 'AZ', county: 'Maricopa', price: 475000, beds: 3, baths: 2, sqft: 1760, status: 'For Sale', yearBuilt: 2015 },
  { id: 'l8', address: '53 Birchwood Lane', city: 'Raleigh', state: 'NC', county: 'Wake', price: 395000, beds: 2, baths: 1, sqft: 1120, status: 'For Sale', yearBuilt: 1948 },
];

module.exports = { LISTINGS };
