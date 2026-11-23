require('dotenv').config();
const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');
const { LISTINGS } = require('./listings');

const PORT = process.env.PORT || 4300;
const app = express();
app.use(cors());
app.use(express.json());

const apiKey = process.env.OPENAI_API_KEY;
const client = apiKey ? new OpenAI({ apiKey }) : null;

const SYSTEM_PROMPT = `You are OneHome's conversational search assistant, helping a home buyer narrow down
listings through natural conversation (similar to a ChatGPT-style conversational search mode). You have
access to a small set of real estate listings via the apply_filters and clear_filters tools - always call
one of those tools when the user describes criteria (price, beds, baths, city, state, or status) or asks to
reset/see everything again, rather than just describing listings yourself. Keep replies short, warm, and
conversational (1-2 sentences). If a message is a clarifying question with no filterable criteria yet
(e.g. "what can you help me find?"), you may reply without calling a tool.`;

/**
 * Canonical tool definitions, in the Realtime API's flat shape
 * ({ type, name, description, parameters }). The Chat Completions API (used
 * by the text /api/ai-search path) wants the same fields nested one level
 * deeper under "function" instead - CHAT_TOOLS below just re-shapes these
 * rather than maintaining two separate schemas that could drift apart.
 */
const TOOL_DEFS = [
  {
    name: 'apply_filters',
    description:
      "Filter the home listings by whatever criteria the user has described so far in the conversation. Only include fields the user actually specified or implied; omit anything unspecified.",
    parameters: {
      type: 'object',
      properties: {
        minPrice: { type: 'number', description: 'Minimum price in dollars' },
        maxPrice: { type: 'number', description: 'Maximum price in dollars' },
        minBeds: { type: 'number', description: 'Minimum number of bedrooms' },
        minBaths: { type: 'number', description: 'Minimum number of bathrooms' },
        city: { type: 'string', description: 'City name, e.g. "Austin"' },
        state: { type: 'string', description: 'Two-letter state code, e.g. "TX"' },
        status: { type: 'string', enum: ['For Sale', 'Pending', 'Sold'] },
      },
    },
  },
  {
    name: 'clear_filters',
    description: 'Reset the search back to showing every listing (the user wants to start over or see everything again).',
    parameters: { type: 'object', properties: {} },
  },
];

const CHAT_TOOLS = TOOL_DEFS.map((t) => ({ type: 'function', function: t }));
const REALTIME_TOOLS = TOOL_DEFS.map((t) => ({ type: 'function', ...t }));

function applyFilters(filters) {
  const f = filters || {};
  return LISTINGS.filter((l) => {
    if (f.minPrice != null && l.price < f.minPrice) return false;
    if (f.maxPrice != null && l.price > f.maxPrice) return false;
    if (f.minBeds != null && l.beds < f.minBeds) return false;
    if (f.minBaths != null && l.baths < f.minBaths) return false;
    if (f.city && l.city.toLowerCase() !== f.city.toLowerCase()) return false;
    if (f.state && l.state.toLowerCase() !== f.state.toLowerCase()) return false;
    if (f.status && l.status !== f.status) return false;
    return true;
  });
}

/** Turns the structured filter object into the short chip labels the UI shows (e.g. "3+ bd", "< $900K"). */
function summarizeFilters(filters) {
  if (!filters) return [];
  const chips = [];
  if (filters.minPrice != null) chips.push(`> $${Math.round(filters.minPrice / 1000)}K`);
  if (filters.maxPrice != null) chips.push(`< $${Math.round(filters.maxPrice / 1000)}K`);
  if (filters.minBeds != null) chips.push(`${filters.minBeds}+ bd`);
  if (filters.minBaths != null) chips.push(`${filters.minBaths}+ ba`);
  if (filters.city) chips.push(filters.city);
  if (filters.state) chips.push(filters.state);
  if (filters.status) chips.push(filters.status);
  return chips;
}

/** Runs a named tool call (apply_filters/clear_filters) against the shared listings dataset - the one
 *  place this actually happens, called by both the text path (below) and the voice path's function-call
 *  handler (client posts here after the Realtime session reports a completed function call). */
