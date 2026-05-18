// Vercel serverless TTS proxy → Azure Cognitive Services Neural voices.
//
// Why: the browser Web Speech API ships robotic legacy voices on most
// devices. Azure Neural voices (Zariyah / Hamed for Arabic, Jenny / Guy
// for English) sound dramatically more natural. This proxy hides the
// Azure API key from the client and lets the SPA call it as a same-origin
// endpoint.
//
// Setup (one-time):
//   1. Create an Azure Speech resource (https://aka.ms/azure-speech) —
//      free tier F0 gives 500K characters/month of Neural TTS.
//   2. In Vercel project settings → Environment Variables, add:
//        AZURE_TTS_KEY     = <key 1 from the Azure resource>
//        AZURE_TTS_REGION  = <the region slug, e.g. "westeurope" or "eastus">
//   3. Redeploy. Done.
//
// Caching strategy: we serve audio with a 30-day immutable Cache-Control
// header AND key the request on the query string so Vercel's edge layer
// caches by (text, lang) tuple. The first user pays the Azure call; every
// subsequent user worldwide hits the edge.
//
// Cost ceiling: at the F0 free tier (500K chars/month), this serves ~10K
// average Hadith/Dua playbacks per month before any billing. Edge caching
// makes the effective ceiling much higher since each unique phrase only
// hits Azure once per cache lifetime.

const VOICES = {
  ar: 'ar-SA-ZariyahNeural',    // Saudi Arabic female, very natural
  ar_male: 'ar-SA-HamedNeural', // Saudi Arabic male
  en: 'en-US-JennyNeural',       // US English female, friendly
  en_male: 'en-US-GuyNeural',    // US English male
};

function escapeXml(s) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

export default async function handler(req, res) {
  // Only GET so the request is cacheable at the edge.
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return res.status(405).json({ error: 'GET only' });
  }

  const text = (req.query.text || '').toString();
  const lang = (req.query.lang || 'ar').toString();
  const gender = (req.query.gender || 'female').toString();

  if (!text || text.length > 2000) {
    return res.status(400).json({ error: 'text param required, max 2000 chars' });
  }

  const key = process.env.AZURE_TTS_KEY;
  const region = process.env.AZURE_TTS_REGION;

  // No keys configured — fail with 501 so the client can transparently
  // fall back to browser Web Speech without thinking it's a bug.
  if (!key || !region) {
    return res.status(501).json({ error: 'cloud TTS not configured' });
  }

  const voiceKey =
    lang === 'ar'
      ? gender === 'male' ? 'ar_male' : 'ar'
      : gender === 'male' ? 'en_male' : 'en';
  const voice = VOICES[voiceKey];
  const xmlLang = lang === 'ar' ? 'ar-SA' : 'en-US';

  // SSML — small prosody tweak: rate -10% for Arabic religious content
  // reads more reverent. English at neutral.
  const rate = lang === 'ar' ? '-10%' : '0%';
  const ssml =
    `<speak version='1.0' xml:lang='${xmlLang}'>` +
    `<voice name='${voice}'>` +
    `<prosody rate='${rate}'>${escapeXml(text)}</prosody>` +
    `</voice></speak>`;

  const azureUrl = `https://${region}.tts.speech.microsoft.com/cognitiveservices/v1`;

  try {
    const azureResp = await fetch(azureUrl, {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': key,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
        'User-Agent': 'aziz-academy',
      },
      body: ssml,
    });

    if (!azureResp.ok) {
      const detail = await azureResp.text().catch(() => '');
      console.error(`Azure TTS ${azureResp.status}: ${detail}`);
      return res.status(502).json({
        error: `upstream azure error ${azureResp.status}`,
      });
    }

    const buf = Buffer.from(await azureResp.arrayBuffer());

    res.setHeader('Content-Type', 'audio/mpeg');
    // 30-day immutable cache. Combined with the query-string key, this means
    // each unique (text, lang, gender) tuple only hits Azure once per month
    // per edge POP.
    res.setHeader(
      'Cache-Control',
      'public, max-age=2592000, s-maxage=2592000, immutable',
    );
    // Useful for debugging "did this come from edge cache?"
    res.setHeader('X-TTS-Source', 'azure-neural');
    return res.status(200).send(buf);
  } catch (err) {
    console.error('TTS proxy error:', err);
    return res.status(500).json({ error: 'proxy failure' });
  }
}
