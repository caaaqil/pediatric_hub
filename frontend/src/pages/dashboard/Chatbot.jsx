/**
 * Chatbot.jsx — PediaBot
 * Features:
 *  • Language toggle (Soomaali / English) — switching starts a fresh session
 *  • Collapsible history sidebar showing archived sessions
 *  • "+ New Chat" saves the current session before clearing the view
 *  • Language is always sent as an explicit param; langRef prevents stale-closure bugs
 *  • Emergency UI only fires for real life-threatening keywords
 */

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { api } from '../../lib/axios';
import {
    Bot, Send, User, AlertTriangle, ShieldAlert,
    Mic, MicOff, Volume2, VolumeX, Plus, Globe,
    ChevronLeft, ChevronRight, MessageSquare, Clock, Trash2,
} from 'lucide-react';
import useAuthStore from '../../store/authStore';
import { Link } from 'react-router-dom';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const LANG = {
    en: {
        name: 'English',
        placeholder: 'Type your question…',
        greeting: "Hello! I'm PediaBot. Ask me about symptoms, vaccines, child nutrition, or how to use this app.",
        newChat: 'New Chat',
        history: 'Previous Chats',
        noHistory: 'No previous chats.',
        listening: 'Listening…',
        disclaimer: 'AI guidance only — not a substitute for professional medical advice. Emergencies: call 252-1.',
        topics: ['My child has a fever', 'Vaccination schedule', 'Signs of dehydration', 'Nutrition for toddlers'],
    },
    so: {
        name: 'Soomaali',
        placeholder: 'Su\'aashaada halkan qor…',
        greeting: 'Salaam! Waxaan ahay PediaBot. I weydii su\'aalaha ku saabsan xanuunka, tallaalka, nafaqada, ama sida loo isticmaalo app-kan.',
        newChat: 'Sheeko Cusub',
        history: 'Sheekooyinkii Hore',
        noHistory: 'Sheeko hore ma jirto.',
        listening: 'Dhageysanaya…',
        disclaimer: 'Talo AI kaliya — ma beddelo dhakhtarka. Xaaladda degdegga: wac 252-1.',
        topics: ['Ilmahaygii wuxuu hayaa xummad', 'Jadwalka tallaalka', 'Calaamadaha biyo xumaanta', 'Nafaqada carruurta yar'],
    },
};

// Only messages that start with 🚨 are real emergency replies (set by backend fast-path).
// This prevents AI responses that merely MENTION emergency symptoms from triggering the red UI.

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

/** Topic quick-access pills shown in empty state */
const TopicPills = ({ lang, onSend }) => (
    <div className="flex flex-wrap gap-2 mt-3">
        {LANG[lang].topics.map((t, i) => (
            <button key={i} onClick={() => onSend(t)}
                className="cursor-pointer px-3 py-1.5 rounded-full text-xs font-semibold border border-(--border) bg-(--surface) text-(--text-secondary) hover:border-cyan-500 hover:text-cyan-700 dark:hover:text-cyan-300 transition-all">
                {t}
            </button>
        ))}
    </div>
);

