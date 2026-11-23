import { Injectable, signal } from '@angular/core';

export interface AiChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

const API_URL = 'http://localhost:4300/api/ai-search';

const GREETING: AiChatMessage = {
  role: 'assistant',
  content:
    "Hi! Tell me what you're looking for \u2014 price range, bedrooms, a city, anything \u2014 and I'll narrow down the results for you.",
};

/**
 * POC conversational search, mirroring a ChatGPT-style chat mode. Talks to the
 * new server/ Express backend (server/index.js) rather than calling an LLM
 * directly from the browser, since that would expose the API key to anyone
 * who opens devtools. The backend turns natural language into a structured
 * filter object (via OpenAI tool calling) and applies it deterministically
 * against the shared mock listings dataset, then returns both a
 * conversational reply and the resulting listing ids - this service just
 * relays that round trip and exposes it as signals for the panel and grid to
 * read.
 */
@Injectable({ providedIn: 'root' })
export class AiSearchService {
  readonly isOpen = signal(false);
  readonly messages = signal<AiChatMessage[]>([]);
  readonly sending = signal(false);
  /** Short chip labels describing the currently-applied filters, e.g. "3+ bd", "< $900K". */
  readonly activeFilters = signal<string[]>([]);
  /** null = show every listing; otherwise restrict the grid to just these ids. */
  readonly visibleListingIds = signal<string[] | null>(null);

  open(): void {
    this.isOpen.set(true);
    if (this.messages().length === 0) {
      this.messages.set([GREETING]);
    }
  }

  close(): void {
    this.isOpen.set(false);
  }

  async send(text: string): Promise<void> {
    const trimmed = text.trim();
    if (!trimmed || this.sending()) return;

    const next: AiChatMessage[] = [...this.messages(), { role: 'user', content: trimmed }];
    this.messages.set(next);
    this.sending.set(true);

    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: next }),
      });
      const data = await res.json();
      this.messages.set([...next, { role: 'assistant', content: data.reply }]);
      this.activeFilters.set(data.filters ?? []);
      this.visibleListingIds.set(data.matchingIds ?? null);
    } catch {
      this.messages.set([
        ...next,
        { role: 'assistant', content: "I couldn't reach the AI search service \u2014 is the server running?" },
      ]);
    } finally {
      this.sending.set(false);
    }
  }

  /** Clears the applied filters (back to showing every listing) without touching the transcript. */
  clearFilters(): void {
    this.activeFilters.set([]);
    this.visibleListingIds.set(null);
  }
}