function runTool(name, args) {
  const isClear = name === 'clear_filters';
  const filters = isClear ? null : args || {};
  const matches = isClear ? LISTINGS : applyFilters(filters);
  return {
    filters: isClear ? null : summarizeFilters(filters),
    matchingIds: isClear ? null : matches.map((m) => m.id),
    matchCount: matches.length,
    matchSummaries: matches.map((m) => `${m.address}, ${m.city} ${m.state} - $${m.price.toLocaleString()}`),
  };
}

app.post('/api/ai-search', async (req, res) => {
  const messages = Array.isArray(req.body?.messages) ? req.body.messages : [];

  if (!client) {
    res.json({
      reply:
        "AI search isn't wired up yet in this environment \u2014 ask your developer to add an OPENAI_API_KEY to server/.env to enable it.",
      filters: null,
      matchingIds: null,
    });
    return;
  }

  try {
    const first = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'system', content: SYSTEM_PROMPT }, ...messages],
      tools: CHAT_TOOLS,
      tool_choice: 'auto',
    });

    const choice = first.choices[0].message;
    const toolCall = choice.tool_calls?.[0];

    if (!toolCall) {
      res.json({ reply: choice.content ?? "I'm not sure how to help with that yet.", filters: null, matchingIds: null });
      return;
    }

    const args = JSON.parse(toolCall.function.arguments || '{}');
    const result = runTool(toolCall.function.name, args);

    const second = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        ...messages,
        choice,
        {
          role: 'tool',
          tool_call_id: toolCall.id,
          content: JSON.stringify({ matchCount: result.matchCount, matches: result.matchSummaries }),
        },
      ],
    });

    res.json({
      reply: second.choices[0].message.content ?? `Found ${result.matchCount} matching listings.`,
      filters: result.filters,
      matchingIds: result.matchingIds,
    });
  } catch (err) {
    console.error('[ai-search] error', err);
    res.status(500).json({ reply: "Something went wrong reaching the AI search service. Please try again.", filters: null, matchingIds: null });
  }
});

/**
 * Mints a short-lived ("ephemeral") token the browser/app can use to open a
 * direct WebRTC voice session with OpenAI's Realtime API - this is the real
 * voice-to-voice mode (not speech-to-text bolted onto the text endpoint
 * above). The long-lived OPENAI_API_KEY never leaves this server; only the
 * ephemeral token (scoped, short expiry) is handed to the client.
 * See https://platform.openai.com/docs/guides/realtime-webrtc
 */
app.post('/api/realtime-session', async (req, res) => {
  if (!apiKey) {
    res.status(503).json({ error: "AI search isn't wired up yet \u2014 ask your developer to add an OPENAI_API_KEY to server/.env to enable it." });
    return;
  }

  try {
    const response = await fetch('https://api.openai.com/v1/realtime/client_secrets', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        session: {
          type: 'realtime',
          model: 'gpt-realtime',
          instructions: SYSTEM_PROMPT,
          audio: { output: { voice: 'marin' } },
          tools: REALTIME_TOOLS,
          tool_choice: 'auto',
        },
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error('[realtime-session] OpenAI error', response.status, text);
      res.status(502).json({ error: 'Failed to start a voice session with OpenAI.' });
      return;
    }

    const data = await response.json();
    res.json(data);
  } catch (err) {
    console.error('[realtime-session] error', err);
    res.status(500).json({ error: 'Failed to start a voice session.' });
  }
});

/** Shared tool executor for the voice path - see runTool() above. */
app.post('/api/apply-filters', (req, res) => {
  const { name, arguments: args } = req.body || {};
  if (name !== 'apply_filters' && name !== 'clear_filters') {
    res.status(400).json({ error: 'Unknown tool name' });
    return;
  }
  res.json(runTool(name, args));
});

app.listen(PORT, () => {
  console.log(`[ai-search] listening on http://localhost:${PORT}`);
  if (!client) {
    console.warn('[ai-search] OPENAI_API_KEY not set - responses will explain AI search is not configured yet.');
  }
});