/** Single chat message bubble */
const Bubble = ({ m, lang }) => {
    const isUser      = m.sender === 'USER';
    const isEmergency = !isUser && m.message.startsWith('🚨');
    const time        = new Date(m.timestamp || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    return (
        <div className={`flex gap-2.5 items-end ${isUser ? 'flex-row-reverse' : 'flex-row'}`}>
            {/* Avatar */}
            <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 shadow-sm text-white
                ${isUser ? 'bg-slate-400' : isEmergency ? 'bg-red-500' : 'bg-cyan-600'}`}>
                {isUser ? <User size={14}/> : <Bot size={14}/>}
            </div>

            {/* Bubble */}
            <div className={`flex flex-col gap-1 max-w-[74%] ${isUser ? 'items-end' : 'items-start'}`}>
                <div className={`px-4 py-3 rounded-2xl text-sm leading-relaxed shadow-sm
                    ${isUser
                        ? 'bg-cyan-600 text-white rounded-br-sm'
                        : isEmergency
                            ? 'bg-red-50 dark:bg-red-950/30 border-2 border-red-300 dark:border-red-700 text-(--text-primary) rounded-bl-sm'
                            : 'bg-(--surface) border border-(--border) text-(--text-primary) rounded-bl-sm'
                    }`}>
                    <p className="whitespace-pre-wrap">{m.message}</p>

                    {/* Emergency actions */}
                    {isEmergency && !isUser && (
                        <div className="mt-3 pt-3 border-t border-red-200 dark:border-red-800 flex gap-2 flex-wrap">
                            <a href="tel:252"
                                className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-lg cursor-pointer transition-colors">
                                <AlertTriangle size={12}/> {lang === 'so' ? 'Wac 252-1' : 'Call 252-1'}
                            </a>
                            <Link to="/emergency"
                                className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-(--surface) border border-(--border) text-(--text-secondary) text-xs font-bold rounded-lg cursor-pointer hover:border-cyan-400 transition-colors">
                                {lang === 'so' ? 'Isbitaalada' : 'Find Hospital'}
                            </Link>
                        </div>
                    )}
                </div>
                <span className="text-[10px] text-(--text-muted) px-1">{time}</span>
            </div>
        </div>
    );
};

/** Animated typing indicator */
const Typing = () => (
    <div className="flex gap-2.5 items-end">
        <div className="w-8 h-8 rounded-full bg-cyan-600 flex items-center justify-center shrink-0">
            <Bot size={14} className="text-white"/>
        </div>
        <div className="px-4 py-3.5 rounded-2xl rounded-bl-sm bg-(--surface) border border-(--border) shadow-sm flex gap-1.5 items-center">
            {[0, 150, 300].map(d => (
                <span key={d} className="w-2 h-2 rounded-full bg-cyan-400 animate-bounce" style={{ animationDelay: `${d}ms` }}/>
            ))}
        </div>
    </div>
);

/** History sidebar item */
const HistoryItem = ({ session, active, lang, onClick }) => {
    const title  = session.title || (lang === 'so' ? 'Sheeko la xidh' : 'Closed chat');
    const date   = new Date(session.createdAt).toLocaleDateString([], { month: 'short', day: 'numeric' });
    const badge  = session.language === 'so' ? '🇸🇴' : '🇬🇧';

    return (
        <button onClick={onClick}
            className={`cursor-pointer w-full text-left px-3 py-3 rounded-xl border transition-all group
                ${active
                    ? 'bg-cyan-50 dark:bg-cyan-950/30 border-cyan-300 dark:border-cyan-700'
                    : 'bg-(--surface) border-(--border) hover:border-cyan-400 hover:bg-(--surface-soft)'
                }`}>
            <div className="flex items-center gap-2 mb-1">
                <span className="text-sm">{badge}</span>
                <span className="text-xs font-black text-(--text-primary) truncate flex-1">{title}</span>
            </div>
            <div className="flex items-center gap-1 text-(--text-muted)">
                <Clock size={9}/>
                <span className="text-[10px]">{date}</span>
            </div>
        </button>
    );
};

// ---------------------------------------------------------------------------
// Main component
// ---------------------------------------------------------------------------
export const Chatbot = () => {
    const { user }                            = useAuthStore();
    const [lang, setLang]                     = useState('so');
    const [sessionId, setSessionId]           = useState(null);
    const [messages, setMessages]             = useState([]);
    const [input, setInput]                   = useState('');
    const [loading, setLoading]               = useState(false);
    const [initDone, setInitDone]             = useState(false);
    const [initError, setInitError]           = useState(false);
    const [isListening, setIsListening]       = useState(false);
    const [speakerOn, setSpeakerOn]           = useState(false);
    const [sidebarOpen, setSidebarOpen]       = useState(false);
    const [pastSessions, setPastSessions]     = useState([]);
    const [activeHistoryId, setActiveHistoryId] = useState(null);
    const [historyLoading, setHistoryLoading] = useState(false);

    // Refs
    const bottomRef      = useRef(null);
    const recognitionRef = useRef(null);
    const transcriptRef  = useRef('');
    const inputRef       = useRef(null);
    /**
     * langRef always mirrors the lang state value synchronously.
     * This prevents stale-closure bugs in handleSend's async callbacks —
     * the language sent to the API is always what's currently selected.
     */
    const langRef        = useRef('so');
    const sessionIdRef   = useRef(null);

    /* ── Scroll to bottom on new messages ──────────────────────────────── */
    useEffect(() => {
        bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages, loading]);

    /* ── Session initialisation ─────────────────────────────────────────── */
    const initSession = useCallback(async (forceNew = false, newLang) => {
        const l = newLang ?? langRef.current;
        setInitError(false);
        try {
            const res = await api.post('/chatbot/session', { forceNew, language: l });
            const id  = res.data.data.id;
            setSessionId(id);
            sessionIdRef.current = id;
            setActiveHistoryId(null);

            if (!forceNew) {
                const hist = await api.get(`/chatbot/${id}/history`);
                setMessages(hist.data.data?.length ? hist.data.data : []);
            } else {
                setMessages([]);
            }
            setInitDone(true);
        } catch (e) {
            console.error('Chat init failed', e);
            setInitError(true);
            setInitDone(true); // still show the UI so greeting renders
        }
    }, []);

    useEffect(() => { initSession(); }, [initSession]);

    /* ── Load history sidebar list ──────────────────────────────────────── */
    const loadPastSessions = useCallback(async () => {
        setHistoryLoading(true);
        try {
            const res = await api.get('/chatbot/sessions');
            setPastSessions(res.data.data || []);
        } catch (e) {
            console.error('History load failed', e);
        } finally {
            setHistoryLoading(false);
        }
    }, []);

    // Reload history list whenever the sidebar is opened
    useEffect(() => {
        if (sidebarOpen) loadPastSessions();
    }, [sidebarOpen, loadPastSessions]);

    /* ── Language switch → archive current session, start fresh ────────── */
    const handleLangChange = async (newLang) => {
        if (newLang === langRef.current) return;
        langRef.current = newLang;
        setLang(newLang);
        setSpeakerOn(false);
        window.speechSynthesis?.cancel();

        // Archive the current session before switching
        if (sessionIdRef.current) {
            try { await api.post(`/chatbot/${sessionIdRef.current}/close`); } catch (_) {}
        }
        await initSession(true, newLang);
    };

    /* ── New Chat — save current session then open a blank one ─────────── */
    const handleNewChat = async () => {
        if (sessionIdRef.current && messages.length > 0) {
            try { await api.post(`/chatbot/${sessionIdRef.current}/close`); } catch (_) {}
        }
        await initSession(true);
        // Refresh history sidebar if it's open
        if (sidebarOpen) loadPastSessions();
    };

    /* ── Restore an archived session ────────────────────────────────────── */
    const handleLoadHistory = async (session) => {
        try {
            setActiveHistoryId(session.id);
            langRef.current = session.language;
            setLang(session.language);
            const res = await api.get(`/chatbot/${session.id}/history`);
            // Show messages in read-only view — do NOT set sessionId to archived session
            setMessages(res.data.data || []);
        } catch (e) {
            console.error('History restore failed', e);
        }
    };

    /* ── TTS ─────────────────────────────────────────────────────────────── */
    const speak = (text) => {
        if (!speakerOn || !window.speechSynthesis) return;
        window.speechSynthesis.cancel();
        const u   = new SpeechSynthesisUtterance(text.replace(/[#*_`[\]🚨]/g, ''));
        u.lang    = langRef.current === 'so' ? 'so-SO' : 'en-US';
        u.rate    = 0.92;
        window.speechSynthesis.speak(u);
    };

    /* ── STT ─────────────────────────────────────────────────────────────── */
    const startListening = () => {
        const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!SR) { alert('Voice input requires Chrome or Edge.'); return; }
        const rec         = new SR();
        rec.lang          = langRef.current === 'so' ? 'so-SO' : 'en-US';
        rec.continuous    = false;
        rec.interimResults = true;
        rec.onresult = (e) => {
            const t = Array.from(e.results).map(r => r[0].transcript).join('');
            setInput(t);
            transcriptRef.current = t;
        };
        rec.onend = () => {
            setIsListening(false);
            const t = transcriptRef.current.trim();
            transcriptRef.current = '';
            if (t) handleSend(t);
        };
        rec.onerror = () => { setIsListening(false); transcriptRef.current = ''; };
        rec.start();
        recognitionRef.current = rec;
        setIsListening(true);
        transcriptRef.current = '';
    };

    const stopListening = () => { recognitionRef.current?.stop(); setIsListening(false); };

    /* ── Send message ────────────────────────────────────────────────────── */
    const handleSend = async (text) => {
        const msg     = (text || input).trim();
        const sid     = sessionIdRef.current;
        const curLang = langRef.current;

        if (!msg || loading) return;

        // If session hasn't initialised yet, retry once
        if (!sid) {
            if (initError) return; // backend is down, don't spin
            await initSession();
            if (!sessionIdRef.current) return;
        }

        // If viewing a history session (read-only), prompt user to start new chat
        if (activeHistoryId) {
            await initSession(true);
            return;
        }

        const activeSid = sessionIdRef.current;
        if (!activeSid) return;

        setInput('');
        setMessages(prev => [
            ...prev,
            { id: `opt-${Date.now()}`, sender: 'USER', message: msg, timestamp: new Date().toISOString() },
        ]);
        setLoading(true);

        try {
            const res = await api.post(`/chatbot/${activeSid}/chat`, { message: msg, language: curLang });
            setMessages(prev => [...prev, res.data.data]);
            speak(res.data.data.message);
        } catch {
            setMessages(prev => [
                ...prev,
                {
                    id: `err-${Date.now()}`, sender: 'AI',
                    message: curLang === 'so'
                        ? 'Khalad ayaa dhacay. Dib u isku day.'
                        : 'Something went wrong. Please try again.',
                    timestamp: new Date().toISOString(),
                },
            ]);
        } finally {
            setLoading(false);
            inputRef.current?.focus();
        }
    };

    const cfg = LANG[lang];

    // ---------------------------------------------------------------------------
    // Render
    // ---------------------------------------------------------------------------
    return (
        <div className="h-[calc(100vh-112px)] flex gap-3 max-w-5xl mx-auto">

            {/* ── HISTORY SIDEBAR ────────────────────────────────────────── */}
            <div className={`flex flex-col transition-all duration-300 shrink-0
                ${sidebarOpen ? 'w-64' : 'w-0 overflow-hidden'}`}>
                {sidebarOpen && (
                    <div className="flex flex-col h-full bg-(--surface) border border-(--border) rounded-2xl overflow-hidden shadow-sm">

                        {/* Sidebar header */}
                        <div className="flex items-center justify-between px-4 py-3 border-b border-(--border) bg-(--surface-soft)">
                            <div className="flex items-center gap-2">
                                <MessageSquare size={14} className="text-cyan-600"/>
                                <span className="text-xs font-black text-(--text-primary)">{cfg.history}</span>
                            </div>
                            <button onClick={() => setSidebarOpen(false)}
                                className="cursor-pointer p-1 rounded-lg text-(--text-muted) hover:text-(--text-primary) hover:bg-(--surface-soft) transition-colors">
                                <ChevronLeft size={14}/>
                            </button>
                        </div>

                        {/* Session list */}
                        <div className="flex-1 overflow-y-auto p-3 space-y-2">
                            {historyLoading ? (
                                <div className="space-y-2">
                                    {[1,2,3].map(i => (
                                        <div key={i} className="h-14 rounded-xl bg-(--surface-soft) animate-pulse"/>
                                    ))}
                                </div>
                            ) : pastSessions.length === 0 ? (
                                <div className="text-center py-8">
                                    <MessageSquare size={28} className="mx-auto text-(--text-muted)/30 mb-2"/>
                                    <p className="text-xs text-(--text-muted)">{cfg.noHistory}</p>
                                </div>
                            ) : (
                                pastSessions.map(s => (
                                    <HistoryItem
                                        key={s.id}
                                        session={s}
                                        active={activeHistoryId === s.id}
                                        lang={lang}
                                        onClick={() => handleLoadHistory(s)}
                                    />
                                ))
                            )}
                        </div>
                    </div>
                )}
            </div>

            {/* ── MAIN CHAT AREA ─────────────────────────────────────────── */}
            <div className="flex-1 flex flex-col min-w-0">

                {/* Header */}
                <div className="bg-(--surface) border border-(--border) rounded-2xl shadow-sm mb-3 overflow-hidden">
                    <div className="px-4 py-3 flex items-center gap-3">

                        {/* History toggle */}
                        <button onClick={() => setSidebarOpen(p => !p)}
                            aria-label="Toggle history"
                            className={`cursor-pointer p-2 rounded-xl border transition-all
                                ${sidebarOpen
                                    ? 'bg-cyan-600 text-white border-cyan-600'
                                    : 'bg-(--surface-soft) text-(--text-muted) border-(--border) hover:border-cyan-400 hover:text-cyan-600'
                                }`}>
                            {sidebarOpen ? <ChevronLeft size={16}/> : <ChevronRight size={16}/>}
                        </button>

                        {/* Bot avatar */}
                        <div className="relative shrink-0">
                            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-cyan-500 to-cyan-700 flex items-center justify-center shadow-sm">
                                <Bot size={20} className="text-white"/>
                            </div>
                            <span className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-emerald-500 rounded-full border-2 border-(--surface)"/>
                        </div>

                        {/* Name */}
                        <div className="flex-1 min-w-0">
                            <h2 className="font-black text-sm text-(--text-primary)">PediaBot</h2>
                            <div className="flex items-center gap-1.5">
                                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"/>
                                <span className="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400 uppercase tracking-wide">Online</span>
                            </div>
                        </div>

                        {/* Language toggle — large, clear, accessible */}
                        <div className="flex items-center bg-(--surface-soft) border border-(--border) rounded-xl p-1 gap-1">
                            {Object.entries(LANG).map(([key, c]) => (
                                <button key={key}
                                    onClick={() => handleLangChange(key)}
                                    aria-pressed={lang === key}
                                    aria-label={`Switch to ${c.name}`}
                                    className={`cursor-pointer flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-black transition-all duration-200
                                        ${lang === key
                                            ? 'bg-cyan-600 text-white shadow-sm'
                                            : 'text-(--text-muted) hover:text-(--text-secondary)'
                                        }`}>
                                    <Globe size={12}/>
                                    {c.name}
                                </button>
                            ))}
                        </div>

                        {/* Speaker toggle */}
                        <button onClick={() => { setSpeakerOn(p => !p); window.speechSynthesis?.cancel(); }}
                            aria-label={speakerOn ? 'Mute' : 'Read replies aloud'}
                            className={`cursor-pointer p-2.5 rounded-xl border transition-all
                                ${speakerOn
                                    ? 'bg-cyan-600 text-white border-cyan-600'
                                    : 'bg-(--surface-soft) text-(--text-muted) border-(--border) hover:border-cyan-400'
                                }`}>
                            {speakerOn ? <Volume2 size={15}/> : <VolumeX size={15}/>}
                        </button>

                        {/* New Chat — saves current session first */}
                        <button onClick={handleNewChat}
                            aria-label="Start new chat"
                            className="cursor-pointer flex items-center gap-1.5 px-3 py-2 rounded-xl bg-(--surface-soft) border border-(--border) text-xs font-black text-(--text-secondary) hover:border-cyan-500 hover:text-cyan-600 transition-all">
                            <Plus size={14}/> {cfg.newChat}
                        </button>
                    </div>

                    {/* Compact disclaimer strip */}
                    <div className="px-4 py-2 border-t border-(--border) bg-amber-50/60 dark:bg-amber-950/20 flex items-center gap-2">
                        <ShieldAlert size={11} className="text-amber-500 shrink-0"/>
                        <p className="text-[10px] text-amber-700 dark:text-amber-400 font-medium leading-tight">{cfg.disclaimer}</p>
                    </div>
                </div>

                {/* Read-only history notice */}
                {activeHistoryId && (
                    <div className="mb-2 px-4 py-2.5 bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800 rounded-xl flex items-center justify-between gap-3">
                        <p className="text-xs font-semibold text-amber-700 dark:text-amber-400">
                            {lang === 'so' ? 'Waxaad arag taariikhda sheekadii hore. Ku dhufo "Sheeko Cusub" si aad u bilaabto.' : 'Viewing a past chat. Click "New Chat" to start a fresh conversation.'}
                        </p>
                        <button onClick={handleNewChat}
                            className="cursor-pointer text-[10px] font-black px-2.5 py-1 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors shrink-0">
                            {cfg.newChat}
                        </button>
                    </div>
                )}

                {/* Messages feed */}
                <div className="flex-1 overflow-y-auto bg-(--surface-soft) border border-(--border) rounded-2xl px-4 py-5 space-y-4">

                    {/* Init error — backend unreachable */}
                    {initError && (
                        <div className="mb-1 px-4 py-3 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800 rounded-xl flex items-center justify-between gap-3">
                            <p className="text-xs font-semibold text-red-700 dark:text-red-400">
                                {lang === 'so'
                                    ? 'Xiriirka server-ka ayaa fashilmay. Hubi in backend-ku uu shaqaynayo oo `npx prisma generate` la socodsiiyo.'
                                    : 'Could not connect to the server. Make sure the backend is running and prisma generate has been run.'}
                            </p>
                            <button onClick={() => initSession()}
                                className="cursor-pointer text-[10px] font-black px-2.5 py-1 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors shrink-0">
                                {lang === 'so' ? 'Isku day' : 'Retry'}
                            </button>
                        </div>
                    )}

                    {/* Greeting + quick topics — always visible when chat is empty */}
                    {messages.length === 0 && !activeHistoryId && (
                        <div>
                            <Bubble
                                m={{ id: 'greet', sender: 'AI', message: cfg.greeting, timestamp: new Date().toISOString() }}
                                lang={lang}
                            />
                            <div className="ml-11 mt-2">
                                <p className="text-[10px] font-black uppercase tracking-widest text-(--text-muted) mb-1">
                                    {lang === 'so' ? 'Su\'aalaha caadiga ah' : 'Common questions'}
                                </p>
                                <TopicPills lang={lang} onSend={handleSend}/>
                            </div>
                        </div>
                    )}

                    {messages.map(m => <Bubble key={m.id} m={m} lang={lang}/>)}
                    {loading && <Typing/>}
                    <div ref={bottomRef}/>
                </div>

                {/* Input bar */}
                <div className="mt-3 bg-(--surface) border border-(--border) rounded-2xl shadow-sm overflow-hidden">
                    <form onSubmit={e => { e.preventDefault(); handleSend(); }}
                        className="flex items-center gap-2 px-4 py-3">

                        <button type="button"
                            onClick={isListening ? stopListening : startListening}
                            disabled={loading || !!activeHistoryId}
                            aria-label={isListening ? 'Stop recording' : 'Voice input'}
                            className={`cursor-pointer w-10 h-10 rounded-xl flex items-center justify-center border-2 transition-all shrink-0 disabled:opacity-40
                                ${isListening
                                    ? 'bg-red-500 border-red-500 text-white animate-pulse'
                                    : 'bg-(--surface-soft) border-(--border) text-(--text-muted) hover:border-cyan-400 hover:text-cyan-600'
                                }`}>
                            {isListening ? <MicOff size={16}/> : <Mic size={16}/>}
                        </button>

                        <input ref={inputRef} type="text"
                            disabled={loading || isListening || !!activeHistoryId}
                            value={input}
                            onChange={e => setInput(e.target.value)}
                            onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend(); } }}
                            placeholder={activeHistoryId
                                ? (lang === 'so' ? 'Waxaad arkaysaa taariikhda…' : 'Viewing history…')
                                : isListening ? cfg.listening : cfg.placeholder
                            }
                            className="flex-1 bg-(--surface-soft) border border-(--border) rounded-xl px-4 py-2.5 text-sm font-medium text-(--text-primary) placeholder-(--text-muted) focus:outline-none focus:border-cyan-500 focus:ring-2 focus:ring-cyan-500/15 disabled:opacity-50 transition-all"
                        />

                        <button type="submit"
                            disabled={loading || !input.trim() || isListening || !!activeHistoryId}
                            aria-label="Send message"
                            className="cursor-pointer w-10 h-10 rounded-xl flex items-center justify-center bg-cyan-600 hover:bg-cyan-700 disabled:opacity-40 disabled:cursor-not-allowed text-white transition-all shrink-0 shadow-sm">
                            {loading
                                ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"/>
                                : <Send size={16}/>
                            }
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};
