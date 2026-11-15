// AgriSmart assistant proxy: a Cloudflare Worker that keeps the AI key on
// the server, so a public website never exposes it.
//
// Deploy (from this folder):
//   npx wrangler secret put AI_API_KEY      # paste the key when asked
//   npx wrangler deploy
// Then put the worker's address in .env as AI_PROXY_URL, leave AI_API_KEY
// empty, and rebuild the site.
//
// Works with Groq (default) or any OpenAI-compatible service: set
// AI_BASE_URL and MODEL in wrangler.toml.
//
// Request from the app: { system, language, messages:[{role, content}] }
// Response: { reply }

const ALLOWED_ORIGIN = '*'; // set to your site's address in production

export default {
  async fetch(request, env) {
    const cors = {
      'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };
    const json = (obj, status = 200) =>
      new Response(JSON.stringify(obj), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

    if (request.method === 'OPTIONS') return new Response(null, { headers: cors });
    if (request.method !== 'POST') return json({ error: 'POST only' }, 405);

    let body;
    try { body = await request.json(); } catch { return json({ error: 'Bad JSON' }, 400); }
    const messages = (body.messages || []).slice(-12)
      .map(m => ({ role: m.role === 'assistant' ? 'assistant' : 'user', content: String(m.content).slice(0, 4000) }));
    if (!messages.length) return json({ error: 'No messages' }, 400);

    const base = env.AI_BASE_URL || 'https://api.groq.com/openai/v1';
    const upstream = await fetch(`${base}/chat/completions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${env.AI_API_KEY}` },
      body: JSON.stringify({
        model: env.MODEL || 'llama-3.3-70b-versatile',
        max_tokens: 700,
        messages: [{ role: 'system', content: String(body.system || '').slice(0, 30000) }, ...messages],
      }),
    });
    if (!upstream.ok) return json({ error: await upstream.text() }, 502);
    const data = await upstream.json();
    return json({ reply: data.choices?.[0]?.message?.content || '' });
  },
};
