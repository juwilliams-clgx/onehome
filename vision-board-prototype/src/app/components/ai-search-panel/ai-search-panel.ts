import { Component, ElementRef, ViewChild, effect, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AiSearchService } from '../../services/ai-search.service';
import { IconComponent } from '../icon/icon';

/**
 * Conversational search panel - a ChatGPT-style chat mode for narrowing down
 * listings, opened from the search header's existing "AI Search" sparkle
 * chip (previously a stub that just showed a toast). Renders as a right-side
 * panel on desktop and a bottom sheet on mobile (same responsive pattern as
 * FilterSheetComponent), sitting alongside the grid rather than replacing
 * it - the grid keeps updating live, and the understood criteria stay
 * visible as removable chips, so the filtering stays transparent instead of
 * being a black box inside the conversation.
 */
@Component({
  selector: 'app-ai-search-panel',
  standalone: true,
  imports: [FormsModule, IconComponent],
  templateUrl: './ai-search-panel.html',
  styleUrl: './ai-search-panel.scss',
})
export class AiSearchPanelComponent {
  protected readonly aiSearch = inject(AiSearchService);
  protected draft = '';

  @ViewChild('scrollEl') private scrollEl?: ElementRef<HTMLDivElement>;

  constructor() {
    // Auto-scroll to the newest message whenever the transcript grows.
    effect(() => {
      this.aiSearch.messages();
      queueMicrotask(() => {
        const el = this.scrollEl?.nativeElement;
        if (el) el.scrollTop = el.scrollHeight;
      });
    });
  }

  close(): void {
    this.aiSearch.close();
  }

  send(): void {
    const text = this.draft;
    this.draft = '';
    this.aiSearch.send(text);
  }

  clearFilters(): void {
    this.aiSearch.clearFilters();
  }

  toggleVoice(): void {
    const state = this.aiSearch.voiceState();
    if (state === 'listening' || state === 'connecting') {
      this.aiSearch.stopVoice();
    } else {
      this.aiSearch.startVoice();
    }
  }
}
