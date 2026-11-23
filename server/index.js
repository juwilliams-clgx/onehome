require('dotenv').config();
const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');
const { LISTINGS } = require('./listings');

const PORT = process.env.PORT || 4300;
const app = express();
app.use(cors());
app.use(express.json());

const client = process.env.OPENAI_API_KEY ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY }) : null;

const SYSTEM_PROMPT = `You are OneHome's conversational search assistant, helping a home buyer narrow down
listings through natural conversation (similar to a ChatGPT-style conversational search mode). You have
access to a small set of real estate listings via the apply_filters and clear_filters tools - always call
one of those tools when the user describes criteria (price, beds, baths, city, state, or status) or asks to
reset/see everything again, rather than just describing listings yourself. Keep replies short, warm, and
conversational (1-2 sentences). If a message is a clarifying question with no filterable criteria yet
(e.g. "what can you help me find?"), you may reply without calling a tool.`;

const TOOLS = [
  {
    type: 'function',
    function: {
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
  },
  {
    type: 'function',
    function: {
      name: 'clear_filters',
      description: 'Reset the search back to showing every listing (the user wants to start over or see everything again).',
      parameters: { type: 'object', properties: {} },
    },
  },
];

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
      tools: TOOLS,
      tool_choice: 'auto',
    });

    const choice = first.choices[0].message;
    const toolCall = choice.tool_calls?.[0];

    if (!toolCall) {
      res.json({ reply: choice.content ?? "I'm not sure how to help with that yet.", filters: null, matchingIds: null });
      return;
    }

    const isClear = toolCall.function.name === 'clear_filters';
    const filters = isClear ? null : JSON.parse(toolCall.function.arguments || '{}');
    const matches = isClear ? LISTINGS : applyFilters(filters);

    const second = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        ...messages,
        choice,
        {
          role: 'tool',
          tool_call_id: toolCall.id,
          content: JSON.stringify({
            matchCount: matches.length,
            matches: matches.map((m) => `${m.address}, ${m.city} ${m.state} - $${m.price.toLocaleString()}`),
          }),
        },
      ],
    });

    res.json({
      reply: second.choices[0].message.content ?? `Found ${matches.length} matching listings.`,
      filters: isClear ? null : summarizeFilters(filters),
      matchingIds: isClear ? null : matches.map((m) => m.id),
    });
  } catch (err) {
    console.error('[ai-search] error', err);
    res.status(500).json({ reply: "Something went wrong reaching the AI search service. Please try again.", filters: null, matchingIds: null });
  }
});

app.listen(PORT, () => {
  console.log(`[ai-search] listening on http://localhost:${PORT}`);
  if (!client) {
    console.warn('[ai-search] OPENAI_API_KEY not set - responses will explain AI search is not configured yet.');
  }
});
