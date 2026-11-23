import { Injectable, signal } from '@angular/core';

export interface AiChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export type VoiceState = 'idle' | 'connecting' | 'listening' | 'error';

const API_BASE = 'http://localhost:4300';
const API_URL = `${API_BASE}/api/ai-search`;
const REALTIME_SESSION_URL = `${API_BASE}/api/realtime-session`;
const APPLY_FILTERS_URL = `${API_BASE}/api/apply-filters`;

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
 *
 * Voice mode is the real thing, not speech-to-text bolted onto the text path
 * above: it opens a live WebRTC connection directly to OpenAI's Realtime API
 * (true voice-to-voice, the same technology behind ChatGPT's voice mode),
 * using a short-lived ephemeral token minted by the backend so the real API
 * key never reaches the browser. Function calls the model makes mid-
 * conversation (apply_filters/clear_filters) are executed by the same
 * backend tool executor the text path uses (POST /api/apply-filters), and
 * update the exact same activeFilters/visibleListingIds signals - so the
 * grid filters identically regardless of whether the user typed or spoke.
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

  readonly voiceState = signal<VoiceState>('idle');
  readonly voiceError = signal<string | null>(null);

  private peerConnection?: RTCPeerConnection;
  private dataChannel?: RTCDataChannel;
  private micStream?: MediaStream;
  private remoteAudioEl?: HTMLAudioElement;

  open(): void {
    this.isOpen.set(true);
    if (this.messages().length === 0) {
      this.messages.set([GREETING]);
    }
  }

  close(): void {
    this.isOpen.set(false);
    this.stopVoice();
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

  // ---------------------------------------------------------------------
  // Voice mode (OpenAI Realtime API over WebRTC)
  // ---------------------------------------------------------------------

  async startVoice(): Promise<void> {
    if (this.voiceState() === 'connecting' || this.voiceState() === 'listening') return;
    this.voiceState.set('connecting');
    this.voiceError.set(null);

    try {
      const tokenRes = await fetch(REALTIME_SESSION_URL, { method: 'POST' });
      if (!tokenRes.ok) {
        const body = await tokenRes.json().catch(() => ({}));
        throw new Error(body.error ?? 'Could not start a voice session.');
      }
      const session = await tokenRes.json();
      const ephemeralKey: string = session.value;

      const pc = new RTCPeerConnection();
      this.peerConnection = pc;

      this.remoteAudioEl = document.createElement('audio');
      this.remoteAudioEl.autoplay = true;
      pc.ontrack = (event) => {
        if (this.remoteAudioEl) this.remoteAudioEl.srcObject = event.streams[0];
      };

      this.micStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.micStream.getTracks().forEach((track) => pc.addTrack(track, this.micStream!));

      const dc = pc.createDataChannel('oai-events');
      this.dataChannel = dc;
      dc.addEventListener('message', (event) => this.handleRealtimeEvent(JSON.parse(event.data)));
      dc.addEventListener('open', () => this.voiceState.set('listening'));

      const offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      const sdpRes = await fetch('https://api.openai.com/v1/realtime/calls?model=gpt-realtime', {
        method: 'POST',
        body: offer.sdp,
        headers: {
          Authorization: `Bearer ${ephemeralKey}`,
          'Content-Type': 'application/sdp',
        },
      });
      if (!sdpRes.ok) throw new Error('OpenAI rejected the voice connection request.');
      const answerSdp = await sdpRes.text();
      await pc.setRemoteDescription({ type: 'answer', sdp: answerSdp });
    } catch (err) {
      this.voiceState.set('error');
      this.voiceError.set(err instanceof Error ? err.message : 'Could not start voice mode.');
      this.stopVoice();
    }
  }

  stopVoice(): void {
    this.dataChannel?.close();
    this.dataChannel = undefined;
    this.micStream?.getTracks().forEach((t) => t.stop());
    this.micStream = undefined;
    this.peerConnection?.close();
    this.peerConnection = undefined;
    this.remoteAudioEl = undefined;
    if (this.voiceState() !== 'error') this.voiceState.set('idle');
  }

  /** Server events arriving over the WebRTC data channel - see https://platform.openai.com/docs/guides/realtime */
  private handleRealtimeEvent(event: any): void {
    switch (event.type) {
      case 'conversation.item.input_audio_transcription.completed':
        if (event.transcript) {
          this.messages.update((m) => [...m, { role: 'user', content: event.transcript }]);
        }
        break;

      case 'response.audio_transcript.done':
        if (event.transcript) {
          this.messages.update((m) => [...m, { role: 'assistant', content: event.transcript }]);
        }
        break;

      case 'response.done': {
        const outputs = event.response?.output ?? [];
        for (const output of outputs) {
          if (output.type === 'function_call') {
            this.handleFunctionCall(output.name, output.arguments, output.call_id);
          }
        }
        break;
      }

      case 'error':
        this.voiceError.set(event.error?.message ?? 'Voice session error.');
        break;
    }
  }

  private async handleFunctionCall(name: string, argsJson: string, callId: string): Promise<void> {
    let args: unknown = {};
    try {
      args = JSON.parse(argsJson || '{}');
    } catch {
      /* ignore malformed args */
    }

    const res = await fetch(APPLY_FILTERS_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, arguments: args }),
    });
    const result = await res.json();

    this.activeFilters.set(result.filters ?? []);
    this.visibleListingIds.set(result.matchingIds ?? null);

    this.dataChannel?.send(
      JSON.stringify({
        type: 'conversation.item.create',
        item: {
          type: 'function_call_output',
          call_id: callId,
          output: JSON.stringify({ matchCount: result.matchCount, matches: result.matchSummaries }),
        },
      }),
    );
    this.dataChannel?.send(JSON.stringify({ type: 'response.create' }));
  }
}
