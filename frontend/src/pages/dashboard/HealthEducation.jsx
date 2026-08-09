import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    BookOpen, Search, X, Clock, Apple, Droplets, Utensils, Star, ChevronRight,
    Heart, Shield, Brain, Zap, Baby, Stethoscope, AlertTriangle, CheckCircle,
    ArrowRight, Eye, Thermometer, Wind, Moon, Sparkles, Leaf, Activity,
    ChevronLeft, ChevronDown, Users, Award, TrendingUp
} from 'lucide-react';

/* ─── Custom Keyframe Animations ─────────────────────────────────────── */
const STYLES = `
@keyframes he-slideUp   { from { opacity:0; transform:translateY(32px) } to { opacity:1; transform:translateY(0) } }
@keyframes he-fadeIn    { from { opacity:0 } to { opacity:1 } }
@keyframes he-float     { 0%,100% { transform:translateY(0) } 50% { transform:translateY(-10px) } }
@keyframes he-heroZoom  { from { transform:scale(1) } to { transform:scale(1.08) } }
@keyframes he-shimmer   { from { background-position:-200% 0 } to { background-position:200% 0 } }
@keyframes he-pulse     { 0%,100% { opacity:1 } 50% { opacity:.4 } }
@keyframes he-spin-slow { from { transform:rotate(0deg) } to { transform:rotate(360deg) } }
@keyframes he-grow      { from { transform:scaleX(0) } to { transform:scaleX(1) } }
@keyframes he-pop       { 0% { transform:scale(0.8); opacity:0 } 70% { transform:scale(1.05) } 100% { transform:scale(1); opacity:1 } }
@keyframes he-ticker    { from { transform:translateX(0) } to { transform:translateX(-50%) } }

.he-slide-up   { animation: he-slideUp   0.5s ease both }
.he-fade-in    { animation: he-fadeIn    0.6s ease both }
.he-float      { animation: he-float     3s ease-in-out infinite }
.he-hero-zoom  { animation: he-heroZoom  12s ease-in-out infinite alternate }
.he-pulse-dot  { animation: he-pulse     1.5s ease-in-out infinite }
.he-spin-slow  { animation: he-spin-slow 10s linear infinite }
.he-pop        { animation: he-pop       0.4s cubic-bezier(.34,1.56,.64,1) both }
.he-ticker     { animation: he-ticker    28s linear infinite }

.he-card { transition: all .25s ease }
.he-card:hover { transform: translateY(-6px); box-shadow: 0 20px 48px rgba(0,0,0,.12) }

.he-img { transition: transform .6s ease }
.he-card:hover .he-img { transform: scale(1.06) }

.he-badge { transition: all .2s ease }
.he-badge:hover { transform: scale(1.08) }

.he-progress-bar { animation: he-grow 1.2s cubic-bezier(.4,0,.2,1) both }
.he-progress-bar { transform-origin: left }

.he-scroll-visible { animation: he-slideUp 0.55s ease both }
`;

/* ─── Images ─────────────────────────────────────────────────────────── */
const IMG = {
    feeding:    'https://images.unsplash.com/photo-1609220136736-443140cffec6?auto=format&fit=crop&w=900&h=500&q=80',
    fever:      'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?auto=format&fit=crop&w=900&h=500&q=80',
    cold:       'https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=900&h=500&q=80',
    sleep:      'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=900&h=500&q=80',
    hygiene:    'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=900&h=500&q=80',
    vaccine:    'https://images.unsplash.com/photo-1576765608866-5b51046452be?auto=format&fit=crop&w=900&h=500&q=80',
    milestone:  'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=900&h=500&q=80',
    diarrhea:   'https://images.unsplash.com/photo-1536236789960-1f48e5c45c32?auto=format&fit=crop&w=900&h=500&q=80',
    dental:     'https://images.unsplash.com/photo-1588776814546-1ffbb39ac5e8?auto=format&fit=crop&w=900&h=500&q=80',
    play:       'https://images.unsplash.com/photo-1530099486328-e021101a494a?auto=format&fit=crop&w=900&h=500&q=80',
    mental:     'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&w=900&h=500&q=80',
    firstaid:   'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=900&h=500&q=80',
    hero:       'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=1600&h=700&q=80',
    /* unique images for articles 13-40 */
    vitamins:   'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=900&h=500&q=80',
    family_meal:'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=900&h=500&q=80',
    flu_shot:   'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=900&h=500&q=80',
    doc_talk:   'https://images.unsplash.com/photo-1559757148-9b350e01da28?auto=format&fit=crop&w=900&h=500&q=80',
    child_speak:'https://images.unsplash.com/photo-1590650153855-d9e808231d41?auto=format&fit=crop&w=900&h=500&q=80',
    inhaler:    'https://images.unsplash.com/photo-1601084881623-cdf9a8ea242c?auto=format&fit=crop&w=900&h=500&q=80',
    newborn:    'https://images.unsplash.com/photo-1522773906914-b93c0c68d7e0?auto=format&fit=crop&w=900&h=500&q=80',
    cry_baby:   'https://images.unsplash.com/photo-1516912481808-3406841bd33c?auto=format&fit=crop&w=900&h=500&q=80',
    emergency:  'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?auto=format&fit=crop&w=900&h=500&q=80',
    crib:       'https://images.unsplash.com/photo-1545558014-8692077e9b5c?auto=format&fit=crop&w=900&h=500&q=80',
    kitchen:    'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=900&h=500&q=80',
    water:      'https://images.unsplash.com/photo-1559839914-17aae19cec71?auto=format&fit=crop&w=900&h=500&q=80',
    sweets:     'https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&w=900&h=500&q=80',
    kids_social:'https://images.unsplash.com/photo-1484390875402-4887efe66a8b?auto=format&fit=crop&w=900&h=500&q=80',
    toddler:    'https://images.unsplash.com/photo-1548802673-380d9f3abade?auto=format&fit=crop&w=900&h=500&q=80',
    aid_kit:    'https://images.unsplash.com/photo-1584820927498-cad0e17e2a39?auto=format&fit=crop&w=900&h=500&q=80',
    nuts:       'https://images.unsplash.com/photo-1549820460-9b498d3a0f0c?auto=format&fit=crop&w=900&h=500&q=80',
    rash:       'https://images.unsplash.com/photo-1599045118108-bf9954418b76?auto=format&fit=crop&w=900&h=500&q=80',
    healthy_wt: 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?auto=format&fit=crop&w=900&h=500&q=80',
    xray:       'https://images.unsplash.com/photo-1530026405686-3239d0898b30?auto=format&fit=crop&w=900&h=500&q=80',
    brain_doc:  'https://images.unsplash.com/photo-1576669801775-ff43c5ab079d?auto=format&fit=crop&w=900&h=500&q=80',
    autism_play:'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=900&h=500&q=80',
    water_pump: 'https://images.unsplash.com/photo-1504502350688-00f5d59bbdeb?auto=format&fit=crop&w=900&h=500&q=80',
    hosp_baby:  'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?auto=format&fit=crop&w=900&h=500&q=80',
    child_study:'https://images.unsplash.com/photo-1531498860-b7166a35e715?auto=format&fit=crop&w=900&h=500&q=80',
    bandage:    'https://images.unsplash.com/photo-1583912268183-a34d5fe17c0a?auto=format&fit=crop&w=900&h=500&q=80',
    skin_care:  'https://images.unsplash.com/photo-1559757175-5700dde675bc?auto=format&fit=crop&w=900&h=500&q=80',
    mosquito:   'https://images.unsplash.com/photo-1541659985753-b1b4d6be4ac5?auto=format&fit=crop&w=900&h=500&q=80',
};

