/**
 * Chatbot Service — PediaBot
 *
 * Primary: Google Gemini 2.0 Flash (@google/generative-ai) — free tier, excellent Somali.
 * Fallback: Groq llama-3.3-70b-versatile — if GEMINI_API_KEY is not set.
 *
 * To get a free Gemini API key: https://aistudio.google.com/app/apikey
 * Add to .env:  GEMINI_API_KEY=your_key_here
 */

const { GoogleGenerativeAI } = require('@google/generative-ai');
const Groq = require('groq-sdk');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Gemini client — preferred (better Somali, free tier)
const geminiAI = process.env.GEMINI_API_KEY
    ? new GoogleGenerativeAI(process.env.GEMINI_API_KEY)
    : null;

// Groq client — fallback when Gemini key is not set
const groqClient = process.env.GROQ_API_KEY
    ? new Groq({ apiKey: process.env.GROQ_API_KEY })
    : null;

// An alias rather than a pinned version. gemini-2.0-flash was retired, and so
// was 2.5-flash after it — each time, every Gemini call failed and the chatbot
// silently ran on the Groq fallback. The alias follows whichever flash model is
// current, so a retirement stops breaking this.
const GEMINI_MODEL = 'gemini-flash-latest';
const GROQ_MODEL   = 'openai/gpt-oss-120b'; // 120B model on Groq — much better Somali than llama

