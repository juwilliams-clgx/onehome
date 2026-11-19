import { Routes } from '@angular/router';
import { PropertyGridComponent } from './components/property-grid/property-grid';
import { PhotoViewerComponent } from './components/photo-viewer/photo-viewer';
import { PropertyDetailComponent } from './components/property-detail/property-detail';
import { CapacityLimitMockupComponent } from './components/capacity-limit-mockup/capacity-limit-mockup';
import { ManageListComponent } from './components/manage-list/manage-list';
import { UatPropertyListComponent } from './components/uat-property-list/uat-property-list';
import { CompareViewComponent } from './components/compare-view/compare-view';
import { AgentListingsComponent } from './components/agent-listings/agent-listings';
import { AgentPhotoUploadComponent } from './components/agent-photo-upload/agent-photo-upload';
import { ServiceUnavailableMockupComponent } from './components/service-unavailable-mockup/service-unavailable-mockup';

export const routes: Routes = [
  { path: '', component: PropertyGridComponent },
  { path: 'vision-board', component: PhotoViewerComponent },
  { path: 'property/:id', component: PropertyDetailComponent },
  { path: 'compare', component: CompareViewComponent },
  { path: 'mockup/capacity-limit', component: CapacityLimitMockupComponent, data: { listName: 'Favorites' } },
  {
    path: 'mockup/capacity-limit/favorites',
    component: CapacityLimitMockupComponent,
    data: { listName: 'Favorites' },
  },
  {
    path: 'mockup/capacity-limit/dislikes',
    component: CapacityLimitMockupComponent,
    data: { listName: 'Dislikes' },
  },
  { path: 'my-properties/favorites', component: ManageListComponent, data: { listName: 'Favorites' } },
  { path: 'my-properties/dislikes', component: ManageListComponent, data: { listName: 'Dislikes' } },
  { path: 'uat/properties', component: UatPropertyListComponent },
  { path: 'agent/listings', component: AgentListingsComponent },
  { path: 'agent/listings/:id/photos', component: AgentPhotoUploadComponent },
  { path: 'mockup/service-unavailable', component: ServiceUnavailableMockupComponent },
];