/* ─── Articles ────────────────────────────────────────────────────────── */
export const ARTICLES = [
    {
        id: 1,
        featured: true,
        category: 'Nafaqada & Quudinta',
        icon: <Apple size={16}/>,
        accent: 'from-orange-600 to-amber-500',
        accentLight: 'from-orange-500/20 to-amber-500/10',
        badge: 'bg-orange-100 text-orange-700 border-orange-200',
        dot: 'bg-orange-500',
        image: IMG.feeding,
        title: 'Sida Loo Quudiyo Ilmahaaga (0–5 Sano)',
        subtitle: 'Nafaqada saxda ah ayaa xoojisa maskaxda iyo difaaca jirka ilmahaaga lana xoojisa koritaanka.',
        readTime: '6 daqiiqo',
        views: '12.4k',
        sections: [
            {
                heading: '🤱 0–6 Bilood: Caano Hooyo Keliya',
                body: `Caano hooyo oo keliya ku quudi. Caanka hooyo waxay ka kooban tahay dhammaan nafaqada iyo antibodies ee ilmahaagu u baahan yahay. Haddaad awoodi weydo, caano warqad isticmaal.\n\nBiyo ama wax kale ha siinin ilmahaaga lixda bilood ee ugu horeeya — caano hooyo waxa wax kasta ka koobanna.`,
            },
            {
                heading: '🍴 6–12 Bilood: Bilow Cuntada Jilicsan',
                body: `Bilow ku dar: khudaar la jarjaray, miraha la shiiqay, iyo cereal bir leh. Maalin kasta mid cusub ku dar.\n\nIska fogow: malab, caano lo'aad, shilibo badan, iyo cuntada khatar ah. Da'da yar darteed, hay kharruufta iyo saaminada.`,
            },
            {
                heading: '🥣 1–3 Sano: Cuntada Qoyska',
                body: `U gudub cuntada jilicsan ee qoyska. Sii 3 jeer wax cunid + 2 jeer wax cunid oo yar maalintii. Ku dar caano, mid-midab, boroto, iyo khudaar midableysan.`,
            },
            {
                heading: '🍱 3–5 Sano: Kala-duwanaansho Ku Dhiirigeli',
                body: `Ku dhiirigeli kala-duwanaansho. Ka fogow sonkor badan iyo cuntada la soo-gaabiyay. Cuntada midableyso si ay carruurtu uga raaxaysato — midabka cuntadu waa calaamad nafaqo fiican.`,
            },
            {
                heading: '⚠️ Calaamadaha Nafaqo Xumo',
                body: `Miisaan xumo, daalnimo, maqaarku casaan yahay ama dhumuc weyn. La tasho dhakhtar si degdeg ah haddaad walaac qabto.`,
            },
        ],
    },
    {
        id: 2,
        featured: true,
        category: 'Maareynta Xummadda',
        icon: <Thermometer size={16}/>,
        accent: 'from-red-600 to-rose-500',
        accentLight: 'from-red-500/20 to-rose-500/10',
        badge: 'bg-red-100 text-red-700 border-red-200',
        dot: 'bg-red-500',
        image: IMG.fever,
        title: 'Xummadda Carruurta: Goorta La Walaacdo',
        subtitle: 'Xummaddu waxay ka mid tahay xaaladaha ugu badan ee u keena carruurta caafimaadka. Barashadu waa badbaado.',
        readTime: '5 daqiiqo',
        views: '18.2k',
        sections: [
            {
                heading: '🌡️ Heerkulka la garanayo',
                body: `Caadi: Hoosta 37.5°C (99.5°F)\nXummad Khafiif: 37.5–38.5°C\nXummad Xoog: 38.5–40°C\nXummad Aad u Xoog: Ka sareeya 40°C — degdeg la xiriir dhakhtar.`,
            },
            {
                heading: '✅ Daaweynta Guriga',
                body: `• Biyo badan sii — biyo, caano hooyo, ORS\n• Dhar fudud u hid, ha duubnayn\n• Paracetamol ama Ibuprofen (qiyaas miisaanka keliya)\n• Biyo diiran oo aan kulul lahayn ku soo qaad\n• Xaafad qabow ama hawada wanaagsan u fur`,
            },
            {
                heading: '🚨 Xaaladaha Degdegga ah',
                body: `Aado isbitaalka SI DEGDEG AH haddii:\n• Ilmaha ka yar yahay 3 bilood\n• Heerkulku ka sareeyo 40°C\n• Xummaddu ka badato 3 maalmood\n• Ilmuhu leeyahay neefsasho dhibaato ama wareeg\n• Uurkii hooyo xannuunsato ama samaan la'aad\n• Calaamadaha biyo la'aanta soo baxaan`,
            },
        ],
    },
    {
        id: 3,
        featured: true,
        category: 'Caafimaadka Neefsiga',
        icon: <Wind size={16}/>,
        accent: 'from-blue-600 to-sky-500',
        accentLight: 'from-blue-500/20 to-sky-500/10',
        badge: 'bg-blue-100 text-blue-700 border-blue-200',
        dot: 'bg-blue-500',
        image: IMG.cold,
        title: 'Hargabka & Qufaca: Hagaha Daryeelka',
        subtitle: 'Carruurtu waxay helaan 6–8 jeer hargab sano kasta. Wax barasho sida loo xoojiyo difaaca jirka.',
        readTime: '7 daqiiqo',
        views: '9.7k',
        sections: [
            {
                heading: '🤧 Calaamadaha Hargabka Caadiga ah',
                body: `• San socda ama xidhanyahay\n• Qufac yar, hindhisasho\n• Xummad khafiif (hoos u 38.5°C)\n• Cunid yareysiga\n• Daalnimo`,
            },
            {
                heading: '💊 Daaweynta Guriga',
                body: `• Dhibicyo dameero sanaha xidhanyahay\n• Malab (carruurta ka weyn 1 sano) si qufaca loo qaboojiyaa\n• Uumi biyo kulul oo la eego\n• Biyo badan ka cab — biyo diiran, maraq, caano hooyo\n• Nasasho iyo nasiib wanaag`,
            },
            {
                heading: '🛑 Digniin Muhiim ah',
                body: `HA SIIN aspirin carruurta hoosta 16 sano — xaalad halis ah (Reye's syndrome) ayay keeni kartaa.\n\nHa isticmaalin dawooyinka xannibaadda qufaca carruurta yar (hoosta 6 sano) haddaadan dhakhtar la tashin.`,
            },
            {
                heading: '🚨 Dhakhtar u Aad haddii',
                body: `• Neefsashu adag tahay ama degdeg\n• Bushimaha ama faraha af-duubnaadaan (calaamad oksijiin la'aan)\n• Ilmuhu ka diiday 8+ saacadood cabbitaan\n• Xanuun dheg ama doonka xun soo baxo\n• Qufacu ka badato 10 maalmood`,
            },
        ],
    },
    {
        id: 4,
        category: 'Hurdo & Nasasho',
        icon: <Moon size={16}/>,
        accent: 'from-indigo-600 to-violet-500',
        accentLight: 'from-indigo-500/20 to-violet-500/10',
        badge: 'bg-indigo-100 text-indigo-700 border-indigo-200',
        dot: 'bg-indigo-500',
        image: IMG.sleep,
        title: 'Hurdo Fiican: Aasaaska Caafimaadka',
        subtitle: 'Hurdo waxay muhiim u tahay hormoonka koritaanka, horumarinta maskaxda, iyo difaaca jirka.',
        readTime: '4 daqiiqo',
        views: '7.3k',
        sections: [
            {
                heading: '😴 Hurdada la Talinayo iyadoo Da\'da la Eegayo',
                body: `Dhalaanka Cusub (0–3 bilood): 14–17 saacadood\nDhallaanka (4–11 bilood): 12–15 saacadood\nCarruurta Yar (1–2 sano): 11–14 saacadood\nCarruurta Dugsiga Kahor (3–5 sano): 10–13 saacadood\nCarruurta Dugsiga (6–12 sano): 9–11 saacadood`,
            },
            {
                heading: '✅ Tilmaamaha Hurdo Fiican',
                body: `• Hab joogto ah oo hurdo-u-diyaarinta ah (qubeys, sheeko, nalka damee)\n• Qol gudcur ah, qabow, oo aamusan\n• Shaashadaha jooji 1 saacadood ka hor seexashada\n• Ka fogow kafayeenta carruurta waaweyn\n• Sariir raaxo leh oo ammaan ah`,
            },
            {
                heading: '⚠️ Calaamadaha Dhibaatada Hurdada',
                body: `Soo kicid habeenkii si joogto ah, gudal, kaadida sariirta (ka dib 5 sano), dhibaata toosidda subaxdii — la tasho dhakhtar haddaad dhibaatooyinkan aragto.`,
            },
        ],
    },
    {
        id: 5,
        category: 'Nadiifnimada',
        icon: <Sparkles size={16}/>,
        accent: 'from-teal-600 to-emerald-500',
        accentLight: 'from-teal-500/20 to-emerald-500/10',
        badge: 'bg-teal-100 text-teal-700 border-teal-200',
        dot: 'bg-teal-500',
        image: IMG.hygiene,
        title: 'Nadiifnimada Ilmahaaga: Ka Hortagga Xanuunka',
        subtitle: 'Caadooyinka nadiifnimada waxay ilaaliyaan carruurta caabuqyada iyo xanuunada halis ah.',
        readTime: '5 daqiiqo',
        views: '11.1k',
        sections: [
            {
                heading: '🤲 Dhaqidda Gacmaha (Ugu Muhiimsan!)',
                body: `Ka hor iyo ka dib wax cunid\nKa dib isticmaalka musqusha\nKa dib ciyaarka dibedda\nKa dib qufacida, hindhisashada, ama sanka nadiifinta\n\n20 ilbiriqsi ku dhaq saabuun iyo biyo qulqulaya.`,
            },
            {
                heading: '🦷 Nadiifnimada Ilkaha',
                body: `Bilow cadaynta markii ilkuhu ugu horreeya soo baxo (6–8 bilood)\n2 jeer maalintii oo dawo ilko fluoride leh\nBooqashada dhakhtar-ilkaha ugu horreeya da'da 1\nKa fogow caanaha habeenka ka dib cadaynta`,
            },
            {
                heading: '🛁 Qubeyska & Daryeelka Guud',
                body: `Maalin kasta ama maalin kasta ma-ahaanba carruurta yar yar\nDhegaha si tartiib ah u nadiifi — waligaa wax ku xarin\nCidiyaha gaaban iyo nadiif hay\nDhar maalin kasta beddel`,
            },
        ],
    },
    {
        id: 6,
        category: 'Tallaalada',
        icon: <Shield size={16}/>,
        accent: 'from-purple-600 to-fuchsia-500',
        accentLight: 'from-purple-500/20 to-fuchsia-500/10',
        badge: 'bg-purple-100 text-purple-700 border-purple-200',
        dot: 'bg-purple-500',
        image: IMG.vaccine,
        title: 'Muhiimadda Jadwalka Tallaalka Carruurta',
        subtitle: 'Tallaaladu waxay ilaaliyaan carruurta xanuunada halis ah ee muddooyinka ugu nugul ee nolosha.',
        readTime: '8 daqiiqo',
        views: '15.6k',
        sections: [
            {
                heading: '💉 Tallaalada Muhiimka ah',
                body: `BCG — Dhalashada (Tuberculosis)\nOPV — Dhibcaha Polio: dhalashada, 6, 10, 14 toddobaad\nPentavalent — 6, 10, 14 toddobaad (DPT+HepB+Hib)\nJadeecada (MR) — 9 bilood iyo 15 bilood\nPneumococcal — 6, 10, 14 toddobaad + booster 12 bilood\nRotavirus — 6, 10 toddobaad`,
            },
            {
                heading: '✅ Maxay Jadwalku u Muhiimsan Yahay?',
                body: `Tallaaladu waxay la siinayaan goorta dhallaanka ugu nugul. Maqlidda ama dib-u-dhigidda qaybaha waxay keenayaa daloolooyin ilaalineed maalinlaha ku yimid xanuunka.`,
            },
            {
                heading: '🌍 Kaabiyaha Kooxeed (Herd Immunity)',
                body: `Marka dadka ku filan la tallaalay, xitaa kuwa aan la tallaalin waxaa ilaalinaya tallaalka kuwa kale. Tallaalkaagu wuxuu ilaalinayaa qoysgaaga iyo bulshadaada.`,
            },
            {
                heading: '⚠️ Saameynaha Caadiga ah',
                body: `Xummad khafiif, xanuun meesha la dhaliiyay — kuwaas waa caadi oo wakhti gaaban ah bay jiraan. Haddaad saameyn culus aragto, dhakhtar la xiriir.`,
            },
        ],
    },
    {
        id: 7,
        category: 'Horumarinta',
        icon: <TrendingUp size={16}/>,
        accent: 'from-pink-600 to-rose-500',
        accentLight: 'from-pink-500/20 to-rose-500/10',
        badge: 'bg-pink-100 text-pink-700 border-pink-200',
        dot: 'bg-pink-500',
        image: IMG.milestone,
        title: 'Marxaladaha Horumarinta ee Muhiimka ah',
        subtitle: 'La socoshada kobaca iyo horumarinta ilmahaaga waxay kaa caawisaa in arrimaha hore loo garanno.',
        readTime: '4 daqiiqo',
        views: '8.9k',
        sections: [
            {
                heading: '👶 Marxaladaha Horumarinta',
                body: `2 Bilood: Leefleefida, indhaha ku raacida walxaha, codka u jawaabista\n4 Bilood: Madaxa adag haysta, qososhada, barbaar hadlida\n6 Bilood: Fadhiista la taageerayo, walxaha gacma-kale u wareejinta\n9 Bilood: Jarjarista, toosa taagista, "hooyo"/"aabo" leh\n12 Bilood: Tallaabadii ugu horraysay, "maya" gartaa\n18 Bilood: Adag u soconaysa, 10+ ereyood leh\n2 Sano: Ordista, 2 erey xididsan\n3 Sano: Kaalmo ku xidhitaa, jumlado leh`,
            },
            {
                heading: '🚨 Dhakhtar la Hadal haddii Ilmahaagu',
                body: `• Indhaha la xiriir la'yahay 3 bilood ka hor\n• Xirfadaha hore gaara wuu lumiyaa (dib u noqoshada)\n• 18 biloodka ka hor socon kari wayo\n• Hadal la'aanta ka dib 12 bilood\n• Xiisaynta bulshada la'aanta`,
            },
        ],
    },
    {
        id: 8,
        category: 'Biyo La\'aanta',
        icon: <Droplets size={16}/>,
        accent: 'from-cyan-600 to-teal-500',
        accentLight: 'from-cyan-500/20 to-teal-500/10',
        badge: 'bg-cyan-100 text-cyan-700 border-cyan-200',
        dot: 'bg-cyan-500',
        image: IMG.diarrhea,
        title: 'Maareynta Gudaha Socda & Biyo La\'aanta',
        subtitle: 'Gudaha socdu waa sababta ugu weyn ee xanuunka carruurta. Degdeg bay u halis noqon kartaa.',
        readTime: '6 daqiiqo',
        views: '13.2k',
        sections: [
            {
                heading: '💧 Xalka Dib-u-Soo-celinta Biyaha (ORS)',
                body: `Isku dar: 1 litir biyo nadiif + 6 qaaddo sonkor + ½ qaaddo cusboo\nSii xoogaa yar oo badan. HA JOOJINAYN caano hooyo.\n\nORS xaanshaha ka iibso kaabiyaasha caafimaadka — waa ammaan oo waxtar leh.`,
            },
            {
                heading: '📋 Calaamadaha Biyo La\'aanta',
                body: `• Afka iyo carrabka engeg\n• Ilmaan la'aanta marka la ooyayo\n• Xudun qoyan la'aantiis 8+ saacadood\n• Madaxa hore ee dhalaanka (fontanelle) oo ku dhacay\n• Hurdo xad dhaaf ah ama daalnimo`,
            },
            {
                heading: '🥣 Cuntada Gudaha Socoda Waqtiga',
                body: `Caano hooyo sii\nBiyo timiro, bariis fudud, baradho la kariyay, muus\nKa fogow khameeryada, cuntada xoogga badan, caanaha (marka laga reebo caano hooyo)`,
            },
            {
                heading: '🏥 Degdeg Xarunta Caafimaadka u Aad haddii',
                body: `• Dhiig ka jiro kaadida\n• Calaamadaha biyo la'aanta soo baxaan\n• 10ka waraabe oo biyo ah ka badan 24 saacadood\n• Matagu joojiyaa ORS inay hooto`,
            },
        ],
    },
    {
        id: 9,
        category: 'Caafimaadka Ilkaha',
        icon: <Stethoscope size={16}/>,
        accent: 'from-lime-600 to-green-500',
        accentLight: 'from-lime-500/20 to-green-500/10',
        badge: 'bg-lime-100 text-lime-700 border-lime-200',
        dot: 'bg-lime-500',
        image: IMG.dental,
        title: 'Ilkaha Carruurta: Ka Horumarinta Xanuunka',
        subtitle: 'Daryeelka ilkaha wuxuu bilaabmaa horaan. Caadooyinka wanaagsan waxay ilaaliyaan ilkaha nolosha oo dhan.',
        readTime: '5 daqiiqo',
        views: '6.4k',
        sections: [
            {
                heading: '🦷 Markii Loo Bilaabaa',
                body: `Bilow nadiifinta dhallaanka xaafkiisa haddana ilmo la'aantii oo dhar qoyan\nMarkii ilkaha ugu horreeya soo baxaan (6–8 bilood), cadayn bilow\nIsticmaal naanaysta carruurta oo xikmad adag — haddaan ay jirin, faraha adeegsoo\nBooqashada dhakhtar-ilkaha ugu horreeya da'da 1 sano`,
            },
            {
                heading: '✅ Caadooyinka Ilkaha Fiican',
                body: `2 jeer maalintii cadayn — subax iyo habeenkii ka hor seexashada\nFluoride dawo ilko isticmaal (xukun yar carruurta hoosta 3 sano)\nKa fogow caanaha habeenka ka dib ilkaha cadaynta\nSonkor iyo cabbitaanka sonkorta leh xaddid`,
            },
            {
                heading: '⚠️ Xanuunka Ilkaha',
                body: `Caries (ilkaha dumidda) waxay bilaabmaan marka bakteeriyadu ku baxdo sonkorta\nHaddaad aragtaa madow, dhuunta, ama ilmuhu xanuuno marka wax cuno — dhakhtar-ilkaha aad\nXanuunka ilkaha wuxuu saameyn karaa cunista, hadalka, iyo barashada`,
            },
        ],
    },
    {
        id: 10,
        category: 'Ciyaaraha & Horumarinta',
        icon: <Brain size={16}/>,
        accent: 'from-yellow-600 to-amber-500',
        accentLight: 'from-yellow-500/20 to-amber-500/10',
        badge: 'bg-yellow-100 text-yellow-700 border-yellow-200',
        dot: 'bg-yellow-500',
        image: IMG.play,
        title: 'Ciyaarka & Horumarinta Maskaxda Ilmahaaga',
        subtitle: 'Ciyaarku waa shaqada carruurta. Waxay barantaa, waxay xoojisaa, waxayna dhisaa xidhiidh bulsheed.',
        readTime: '6 daqiiqo',
        views: '10.3k',
        sections: [
            {
                heading: '🧠 Sababta Ciyaarku u Muhiimsan Yahay',
                body: `Ciyaarku wuxuu xoojiyaa:\n• Maskaxda (xallinta dhibaatooyinka, hal-abuurka)\n• Jirka (xoogga murqaha, xannibaadda)\n• Hadalka (erayada cusub, xaaladaha)\n• Bulshada (wadaagga, is-dhexgalka, macquulnimada)\n• Xasilloonida qofnimada`,
            },
            {
                heading: '✅ Ciyaarka La Talinayo Iyadoo Da\'da la Eegayo',
                body: `0–12 bilood: Ciyaaro wax milicsada, maqalka, samaynta wejiga iyo codka\n1–3 sano: Dhismaha, sawirista, qaabashadda iwm.\n3–5 sano: Ciyaarista roolada ("doctor iyo bukaanka"), samaynta waxaaga\n6–12 sano: Ciyaarta kooxda, ciyaaraha xeerka leh`,
            },
            {
                heading: '📱 Shaashadaha iyo Carruurta',
                body: `Hoosta 18 bilood: Iska fogow (video-call mooyaane)\n18–24 bilood: Inta badan la-socod\n2–5 sano: Saacad 1 oo kaliya maalintii, xulashada waxbaridda\n6+ sano: 2 saacadood oo kala badna maalintii\n\nHal abuur, ciyaar dhaqdhaqaaq leh, iyo akhriska ka muhiimsan.`,
            },
        ],
    },
    {
        id: 11,
        category: 'Caafimaadka Maskaxda',
        icon: <Heart size={16}/>,
        accent: 'from-rose-600 to-pink-500',
        accentLight: 'from-rose-500/20 to-pink-500/10',
        badge: 'bg-rose-100 text-rose-700 border-rose-200',
        dot: 'bg-rose-500',
        image: IMG.mental,
        title: 'Caafimaadka Xagga Maskaxda ee Carruurta',
        subtitle: 'Caafimaadka maskaxdu waa muhiim sida caafimaadka jirka. Waalidka doorka muhiimka wuxuu ku jiraa.',
        readTime: '7 daqiiqo',
        views: '8.1k',
        sections: [
            {
                heading: '💙 Calaamadaha Walaacda Maskaxda',
                body: `• Murugo joogto ah oo ka badan toddobaadkii\n• Xanaaq weyn oo taxanaha ah\n• Ka saarnaansho asxaabta\n• Barashada hoos u dhac\n• Hurdo dhibaato ama rabitaanka cuntada bedelashada\n• Xanuun jir oo sabab la'aanta (madax-xanuun, calool-xanuun)`,
            },
            {
                heading: '✅ Sida Loo Taageero',
                body: `• Hadal furan la siiyi — in uu dhadhan karo\n• Wakhti toos ah la qaado\n• Caadooyinka joogto ah ee ammaan bixiya\n• Xanaaqyada xakamayn baro\n• Ku ammaana iyo rajada weyn ku samayn baro`,
            },
            {
                heading: '🤝 Goorta La Raadsado Caawimaad',
                body: `Haddaad aaminsan tahay ilmahaaga caafimaadkiisa maskaxdu waxay saamaynaysaa noloshooda maalinlaha ah, dhakhtar carruurta la xiriir. Ma dhib ma aha — waa gargaar.`,
            },
        ],
    },
    {
        id: 12,
        category: 'Daaweynta Ugu Horraysa',
        icon: <Zap size={16}/>,
        accent: 'from-slate-600 to-gray-500',
        accentLight: 'from-slate-500/20 to-gray-500/10',
        badge: 'bg-slate-100 text-slate-700 border-slate-200',
        dot: 'bg-slate-500',
        image: IMG.firstaid,
        title: 'Daaweynta Ugu Horraysa: Dhaawacyada Guriga',
        subtitle: 'Barashada tallaabooyinka maamulka dhaawacyada yar waxay badbaadin kartaa nolosha ilmahaaga.',
        readTime: '8 daqiiqo',
        views: '14.7k',
        sections: [
            {
                heading: '🩹 Dhaawacyada Yar yar',
                body: `1. Gacmaha dhaq biyo iyo saabuun\n2. Dhaawaca biyo nadiif ku dhaq\n3. Cadaad khafiif saar si dhiig loo joojiyo\n4. Bandage ama dhar nadiif si marinnimo leh u duub\n5. Caabuqa ka fiirso maalimaha xigta`,
            },
            {
                heading: '🔥 Gubashada',
                body: `BIYO QABOW (maran 10–20 daqiiqo) — HA ISTICMAALIN buruud, barafka, ama toothpaste\nDhar la sarreeyaana u sido\nHaddii qodob weyn, caloosha, ama wejiga — degdeg u tag isbitaalka`,
            },
            {
                heading: '🦟 Ciniirida & Caloosha Xanuunka',
                body: `Ciniirida: Ka fogow qodista, dab heli, nadiifiye xashiishka (insect repellent) isticmaal\nCaloosha xanuunka: La eeg haddii xummad leh, haddaan la rarin — ORS bilow\nHadduu dhiig muuqdo ama calool xanuunka xoog — isbitaalka u aad`,
            },
            {
                heading: '⚡ Waxyaabaha Laga Diiwaangeliyaa',
                body: `Ilmahaagu hadduu wax macluul qado, wax dhigi doono afka, ama feedhis galo:\n• Miisaankiisa/maamuusha\n• Wakhtiga dhacdada\n• Muddada / isbedelada\n• Dhakhtar u aad si degdeg ah`,
            },
        ],
    },
    /* ── Article 13 ── */
    {
        id: 13,
        category: 'Nafaqada & Quudinta',
        icon: <Leaf size={16}/>,
        accent: 'from-green-600 to-emerald-500',
        accentLight: 'from-green-500/20 to-emerald-500/10',
        badge: 'bg-green-100 text-green-700 border-green-200',
        dot: 'bg-green-500',
        image: IMG.vitamins,
        title: 'Vitamin D & Birta: Nafaqada Muhiimka ah Carruurta',
        subtitle: 'Dhibcaha yar ee vitamin D iyo birtu waxay leeyihiin saameyn weyn ee koritaanka lafaha iyo maskaxda.',
        readTime: '5 daqiiqo',
        views: '7.2k',
        sections: [
            {
                heading: '☀️ Sababta Vitamin D u Muhiimsan',
                body: `Vitamin D waxay ka caawisaa jidhka inuu xajiyado kalsiyamka lafaha iyo ilkaha. Carruurta badankooda jirta gudaha, iftiinka cadceeda la'aanteed, waxay helaan yaraanta vitamin D.\n\nDhallaanka naas la nuujinayo waxay u baahan yihiin dhibcaha vitamin D 400 IU maalintii — caano hooyo kaligeeda kuma filna.`,
            },
            {
                heading: '🥩 Birta: Dhiigga iyo Maskaxda',
                body: `Birtu waxay qaadaa oksijiin dhiigga oo jidhka oo dhan. Yarida birtu (anemia) waxay keentaa:\n• Daalnimo iyo hurdo badan\n• Barashada xoogaa hoos u dhac\n• Maqaarkii caabiray oo kaan-cad noqon\n\nCuntada biro leh: digir, hilib cas, khudaarta cagaaran, boorash.`,
            },
            {
                heading: '✅ Tallaabooyinka Guriga',
                body: `• 15–20 daqiiqo iftiinka cadceeda maalintii (garbaha iyo lugaha)\n• Ku dar cuntada: ukun, kalluun, boorash, tamar\n• Dhakhtar weydii kaabiyaha vitamin D iyo bir hadduu loo baahdo\n• Ka fogow "junk food" ee vitamin D la'aanta\n• Vitamin C (miro citrus ah) ayaa kordhiya nuqulka birta`,
            },
        ],
    },
    /* ── Article 14 ── */
    {
        id: 14,
        category: 'Nafaqada & Quudinta',
        icon: <Utensils size={16}/>,
        accent: 'from-orange-600 to-amber-500',
        accentLight: 'from-orange-500/20 to-amber-500/10',
        badge: 'bg-orange-100 text-orange-700 border-orange-200',
        dot: 'bg-orange-500',
        image: IMG.family_meal,
        title: 'Cabbirka Cuntada iyo Wakhtiga Cunidda ee Da\'yada Kala Duwan',
        subtitle: 'Ilmo kasta wuxuu leeyahay baahida nafaqada oo kale. Barasho sida aad u cabirto cuntada saxda ah.',
        readTime: '4 daqiiqo',
        views: '5.8k',
        sections: [
            {
                heading: '🍽️ Cabbirka Cuntada ee Da\'yada Kala Duwan',
                body: `1–3 Sano: ¼ qaybta cuntada dadka waaweyni — 3 jeer maalin + 2 jeer wax yar\n3–5 Sano: ½ qaybta — 3 jeer maalin oo buuxda\n6–10 Sano: ¾ qaybta — cuntada qoyska oo dhan\n\nIlmuhu naftiisu ogtahay goorta uu dheriyay — ha ku qasbanayn inuu wax ku daro.`,
            },
            {
                heading: '⏰ Wakhtiyada Cuntada Fiican',
                body: `• Subax: 7–8 am — awood baro iyo ciyaar\n• Duhur: 12–1 pm — cuntada ugu weyn\n• Galab: 3–4 pm — wax yar (miro, leeso, caano)\n• Habeenkii: 6–7 pm — cuntada fudud\n\nKa fogow wax cunid 1 saacadood ka hor seexashada — caloosha hurdo lama isticmaali.`,
            },
            {
                heading: '⚠️ Calaamadaha Ilmuhu Ku Filan Waa',
                body: `Ilmuhu ku filan yahay hadduu:\n• Miisaanka si caadi ah kor u kaco\n• Awood u yeesho ciyaar iyo waxbarasho\n• Jirku caafimaad qabo\n• 6+ jeer xudun qoyan sameeyo (dhallaanka)\n\nHadduu miisaanku hoos u dhaco ama nafaqo baahan yahay — dhakhtar la tasho.`,
            },
        ],
    },
    /* ── Article 15 ── */
    {
        id: 15,
        category: 'Tallaalada',
        icon: <Shield size={16}/>,
        accent: 'from-purple-600 to-fuchsia-500',
        accentLight: 'from-purple-500/20 to-fuchsia-500/10',
        badge: 'bg-purple-100 text-purple-700 border-purple-200',
        dot: 'bg-purple-500',
        image: IMG.flu_shot,
        title: 'Tallaalka Hargabka (Flu) ee Carruurta: Waa Maxay Muhiimaddiisa?',
        subtitle: 'Tallaalka hargabka sannadlaha ah wuxuu ilaaliyaa carruurta da\'da yar xanuunka daran ee hargabka.',
        readTime: '5 daqiiqo',
        views: '6.1k',
        sections: [
            {
                heading: '🦠 Hargabka (Influenza) Maxuu Yahay?',
                body: `Hargabku waa fayraska neefsiga ee si degdeg u faafa. Waxuu keenaa:\n• Xummad sarreysa si degdeg ah\n• Jir-xanuun iyo madax-xanuun\n• Qufac culus iyo daal weyn\n\nCarruurta ka yar 5 sano — gaar ahaan hoosta 2 sano — halis badan ayuu u yahay.`,
            },
            {
                heading: '💉 Goorta la Tallaalo',
                body: `Sannad kasta gu\'ba ka hor xilliga hargabka.\n\nCarruurta 6 bilood ilaa 8 sano oo markii ugu horraysa la tallaalo waxay u baahan yihiin 2 dhibcood — toddobaad 4 ka dib.\n\nWaxay ammaan tahay: naas la nuujinaya, xanuun jirka leh, carruurta tallaalada kale sidday leedahay.`,
            },
            {
                heading: '✅ Ka Dib Tallaalka',
                body: `• Meesha tallaalka dhaliiyey xanuun yar — caadi waa\n• Xummad khafiif — caadi waa\n• Dhakhtar la xiriir haddii saameyntu 48 saacadood ka badan tahay\n• Tallaalku kama ilaalinayo dhammaan noocyada hargabka, laakiin wuxuu yareeya culayskooda si weyn`,
            },
        ],
    },
    /* ── Article 16 ── */
    {
        id: 16,
        category: 'Tallaalada',
        icon: <CheckCircle size={16}/>,
        accent: 'from-purple-600 to-fuchsia-500',
        accentLight: 'from-purple-500/20 to-fuchsia-500/10',
        badge: 'bg-purple-100 text-purple-700 border-purple-200',
        dot: 'bg-purple-500',
        image: IMG.doc_talk,
        title: 'Su\'aalaha Ugu Badan ee Waalidku Leeyihiin Tallaalada Ku Saabsan',
        subtitle: 'Jawaabaha caddaynaysa su\'aalaha waalidka badankoodu leeyihiin tallaalada ku saabsan.',
        readTime: '6 daqiiqo',
        views: '9.4k',
        sections: [
            {
                heading: '❓ Tallaaladu ma keeni karaan xanuunka ay ka hortagayaan?',
                body: `Maya. Tallaaladu waxay ka kooban yihiin ama fayraska dhintay ama qaybaha yar yar ee kuma filan inay xanuun keenaan. Xummadda yar ee ka dib tallaalka waxay tusinaysaa difaacu waa shaqeynayaa.`,
            },
            {
                heading: '❓ Haddii aan tallaalin, waa xaaladee?',
                body: `Carruurta aan la tallaalin waxay halis badan u muteystaan xanuunada sida:\n• Jadeecada (measles) — naakhas naakhas\n• Boogaanka (whooping cough) — khatar daran carruurta yar\n• Diphtheria — xanuun geeridda keeni kara\n\nTallaaladu sidoo kale waxay ilaaliyaan dadka kale ee ku xeeran (kuwa aan tallaalin karin).`,
            },
            {
                heading: '✅ Goorta Looga Dhigto Tallaalka',
                body: `Tallaalka dib loo dhigo oo kaliya haddii:\n• Xanuun culus (ma aha hargab yar)\n• Allergy culus oo la xaqiijiyay tallaalka qaybtiisa\n• Dhakhtar casrigan bixiyay oggolaansho gaar ah\n\nHargab yar ama qanjidhow — MA AHA sabab dib-u-dhigis.`,
            },
        ],
    },
    /* ── Article 17 ── */
    {
        id: 17,
        category: 'Horumarinta',
        icon: <Activity size={16}/>,
        accent: 'from-pink-600 to-rose-500',
        accentLight: 'from-pink-500/20 to-rose-500/10',
        badge: 'bg-pink-100 text-pink-700 border-pink-200',
        dot: 'bg-pink-500',
        image: IMG.child_speak,
        title: 'Horumarinta Hadalka Carruurta: Marxaladaha & Goorta La Walaacdo',
        subtitle: 'Fahmidda tirada ereyada caadiga ah ee xilliyada kala duwan waxay kaa caawisaa gaaritaanka hore.',
        readTime: '5 daqiiqo',
        views: '7.6k',
        sections: [
            {
                heading: '🗣️ Marxaladaha Hadalka',
                body: `6 bilood: Codad iyo "babababa"\n9 bilood: "Aabo" iyo "hooyo" labadoodaba\n12 bilood: 1–3 erey micne leh\n18 bilood: 10–20 erey\n2 sano: 50+ erey, 2 erey xididsan "caano bixi"\n3 sano: 200–1000 erey, jumladaha 3–4 erey\n4 sano: Sheekooyin gaagaaban sheegi karaan`,
            },
            {
                heading: '✅ Sida Loo Dhiirigeeliyo Hadalka',
                body: `• La hadal xitaa marka aanu jawaabininin — cod ahaanshaha erayadaada ayuu baranayaa\n• Buugaagta akhriso maalin kasta\n• Suubiyeyaasha weydii: "Maxay tihiin kuwanu?"\n• Ha koobin qaamuuska — si buuxda u hadal\n• Heesaha iyo riwaayaddaha way caawiyaan\n• TV-ga yar — hadalka dadka noolaa waa muhiim`,
            },
            {
                heading: '🚨 La Xiriir Dhakhtar haddii',
                body: `• 12 bilood: "aabo/hooyo" lama maqlin\n• 15 bilood: 0 erey\n• 18 bilood: 10 erey ka yar\n• 24 bilood: 50 erey ka yar\n• Hadalki la baranaa wuu lumay (dib u noqoshada)\n\nHadal dib-u-dhigis hore loo garanno ayaa ku filan si wax looga qabto.`,
            },
        ],
    },
    /* ── Article 18 ── */
    {
        id: 18,
        category: 'Caafimaadka Neefsiga',
        icon: <Wind size={16}/>,
        accent: 'from-blue-600 to-sky-500',
        accentLight: 'from-blue-500/20 to-sky-500/10',
        badge: 'bg-blue-100 text-blue-700 border-blue-200',
        dot: 'bg-blue-500',
        image: IMG.inhaler,
        title: 'Asthmada Carruurta: Calaamadaha iyo Maareynta Guriga',
        subtitle: 'Asthma waa xaaladda ugu badan ee neefsiga ee carruurta dugsiga. Baro sida loo garan iyo loo xukumo.',
        readTime: '7 daqiiqo',
        views: '8.3k',
        sections: [
            {
                heading: '🫁 Waa Maxay Asthma?',
                body: `Asthma waxay ka dhacdaa marka meelaha neefsiga (airways) xannibnaadaan oo xambaarsanaanta keenayso:\n• Neefsasho adag\n• Sanqar maraaga ah neefta (wheezing)\n• Qufac — gaar ahaan habeenkii ama marka la ciyaaro\n• Laab adag`,
            },
            {
                heading: '⚠️ Waxyaabaha Asthma Kiciya',
                body: `• Baaruud, ciid, shahwadda\n• Adkaalka biyaha (mould)\n• Shareraha xayawaanka (biya bisad, eey)\n• Hargabka iyo xanuunada neefsiga\n• Qiiqa sigarka — gaar ahaan carruurta\n• Hawada qabow`,
            },
            {
                heading: '✅ Maareynta & Xaaladaha Degdeg',
                body: `• Inhalerka kicida (reliever) wakhti kasta diyaar u yeelo\n• Ka fogow waxyaabaha kiciya\n• Dhakhtar la tasho jadwal daawo si joogto ah\n\n🚨 Degdeg isbitaalka u aad haddii: neefsashu adkaatay, inhaler kama nabad gelin, ama cududda/bushimahu madoobaaday.`,
            },
        ],
    },
    /* ── Article 19 ── */
    {
        id: 19,
        category: 'Daryeelka Dhalidda',
        icon: <Baby size={16}/>,
        accent: 'from-amber-600 to-yellow-500',
        accentLight: 'from-amber-500/20 to-yellow-500/10',
        badge: 'bg-amber-100 text-amber-700 border-amber-200',
        dot: 'bg-amber-500',
        image: IMG.newborn,
        title: 'Daryeelka Dhallaanka Cusub: Toddobaadyada Ugu Horreeya',
        subtitle: 'Bilowga nolosha ayaa ugu xasaasisan. Tallaabooyinka muhiimka ah ee dhallaanka cusub daryeelida.',
        readTime: '8 daqiiqo',
        views: '11.9k',
        sections: [
            {
                heading: '👶 Kulaylka, Nadiifnimada & Suunka',
                body: `Dhallaanka cusub wuxuu u baahan yahay:\n• Kulaylka: Heerkulka 36.5–37.5°C u hay — dhar fudud ku duub\n• Nadiifnimada: Suunka xabaalka (umbilical cord) qaliin u hay — biyo toosa ku ma dhaqin\n• Maqaarka: Wax kasta ha ku malin ilaa suunku qaliin noqdo`,
            },
            {
                heading: '🤱 Quudinta Dhalaanka Cusub',
                body: `• 8–12 jeer nuuji 24 saacadood gudahood (saacad kasta ilaa 2 saacadood)\n• Calaamadaha ku filan: 6+ xudun qoyan 24 saacadood, miisaanka kor u kaca\n• Haddaad dhibaato nuujinta muushato — oogad ama dhakhtar la tasho`,
            },
            {
                heading: '😴 Hurdo Ammaan ah & 🚨 Goorta Isbitaalka',
                body: `Hurdo ammaan:\n• Duubida laftiisa saar (marna fuusha kore)\n• Sariirta qof u gaar ah — marna sariirta waalidka\n• Meel adag — marna farshaxan jilicsan\n\nIsbitaalka degdeg u aad haddii: xummad 38°C+ (hoosta 3 bilood), neefsashadu xor ma'ahayn, midabku buluugga noqday, ama cunid diidid 2 jeer.`,
            },
        ],
    },
    /* ── Article 20 ── */
    {
        id: 20,
        category: 'Daryeelka Dhalidda',
        icon: <Baby size={16}/>,
        accent: 'from-amber-600 to-yellow-500',
        accentLight: 'from-amber-500/20 to-yellow-500/10',
        badge: 'bg-amber-100 text-amber-700 border-amber-200',
        dot: 'bg-amber-500',
        image: IMG.cry_baby,
        title: 'Colic iyo Ooyinta Dhallaanka Cusub: Sababaha & Xalka',
        subtitle: 'Dhallaanka colic wuxuu ooyaa saacadood badan sababla\'aan muuqata. Waxaa jirta maareyn ammaan ah.',
        readTime: '5 daqiiqo',
        views: '9.3k',
        sections: [
            {
                heading: '😢 Waa Maxay Colic?',
                body: `Colic waa ooyinta joogto ah ee dhallaanka caafimaadka qaba oo:\n• 3 saacadood oo badan maalintii\n• 3 maalmood oo badan usbuucii\n• 3 usbuuc oo badan\n\nKhatar kuma aha laakiin aad bay u culus u tahay waalidka. Waxay bilaabantaa 2–4 usbuuc kadib waxayna dhammaataa 3–4 bilood.`,
            },
            {
                heading: '✅ Tallaabooyinka Kalmada',
                body: `• Gacanta la saar sarkeeda oo garbaha u rub si jilicsan\n• Gees u hid ama xagga caloosha — adigoo ka fiirso\n• Cod cadaad ah (white noise) — biyo socda, barafta shaqaynaysa\n• Dhaqdhaqaaqa tartiib — cagaduug la socota\n• Biyo kulul ee dhar dhex laga dhigay caloosha hoos\n• Qubeyska biyo diirran ah`,
            },
            {
                heading: '⚠️ Saameynta Waalidka & Digniin',
                body: `Ooyinta joojin la'aanta waa culeys weyn. Haddaad daalay:\n• Shaqsi kale sixi dhallaanka (aabi, hooyo kale)\n• Dhallaanka meel ammaan dhig — masaafada gaaban u tag oo neef qaado\n• La hadal dhakhtar haddii culaysku baahu yahay\n\n⚠️ MARNA si xanaaq ugu dhaqin ama gariir uga dhig — halis daran (shaken baby syndrome).`,
            },
        ],
    },
    /* ── Article 21 ── */
    {
        id: 21,
        category: 'Maareynta Xummadda',
        icon: <Thermometer size={16}/>,
        accent: 'from-red-600 to-rose-500',
        accentLight: 'from-red-500/20 to-rose-500/10',
        badge: 'bg-red-100 text-red-700 border-red-200',
        dot: 'bg-red-500',
        image: IMG.emergency,
        title: 'Feedhiska Xummadda Keenta: Waxa la Samaynayo',
        subtitle: 'Feedhiska (febrile seizure) waa mid ka mid ah waxyaabaha ugu cabsida badan waalidka. Barasho sida loo maareyo.',
        readTime: '6 daqiiqo',
        views: '16.4k',
        sections: [
            {
                heading: '⚡ Waa Maxay Feedhiska Xummadda (Febrile Seizure)?',
                body: `Feedhiska xummaddu waa jidhku garaacayo ee ku dhaca marka xummaddu si degdeg ah kor u kacdo. Wuxuu inta badan dhacaa:\n• Carruurta 6 bilood – 5 sano\n• Ka dib xummad degdeg ah oo sareysa\n• Waxuu socdaa 1–3 daqiiqo\n• Waa mid ka mid ah waxyaabaha ugu badan ee carruurta la keena xarunta degdegga`,
            },
            {
                heading: '✅ Waxa la Samaynayo Intuu Socdo',
                body: `1. NABAD QABO — waa cabsi weyn laakiin inta badan khatarna ma aha\n2. Ilmaha dhig dhinac ama xagga hoose si aanay wax u nuugin\n3. Waxyaabaha khatarta ah ka fogee — maqaarka, kagaha, sharaarad\n4. HA GELIN wax afka — faraha, barafka, ama wax kale\n5. Wakhti xisaabi — hadduu ka badan yahay 5 daqiiqo, 999 wac\n6. Ka dib feedhiska, ilmuhu seexan doonaa — caadi waa`,
            },
            {
                heading: '🚨 Goorta La Waco 999 / Isbitaalka',
                body: `• Feedhisku ka badanayo 5 daqiiqo\n• Neeftu joogi doonto\n• Feedhis kale oo xidiga ah ku yimaada\n• Ilmuhu 18 bilood ka hooseeyo\n• Feedhis waa markii ugu horraysay\n\nKa dib feedhis kasta, xitaa marka ilmuhu fiicnaado — dhakhtar soo aad si xaaladda loo xaqiijiyo.`,
            },
        ],
    },
    /* ── Article 22 ── */
    {
        id: 22,
        category: 'Hurdo & Nasasho',
        icon: <Moon size={16}/>,
        accent: 'from-indigo-600 to-violet-500',
        accentLight: 'from-indigo-500/20 to-violet-500/10',
        badge: 'bg-indigo-100 text-indigo-700 border-indigo-200',
        dot: 'bg-indigo-500',
        image: IMG.crib,
        title: 'Hurdo Ammaan ee Dhallaanka: Ka Hortagga SIDS',
        subtitle: 'SIDS (Sudden Infant Death Syndrome) waa dhimashada aan la filayn ee dhallaanka ka yar sano. Waxaa laga hortagi karaa.',
        readTime: '5 daqiiqo',
        views: '13.7k',
        sections: [
            {
                heading: '😴 ABC ee Hurdo Ammaan ah',
                body: `A — Alone (Kali): Dhallaanka keligiis sari, marna la jiifin\nB — Back (Dib): Had iyo jeer dib u jiif — marna fuusha\nC — Crib (Sariirta): Sariirta dhallaanka oo u gaar ah — marna sariirta waalidka\n\nXeerahan saddexda ah waxay yareeyan SIDS 50% ka badan.`,
            },
            {
                heading: '🛏️ Deegaanka Hurdo Fiican',
                body: `• Sariir adag oo maqaar fiican leh — marna farshaxan jilicsan\n• Buug-saar, caraayeen, waxbarasho — ka saar sariirta\n• Heerkulka qolka: 16–20°C — ha kulaynayn si xad dhaaf\n• Sucking (nuujinta garbaha) marka seexanayso waxay yareeysaa SIDS\n• Shaashadaha ka fogow qolka hurdo`,
            },
            {
                heading: '✅ Waxyaabaha Dheeraadka ah',
                body: `• Sigarka: Ha ka sigaarayn gudaha guriga ama baabuurta — khatarna waa\n• Caano hooyo: Waxay yareeysaa SIDS risk-ka\n• Tallaalada: Waxay ilaaliyaan — kuma kordhiso SIDS\n• Waqti caloosha: Marka ilmuhu toosnaado, waqti caloosha sii (tummy time) si lafahooda u xoojiyo — laakiin lala socodsiiyo`,
            },
        ],
    },
    /* ── Article 23 ── */
    {
        id: 23,
        category: 'Nadiifnimada',
        icon: <Sparkles size={16}/>,
        accent: 'from-teal-600 to-emerald-500',
        accentLight: 'from-teal-500/20 to-emerald-500/10',
        badge: 'bg-teal-100 text-teal-700 border-teal-200',
        dot: 'bg-teal-500',
        image: IMG.kitchen,
        title: 'Nadiifnimada Cuntada & Jikada: Ka Hortagga Suntoobidda',
        subtitle: 'Suntoobidda cuntada (food poisoning) waa mid ka mid ah sababa ugu badan ee xanuunka carruurta. La barosho.',
        readTime: '5 daqiiqo',
        views: '8.9k',
        sections: [
            {
                heading: '🦠 Sida Bakteeriyadu u Faafto Cuntada',
                body: `Bakteeriyadu waxay faafaan marka:\n• Gacmaha nadiifna la'aanta cuntada laga galo\n• Cuntada heerkulka khaldan lagu kaydiyo (4–60°C waa "danger zone")\n• Cuntada la karin ee gabi ahaanba la kararin\n• Naaska iyo qalab cuntada la'aan nadiifin`,
            },
            {
                heading: '✅ Tilmaamaha Ammaan ee Jikada',
                body: `• Gacmaha dhaq: Ka hor iyo ka dib cuntada taabashada\n• Kala sooc: Hilib qooq iyo cuntada kale si gooni ah u keydi\n• Kari: Heerkulka ku filan: hilib 75°C+, ukun illaa ay adag noqdaan\n• Qabooji: Cuntada la dhameystiray 2 saacadood gudahood qabooji\n• Nadiifi qalab cuntada maalin kasta`,
            },
            {
                heading: '🚨 Calaamadaha Suntoobidda',
                body: `Guriga ku daawayn karo:\n• Matag, caloosha xanuun, shuban\n\nIsbitaalka u aad haddii:\n• Dhiig ka jiro mataga ama shuban\n• Biyo la'aanta calaamadaha\n• Xummad 39°C+\n• Ilmuhu ka yar yahay 2 sano`,
            },
        ],
    },
    /* ── Article 24 ── */
    {
        id: 24,
        category: 'Biyo La\'aanta',
        icon: <Droplets size={16}/>,
        accent: 'from-cyan-600 to-teal-500',
        accentLight: 'from-cyan-500/20 to-teal-500/10',
        badge: 'bg-cyan-100 text-cyan-700 border-cyan-200',
        dot: 'bg-cyan-500',
        image: IMG.water,
        title: 'ORS Guriga ka Samayso: Tilmaamaha Buuxda',
        subtitle: 'ORS (Oral Rehydration Solution) waxay badbaadisaa nolosha. Waxaad guriga ka sameyn kartaa haddaan xaanshaha laga helin.',
        readTime: '4 daqiiqo',
        views: '19.2k',
        sections: [
            {
                heading: '💧 Sida ORS Guriga Loogu Sameeyo',
                body: `Waxa aad u baahan tahay:\n• 1 litir biyo nadiif ah (la kariyay ama la sifiyay)\n• 6 qaaddo waaweyn (tablespoon) sonkor\n• ½ qaaddo yar (teaspoon) cusboo\n\nSii wax yar oo badan, ma aha wax badan oo xiddig. Ha siinin ilmahaaga ORS-ka jarmo weyn oo xidid ah — dib u matag ayuu keeni karaa.`,
            },
            {
                heading: '📋 Tirada la Siinayo Da\'da Kala Duwan',
                body: `Ka dib walba oo walba (shuban ama matag):\n• Hoosta 2 sano: 50–100ml (ku dhawaad koob ¼ ilaa ½)\n• 2–10 sano: 100–200ml (koob ½ ilaa 1)\n• Ka weyn 10 sano: Inta uu doonayo\n\nHadduu ilmuhu matago ORS-ka, jooji 10 daqiiqo ka dibna bilow si tartiib ah.`,
            },
            {
                heading: '⚠️ ORS Beddelka Yahay — Mana Aha',
                body: `ORS waa dib-u-soo-celinta biyaha — ma aha daawo. Cuntada ha joojin. Caano hooyo sii xitaa marka shubanku socdo.\n\nIsbitaalka u aad haddii:\n• 10+ jeer shuban 24 saacadood\n• Dhiig muuqdo\n• Matagu ORS ka hortagayo\n• Calaamadaha biyo la'aanta culus`,
            },
        ],
    },
    /* ── Article 25 ── */
    {
        id: 25,
        category: 'Caafimaadka Ilkaha',
        icon: <Stethoscope size={16}/>,
        accent: 'from-lime-600 to-green-500',
        accentLight: 'from-lime-500/20 to-green-500/10',
        badge: 'bg-lime-100 text-lime-700 border-lime-200',
        dot: 'bg-lime-500',
        image: IMG.sweets,
        title: 'Sonkorta & Ilkaha Carruurta: Xiriirka Khilaafka ah',
        subtitle: 'Sonkorta badan waa sababta #1 ee ilkaha dumidda. Waxaad hortagtaa iyagoo wali yar.',
        readTime: '4 daqiiqo',
        views: '7.8k',
        sections: [
            {
                heading: '🦷 Sida Sonkortu u Dumiso Ilkaha',
                body: `Bakteeriyada afka waxay cunaa sonkorta waxayna soo saaraan aashitada. Aashitadaasi waxay dunto:\n• Maqaarka ilkaha (enamel)\n• Godad yar oo ilkaha ku dhaca (cavities)\n• Xanuun iyo caabuq\n\nCarruurta cabbirkooda ilkaha way u nugul yihiin sonkorta aashitada.`,
            },
            {
                heading: '🚫 Cabbitaanada & Cuntada Khatar ah',
                body: `Ka fogow ama xaddid:\n• Caanaha xalalka ee baalasha loogu yeeray (badan sonkor)\n• Matooradaha (sweets) iyo lollipops\n• Juice-ka miraha — xitaa "100% natural" ee sonkor badan\n• Caanaha habeenka ka dib ilkaha cadaynta\n• Biscuit iyo qamac\n\nBeddelka fiican: biyo, miraha dhabta ah, khudaar.`,
            },
            {
                heading: '✅ Ka Hortagga Wax ku Oolka ah',
                body: `• 2 jeer maalintiiba cadayn (subax + habeenkii)\n• Fluoride toothpaste isticmaal — xukun yar (pea-size) carruurta 2–6 sano\n• Ka fogow caanaha botelka ee habeenka — ORS ama biyo beddelka\n• Dhakhtar ilkaha booqo: da'da 1 sano + 6 bilood markiiba\n• Salinoo (floss) bilow markay 2 ilko xiddigsanaan yimaadaan`,
            },
        ],
    },
    /* ── Article 26 ── */
    {
        id: 26,
        category: 'Ciyaaraha & Horumarinta',
        icon: <Brain size={16}/>,
        accent: 'from-yellow-600 to-amber-500',
        accentLight: 'from-yellow-500/20 to-amber-500/10',
        badge: 'bg-yellow-100 text-yellow-700 border-yellow-200',
        dot: 'bg-yellow-500',
        image: IMG.kids_social,
        title: 'Horumarinta Bulsheed ee 0–5 Sano: Xilliyada Muhiimka ah',
        subtitle: 'Horumarinta xagga bulshada iyo dareenka waxay aasaas u tahay nolosha oo dhan. Bilowda waa guri.',
        readTime: '6 daqiiqo',
        views: '8.2k',
        sections: [
            {
                heading: '👶 0–12 Bilood: Xidhiidh Adag',
                body: `Dhallaanku wuxuu baranayaa xagga bulshada marka waalidku:\n• Indhaha ay isla fiiriyaan (eye contact)\n• Codka dhinac ka jawaabaan\n• Qososhada ku jawaabaan\n• Hadalka codadkiisa u tarjumaan\n\nQabashada, nuujinta, iyo debed ka jawaabida waxay xoojiyaan xidhiidhka amaanka ah (secure attachment).`,
            },
            {
                heading: '🤝 1–3 Sano: Ciyaarta Dhinac',
                body: `Da'dan, carruurtu ma ciyaari wada — waxay ciyaaraan meel u dhow oo ay is-arkaan. Caadi waa.\n\nKorsooji:\n• Soo jiid xaaladaha bulshada — booqashooyinka, beerta\n• Hadal badan — "Maxay qabtaa inantaas?"\n• Is-dhexgalka kaalin wanaagsan oo aad tusaalo u noqoto`,
            },
            {
                heading: '👫 3–5 Sano: Saaxiibnimo & Xeerarka',
                body: `Heer kasto:\n• Wadaagga (sharing) barasho — ma fududna, waqti qaadanaysa\n• Ciyaarta xeerka leh — turn-taking, kubbadda\n• Xaaladaha dareenka fasiraad — "Maxuu u ooyayaa?"\n• Nidaamka — waa maxay saxda iyo cidhibta\n\n🚨 La xiriir dhakhtar haddii ilmuhu la ciyaari la'yahay, la xiriir la'yahay, ama welwelka bulshada la'yahay.`,
            },
        ],
    },
    /* ── Article 27 ── */
    {
        id: 27,
        category: 'Caafimaadka Maskaxda',
        icon: <Heart size={16}/>,
        accent: 'from-rose-600 to-pink-500',
        accentLight: 'from-rose-500/20 to-pink-500/10',
        badge: 'bg-rose-100 text-rose-700 border-rose-200',
        dot: 'bg-rose-500',
        image: IMG.toddler,
        title: 'Xanaaqyada Carruurta: Sababaha & Sida Loo Maareyo',
        subtitle: 'Tantrum waa xanaaq cabir dhaafka ah. Xanuun ma aha — horumarinta jireed iyo maskaxda ayaa sababta.',
        readTime: '5 daqiiqo',
        views: '11.3k',
        sections: [
            {
                heading: '🧠 Maxaa Keena Xanaaqyada?',
                body: `Maskaxda hore ee carruurta (prefrontal cortex) weli si buuxda uma horumarisna, sidaas awgeed xaaladaha xukumida dareenka waa adagtahay. Xanaaqyadu inta badan dhacaan marka:\n• Daalnimada, gaajada, ama dhidhidda\n• Liidashada in ay wax samaystaan\n• Isbedelka caadada iyo xaaladaha`,
            },
            {
                heading: '✅ Xaaladda la Samaynayo',
                body: `INTUU SOCDO:\n• Nabad qabo — xanaaqaagaagu wuu korodhsiinayaa keenadooda\n• Meel ammaan ah u jiri — jiidis dhimashada sababa ama nafsiga\n• Hadal yar — "Waan ku joogaa"\n• HA DOODIN, HA IXTIRAAMIN\n\nKA DIB:\n• Caloosha hoos u dhig oo gartaa — "Waxaad dareentay..."\n• Soo xidhiidh — hug yar\n• Ka baro iyo isku soo laab`,
            },
            {
                heading: '🚨 Goorta La Walaacdo',
                body: `Xanaaqyada caadiga ah waxay dhammaanayaan 4 sano. La xiriir dhakhtar haddii:\n• Xanaaqyadu si joogto ah u dhaafaan 15 daqiiqo\n• Nafta ama dadka kale u xanuunsato\n• Ka badan 5 jeer maalintii\n• Jilicsan ka dib 4 sano`,
            },
        ],
    },
    /* ── Article 28 ── */
    {
        id: 28,
        category: 'Daaweynta Ugu Horraysa',
        icon: <Zap size={16}/>,
        accent: 'from-slate-600 to-gray-500',
        accentLight: 'from-slate-500/20 to-gray-500/10',
        badge: 'bg-slate-100 text-slate-700 border-slate-200',
        dot: 'bg-slate-500',
        image: IMG.aid_kit,
        title: 'Wax Macluul ah Carruurta: Cabada & Tallaabooyinka Badbaadinta',
        subtitle: 'Wax macluul ah la cabadeeyo waa degdeg. Daqiiqadaha hore ayaa badbaadin kara nolosha ilmahaaga.',
        readTime: '7 daqiiqo',
        views: '21.5k',
        sections: [
            {
                heading: '🚨 Calaamadaha Wax Macluul ah la Cabadeeyo',
                body: `• Gacmaha afka u qaada si degdeg\n• Xidantaa, ciyoo, ama codka sharqaynaya\n• Neefsashu adkaaday ama joogi doonto\n• Wajiga casaanaaday ama buluugaaday\n• Hadal kari waayo ama ooy kari waayo`,
            },
            {
                heading: '✅ Cabada Dhallaanka (Ka yar 1 Sano)',
                body: `1. Dhabarka hoos kaga jiif — garbaha ku taagan\n2. 5 garaac dhabar: Garbaha u dhexeeya xoogga jilicsan ku garaac\n3. 5 GARAAC laab: 2 farta dhexe garbaha hore hor jog\n4. Ka eeg afka — hadduu wax arkayso si tartiib u saar\n5. Ku celceli ilaa waxu baxo ama uu neefto\n\nMarna dul kaga jiifo ama lugaha u laab.`,
            },
            {
                heading: '✅ Cabada Carruurta (1 Sano+) — Heimlich',
                body: `1. Dhabarka hoos yar u jiif si loo xoojiyaa\n2. Gadaashiisa ka gal, gacmahaaga ku wareejiso caloosha\n3. Meel hoose xididdaynta (navel) ka sareysa gaca dhufo\n4. Kor iyo gudaha xooggeed u riix — si degdeg\n5. Ku celceli ilaa waxu baxo\n\nHadduu maqnaaday: CPR bilow. Wac 999.`,
            },
        ],
    },
    /* ── Article 29 ── */
    {
        id: 29,
        category: 'Nafaqada & Quudinta',
        icon: <AlertTriangle size={16}/>,
        accent: 'from-orange-600 to-amber-500',
        accentLight: 'from-orange-500/20 to-amber-500/10',
        badge: 'bg-orange-100 text-orange-700 border-orange-200',
        dot: 'bg-orange-500',
        image: IMG.nuts,
        title: 'Alerji Cuntada ee Carruurta: Gaarista, Calaamadaha & Maareynta',
        subtitle: 'Alerji cuntada waxay saameyn kartaa 1 ka mid ah 12 caruur. Gaar ahaan 8 nooc cuntaa ayaa sababta ugu badan.',
        readTime: '6 daqiiqo',
        views: '9.6k',
        sections: [
            {
                heading: '🥜 8 Cuntada Ugu Badan ee Alerji',
                body: `1. Caano lo'aad (milk)\n2. Ukun (eggs)\n3. Qamandi (peanuts)\n4. Geedaha midhaha (tree nuts)\n5. Kalluunka (fish)\n6. Xayawaanka badda (shellfish)\n7. Sarreen (wheat/gluten)\n8. Digir caddaan (soy)\n\n90% alerji cuntada waxaa sababa siddan nooc.`,
            },
            {
                heading: '⚠️ Calaamadaha Alerji',
                body: `Fudud/Dhexdhexaad:\n• Maqaarka cas ama xayaan\n• Afka ama bushimaha xanuun\n• Caloosha xanuun, matag\n• San socda ama indho wareeran\n\nCulus (Anaphylaxis — 999 WAC DEGDEG):\n• Neefta adkaanaysa\n• Qoorta ama wejiga wareeran\n• Dhiiggu hoos u dhacay\n• Xanaaqfuranta ama maqnaanshadda`,
            },
            {
                heading: '✅ Maareynta Alerji',
                body: `• Dhakhtar la tasho si dhakhtar cuntada looga daaweeyo\n• Cuntada sababta ku qor oo maalin kasta ka fogow\n• Waxbarashada dugsiga: macallimiin u sheeg\n• EpiPen: haddii alerji culus xaqiijiyay, wax kasta diyaar u yeelo\n• Bilow cuntada cusub mid mid ahaan iyo maalin ama laba maalin u dhexeeya`,
            },
        ],
    },
    /* ── Article 30 ── */
    {
        id: 30,
        category: 'Faafitaanka Xanuunada',
        icon: <Shield size={16}/>,
        accent: 'from-violet-600 to-purple-500',
        accentLight: 'from-violet-500/20 to-purple-500/10',
        badge: 'bg-violet-100 text-violet-700 border-violet-200',
        dot: 'bg-violet-500',
        image: IMG.rash,
        title: 'Jadeecada (Measles): Calaamadaha, Tallaalka & Ka Hortagga',
        subtitle: 'Jadeecadu waxay noqon kartaa xanuun halis ah. Tallaalku waa ilaalinta ugu waxtar badan.',
        readTime: '6 daqiiqo',
        views: '14.1k',
        sections: [
            {
                heading: '🔴 Calaamadaha Jadeecada',
                body: `Marxalad 1 (Bilowga, 2–4 maalmood):\n• Xummad sareysa\n• Qufac, san socda\n• Indho cas (conjunctivitis)\n• Dhibcaha Koplik (dhibco cad afka gudaha)\n\nMarxalad 2 (Khasabka, 3–5 maalmood):\n• Khasab cas oo bilaabma wejiga ka dibna jidhka\n• Xummaddu waxay gaaraysa 40°C+`,
            },
            {
                heading: '⚠️ Faafitaanka & Khatarada',
                body: `Jadeecadu waa mid ka mid ah xanuunada ugu faafa badan adduunka:\n• 1 qof oo xanuunsaday wuxuu faafi karaa 9–18 qof\n• Waxay faaftaa cid 4 maalmood ka hor khasabka iyo 4 maalmood ka dib\n\nCillado halis ah: Pheumonia (wadnaha xanuun), encephalitis (maskaxda wareeridda), dhimashada`,
            },
            {
                heading: '💉 Ka Hortagga & Tallaalka',
                body: `Tallaalka MR (Measles-Rubella):\n• 9 bilood: Tallaalka koowaad\n• 15 bilood: Tallaalka labaad (booster)\n\nWaxay bixisaa ilaalin 97% ah marka labadaba la helo.\n\nHaddii si degdeg loo baahdo: tallaalka 72 saacadood gudood ka dib xiriirka waxay hortagi kartaa xanuunka.`,
            },
        ],
    },
    /* ── Article 31 ── */
    {
        id: 31,
        category: 'Nafaqada & Quudinta',
        icon: <Apple size={16}/>,
        accent: 'from-orange-600 to-amber-500',
        accentLight: 'from-orange-500/20 to-amber-500/10',
        badge: 'bg-orange-100 text-orange-700 border-orange-200',
        dot: 'bg-orange-500',
        image: IMG.healthy_wt,
        title: 'Miisaanka Farraxsanaanta Carruurta: Ka Hortagga & Maareynta',
        subtitle: 'Carruurta miisaankoodu sarreeyo waxay khatarta weyn u yihiin xanuunada qaan-gaadhnimada. Hortagga waa aasaaska.',
        readTime: '6 daqiiqo',
        views: '10.2k',
        sections: [
            {
                heading: '⚖️ Sida Loo Garanayo Heerka Caafimaadka',
                body: `BMI (Body Mass Index) waa qiyaasta inta badan la isticmaalo, laakiin carruurta waxaa lagu xisaabaa da\'da iyo jinsiyadda.\n\nDhakhtar ayaa xisaabinaya — ha isku xisaabin guriga.\n\nCalaamadaha la soco:\n• Miisaanka si deg-deg ah u kaca iyada oo dhererku aanay u dheeraanayn\n• Kala cuntada yar ya'ay joogtoonayn\n• Daalnimo marka la cayaarayo\n• Neefs dheer ama dhiig cadaadis`,
            },
            {
                heading: '🥗 Isbedelada Guriga ee Wax Ku Oolka ah',
                body: `Cuntada:\n• Ka faa'ideyso khudaarta iyo miraha — ½ saxan kasta cuntada\n• Caanaha lo'aad ee dufanka leh (full-fat) bedel — 2% ama skimmed\n• Sonkorta lagu daraa cabbitaanada jooji — biyo u bedel\n• Waxqabad guriga: cunto kar — carruurtu waxay jecel yihiin cuntada ay samaysteen\n\nCiyaarta:\n• 60 daqiiqo dhaqdhaqaaq firfircoon maalin kasta\n• Shaashadaha 2 saacadood xaddid\n• Ciyaarta dibedda dhiirigeliso`,
            },
            {
                heading: '⚠️ Waxa La Iska Fogeynayo',
                body: `• HA SAARIN carruurta "diet" adag — koritaankooda waa xumayn kara\n• Ha naxdin ku cadaadinid cuntada — "Waa in aad cunaysaa"\n• Ha kula hadlin jidhkooda si xun\n• Abaalmarin cuntada la dhigin — "Haddaad cunto, waxaad helaysaa..."\n\nDhakhtar la tasho si qorshaha saxda ah loo sameeyo.`,
            },
        ],
    },
    /* ── Article 32 ── */
    {
        id: 32,
        category: 'Caafimaadka Neefsiga',
        icon: <Wind size={16}/>,
        accent: 'from-blue-600 to-sky-500',
        accentLight: 'from-blue-500/20 to-sky-500/10',
        badge: 'bg-blue-100 text-blue-700 border-blue-200',
        dot: 'bg-blue-500',
        image: IMG.xray,
        title: 'Pneumonia Carruurta: Calaamadaha, Daaweynta & Xaaladaha Degdeg',
        subtitle: 'Pneumonia waa sababta #1 ee dhimashada carruurta adduunka oo dhan. Hore u garo, hore u daawayn.',
        readTime: '7 daqiiqo',
        views: '17.3k',
        sections: [
            {
                heading: '🫁 Waa Maxay Pneumonia?',
                body: `Pneumonia waa caabuqa sambabka (lungs). Bakteeriya, fayraska, ama fangaska waxay buuxiyaan xubnahayeynta biyo ama xoogyar ah, taasoo adkaynaysa neefsashada.\n\nCarruurta ugu halis badan:\n• Hoosta 5 sano (gaar ahaan hoosta 2 sano)\n• Aan la tallaalin\n• Nafaqo xumo leh\n• HIV ama difaac jir la'aanta`,
            },
            {
                heading: '🚨 Calaamadaha — Dhakhtar Degdeg u Aad',
                body: `Calaamadaha culus (ISBITAALKA DEGDEG):\n• Neeftu aad u dhaqso (hoosta 2 bilood: 60+ neef/daqiiqo)\n• Laabta ama luqunta hoos u go'ota marka la neefto\n• Bushinku ama cududdu madoobaaday\n• Ilmuhu cabbiray ama wax cabi waayo\n• Xummad 39°C+ ee daawo ka jawaabaysa\n\nAd isbitaalka si degdeg ah — Pneumonia mararka qaarkooda saacadaha gudood ayay halis noqon kartaa.',`,
            },
            {
                heading: '✅ Ka Hortagga Pneumonia',
                body: `• Tallaalada: PCV (Pneumococcal) iyo Hib waxay ka hortagaan noocyada ugu badan\n• Naas nuujinta: Dhallaanka naas nuujinta waxay yareeysaa khatarta 15%\n• Nadiifnimada: Gacmaha dhaqista waxay hortagtaa faafitaanka\n• Cunto wanaagsan: Difaaca jirku wuxuu ku xirnaaday nafaqada\n• Sigarka: Guriga ka samayn — qiigu wuxuu xoojiiya khatarta pneumonia`,
            },
        ],
    },
    /* ── Article 33 ── */
    {
        id: 33,
        category: 'Tallaalada',
        icon: <Shield size={16}/>,
        accent: 'from-purple-600 to-fuchsia-500',
        accentLight: 'from-purple-500/20 to-fuchsia-500/10',
        badge: 'bg-purple-100 text-purple-700 border-purple-200',
        dot: 'bg-purple-500',
        image: IMG.brain_doc,
        title: 'Tallaalka Meningitis: Ilaalin Maskaxda & Xididdada Neerfaha',
        subtitle: 'Meningitis waxay noqon kartaa xanuun geeridda keena saacadihii gudood. Tallaalku waa kaligii difaaca.',
        readTime: '5 daqiiqo',
        views: '8.7k',
        sections: [
            {
                heading: '🧠 Meningitis Waa Maxay?',
                body: `Meningitis waa caabuqa xuubka ku hareereysan maskaxda iyo xididdada neerfaha (meninges). Waxay keeni kartaa:\n• Dhimashad (10–15% xaaladaha)\n• Dhagoolnimo joogto ah\n• Naakhas naakhas\n• Dhibaato waxbarasho\n\nNooca bakteeriyada ah ayaa ugu halis badan — daqiiqadaha hore waa muhiim.`,
            },
            {
                heading: '⚠️ Calaamadaha Halis — 999 WAC',
                body: `Calaamadaha meningitis:\n• Madax-xanuun aad u xoog badan\n• Qoorta adag (gooynta aan ahayn)\n• Iftiin ka xanaaqa\n• Khasab cas/madow oo gudaha jir ka muuqda — hadduu faraha cadaanka kaga dambeeyo: DEGDEG\n• Xummad culus + qufac la'aanta\n• Wareega ama xanaaqfuranta\n• Dhallaanka: fontanelle (madaxa hore) oo wareeran ama la taabanto adag`,
            },
            {
                heading: '💉 Tallaalada Meningitis',
                body: `Tallaalka Hib (Haemophilus influenzae type b):\n• 6, 10, 14 toddobaad — qayb ka mid ah Pentavalent\n\nTallaalka PCV (Pneumococcal):\n• 6, 10, 14 toddobaad + booster 12 bilood\n\nTallaalka MenACWY:\n• Laga bilaabo 9 bilood — gaar ahaan marka ay xaajiga u aadayaan\n\nTallaalada waqtigooda siiy — waa ilaalin ku gaadha maskaxda.`,
            },
        ],
    },
    /* ── Article 34 ── */
    {
        id: 34,
        category: 'Horumarinta',
        icon: <TrendingUp size={16}/>,
        accent: 'from-pink-600 to-rose-500',
        accentLight: 'from-pink-500/20 to-rose-500/10',
        badge: 'bg-pink-100 text-pink-700 border-pink-200',
        dot: 'bg-pink-500',
        image: IMG.autism_play,
        title: 'Autism Spectrum Disorder (ASD): Calaamadaha Hore & Taageerada',
        subtitle: 'Gaarista hore ee ASD waxay awoodi kartaa carruurta inay taageero hore helaan oo si fiican u horumaraan.',
        readTime: '7 daqiiqo',
        views: '12.5k',
        sections: [
            {
                heading: '🔍 Calaamadaha Hore (6–24 Bilood)',
                body: `La soco calaamadahan:\n• Magacaaga lagu yeedho ma jeedo (12 bilood)\n• Indhaha la xiriir la'aanta joogto ah\n• Wax aan sheegin ama tilmaamayn (pointing)\n• Qosol ama dareen wadaag la'aanta\n• Hadalki horay u baranaa oo la lumiyay\n• Ciyaar "pretend play" la'aantiis (18 bilood ka dib)\n• Jiqsiga aad u daran — nidaam bedelkiisa ka cabsanaya`,
            },
            {
                heading: '✅ Haddii Aad Walaacsantahay',
                body: `1. Dhakhtar carruurta la tasho si degdeg ah\n2. Sharraxaad buuxda: waxa aad aragtid, goorta, jeer immisa\n3. Muuqaal ka duub — aabayaasha badankoodu waxay yidhaahdaan "guriga waa kale"\n4. Tartamida dhakhtar kale haddii la diido\n\nASD ma aha cillad — waa kala duwan yahay maskaxda u shaqaynta. Taageero hore waxay saameyn weyn ku leedahay natiijada.',`,
            },
            {
                heading: '🤝 Xarumaha Taageerada Somaaliya',
                body: `Khidmadaha la raadsan karo:\n• Dhakhtarka carruurta (pediatrician) — bilowga\n• Takhasuska horumarinta (developmental specialist)\n• Xanuunqabka hadalka (speech therapist)\n• Takhasuska shaqada (occupational therapist)\n\nNaf-nafsiga waalidku waa muhiim — iskaashi la raadso, macluumaad baadh.`,
            },
        ],
    },
    /* ── Article 35 ── */
    {
        id: 35,
        category: 'Faafitaanka Xanuunada',
        icon: <Shield size={16}/>,
        accent: 'from-violet-600 to-purple-500',
        accentLight: 'from-violet-500/20 to-purple-500/10',
        badge: 'bg-violet-100 text-violet-700 border-violet-200',
        dot: 'bg-violet-500',
        image: IMG.water_pump,
        title: 'Cholera Carruurta: Ka Hortagga, Calaamadaha & ORS Degdeg',
        subtitle: 'Cholera waa xanuunka biyaha wasakhaysan ee si degdeg u geeya biyo la\'aanta halista ah. Hore u yeesha ORS.',
        readTime: '5 daqiiqo',
        views: '9.1k',
        sections: [
            {
                heading: '💧 Waa Maxay Cholera?',
                body: `Cholera waa caabuqa mindhicirka ay keento bakteeriyada Vibrio cholerae. Waxay faaftaa:\n• Biyo wasakhaysan (inta badan biyo macaan\n• Cunto aan si buuxda loo karin\n• Gacmaha nadiifna la'aanta\n\nCarruurtu waxay ku dhintaan saacadihii gudood haddaan daaweyn la bilaaban.`,
            },
            {
                heading: '🚨 Calaamadaha & Degdegga',
                body: `• Shuban biyo-biyo ah oo si degdeg u bilaabanaya ("rice-water stool")\n• Matag badan\n• Biyo la'aan si aad u dhaqso u horumaraysa\n• Xidid iyo murqo-xanuun\n\nIsku day ORS degdeg u bilaw — hadduu ilmuhu i aad u daaloobay, indhaha hoos u dhacay, ama afku engegay: ISBITAALKA DEGDEG.`,
            },
            {
                heading: '✅ Ka Hortagga Guriga',
                body: `• Biyo: Kar ama chlorine ku dar — marna biyo aan la karin cabin\n• Gacmaha: 20 ilbiriqsi saabuun ka hor cuntada iyo ka dib musqusha\n• Cuntada: Si buuxda kar — cuntada juicy-ga ah ee rinjiga ah\n• Musqusha: Faransiis isticmaal — ana musqusha furan ka fogow\n• ORS: Had iyo jeer guriga haysato — daaweynta koowaad cholera`,
            },
        ],
    },
    /* ── Article 36 ── */
    {
        id: 36,
        category: 'Daryeelka Dhalidda',
        icon: <Baby size={16}/>,
        accent: 'from-amber-600 to-yellow-500',
        accentLight: 'from-amber-500/20 to-yellow-500/10',
        badge: 'bg-amber-100 text-amber-700 border-amber-200',
        dot: 'bg-amber-500',
        image: IMG.hosp_baby,
        title: 'Jaundice (Huruudda) Dhallaanka Cusub: Goorta La Walaacdo',
        subtitle: 'Jaundice waa midabka huruudda ah ee inta badan ka muuqda dhallaanka cusub. Badankeed caadi bay tahay — laakiin xog ayaa muhiim.',
        readTime: '5 daqiiqo',
        views: '13.4k',
        sections: [
            {
                heading: '🟡 Waa Maxay Jaundice?',
                body: `Jaundice waxay dhacaysaa marka bilirubin (dunta dhiiga) ay ku uruurto jirka. Jidhku wuxuu u muuqdaa huruud/jaalle:\n• Maqaarka — ka bilow wejiga ka dibna jidhka\n• Indho cadaanka\n\nCaadiga ah waxay bilaabanaysaa 2–3 maalmood ka dib dhalashada waxayna dhammaanaysaa 1–2 usbuuc. Dhallaanka hore dhashay (premature) waxay u baahan yihiin nadiifin dheeraad ah.`,
            },
            {
                heading: '🚨 Goorta Dhakhtar Degdeg La Arko',
                body: `• 24 saacadood gudood ka dib dhalashada waxay muuqataa\n• Midabku wuu xoogeeyay — caloosha iyo lugaha gaartay\n• Dhallaanku nuujin diidaa ama aad u daaloobaa\n• Ka dib 2 usbuuc wali jirta\n• Cayaanka midabkiisu waa cagaaran (bile caabuq)\n\nJaundice culus waxay saameyn kartaa maskaxda — daaweynta phototherapy isbitaalka ku sameyso.`,
            },
            {
                heading: '✅ Guriga Gacan ka Gaadha',
                body: `• Naas nuuji si joogto ah — 8–12 jeer maalintii\n• Nuujinta badan waxay caawisaa bilirubin si deg-deg u baxo (kaadi iyo saxaro)\n• Iftiin cadceeda khafiif (subax hore, 15–20 daqiiqo) — ha dirqin\n• Miisaanka iyo midabka maalin kasta la soco\n• Booqasho dhakhtar 2–3 maalood ka dib isbitaalka ka baxistaa`,
            },
        ],
    },
    /* ── Article 37 ── */
    {
        id: 37,
        category: 'Caafimaadka Maskaxda',
        icon: <Heart size={16}/>,
        accent: 'from-rose-600 to-pink-500',
        accentLight: 'from-rose-500/20 to-pink-500/10',
        badge: 'bg-rose-100 text-rose-700 border-rose-200',
        dot: 'bg-rose-500',
        image: IMG.child_study,
        title: 'ADHD Carruurta: Waa Maxay, Sida Loo Garanno & Taageerada',
        subtitle: 'ADHD (Attention Deficit Hyperactivity Disorder) waa mid ka mid ah xaaladaha maskaxda ee ugu badan carruurta dugsiga.',
        readTime: '6 daqiiqo',
        views: '9.8k',
        sections: [
            {
                heading: '🧠 Calaamadaha ADHD',
                body: `Laba nooc ayaa jira:\n\nDhaqdhaqaaqa badan (Hyperactive-Impulsive):\n• Joogsanaan la'aanta\n• Kaga boodbooda\n• Hadal aan wakhtigiisa ahayn\n• Samir la'aanta\n\nFikirka maqnaanshaha (Inattentive):\n• Shaqada dhamaystirka la'aanta\n• Su\'aalaha jawaab la'aanta\n• Wax lumiya joogtada ah\n• Hawlaha nidaamka u baahan ka diidasho',`,
            },
            {
                heading: '✅ Guriga Taageero',
                body: `• Nidaam iyo hab joogto ah — waqtiyada cad, xeerarka cad\n• Hawlaha yaryar u qeybi — hal tallaabo waqti kasta\n• Fakhadka yar — waxbarasho meel aamusan\n• Abaalmarin joogto ah — waxay gacan ka geysataa maskaxda ADHD\n• Ciyaarta dhaqdhaqaaqa leh waxay yareeysaa calaamadaha\n• Hurdo ku filan — yarida hurdadu waxay culaystaa ADHD`,
            },
            {
                heading: '🤝 Goorta Takhasuska La Raadsado',
                body: `ADHD waxaa lagu ogaadaa:\n• Dhakhtar carruurta\n• Takhasuska horumarinta\n• Macallimka warbixinta\n\nDaaweynta waxay ku jiri kartaa:\n• Tababar dareenka xukumida (behavioral therapy)\n• Daawo haddii loo baahdo (dhakhtar go\'aamiya)\n• Xarunta taageerada dugsiga\n\nADHD waa isbedel maskax — ma aha daciifnimo. Waxaa jira carruurto ADHD leh oo aad u guulaystay.`,
            },
        ],
    },
    /* ── Article 38 ── */
    {
        id: 38,
        category: 'Daaweynta Ugu Horraysa',
        icon: <Zap size={16}/>,
        accent: 'from-slate-600 to-gray-500',
        accentLight: 'from-slate-500/20 to-gray-500/10',
        badge: 'bg-slate-100 text-slate-700 border-slate-200',
        dot: 'bg-slate-500',
        image: IMG.bandage,
        title: 'Gubashada, Xididdada Jabidda & Maqaarka Dhaawaca: Hagaha Buuxda',
        subtitle: 'Xaaladaha dhaawacyada waa kuwa inta badan guriga ka dhaca. Hore u baradhood si aad u badbaadiso.',
        readTime: '7 daqiiqo',
        views: '15.8k',
        sections: [
            {
                heading: '🔥 Gubashada — Daraja & Daaweynta',
                body: `Daraja 1 (Khafiif — casaanida oo keliya):\n• Biyo qabow 10–20 daqiiqo\n• Ha gelin baraf, buruud, toothpaste\n• Bandage xidhi\n\nDaraja 2 (Dhexdhexaad — baloolaha):\n• Biyo qabow\n• Baloolaha ha qodin — caabuq keeni kartaa\n• Isbitaalka u aad\n\nDaraja 3 (Culus — maqaarka gubtay):\n• DEGDEG isbitaalka — ha isku dayin guriga ku daaweyso`,
            },
            {
                heading: '🦴 Xididdada Jabidda (Fracture)',
                body: `Calaamadaha:\n• Xanuun culus meel gaar ah\n• Wax gelin la'aanta ama dhaqdhaqaaq la'aanta\n• Baroorta ama boodka\n• Qaab aan caadiga ahayn\n\nWaxa la samaynayo:\n• Meel aad u jaban u geli ma aha\n• SPLINT khafiif kula xidhi si aanay u dhaqaaqdaan\n• Baraf (dhar ku duub) xanuunka hoos u dhac\n• Isbitaalka u aad — X-ray ayaa loo baahan yahay`,
            },
            {
                heading: '🩹 Maqaarka Dhaawacyada',
                body: `Dhaawaca caadiga ah:\n1. Cadaad ku saaro si dhiig loo joojiyo (3–5 daqiiqo)\n2. Biyo nadiif ku dhaq\n3. Antiseptic khafiif ku dhaq\n4. Bandage nadiif ku duub\n5. Maalimaha xigta caabuqa ka fiirso\n\nIsbitaalka u aad haddii:\n• Dhaawaca ka dheer yahay 1 cm oo qoto dheer\n• Wajiga ama gacanta meesha xididdada\n• Dhiigga joogi la waayo 10 daqiiqo ka dib`,
            },
        ],
    },
    /* ── Article 39 ── */
    {
        id: 39,
        category: 'Nadiifnimada',
        icon: <Sparkles size={16}/>,
        accent: 'from-teal-600 to-emerald-500',
        accentLight: 'from-teal-500/20 to-emerald-500/10',
        badge: 'bg-teal-100 text-teal-700 border-teal-200',
        dot: 'bg-teal-500',
        image: IMG.skin_care,
        title: 'Eczema (Xasaasiyadda Maqaarka) Carruurta: Daryeelka & Xukumida',
        subtitle: 'Eczema waa xaaladda maqaarka ee ugu badan carruurta. Daawo ma laha laakiin waa la maareyn karaa.',
        readTime: '5 daqiiqo',
        views: '7.4k',
        sections: [
            {
                heading: '🔴 Calaamadaha Eczema',
                body: `• Maqaarka engegga oo xanaajiya (itching)\n• Cas, qalalan, ama qoob-qoobid\n• Gaar ahaan: garabaha hore, xuduudda jilbaha, wejiga (dhallaanka)\n• Habeenkii wuu sii daraa — xiliga qaboobaha\n• Marna waxay caloosha raacaysaa — caano lo'aad alerji`,
            },
            {
                heading: '✅ Daryeelka Guriga',
                body: `• Qubeys gaaban (5–10 daqiiqo) biyo diirran — marna kulul\n• Saabuunta la'aanta ama saabuun khafiif, udgoon la'aanta\n• Moisturizer dufan: isla markaaba ka dib qubeyska — 3 daqiiqo gudood\n• Dhar suuf ah — marna polyester ama ciid-ciid\n• Cidiyaha gaaban — xanaajiyaha joojinta\n• Fanaanaha hawada: qolka diirran wuu sii daraa eczema\n• Buug-saarka iyo xayawaanka guriga: ay alerjiyada keenaan',`,
            },
            {
                heading: '💊 Goorta Dhakhtar La Aado',
                body: `Dhakhtar la tasho haddii:\n• Xanaajiyuhu hurdo joojinayo\n• Caabuqa soo baxo (biyo cad/huruud, dhiig)\n• Daaweynta guriga laga jawaabi waayo\n• Maqaarka baaba'aya oo baaxad leh\n\nDhakhtar wuxuu bixin karaa:\n• Cream hydrocortisone (khafiif)\n• Antihistamine habeenkii\n• Cream talaalka ah haddii caabuq`,
            },
        ],
    },
    /* ── Article 40 ── */
    {
        id: 40,
        category: 'Faafitaanka Xanuunada',
        icon: <Shield size={16}/>,
        accent: 'from-violet-600 to-purple-500',
        accentLight: 'from-violet-500/20 to-purple-500/10',
        badge: 'bg-violet-100 text-violet-700 border-violet-200',
        dot: 'bg-violet-500',
        image: IMG.mosquito,
        title: 'Maraygga (Malaria) & Carruurta: Ka Hortagga, Calaamadaha & Daaweynta',
        subtitle: 'Malaria waa xanuunka ugu baaxadda weyn ee carruurta Afrika. Tallaabo hore ayaa badbaadin kara nolosha.',
        readTime: '6 daqiiqo',
        views: '18.6k',
        sections: [
            {
                heading: '🦟 Sida Marayggu u Faafaa',
                body: `Maraygga waxaa keenta xayawaanka yar ee Plasmodium. Waxaa gudbiya kaneecada Anopheles (dheddig) marka ay dhiig nuugto.\n\nCarruurta hoosta 5 sano ayaa ugu halis weyn — 80% dhimashada malaria carruurta iyaga ayaa ka mid ah.\n\nXiliyada roobka ka dib iyo habeenka waa goorta kaneecadu ugu badan.`,
            },
            {
                heading: '🌡️ Calaamadaha Malaria',
                body: `Calaamadaha hore:\n• Xummad xiddig ah (goor walba mid)\n• Hurdo badan iyo qabyo\n• Madax-xanuun\n• Calool-xanuun, matag\n\nIsbitaalka DEGDEG u aad haddii:\n• Xummad 38.5°C+ ee carruurta hoosta 5 sano\n• Wareega ama maqnaanshaha\n• Neefs dhibaato\n• Dhiig ka jiro kaadida\n• Cunid iyo cabbitaan diidid`,
            },
            {
                heading: '✅ Ka Hortagga Guriga',
                body: `Kaneecada ka hortagga:\n• Shabaqa sariirta (mosquito net) isticmaal — ATN (insecticide-treated net)\n• Repellent ku tufto maqaarka habeenkii\n• Dhar dheer habeenkii\n• Waraabaha biyaha xidh — kaneecadu waxay ku dhashaa biyaha taagan\n• Guryaha daaqadaha iyo albaabada shabag ku xidh\n\nRaadraac la xiriir caafimaad ee ganacsiga:\n• Prophylaxis la qaado haddii aad u safrayso\n• Baaritaan dhiig: 48 saacadood gudood xummadda bilaabanaysay`,
            },
        ],
    },
];