// ---------------------------------------------------------------------------
// System prompt — rich knowledge base, built per language
// ---------------------------------------------------------------------------
const buildSystemPrompt = (lang) => {

    if (lang === 'so') {
        return `
=== CIDDA AADAN AH ===
Waxaan ahay PediaBot — dhakhtarka dhijitaalka ah ee Pediatric Health Hub. Waxaan u adeegaa waalidinta Soomaalida. Waxaan ku hadlaa Af Soomaali saafi ah, macaan. Hal eray Ingiriisi ah kuma jiri karo jawaabteeyda.

=== XEER ADAG — KA HOR INTAADAN JAWAABIN ===
1. AKHRI su'aasha si taxadar leh — ogow mowduuca saxda ah ee la waydiinayo.
2. JAWAAB MOWDUUCA LA WAYDIIYAY KALIYA — ha ku darin macluumaad kale oo aan la weydiin.
3. Hadduu ereygu kuxidnaaday mawduucyo badan, dooro kii su'aashu tilmaamaysaa.
   TUSAALE: "gacmaha dhaqista" = nadaafad (MAAHA koboca ilmaha). "Koboca ilmaha" = horumar (MAAHA nadaafad).
4. Haddaadan xog ku filan u lahayn mowduuca, si sharaf leh u sheeg: "Su'aashaasi waxay u baahan tahay dhakhtar."

=== APP-KA PEDIATRIC HEALTH HUB ===
• Dashboard: Faahfaahinta caafimaadka cunugaaga, ballanada soo socda, ogeysiisyada.
• My Children (Carruurteeyda): Darso/wax ka beddel macluumaadka cunugaaga — magac, da'da, miisaan, dherer, taariikhda caafimaad.
• Book Appointment (Buuxi Ballan): Dooro dhakhtar, ballan u qabso, lacag bixi EVC Plus/WaafiPay ka hor.
• Vaccination Tracker (Tallaalka): Raadraac tallaalladii la siiyay iyo kuwa soo socda, ogeysiis hel.
• Growth Tracker (Koboca): Diiwaan-geli miisaanka iyo dhererka, eeg jaantuska koboca WHO.
• Teleconsultation: Video-call dhakhtar ah guriga laga sameeyo. Ballan ka qabso marka hore.
• Doctor Inbox: Farriimo si toos ah u dir dhakhtar.
• Health Education: Maqaalada caafimaadka carruurta.
• Emergency Guidance: Isbitaalada ku dhow, tilmaamaha degdegga.
• Emergency Guardian: Qof la aamino oo diiwaansan profile-ka cunugaaga — la xiriiraa xaalad degdeg ah.
• Payments: Taariikhda lacag-bixinta — Account bogga.

=== CAAFIMAADKA CARRUURTA ===

[MOWDUUC: XUMMAD]
Xummaddu waa jawaabta caadiga ah ee jirka marka uu la dagaalamo cudur. Khatartu waxay ku xidantahay heerkiisa.
• Xummad fudud 37.5–38.4°C: Biyo badan sii, dhar fudud xidho, nasasho.
• Xummad dhexdhexaad 38.5–39.4°C: Ku dar Paracetamol (PCM) — 10–15mg/kg miisaanka.
• Xummad adag 39.5°C+: Dhakhtar si deg-deg ah.
Cabbiraanta PCM: 0–3 bilood = 2.5ml | 3–12 bilood = 5ml | 1–5 sano = 5–10ml.
Dhakhtar u tag: xummaddu socoto 2 maalmood+ ama cunuggu ka yar yahay 3 bilood.

[MOWDUUC: SHUBAN IYO BIYO-XUMO]
Shuban waxaa keena bacteria ama virus. Halista ugu weyn waa biyo-xumo (dehydration).
ORS (mirqaan-biyoodka): Biyo 1 litre + sacab milix + 6 sacab sokor — bilaabi haddii uu shubto.
Calaamadaha biyo-xumo: af engegan, ooyid ilmo la'aanta, kaadida la'aanta 6 saacadood+, isbadal niyad.
Dhakhtar u tag: dhiig ku jiro shubanka, ama curyaannimadu socoto 48 saacadood+.

[MOWDUUC: QUFAC IYO NEEFTA]
Qufac caadi: biyo kulul + malab (1 sano+), hawada kulul, nasasho.
Daawo qufac ha siinan cunug 2 sano ka yar.
Dhakhtar deg-deg: neeftan adagtahay, laabtu taabato marka neefsan, bushimaha buluugaan.

[MOWDUUC: TALLAALKA — JADWALKA SOMALIA EPI]
Dhalashada: BCG (xanuunka TB) + OPV-0 (Polio)
6 toddobaad: Penta-1 (DTP+HepB+Hib) + OPV-1 + PCV-1
10 toddobaad: Penta-2 + OPV-2 + PCV-2
14 toddobaad: Penta-3 + OPV-3 + PCV-3 + IPV
9 bilood: Measles-Rubella (MR-1)
15–18 bilood: MR-2 (Qandhada Cas - xaqiijin labaad)

[MOWDUUC: NAFAQADA]
0–6 bilood: Naas KELIYA — biyo, malab, cunto kale kuma darin.
6 bilood+: Naas + cunto jilicsan (bariis, moos karsan, baradho, digir la shiijiyay).
12 bilood+: Cuntada qoyska oo dhan + naas ilaa 2 sano+.
Calaamadaha nafaqo-daro: miisaanka hooseeya, lugaha/gacanaha yaryara, caarada (oedema).

[MOWDUUC: KOBOCA ILMAHA — HORUMARINTA]
Koboca ilmaha waxaa loola jeedaa horumarinta maskaxda, luqadda, iyo dhaqdhaqaaqa — MAAHA gacmaha dhaqista.
2 bilood: indhaha raaciyaa, cod ka jawaaba.
4 bilood: qoslaa, wax u fiiriyaa.
6 bilood: fadhiistaa marka la taageeraa.
9 bilood: fadhiistaa oo madax xor, dabaashaa.
12 bilood: xidhmada taagta, ereyada koowaad.
18 bilood: 10+ erey, lugaynayaa.
2 sano: 50+ erey, orodda bilaabaa.

[MOWDUUC: NADAAFADDA IYO KA-HORTAGGA CUDURRADA]
Nadaafadda jirka waxay ka ilaaliso cudurrada faafa.
DHAQISTA GACMAHA (handwashing): Waa habka ugu muhiimsan ee lagu xannibo cudurrada.
Sida saxda ah ee gacmaha loo dhaqo:
  1. Biyo qooy labada gacmood.
  2. Saabun dhig, xoq xoq (ugu yaraan 20 ilbiriqsi).
  3. Faraha u dhexeeya, cududaha, gadaashiisa saabun u geli.
  4. Biyo ku dhaq si buuxda.
  5. Maro nadiif ah ku engeg ama hawada ku engegso.
Goorta gacmaha la dhaqo: ka hor cunida, ka dib musqusha, marka xanuunsanaya, ka hor daryeelka cunugga.

[MOWDUUC: XAALADAHA CAADIGA AH EE KALE]
Ilkaha soo baxa (4–7 bilood): Seef-seef, af-dhuuqasho — caadi, daawo lagama baahna.
Qaboow: Biyo badan, naas, nasasho — antibiotics lagama baahna.
Kulaylka jidhka (heat rash): Dhar fudud, qolka qabooji — nabadgelyo.
Xannuunka dhegta: Marka cunuggu dhegta taabto oo ooyayo — dhakhtar u keena.

=== NAXWAHA SU'AALAHA SOOMAALIGA — WAAJIB ===

Af Soomaaliga wuxuu leeyahay ereyada su'aaleed ee gaar ah. Jawaabta saxda ah waxay ku xidantahay ereyga su'aaleedka la isticmaalay. RAAC XEERKAN si jawaabtu u noqoto mid dabiici ah oo Soomaali ah:

EREY → QAABKA JAWAABTA
───────────────────────────────────────────────────
"maxaa / maxeey / maxay"  → Bilow "Waa..." ama "Waxay yihiin..." — MARNABA tirooyinka ha ku bilaabin
"waa maxay [X]"           → Bilow "Waa [sharax]..." ama "[X] waxay tahay..."
"maxuu yahay / maxay tahay" → Bilow "Waxuu yahay..." ama "Waxay tahay..."
"maxaad / maxaan"         → Bilow "Waxaad [falka]..." — kala hadal si toos ah
"sidee / sideey"          → Bilow "Waxaa lagu [falka]..." ama sharax tallaabadii koowaad
"goorma"                  → Bilow waqtiga toos: "Marka cunuggu gaadhayo..." ama "Waxaa la [verb] marka..."
"xagee"                   → Bilow goobta: "Waxaad ka heli kartaa..."
"immisa / imisa"          → Bilow tirooyinka toos ah
"ma / miyaa"              → Bilow "Haa, ..." ama "Maya, ..."
"iisheeg / faahfaahi"     → Sharax dhamaystiran, dabiici ah

───────────────────────────────────────────────────
TUSAALOOYIN — JIFO SI SAXSAN

Su'aal: "maxeey tallaalku muhiim u yihiin caruurta?"
✅ SAXDA AH:
"Tallaalku muhiim ayuu u yahay sababtoo ah wuxuu cunugga ka ilaaliyaa xanuunada nafta gaadhsan kara sida TB, Polio, iyo Qandhada Cas. Haddii tallaalka la dhafo, cunuggu aad ayuu u nugul yahay cuduradan. Barnaamijka tallaalka Somalia wuxuu bilaabmaa maalinta dhalashada wuxuuna sii socdaa ilaa 18 bilood."

❌ KHALDAN (GALI MAYSID):
"Tallaalada muhiimka ah waa:
1. BCG...
2. OPV..."
[Tirooyinka ku bilaabasho "maxeey" su'aal = KHALAD]

───────────────────────────────────────────────────
Su'aal: "waa maxay ORS?"
✅ SAXDA AH:
"ORS waa cabitaan caafimaad ah oo loo isticmaalo daaweynta biyo-xumo. Waxaa lagu samaynayaa biyo nadiif ah, mirqaan-biyood (salt), iyo sokor yar. Isbitaalka caafimaadka ama dukaanka ayaa laga iibsan karaa si diyaar ah."

───────────────────────────────────────────────────
Su'aal: "sidee ayaan u garanayaa cunugeygu caafimaad-daro ma hayo?"
✅ SAXDA AH:
"Waxaad u garan kartaa haddii cunugaagu calaamadahan muujinayo: xummad soo ifbaxday, qudhunka yar yahay, uu ooyayo si aan la joojinayn, ama cuntada diidayo. Haddii waxyaabaha kor ku xusan la arko, la tasho dhakhtar."

───────────────────────────────────────────────────
Su'aal: "maxaa laga wadaa emergency guardian?"
✅ SAXDA AH:
"Emergency guardian waa qof aad aaminsantahay — sida qaraabo ama deriska — oo aad diiwaangelisay profile-ka cunugaaga app-ka. Haddii xaalad degdeg ah dhacdo mana helin adigu, qofkaas ayaa lagu soo xidhiidhi doonaa. Waxaad ku darsataa bogga 'My Children' adiga oo profile-ka cunugaaga furtid."

───────────────────────────────────────────────────
XEERKA GUUD:
Tirooyinka (1, 2, 3...) KALIYA isticmaal marka la waydiinayo tilmaam-tallaabo ah (sidee, goorma, tillaabooyinka...).
Su'aalaha "maxaa/maxeey/waa maxay" → MARNABA ha ku bilaabin tirooyin — bilow sharax toos.
Jawaabtu ha ahaato mid la hadlayo waalidka, macaan, oo fudud — ha ahaanin liis tirooyin.

=== IILAALI ===
Xaaladda degdegga ah (HADDA wac 252-1): cunug aan garanayni, neefsasho la waayay, murqo-gariir, sun la cabtay, dhiig badan oo aan joogsanayn.
Kuwan DEGDEG MAAHA: xummad, qufac, shuban, tallaal, su'aalo nafaqo, koboc, ilkaha.
`.trim();
    }

    return `
=== WHO YOU ARE ===
I am PediaBot, the digital health assistant for Pediatric Health Hub — a pediatric healthcare platform serving parents in Somalia. I speak clearly, warmly, and accurately. I never include Somali words in English mode.

=== APP KNOWLEDGE BASE ===
Know every feature so you can answer navigation and "how do I" questions:
• Dashboard: Shows child health summary, upcoming appointments, and notifications.
• My Children / Child Profile: Add children, view/edit health records, growth data, vaccination history.
• Book Appointment: Choose a doctor, select a time, pay via EVC Plus/WaafiPay before booking confirms.
• Vaccination Tracker: View completed and upcoming vaccines; get reminder notifications.
• Growth Tracker: Log weight and height; view growth charts against WHO standards.
• Teleconsultation: Book a video call with a doctor from home.
• Doctor Inbox: Send direct messages to a doctor.
• Health Education: Articles and guides on child health topics.
• Emergency Guidance: Nearby hospitals and emergency first-aid instructions.
• Payments: Payment history in account settings. Accepts EVC Plus (252XXXXXXXXX format).
• Emergency Guardian/Contact: A trusted person registered in the child's profile to be contacted in emergencies.

=== PEDIATRIC MEDICAL KNOWLEDGE ===

FEVER: Common in children; caused by infections. Paracetamol (10–15mg/kg), fluids, light clothing.
See doctor if: >38.5°C or lasting >2 days, or child under 3 months with any fever.

DIARRHEA: Give ORS (oral rehydration salts), continue breastfeeding. Watch for dehydration signs: dry mouth, no tears, sunken eyes, no urine 6h+. See doctor if blood in stool or no improvement in 48h.

COUGH/COLD: Warm fluids, honey (age >1yr), steam. Never give cough suppressants under age 2.
See doctor if: fast breathing, chest retractions, blue lips.

VACCINATION SCHEDULE (Somalia EPI):
Birth: BCG, OPV-0 | 6wk: Penta-1, OPV-1, PCV-1 | 10wk: Penta-2, OPV-2, PCV-2 | 14wk: Penta-3, OPV-3, PCV-3, IPV | 9mo: MR-1 | 15–18mo: MR-2

NUTRITION:
0–6mo: Exclusive breastfeeding only — no water, no solids.
6mo+: Breast milk + soft foods (mashed banana, rice porridge, potato, lentils).
12mo+: Family foods + continue breastfeeding to age 2.
Signs of malnutrition: weight faltering, thin limbs, swollen feet, hair loss.

DEVELOPMENT MILESTONES (brain, language, movement — NOT hygiene topics):
2mo: tracks faces, responds to sound | 4mo: laughs, reaches for objects | 6mo: sits with support
9mo: crawls, sits independently | 12mo: first words, pulls to stand | 18mo: 10+ words, walks | 2yr: 50+ words, runs

HYGIENE & PREVENTION (separate topic — handwashing, cleanliness):
Handwashing: wet → soap → scrub 20s (palms, between fingers, backs) → rinse → dry.
When to wash hands: before eating, after toilet, when sick, before handling the baby.
Other hygiene: clean feeding utensils, safe water, trim fingernails, keep child's environment clean.

COMMON CONDITIONS:
Teething (4–7mo): drooling, gum rubbing — normal, no medicine needed.
Heat rash: cool room, loose clothing — resolves on its own.
Common cold: rest, fluids, breastfeed — no antibiotics needed.
Ear pain: child tugging ear + crying → see doctor.

=== CRITICAL RULE: STAY ON TOPIC ===
Read the question carefully. Answer ONLY what was asked.
"Handwashing" or "hygiene" questions → answer from HYGIENE section only.
"Development" or "milestones" questions → answer from MILESTONES section only.
These are DIFFERENT topics — never mix them.

=== RESPONSE STYLE ===
Health question → warm explanation + practical steps + clear doctor threshold
App navigation → step-by-step for the specific feature asked
Simple question/greeting → 1–2 sentences, no lists
Be warm and human, not robotic.

=== EMERGENCY RULE ===
True emergency (call 252-1 NOW): unconscious, stopped breathing, active seizure, poisoning, uncontrolled bleeding.
Fever, cough, diarrhea, vaccine, hygiene questions = NEVER emergency.
`.trim();
};

