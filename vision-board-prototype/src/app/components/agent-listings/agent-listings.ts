import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { MOCK_LISTINGS } from '../../mock-listings';

@Component({
  selector: 'app-agent-listings',
  standalone: true,
  imports: [RouterLink],
  templateUrl: './agent-listings.html',
  styleUrl: './agent-listings.scss',
})
export class AgentListingsComponent {
  protected readonly listings = MOCK_LISTINGS;
}