/* ─── Nutrition Items ─────────────────────────────────────────────────── */
const NUTRITION = [
    {
        icon: <Apple size={20}/>,
        label: 'Miraha & Khudaarta',
        desc: '5 jeer maalintiiba ku dadaal. Vitamins A, C, fiber badan.',
        color: 'text-green-700 bg-green-50 border-green-200',
        img: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=400&h=220&q=80',
        pct: 90,
        barColor: 'bg-green-500',
    },
    {
        icon: <Utensils size={20}/>,
        label: 'Boroto & Midab',
        desc: 'Ukun, kalluun, digir — aasaaska unugyada iyo maskaxda.',
        color: 'text-amber-700 bg-amber-50 border-amber-200',
        img: 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=400&h=220&q=80',
        pct: 80,
        barColor: 'bg-amber-500',
    },
    {
        icon: <Star size={20}/>,
        label: 'Vitamins & Kaabiyaasha',
        desc: 'Vitamin A, Birta, Zinc — dhammaystirka nafaqada.',
        color: 'text-purple-700 bg-purple-50 border-purple-200',
        img: 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?auto=format&fit=crop&w=400&h=220&q=80',
        pct: 75,
        barColor: 'bg-purple-500',
    },
    {
        icon: <Droplets size={20}/>,
        label: 'Biyo Nadiif',
        desc: 'Carruurta yar: 1–1.3L/maalin. Dugsiga: 1.5–2L/maalin.',
        color: 'text-blue-700 bg-blue-50 border-blue-200',
        img: 'https://images.unsplash.com/photo-1559839914-17aae19cec71?auto=format&fit=crop&w=400&h=220&q=80',
        pct: 95,
        barColor: 'bg-blue-500',
    },
];