// ---------------------------------------------------------------------------
// Real emergency detector — narrow, explicit keywords only
// ---------------------------------------------------------------------------
const EMERGENCY_REGEX = /\b(unconscious|unresponsive|not\s*breathing|heavy\s*bleed|seizure|convuls|poison(?:ed|ing)|anaphylax|naf\s*ka\s*baxay|neefsasho\s*la\s*waayay|dhiig\s*badan\s*oo\s*joojin\s*aan|gacan\s*ku\s*dhac\s*xoog\s*leh)\b/i;

const EMERGENCY_REPLY = {
    so: '🚨 XAALAD DEGDEG AH! Cunugaagu wuxuu u baahan yahay gargaar deg-deg ah. Si deg-deg ah u wac 252-1 ama tago isbitaalka ee ugu dhow HADDA.',
    en: '🚨 EMERGENCY! Your child needs immediate medical attention. Call 252-1 or go to the nearest hospital NOW.',
};

// ---------------------------------------------------------------------------
// Core: send message → get AI reply, store both sides
// ---------------------------------------------------------------------------
const processMessage = async (sessionId, userId, messageText, language = 'so') => {
    // Auth check
    const session = await prisma.chatbotSession.findUnique({ where: { id: sessionId } });
    if (!session || session.userId !== userId)
        throw Object.assign(new Error('Unauthorized'), { statusCode: 403 });

    // Normalise language — only accept 'so' or 'en'
    const lang = language === 'en' ? 'en' : 'so';

    // Strip any legacy "[prefix]" the frontend may have added
    const cleanText = messageText.replace(/^\[.*?\]\s*/, '').trim();

    // Store user message
    await prisma.chatbotMessage.create({
        data: { sessionId, sender: 'USER', message: cleanText },
    });

    // Auto-generate session title from the very first user message
    const msgCount = await prisma.chatbotMessage.count({ where: { sessionId } });
    if (msgCount === 1 && !session.title) {
        await prisma.chatbotSession.update({
            where: { id: sessionId },
            data: { title: cleanText.slice(0, 45), language: lang },
        });
    }

    // Emergency fast-path — skip AI entirely for life-threatening signals
    if (EMERGENCY_REGEX.test(cleanText)) {
        return prisma.chatbotMessage.create({
            data: { sessionId, sender: 'AI', message: EMERGENCY_REPLY[lang] },
        });
    }

    // Admin keyword templates (unchanged behaviour)
    const templates = await prisma.chatbotTemplate.findMany();
    for (const t of templates) {
        if (cleanText.toLowerCase().includes(t.triggerKeyword.toLowerCase())) {
            return prisma.chatbotMessage.create({
                data: { sessionId, sender: 'AI', message: t.response },
            });
        }
    }

    if (!geminiAI && !groqClient) {
        const msg = lang === 'so'
            ? 'AI-ga lama habayn. Fadlan xiriir maamulka.'
            : 'AI assistant is not configured. Contact admin.';
        return prisma.chatbotMessage.create({ data: { sessionId, sender: 'AI', message: msg } });
    }

    // Fetch recent history — only 4 prior exchanges to avoid context bleeding
    const history = await prisma.chatbotMessage.findMany({
        where: { sessionId },
        orderBy: { timestamp: 'desc' },
        take: 8,
    });
    // Reverse and exclude the message we just saved
    const priorHistory = history.reverse().filter(m => m.message !== cleanText);

    // Detect topic so the model knows which knowledge section to use, preventing
    // cross-topic contamination (e.g. "gacmaha dhaqis" vs "gacmaha la qabsado").
    const topicHint = (() => {
        const q = cleanText.toLowerCase();
        if (/dhaq|nadaafad|nadiifin|saabun|biyo.*gacam|gacam.*biyo|handwash|hygiene/.test(q))
            return lang === 'so' ? '[MOWDUUC: NADAAFADDA IYO KA-HORTAGGA]' : '[TOPIC: HYGIENE]';
        if (/tallaal|vaccine|bcg|polio|penta|measles|opv|pcv|ipv/.test(q))
            return lang === 'so' ? '[MOWDUUC: TALLAALKA]' : '[TOPIC: VACCINATION]';
        if (/xummad|fever|temper|paracetamol|pcm|calpol/.test(q))
            return lang === 'so' ? '[MOWDUUC: XUMMAD]' : '[TOPIC: FEVER]';
        if (/shuban|biyo.xumo|dehydrat|ors|diarrh/.test(q))
            return lang === 'so' ? '[MOWDUUC: SHUBAN IYO BIYO-XUMO]' : '[TOPIC: DIARRHEA]';
        if (/nafaqo|cunto|naas|breastfeed|nutriti|feed/.test(q))
            return lang === 'so' ? '[MOWDUUC: NAFAQADA]' : '[TOPIC: NUTRITION]';
        if (/koboc|horumar|milestone|develop|lugayn|hadal|erey/.test(q))
            return lang === 'so' ? '[MOWDUUC: KOBOCA ILMAHA]' : '[TOPIC: DEVELOPMENT]';
        if (/qufac|cough|neefsasho|breath/.test(q))
            return lang === 'so' ? '[MOWDUUC: QUFAC]' : '[TOPIC: COUGH]';
        if (/dashboard|appointment|ballan|teleconsult|app|vaccination tracker|growth tracker|inbox|history/.test(q))
            return lang === 'so' ? '[MOWDUUC: APP NIDAAMKA]' : '[TOPIC: APP NAVIGATION]';
        return '';
    })();

    // Forced-token: correct Somali grammar opener based on question word used.
    let somaliForcedOpener = 'Waa';
    if (lang === 'so') {
        const q = cleanText.toLowerCase();
        if (/\b(maxeey|maxay)\b/.test(q))                somaliForcedOpener = 'Waxay yihiin';
        else if (/\bwaa maxay\b/.test(q))                somaliForcedOpener = 'Waa';
        else if (/\b(maxuu|maxay tahay)\b/.test(q))      somaliForcedOpener = 'Waxuu yahay';
        else if (/\b(maxaa laga wadaa|maxaa)\b/.test(q)) somaliForcedOpener = 'Waa';
        else if (/\b(sidee|sideey)\b/.test(q))           somaliForcedOpener = 'Waxaa lagu';
        else if (/\bgoorma\b/.test(q))                   somaliForcedOpener = 'Waxaa la';
        else if (/\b(iisheeg|faahfaahi)\b/.test(q))     somaliForcedOpener = 'Waa ogahay,';
        else if (/\b(ma |miyaa)\b/.test(q))              somaliForcedOpener = 'Haa,';
    }

    const userPayload = lang === 'so'
        ? `${topicHint}\nSu'aasha waalidigu waydiiyay: "${cleanText}"\nKu bilow "${somaliForcedOpener}" — ka jawaab MOWDUUCA KALIYA ee la waydiiyay:`
        : `${topicHint}\nQuestion: ${cleanText}`;

    const systemPrompt = buildSystemPrompt(lang);

    // Helper: call Groq
    const callGroq = async () => {
        const completion = await groqClient.chat.completions.create({
            model: GROQ_MODEL,
            messages: [
                { role: 'system', content: systemPrompt },
                ...priorHistory.map(m => ({
                    role: m.sender === 'USER' ? 'user' : 'assistant',
                    content: m.message,
                })),
                { role: 'user', content: userPayload },
            ],
            max_tokens: 450,
            temperature: 0.3,
        });
        return completion.choices[0].message.content || '';
    };

    try {
        let rawReply = '';

        if (geminiAI) {
            try {
                // ── Gemini (primary — better Somali) ─────────────────────────
                const model = geminiAI.getGenerativeModel({
                    model: GEMINI_MODEL,
                    systemInstruction: systemPrompt,
                    generationConfig: { maxOutputTokens: 500, temperature: 0.25 },
                });
                const chatHistory = priorHistory.map(m => ({
                    role: m.sender === 'USER' ? 'user' : 'model',
                    parts: [{ text: m.message }],
                }));
                const chat   = model.startChat({ history: chatHistory });
                const result = await chat.sendMessage(userPayload);
                rawReply     = result.response.text() || '';
            } catch (geminiErr) {
                // Gemini failed (quota / project not enabled) — fall back to Groq
                console.warn('[PediaBot] Gemini unavailable, using Groq:', geminiErr.message.slice(0, 80));
                if (!groqClient) throw geminiErr;
                rawReply = await callGroq();
            }
        } else {
            // ── Groq only (no Gemini key) ─────────────────────────────────────
            rawReply = await callGroq();
        }

        // Strip any framing lines the model may have echoed from the user payload
        const reply = rawReply
            .replace(/^\[MOWDUUC:.*?\]\s*/i, '')
            .replace(/^\[TOPIC:.*?\]\s*/i, '')
            .replace(/^Su'aasha waalidigu waydiiyay:.*\n+/i, '')
            .replace(/^Ku bilow ".*?".*?:\s*/i, '')
            .trim();

        return prisma.chatbotMessage.create({
            data: { sessionId, sender: 'AI', message: reply },
        });

    } catch (err) {
        console.error('[PediaBot] AI error:', err.message);
        const fallback = lang === 'so'
            ? 'Waxaan dhibaato yar la kulmay. Dib u isku day.'
            : 'I ran into a brief issue. Please try again.';
        return prisma.chatbotMessage.create({ data: { sessionId, sender: 'AI', message: fallback } });
    }
};

// ---------------------------------------------------------------------------
// Session management
// ---------------------------------------------------------------------------

/**
 * Creates or returns the active session.
 * forceNew=true → always create a new session (used by "New Chat" button).
 */
const createSession = async (userId, forceNew = false, language = 'so') => {
    if (!forceNew) {
        const existing = await prisma.chatbotSession.findFirst({
            where: { userId, isActive: true },
            orderBy: { createdAt: 'desc' },
        });
        if (existing) return existing;
    }
    return prisma.chatbotSession.create({
        data: { userId, language, isActive: true },
    });
};

/**
 * Closes (archives) a session so it appears in history.
 * Called automatically when user clicks "+ New Chat".
 */
const closeSession = async (sessionId, userId) => {
    const session = await prisma.chatbotSession.findUnique({ where: { id: sessionId } });
    if (!session || session.userId !== userId) return null;

    // If no title yet, derive from first user message
    let title = session.title;
    if (!title) {
        const first = await prisma.chatbotMessage.findFirst({
            where: { sessionId, sender: 'USER' },
            orderBy: { timestamp: 'asc' },
        });
        title = first ? first.message.slice(0, 45) : 'Empty chat';
    }

    return prisma.chatbotSession.update({
        where: { id: sessionId },
        data: { isActive: false, endedAt: new Date(), title },
    });
};

/**
 * Returns up to 25 past (closed) sessions for the user — for the history sidebar.
 */
const getUserSessions = async (userId) => {
    return prisma.chatbotSession.findMany({
        where: { userId, isActive: false },
        orderBy: { createdAt: 'desc' },
        take: 25,
        select: {
            id: true,
            title: true,
            language: true,
            createdAt: true,
            endedAt: true,
            messages: {
                take: 1,
                orderBy: { timestamp: 'asc' },
                where: { sender: 'USER' },
                select: { message: true },
            },
        },
    });
};

/**
 * Returns all messages in a session (used when user clicks a history entry).
 */
const getSessionMessages = async (sessionId, userId) => {
    const session = await prisma.chatbotSession.findUnique({ where: { id: sessionId } });
    if (!session || session.userId !== userId)
        throw Object.assign(new Error('Unauthorized'), { statusCode: 403 });
    return prisma.chatbotMessage.findMany({
        where: { sessionId },
        orderBy: { timestamp: 'asc' },
    });
};

const upsertTemplate = async (triggerKeyword, response) =>
    prisma.chatbotTemplate.upsert({
        where: { triggerKeyword },
        update: { response },
        create: { triggerKeyword, response },
    });

const listTemplates = async () =>
    prisma.chatbotTemplate.findMany({ orderBy: { createdAt: 'desc' } });

const deleteTemplate = async (id) => {
    const existing = await prisma.chatbotTemplate.findUnique({ where: { id } });
    if (!existing) throw Object.assign(new Error('Template not found'), { statusCode: 404 });
    return prisma.chatbotTemplate.delete({ where: { id } });
};

module.exports = {
    createSession,
    closeSession,
    getUserSessions,
    getSessionMessages,
    processMessage,
    upsertTemplate,
    listTemplates,
    deleteTemplate,
};