/* ─── Stats ──────────────────────────────────────────────────────────── */
const STATS = [
    { icon: <BookOpen size={20}/>, value: '40', label: 'Maqaalood', color: 'text-purple-600' },
    { icon: <Users size={20}/>,    value: '50k+', label: 'Waalidiin', color: 'text-blue-600' },
    { icon: <Award size={20}/>,    value: '14', label: 'Qaybood', color: 'text-teal-600' },
    { icon: <Heart size={20}/>,    value: '100%', label: 'Bilaash', color: 'text-rose-600' },
];

/* ─── Quick Tips Ticker ──────────────────────────────────────────────── */
const TIPS = [
    '💧 Biyo badan sii carruurta maalintii — caafimaad waa biyo', '🍎 Miro mid ah maalin kasta — vitamin C xoojiya difaaca',
    '😴 Carruurta 2–5 sano u baahan 10–13 saacadood hurdo', '🤲 Gacmaha dhaqista waxay joojisaa 80% caabuqyada',
    '💉 Tallaalada waqtigooda sii — maanta xanniib berri xanuun', '🦷 2 jeer maalin kasta cadayn — ilkaha nolosha oo dhan kaalay',
    '🌱 Cuntada midableyso — midab kasta waa nafaqo', '🏃 Dhaqdhaqaaqa maalinlaha ah wuxuu xoojiyaa lafaha iyo maskaxda',
];

/* ═══════════════════════════════════════════════════════════════════════ */

export const HealthEducation = () => {
    const navigate = useNavigate();
    const [searchQuery, setSearchQuery]         = useState('');
    const [activeCategory, setActiveCategory]   = useState('Dhammaan');
    const [featuredIdx, setFeaturedIdx]         = useState(0);
    const [visibleIds, setVisibleIds]           = useState(new Set());
    const [nutritionVisible, setNutritionVisible] = useState(false);
    const cardsRef = useRef({});
    const nutritionRef = useRef(null);
    const tickerRef = useRef(null);

    /* Auto-rotate featured */
    useEffect(() => {
        const t = setInterval(() => setFeaturedIdx(i => (i + 1) % 3), 6000);
        return () => clearInterval(t);
    }, []);

    /* Scroll-reveal for article cards */
    useEffect(() => {
        const io = new IntersectionObserver(
            entries => entries.forEach(e => {
                if (e.isIntersecting) setVisibleIds(prev => new Set([...prev, e.target.dataset.cardid]));
            }),
            { threshold: 0.12 }
        );
        Object.values(cardsRef.current).forEach(el => el && io.observe(el));
        return () => io.disconnect();
    }, [activeCategory, searchQuery]);

    /* Nutrition bar reveal */
    useEffect(() => {
        if (!nutritionRef.current) return;
        const io = new IntersectionObserver(
            ([e]) => { if (e.isIntersecting) setNutritionVisible(true); },
            { threshold: 0.2 }
        );
        io.observe(nutritionRef.current);
        return () => io.disconnect();
    }, []);

    const CATEGORIES = ['Dhammaan', ...new Set(ARTICLES.map(a => a.category))];

    const filtered = ARTICLES.filter(a => {
        const q = searchQuery.toLowerCase();
        const matchSearch = !q || a.title.toLowerCase().includes(q) || a.category.toLowerCase().includes(q) || a.subtitle.toLowerCase().includes(q);
        const matchCat = activeCategory === 'Dhammaan' || a.category === activeCategory;
        return matchSearch && matchCat;
    });

    const featured = ARTICLES.filter(a => a.featured);
    const currentFeatured = featured[featuredIdx];

    /* Register card ref */
    const setRef = useCallback((id, el) => { cardsRef.current[id] = el; }, []);

    return (
        <>
            <style>{STYLES}</style>

            <div className="w-full space-y-8 font-sans">

                {/* ══ HERO ══════════════════════════════════════════════════ */}
                <div className="relative rounded-3xl overflow-hidden shadow-2xl" style={{ minHeight: 340 }}>
                    {/* Background image with slow zoom */}
                    <div className="absolute inset-0 overflow-hidden">
                        <img
                            src={IMG.hero}
                            alt="Carruura caafimaad"
                            className="w-full h-full object-cover he-hero-zoom"
                            style={{ transformOrigin: 'center center' }}
                        />
                    </div>
                    {/* Gradient overlay */}
                    <div className="absolute inset-0 bg-linear-to-br from-purple-950/95 via-indigo-900/85 to-purple-800/70"/>

                    {/* Decorative blobs */}
                    <div className="absolute top-6 right-16 w-40 h-40 rounded-full bg-purple-400/15 blur-3xl he-float" style={{ animationDelay: '0s' }}/>
                    <div className="absolute bottom-8 right-40 w-28 h-28 rounded-full bg-indigo-400/20 blur-2xl he-float" style={{ animationDelay: '1.5s' }}/>
                    <div className="absolute top-12 left-1/2 w-20 h-20 rounded-full bg-pink-400/10 blur-2xl he-float" style={{ animationDelay: '0.8s' }}/>

                    <div className="relative z-10 p-8 sm:p-12">
                        {/* Eyebrow */}
                        <div className="inline-flex items-center gap-2 bg-white/10 border border-white/20 rounded-full px-4 py-1.5 mb-5 he-fade-in">
                            <span className="he-pulse-dot w-2 h-2 rounded-full bg-emerald-400 inline-block"/>
                            <span className="text-white/90 text-xs font-black uppercase tracking-widest">🇸🇴 Xarunta Waxbarashada Caafimaadka</span>
                        </div>

                        <div className="flex flex-col lg:flex-row gap-8 items-start lg:items-end justify-between">
                            <div className="max-w-xl he-slide-up" style={{ animationDelay: '0.1s' }}>
                                <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight leading-[1.1] mb-4">
                                    Maktabadda<br/>
                                    <span className="text-transparent bg-clip-text bg-linear-to-r from-purple-300 to-pink-300">
                                        Caafimaadka Carruurta
                                    </span>
                                </h1>
                                <p className="text-white/75 font-medium text-sm leading-relaxed mb-6">
                                    Hagaha xog-ogaanshaha ugu ballaadhan ee ku saabsan quudinta, xanuunka, nadiifnimada, hurdada, tallaalada, iyo horumarinta — waalidiinta oo dhan.
                                </p>

                                {/* Search */}
                                <div className="relative max-w-sm">
                                    <Search size={17} className="absolute left-4 top-3.5 text-white/50"/>
                                    <input
                                        type="text"
                                        value={searchQuery}
                                        onChange={e => setSearchQuery(e.target.value)}
                                        placeholder="Mawduuca raadi..."
                                        className="w-full pl-12 pr-4 py-3.5 rounded-2xl bg-white/10 border border-white/25 text-white placeholder-white/45 focus:outline-none focus:ring-2 focus:ring-purple-400/60 text-sm font-semibold backdrop-blur-sm"
                                    />
                                    {searchQuery && (
                                        <button onClick={() => setSearchQuery('')} className="absolute right-4 top-3.5 text-white/50 hover:text-white transition-colors">
                                            <X size={16}/>
                                        </button>
                                    )}
                                </div>
                            </div>

                            {/* Stats */}
                            <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-2 xl:grid-cols-4 gap-3 he-slide-up shrink-0" style={{ animationDelay: '0.25s' }}>
                                {STATS.map((s, i) => (
                                    <div key={i} className="bg-white/10 border border-white/15 rounded-2xl p-4 text-center backdrop-blur-sm hover:bg-white/15 transition-all" style={{ animationDelay: `${0.1 * i}s` }}>
                                        <div className={`${s.color} flex justify-center mb-1`}>{s.icon}</div>
                                        <div className="text-white font-black text-xl">{s.value}</div>
                                        <div className="text-white/60 text-[10px] font-bold uppercase tracking-wide">{s.label}</div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>

                {/* ══ TIPS TICKER ════════════════════════════════════════════ */}
                <div className="rounded-2xl bg-linear-to-r from-purple-600 to-indigo-600 overflow-hidden shadow-lg">
                    <div className="flex items-center">
                        <div className="flex items-center gap-2 bg-purple-800 px-4 py-3 shrink-0">
                            <Zap size={14} className="text-yellow-300"/>
                            <span className="text-white text-[11px] font-black uppercase tracking-widest whitespace-nowrap">Talo Degdeg</span>
                        </div>
                        <div className="overflow-hidden flex-1 py-3 px-4">
                            <div className="he-ticker whitespace-nowrap text-white text-xs font-semibold">
                                {[...TIPS, ...TIPS].map((tip, i) => (
                                    <span key={i} className="mr-14 inline-block">{tip}</span>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>

                {/* ══ FEATURED CAROUSEL ══════════════════════════════════════ */}
                <div>
                    <div className="flex items-center justify-between mb-4">
                        <h2 className="text-(--text-primary) font-black text-lg flex items-center gap-2">
                            <Star size={18} className="text-amber-500 fill-amber-500"/>
                            Maqaalada Muuqda
                        </h2>
                        <div className="flex items-center gap-2">
                            <button
                                onClick={() => setFeaturedIdx(i => (i - 1 + 3) % 3)}
                                className="w-8 h-8 rounded-full border border-(--border) flex items-center justify-center text-(--text-muted) hover:border-purple-400 hover:text-purple-600 transition-all"
                            >
                                <ChevronLeft size={16}/>
                            </button>
                            {[0,1,2].map(i => (
                                <button key={i} onClick={() => setFeaturedIdx(i)}
                                    className={`w-2 h-2 rounded-full transition-all ${featuredIdx === i ? 'bg-purple-600 w-6' : 'bg-(--border)'}`}/>
                            ))}
                            <button
                                onClick={() => setFeaturedIdx(i => (i + 1) % 3)}
                                className="w-8 h-8 rounded-full border border-(--border) flex items-center justify-center text-(--text-muted) hover:border-purple-400 hover:text-purple-600 transition-all"
                            >
                                <ChevronRight size={16}/>
                            </button>
                        </div>
                    </div>

                    <div
                        key={featuredIdx}
                        className="relative rounded-3xl overflow-hidden cursor-pointer he-pop group shadow-xl"
                        style={{ minHeight: 320 }}
                        onClick={() => navigate('/education/' + currentFeatured.id)}
                    >
                        <img src={currentFeatured.image} alt={currentFeatured.title} className="absolute inset-0 w-full h-full object-cover he-img"/>
                        <div className={`absolute inset-0 bg-linear-to-r ${currentFeatured.accent} opacity-75`}/>
                        <div className="absolute inset-0 bg-linear-to-t from-black/80 via-black/20 to-transparent"/>

                        {/* Content */}
                        <div className="relative z-10 h-full flex flex-col justify-end p-8 sm:p-10">
                            <div className="max-w-xl">
                                <span className={`text-[10px] font-black uppercase px-3 py-1.5 rounded-full border inline-flex items-center gap-1.5 mb-3 ${currentFeatured.badge} bg-white/90`}>
                                    {currentFeatured.icon} {currentFeatured.category}
                                </span>
                                <h2 className="text-2xl sm:text-3xl font-black text-white leading-tight mb-3 drop-shadow-lg">
                                    {currentFeatured.title}
                                </h2>
                                <p className="text-white/80 text-sm font-medium leading-relaxed mb-5">
                                    {currentFeatured.subtitle}
                                </p>
                                <div className="flex items-center gap-6">
                                    <div className="flex items-center gap-2 text-white/70">
                                        <Clock size={14}/>
                                        <span className="text-xs font-bold">{currentFeatured.readTime}</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-white/70">
                                        <Eye size={14}/>
                                        <span className="text-xs font-bold">{currentFeatured.views}</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-white font-black text-sm group-hover:gap-3 transition-all">
                                        Akhri <ArrowRight size={16}/>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* ══ CATEGORY FILTER ════════════════════════════════════════ */}
                <div className="flex gap-2 flex-wrap">
                    {CATEGORIES.map((cat, i) => {
                        const article = ARTICLES.find(a => a.category === cat);
                        const isActive = activeCategory === cat;
                        return (
                            <button
                                key={cat}
                                onClick={() => setActiveCategory(cat)}
                                style={{ animationDelay: `${i * 0.04}s` }}
                                className={`he-badge flex items-center gap-1.5 px-4 py-2 rounded-full text-[11px] font-black uppercase tracking-wide border-2 transition-all
                                    ${isActive
                                        ? 'bg-purple-600 text-white border-purple-600 shadow-lg shadow-purple-200 dark:shadow-purple-900/30'
                                        : 'border-(--border) text-(--text-muted) hover:border-purple-400 hover:text-purple-600 bg-(--surface)'
                                    }`}
                            >
                                {cat !== 'Dhammaan' && article && <span className={`w-1.5 h-1.5 rounded-full inline-block ${isActive ? 'bg-white' : article.dot}`}/>}
                                {cat}
                            </button>
                        );
                    })}
                </div>

                {/* ══ NUTRITION GUIDE ════════════════════════════════════════ */}
                <div ref={nutritionRef}>
                    <h2 className="text-(--text-primary) font-black text-lg flex items-center gap-2 mb-5">
                        <Leaf size={20} className="text-green-500"/>
                        Hagaha Nafaqada
                    </h2>
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                        {NUTRITION.map((n, i) => (
                            <div
                                key={n.label}
                                className={`rounded-2xl border overflow-hidden ${n.color} shadow-sm hover:shadow-lg transition-all group`}
                                style={nutritionVisible ? { animation: `he-slideUp 0.5s ease ${i * 0.1}s both` } : { opacity: 0 }}
                            >
                                <div className="h-32 overflow-hidden">
                                    <img src={n.img} alt={n.label} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"/>
                                </div>
                                <div className="p-4">
                                    <div className="flex items-center gap-2 font-black text-sm mb-2">{n.icon} {n.label}</div>
                                    <p className="text-[11px] font-medium leading-relaxed opacity-85 mb-3">{n.desc}</p>
                                    <div className="h-1.5 rounded-full bg-black/10 overflow-hidden">
                                        <div
                                            className={`h-full rounded-full ${n.barColor} he-progress-bar`}
                                            style={nutritionVisible
                                                ? { width: `${n.pct}%`, animationDelay: `${0.3 + i * 0.1}s` }
                                                : { width: 0 }
                                            }
                                        />
                                    </div>
                                    <div className="text-[10px] font-black mt-1 opacity-60">{n.pct}% Lagugu Taliyay</div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* ══ VACCINATION TIMELINE ═══════════════════════════════════ */}
                <div className="rounded-2xl border border-purple-200 dark:border-purple-800 bg-linear-to-br from-purple-50 to-indigo-50 dark:from-purple-950/30 dark:to-indigo-950/20 p-6">
                    <h2 className="text-(--text-primary) font-black text-lg flex items-center gap-2 mb-6">
                        <Shield size={20} className="text-purple-600"/>
                        Jadwalka Tallaalada
                    </h2>
                    <div className="relative">
                        {/* Line */}
                        <div className="absolute left-4 top-2 bottom-2 w-0.5 bg-purple-200 dark:bg-purple-700"/>
                        <div className="space-y-5">
                            {[
                                { time: 'Dhalashada', vaccines: ['BCG', 'OPV 0', 'Hep-B 0'], color: 'bg-red-500' },
                                { time: '6 Toddobaad', vaccines: ['Pentavalent 1', 'OPV 1', 'PCV 1', 'RV 1'], color: 'bg-orange-500' },
                                { time: '10 Toddobaad', vaccines: ['Pentavalent 2', 'OPV 2', 'PCV 2', 'RV 2'], color: 'bg-yellow-500' },
                                { time: '14 Toddobaad', vaccines: ['Pentavalent 3', 'OPV 3', 'PCV 3', 'IPV'], color: 'bg-green-500' },
                                { time: '9 Bilood', vaccines: ['MR 1', 'OPV 4'], color: 'bg-blue-500' },
                                { time: '15 Bilood', vaccines: ['MR 2', 'PCV Booster'], color: 'bg-purple-500' },
                            ].map((row, i) => (
                                <div key={i} className="flex items-start gap-4 pl-8 relative">
                                    <div className={`absolute left-2.5 top-1.5 w-3 h-3 rounded-full ${row.color} border-2 border-white dark:border-gray-900 z-10 shadow-md`}/>
                                    <div className="flex flex-col sm:flex-row sm:items-center gap-2">
                                        <span className="text-xs font-black text-(--text-primary) w-28 shrink-0">{row.time}</span>
                                        <div className="flex flex-wrap gap-1.5">
                                            {row.vaccines.map(v => (
                                                <span key={v} className="text-[10px] font-bold px-2.5 py-1 rounded-full bg-white dark:bg-gray-800 border border-purple-200 dark:border-purple-700 text-purple-700 dark:text-purple-300 shadow-sm">
                                                    {v}
                                                </span>
                                            ))}
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                {/* ══ ARTICLES GRID ══════════════════════════════════════════ */}
                <div>
                    <div className="flex items-center justify-between mb-5">
                        <h2 className="text-(--text-muted) font-black text-[11px] uppercase tracking-widest flex items-center gap-2">
                            <BookOpen size={13}/>
                            {filtered.length} Maqaal{filtered.length !== 1 ? 'ood' : ''} la Helay
                        </h2>
                        {searchQuery && (
                            <button onClick={() => setSearchQuery('')} className="text-xs text-purple-600 font-black hover:underline flex items-center gap-1">
                                <X size={12}/> Nadiifi
                            </button>
                        )}
                    </div>

                    {filtered.length === 0 ? (
                        <div className="p-14 text-center border-2 border-dashed border-(--border) rounded-3xl">
                            <Search size={40} className="mx-auto text-slate-300 mb-4"/>
                            <h2 className="text-xl font-black text-(--text-secondary) mb-2">Maqaal lama helin</h2>
                            <p className="text-(--text-muted) font-medium text-sm">Xaraf kale isku day ama qaybta bedel.</p>
                        </div>
                    ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
                            {filtered.map((article, i) => (
                                <div
                                    key={article.id}
                                    ref={el => setRef(article.id, el)}
                                    data-cardid={article.id}
                                    onClick={() => navigate('/education/' + article.id)}
                                    className="he-card group rounded-2xl overflow-hidden border border-(--border) bg-(--surface) shadow-sm cursor-pointer flex flex-col"
                                    style={visibleIds.has(String(article.id))
                                        ? { animation: `he-slideUp 0.45s ease ${Math.min(i % 3, 2) * 0.08}s both` }
                                        : { opacity: 0 }
                                    }
                                >
                                    {/* Image */}
                                    <div className="relative h-44 overflow-hidden shrink-0">
                                        <img
                                            src={article.image}
                                            alt={article.title}
                                            className="he-img w-full h-full object-cover"
                                            onError={e => { e.target.style.display='none'; }}
                                        />
                                        <div className={`absolute inset-0 bg-linear-to-t ${article.accent} opacity-35`}/>
                                        <span className={`absolute top-3 left-3 text-[10px] font-black uppercase px-2.5 py-1 rounded-full border flex items-center gap-1 ${article.badge} bg-white/90`}>
                                            {article.icon} {article.category}
                                        </span>
                                        <div className="absolute top-3 right-3 flex items-center gap-1 bg-black/40 rounded-full px-2.5 py-1">
                                            <Eye size={10} className="text-white/70"/>
                                            <span className="text-[10px] font-bold text-white/80">{article.views}</span>
                                        </div>
                                    </div>

                                    {/* Body */}
                                    <div className="p-5 flex flex-col flex-1">
                                        <h3 className="font-black text-(--text-primary) text-[15px] leading-snug mb-2 tracking-tight group-hover:text-purple-600 transition-colors">
                                            {article.title}
                                        </h3>
                                        <p className="text-[12px] font-medium text-(--text-secondary) leading-relaxed mb-4 flex-1">
                                            {article.subtitle}
                                        </p>

                                        {/* Sections preview pills */}
                                        <div className="flex flex-wrap gap-1.5 mb-4">
                                            {article.sections.slice(0, 2).map((s, si) => (
                                                <span key={si} className="text-[9px] font-bold px-2 py-0.5 rounded-full bg-(--surface-soft) text-(--text-muted) border border-(--border)">
                                                    {s.heading.replace(/^[^\s]+ /, '').substring(0, 22)}…
                                                </span>
                                            ))}
                                        </div>

                                        <div className="flex items-center justify-between mt-auto pt-3 border-t border-(--border)">
                                            <div className="flex items-center gap-1.5 text-(--text-muted)">
                                                <Clock size={11}/>
                                                <span className="text-[11px] font-bold">{article.readTime}</span>
                                            </div>
                                            <div className="flex items-center gap-1 text-purple-600 text-[12px] font-black group-hover:gap-2 transition-all">
                                                Akhri <ChevronRight size={14}/>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* ══ EMERGENCY QUICK GUIDE ══════════════════════════════════ */}
                <div className="rounded-3xl bg-linear-to-br from-red-600 to-rose-700 p-6 shadow-xl">
                    <div className="flex items-center gap-3 mb-5">
                        <div className="w-10 h-10 bg-white/20 rounded-2xl flex items-center justify-center">
                            <AlertTriangle size={20} className="text-white"/>
                        </div>
                        <div>
                            <h2 className="text-white font-black text-lg">Hagaha Xaaladaha Degdegga ah</h2>
                            <p className="text-red-200 text-xs font-semibold">Waxaad u aadaysaa isbitaalka marka aad aragto calaamadahan</p>
                        </div>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                        {[
                            { icon: '🌡️', title: 'Xummad Aad u Xoog', desc: 'Ka sareeya 40°C ama ilmaha ka yar 3 bilood' },
                            { icon: '💨', title: 'Neefsasho Dhibaato', desc: 'Xoog u neefsashada ama bushimaha af-duubnaanshaha' },
                            { icon: '💧', title: 'Biyo La\'aan Culus', desc: 'Ilmaan la\'aanta, afka engeganow, kaadi la\'aantiis' },
                            { icon: '⚡', title: 'Feedhis / Dhulgariir', desc: 'Jidhku garaacayo oo aanay lahayn maamul' },
                            { icon: '🤢', title: 'Matag Xoog', desc: 'Ka badato 6 jeer ayaa khatar ah' },
                            { icon: '😴', title: 'Xanaaqdarro Adag', desc: 'Laga toosi karin ama jawaab la\'aanta' },
                        ].map((item, i) => (
                            <div key={i} className="bg-white/10 border border-white/20 rounded-2xl p-4 backdrop-blur-sm">
                                <div className="text-2xl mb-2">{item.icon}</div>
                                <div className="text-white font-black text-sm mb-1">{item.title}</div>
                                <div className="text-red-200 text-[11px] font-medium leading-relaxed">{item.desc}</div>
                            </div>
                        ))}
                    </div>
                    <div className="mt-5 bg-white/10 border border-white/25 rounded-2xl p-4 flex items-center gap-3">
                        <CheckCircle size={20} className="text-green-300 shrink-0"/>
                        <p className="text-white text-sm font-semibold">
                            Xaaladaha sare aragto markaad, si degdeg ah u tag xarunta caafimaadka ugu dhowdaan ama ka weydii Portal-ka La-Tashaashada.
                        </p>
                    </div>
                </div>

            </div>
        </>
    );
};
