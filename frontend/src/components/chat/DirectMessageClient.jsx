import React, { useState, useEffect, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import useAuthStore from '../../store/authStore';
import { Link, useNavigate } from 'react-router-dom';
import {
    Send, MessageSquare, Search, Video, PhoneCall, Phone,
    Calendar, Clock, CheckCircle2, AlertCircle, StopCircle,
    Loader2, Zap, History, CheckCheck, X, ClipboardCheck,
    PhoneOff, User, ChevronRight, Dot, Inbox
} from 'lucide-react';

/* ─── tiny helpers ────────────────────────────────────────────────────── */
const fmt = (dt) => new Date(dt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
const fmtTime = (dt) => new Date(dt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
const fmtDuration = (start, end) => {
    if (!start || !end) return null;
    const mins = Math.round((new Date(end) - new Date(start)) / 60000);
    return mins < 1 ? '< 1 min' : `${mins} min`;
};

const STATUS_BADGE = {
    COMPLETED:    { cls: 'bg-emerald-100 text-emerald-700 border-emerald-200',  icon: <CheckCircle2 size={10}/>, label: 'Completed' },
    CANCELLED:    { cls: 'bg-red-100 text-red-700 border-red-200',              icon: <X size={10}/>,            label: 'Cancelled' },
    NO_SHOW:      { cls: 'bg-slate-100 text-slate-600 border-slate-200',        icon: <PhoneOff size={10}/>,     label: 'No-show' },
    RESCHEDULED:  { cls: 'bg-blue-100 text-blue-700 border-blue-200',           icon: <Clock size={10}/>,        label: 'Rescheduled' },
    CONFIRMED:    { cls: 'bg-teal-100 text-teal-700 border-teal-200',           icon: <CheckCircle2 size={10}/>, label: 'Confirmed' },
    PENDING:      { cls: 'bg-amber-100 text-amber-700 border-amber-200',        icon: <AlertCircle size={10}/>,  label: 'Pending' },
};

/* ═══════════════════════════════════════════════════════════════════════ */
export const DirectMessageClient = () => {
    const { user } = useAuthStore();
    const navigate = useNavigate();
    const queryClient = useQueryClient();
    const messagesEndRef = useRef(null);
    const isDoctor = user?.role === 'DOCTOR';

    const [activeContact, setActiveContact] = useState(null);
    const [messageInput, setMessageInput] = useState('');
    const [search, setSearch] = useState('');
    const [activatingId, setActivatingId] = useState(null);

    /* ── Contacts ────────────────────────────────────────────────────── */
    const { data: contacts = [] } = useQuery({
        queryKey: ['chatContacts'],
        queryFn: async () => (await api.get('/chat/contacts')).data.data,
    });

    /* ── Messages ────────────────────────────────────────────────────── */
    const { data: messages = [] } = useQuery({
        queryKey: ['chatMessages', activeContact?.id],
        queryFn: async () => {
            if (!activeContact) return [];
            return (await api.get(`/chat/${activeContact.id}`)).data.data;
        },
        enabled: !!activeContact?.id,
        refetchInterval: 3000,
    });

    /* ── Upcoming sessions ───────────────────────────────────────────── */
    const { data: allAppts = [], isLoading: apptsLoading } = useQuery({
        queryKey: ['myScheduleAll'],
        queryFn: async () => (await api.get('/appointments/my-schedule')).data.data.appointments || [],
        refetchInterval: 5000,
    });

    const upcoming = allAppts.filter(a => a.status === 'PENDING' || a.status === 'CONFIRMED');
    const history  = allAppts.filter(a => ['COMPLETED', 'CANCELLED', 'NO_SHOW', 'RESCHEDULED'].includes(a.status))
                              .sort((a, b) => new Date(b.scheduledAt) - new Date(a.scheduledAt));

    /* ── Send message ────────────────────────────────────────────────── */
    const sendMsg = useMutation({
        mutationFn: (content) => api.post('/chat', { receiverId: activeContact.id, content }),
        onSuccess: () => {
            queryClient.invalidateQueries(['chatMessages', activeContact?.id]);
            setMessageInput('');
        },
    });

    /* ── Start / Join video session ──────────────────────────────────── */
    const startSession = useMutation({
        mutationFn: async (appointmentId) => {
            setActivatingId(appointmentId);
            const res = await api.post('/teleconsultations/generate', { appointmentId });
            return { appointmentId, ...res.data };
        },
        onSuccess: (data) => {
            navigate(`/teleconsult/${data.appointmentId}`);
            queryClient.invalidateQueries(['myScheduleAll']);
        },
        onError: () => setActivatingId(null),
    });

    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    const filteredContacts = contacts.filter(c =>
        !search || c.name.toLowerCase().includes(search.toLowerCase())
    );

    /* ── Render ──────────────────────────────────────────────────────── */
    return (
        <div className="space-y-6">

            {/* ══ SECTION 1 — DIRECT MESSAGES ════════════════════════════════ */}
            <div className="rounded-2xl border border-[--border] bg-[--surface] shadow-sm overflow-hidden">
                {/* Header */}
                <div className="flex items-center gap-2.5 px-5 py-4 border-b border-[--border] bg-[--surface-soft]">
                    <div className="w-8 h-8 rounded-xl bg-primary-100 dark:bg-primary-950 flex items-center justify-center">
                        <MessageSquare size={16} className="text-primary-600 dark:text-primary-400"/>
                    </div>
                    <div>
                        <h3 className="font-black text-sm text-[--text-primary] tracking-tight">Message Parents</h3>
                        <p className="text-[10px] text-[--text-muted] font-semibold">Secure direct messaging</p>
                    </div>
                    <div className="ml-auto flex items-center gap-1.5 text-[10px] font-black text-emerald-600 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800 px-2.5 py-1 rounded-full">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block animate-pulse"/>
                        End-to-end encrypted
                    </div>
                </div>

                <div className="flex flex-col md:flex-row" style={{ height: 420 }}>
                    {/* Contact Sidebar */}
                    <div className="w-full md:w-64 border-b md:border-b-0 md:border-r border-[--border] flex flex-col bg-[--surface-soft]">
                        {/* Search */}
                        <div className="p-3 border-b border-[--border]">
                            <div className="relative">
                                <Search size={14} className="absolute left-3 top-2.5 text-[--text-muted]"/>
                                <input
                                    value={search}
                                    onChange={e => setSearch(e.target.value)}
                                    placeholder="Search doctor..."
                                    className="w-full pl-8 pr-3 py-2 text-xs font-medium bg-[--surface] border border-[--border] rounded-lg text-[--text-primary] placeholder-[--text-muted] focus:outline-none focus:border-primary-400"
                                />
                            </div>
                        </div>

                        {/* Contact list */}
                        <div className="flex-1 overflow-y-auto">
                            {filteredContacts.length === 0 ? (
                                <div className="p-4 text-center text-xs font-medium text-[--text-muted]">No contacts found</div>
                            ) : filteredContacts.map(c => {
                                const isActive = activeContact?.id === c.id;
                                return (
                                    <button
                                        key={c.id}
                                        onClick={() => setActiveContact(c)}
                                        className={`w-full text-left px-4 py-3.5 border-b border-[--border] transition-all flex items-center gap-3 group
                                            ${isActive
                                                ? 'bg-primary-50 dark:bg-primary-950/40 border-l-2 border-l-primary-600'
                                                : 'border-l-2 border-l-transparent hover:bg-[--surface]'
                                            }`}
                                    >
                                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white text-[11px] font-black shrink-0">
                                            {c.name?.split(' ').map(w => w[0]).slice(0, 2).join('')}
                                        </div>
                                        <div className="min-w-0 flex-1">
                                            <div className={`text-[12px] font-black truncate ${isActive ? 'text-primary-700 dark:text-primary-300' : 'text-[--text-primary]'}`}>
                                                {c.name}
                                            </div>
                                            <div className="text-[10px] text-[--text-muted] font-medium">Doctor</div>
                                        </div>
                                        {isActive && <Dot size={20} className="text-primary-500 shrink-0"/>}
                                    </button>
                                );
                            })}
                        </div>
                    </div>

                    {/* Chat Area */}
                    <div className="flex-1 flex flex-col bg-[--surface]">
                        {activeContact ? (
                            <>
                                {/* Chat header */}
                                <div className="px-5 py-3 border-b border-[--border] flex items-center gap-3 bg-[--surface-soft]">
                                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white text-[11px] font-black">
                                        {activeContact.name?.split(' ').map(w => w[0]).slice(0, 2).join('')}
                                    </div>
                                    <div>
                                        <div className="text-xs font-black text-[--text-primary]">{activeContact.name}</div>
                                        <div className="text-[10px] text-emerald-500 font-bold flex items-center gap-1">
                                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block"/>
                                            Secure channel active
                                        </div>
                                    </div>
                                    <button
                                        onClick={() => setActiveContact(null)}
                                        className="ml-auto text-[--text-muted] hover:text-[--text-primary] transition-colors"
                                    >
                                        <X size={16}/>
                                    </button>
                                </div>

                                {/* Messages */}
                                <div className="flex-1 overflow-y-auto flex flex-col gap-2.5 p-4">
                                    {messages.length === 0 ? (
                                        <div className="m-auto text-center">
                                            <MessageSquare size={32} className="mx-auto text-[--text-muted]/40 mb-2"/>
                                            <p className="text-xs font-medium text-[--text-muted]">No messages yet.<br/>Start a secure conversation.</p>
                                        </div>
                                    ) : messages.map(m => {
                                        const isMe = m.senderId === user.id;
                                        return (
                                            <div key={m.id} className={`flex items-end gap-2 ${isMe ? 'justify-end' : 'justify-start'}`}>
                                                {!isMe && (
                                                    <div className="w-6 h-6 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white text-[9px] font-black shrink-0">
                                                        {activeContact.name?.split(' ').map(w => w[0]).slice(0, 2).join('')}
                                                    </div>
                                                )}
                                                <div className={`max-w-[72%] px-4 py-2.5 rounded-2xl text-xs font-medium shadow-sm leading-relaxed
                                                    ${isMe
                                                        ? 'bg-primary-600 text-white rounded-br-sm'
                                                        : 'bg-[--surface-soft] border border-[--border] text-[--text-primary] rounded-bl-sm'
                                                    }`}>
                                                    {m.content}
                                                    <div className={`text-[9px] mt-1 flex items-center gap-1 ${isMe ? 'text-white/60 justify-end' : 'text-[--text-muted]'}`}>
                                                        {new Date(m.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                        {isMe && <CheckCheck size={10}/>}
                                                    </div>
                                                </div>
                                            </div>
                                        );
                                    })}
                                    <div ref={messagesEndRef}/>
                                </div>

                                {/* Input */}
                                <form onSubmit={e => { e.preventDefault(); if (messageInput.trim()) sendMsg.mutate(messageInput.trim()); }}
                                    className="p-3 border-t border-[--border] flex gap-2">
                                    <input
                                        value={messageInput}
                                        onChange={e => setMessageInput(e.target.value)}
                                        placeholder={`Message ${activeContact.name?.split(' ')[0]}...`}
                                        disabled={sendMsg.isLoading}
                                        className="flex-1 px-4 py-2.5 border border-[--border] rounded-xl text-xs font-medium bg-[--surface-soft] text-[--text-primary] placeholder-[--text-muted] focus:outline-none focus:border-primary-400 focus:ring-2 focus:ring-primary-500/20 transition-all"
                                    />
                                    <button
                                        type="submit"
                                        disabled={!messageInput.trim() || sendMsg.isLoading}
                                        className="w-10 h-10 bg-primary-600 hover:bg-primary-700 disabled:opacity-40 text-white rounded-xl flex items-center justify-center transition-colors shadow-sm shrink-0"
                                    >
                                        <Send size={15}/>
                                    </button>
                                </form>
                            </>
                        ) : (
                            <div className="m-auto flex flex-col items-center justify-center text-center gap-3 p-8">
                                <div className="w-16 h-16 rounded-2xl bg-primary-50 dark:bg-primary-950/40 flex items-center justify-center border border-primary-100 dark:border-primary-900">
                                    <Inbox size={28} className="text-primary-400"/>
                                </div>
                                <div>
                                    <div className="font-black text-sm text-[--text-secondary] mb-1">Select a Doctor</div>
                                    <div className="text-xs font-medium text-[--text-muted]">Choose a contact to start a secure conversation</div>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* ══ SECTION 2 — VIRTUAL CALL ════════════════════════════════════ */}
            <div className="rounded-2xl border border-[--border] bg-[--surface] shadow-sm overflow-hidden">
                {/* Header */}
                <div className="flex items-center gap-2.5 px-5 py-4 border-b border-[--border] bg-[--surface-soft]">
                    <div className="w-8 h-8 rounded-xl bg-teal/10 flex items-center justify-center">
                        <Video size={16} className="text-teal"/>
                    </div>
                    <div>
                        <h3 className="font-black text-sm text-[--text-primary] tracking-tight">Virtual Call</h3>
                        <p className="text-[10px] text-[--text-muted] font-semibold">Upcoming teleconsultations</p>
                    </div>
                    {upcoming.length > 0 && (
                        <span className="ml-auto text-[10px] font-black text-teal bg-teal/10 border border-teal/20 px-2.5 py-1 rounded-full">
                            {upcoming.length} scheduled
                        </span>
                    )}
                </div>

                <div className="p-5">
                    {apptsLoading ? (
                        <div className="flex items-center justify-center py-10 gap-2 text-[--text-muted]">
                            <Loader2 size={18} className="animate-spin"/>
                            <span className="text-xs font-bold">Loading sessions...</span>
                        </div>
                    ) : upcoming.length === 0 ? (
                        <div className="text-center py-10">
                            <div className="w-14 h-14 rounded-2xl bg-[--surface-soft] flex items-center justify-center mx-auto mb-3 border border-[--border]">
                                <Video size={24} className="text-[--text-muted]/50"/>
                            </div>
                            <p className="text-xs font-black text-[--text-secondary] mb-1">No upcoming virtual calls</p>
                            <p className="text-[11px] font-medium text-[--text-muted] mb-4">Schedule a teleconsultation to get started</p>
                            {!isDoctor && (
                                <Link to="/appointments">
                                    <button className="px-4 py-2 bg-teal text-white text-xs font-black rounded-xl hover:opacity-90 transition-opacity">
                                        Book Appointment
                                    </button>
                                </Link>
                            )}
                        </div>
                    ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {upcoming.map(session => {
                                const isConfirmed  = session.status === 'CONFIRMED';
                                const isActivating = activatingId === session.id;
                                const isPast       = new Date(session.scheduledAt) < new Date();

                                return (
                                    <div key={session.id}
                                        className={`relative rounded-xl border overflow-hidden transition-all
                                            ${isPast ? 'border-[--border] opacity-70' : isConfirmed ? 'border-teal/30 bg-teal/5' : 'border-amber-200 dark:border-amber-800 bg-amber-50/40 dark:bg-amber-950/10'}`}>
                                        {/* Color stripe */}
                                        <div className={`absolute top-0 left-0 w-full h-0.5 ${isPast ? 'bg-slate-400' : isConfirmed ? 'bg-teal' : 'bg-amber-400'}`}/>

                                        <div className="p-4">
                                            {/* Title + badge */}
                                            <div className="flex items-start justify-between gap-2 mb-3">
                                                <div>
                                                    <p className="text-xs font-black text-[--text-primary] leading-tight">
                                                        {isDoctor
                                                            ? `${session.child?.firstName} ${session.child?.lastName}`
                                                            : `Dr. ${session.doctor?.lastName}`}
                                                    </p>
                                                    <div className="flex items-center gap-3 mt-1">
                                                        <span className="flex items-center gap-1 text-[10px] font-bold text-[--text-muted]">
                                                            <Calendar size={10}/> {fmt(session.scheduledAt)}
                                                        </span>
                                                        <span className="flex items-center gap-1 text-[10px] font-bold text-[--text-muted]">
                                                            <Clock size={10}/> {fmtTime(session.scheduledAt)}
                                                        </span>
                                                    </div>
                                                </div>
                                                <span className={`text-[9px] font-black uppercase px-2 py-1 rounded-full border flex items-center gap-1 shrink-0
                                                    ${isPast ? 'bg-slate-100 text-slate-500 border-slate-200'
                                                        : STATUS_BADGE[session.status]?.cls || 'bg-gray-100 text-gray-600'}`}>
                                                    {isPast ? <><StopCircle size={9}/> Expired</> : (STATUS_BADGE[session.status]?.icon)}
                                                    {isPast ? '' : STATUS_BADGE[session.status]?.label}
                                                </span>
                                            </div>

                                            {/* Reason */}
                                            {session.reason && (
                                                <p className="text-[10px] font-medium text-[--text-muted] mb-3 line-clamp-1">📋 {session.reason}</p>
                                            )}

                                            {/* Action button */}
                                            {isPast ? (
                                                <div className="text-[10px] font-bold text-slate-400 text-center py-1.5">Session expired</div>
                                            ) : isDoctor && isConfirmed ? (
                                                <button
                                                    onClick={() => startSession.mutate(session.id)}
                                                    disabled={isActivating}
                                                    className="w-full py-2 bg-teal text-white text-[11px] font-black rounded-lg flex items-center justify-center gap-1.5 hover:opacity-90 transition-opacity disabled:opacity-50"
                                                >
                                                    {isActivating ? <><Loader2 size={12} className="animate-spin"/> Opening...</> : <><Zap size={12}/> Start Session</>}
                                                </button>
                                            ) : isDoctor && !isConfirmed ? (
                                                <Link to="/appointments" className="block">
                                                    <button className="w-full py-2 bg-amber-500 text-white text-[11px] font-black rounded-lg flex items-center justify-center gap-1.5 hover:opacity-90 transition-opacity">
                                                        <ClipboardCheck size={12}/> Review & Approve
                                                    </button>
                                                </Link>
                                            ) : !isDoctor && isConfirmed ? (
                                                <button
                                                    onClick={() => startSession.mutate(session.id)}
                                                    disabled={isActivating}
                                                    className="w-full py-2 bg-teal text-white text-[11px] font-black rounded-lg flex items-center justify-center gap-1.5 hover:opacity-90 transition-opacity disabled:opacity-50"
                                                >
                                                    {isActivating ? <><Loader2 size={12} className="animate-spin"/> Connecting...</> : <><PhoneCall size={12}/> Join Call</>}
                                                </button>
                                            ) : (
                                                <div className="flex items-center gap-2 py-1.5 px-3 bg-amber-100 dark:bg-amber-950/30 rounded-lg">
                                                    <Clock size={11} className="text-amber-500 animate-pulse shrink-0"/>
                                                    <span className="text-[10px] font-black text-amber-700 dark:text-amber-400">Awaiting doctor approval</span>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    )}
                </div>
            </div>

            {/* ══ SECTION 3 — CALL HISTORY ════════════════════════════════════ */}
            <div className="rounded-2xl border border-[--border] bg-[--surface] shadow-sm overflow-hidden">
                {/* Header */}
                <div className="flex items-center gap-2.5 px-5 py-4 border-b border-[--border] bg-[--surface-soft]">
                    <div className="w-8 h-8 rounded-xl bg-violet/10 flex items-center justify-center">
                        <History size={16} className="text-violet"/>
                    </div>
                    <div>
                        <h3 className="font-black text-sm text-[--text-primary] tracking-tight">Call History</h3>
                        <p className="text-[10px] text-[--text-muted] font-semibold">Past teleconsultations</p>
                    </div>
                    {history.length > 0 && (
                        <span className="ml-auto text-[10px] font-black text-[--text-muted] bg-[--surface-soft] border border-[--border] px-2.5 py-1 rounded-full">
                            {history.length} records
                        </span>
                    )}
                </div>

                <div className="divide-y divide-[--border]">
                    {apptsLoading ? (
                        <div className="flex items-center justify-center py-10 gap-2 text-[--text-muted]">
                            <Loader2 size={18} className="animate-spin"/>
                            <span className="text-xs font-bold">Loading history...</span>
                        </div>
                    ) : history.length === 0 ? (
                        <div className="text-center py-10">
                            <div className="w-14 h-14 rounded-2xl bg-[--surface-soft] flex items-center justify-center mx-auto mb-3 border border-[--border]">
                                <History size={24} className="text-[--text-muted]/50"/>
                            </div>
                            <p className="text-xs font-black text-[--text-secondary] mb-1">No call history yet</p>
                            <p className="text-[11px] font-medium text-[--text-muted]">Completed calls will appear here</p>
                        </div>
                    ) : history.slice(0, 8).map(session => {
                        const badge = STATUS_BADGE[session.status] || STATUS_BADGE.COMPLETED;
                        const tc = session.teleconsultation;
                        const duration = tc ? fmtDuration(tc.startedAt, tc.endedAt) : null;
                        const hadVideo = !!tc?.startedAt;

                        return (
                            <div key={session.id} className="px-5 py-4 flex items-center gap-4 hover:bg-[--surface-soft] transition-colors group">
                                {/* Icon */}
                                <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${hadVideo ? 'bg-teal/10' : 'bg-[--surface-soft]'}`}>
                                    {hadVideo
                                        ? <Video size={18} className="text-teal"/>
                                        : <Phone size={18} className="text-[--text-muted]"/>
                                    }
                                </div>

                                {/* Info */}
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2 mb-0.5">
                                        <p className="text-xs font-black text-[--text-primary] truncate">
                                            {isDoctor
                                                ? `${session.child?.firstName} ${session.child?.lastName}`
                                                : `Dr. ${session.doctor?.firstName} ${session.doctor?.lastName}`}
                                        </p>
                                        <span className={`text-[9px] font-black uppercase px-2 py-0.5 rounded-full border flex items-center gap-1 shrink-0 ${badge.cls}`}>
                                            {badge.icon} {badge.label}
                                        </span>
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <span className="text-[10px] text-[--text-muted] font-medium flex items-center gap-1">
                                            <Calendar size={9}/> {fmt(session.scheduledAt)} at {fmtTime(session.scheduledAt)}
                                        </span>
                                        {duration && (
                                            <span className="text-[10px] font-bold text-teal flex items-center gap-1">
                                                <Clock size={9}/> {duration}
                                            </span>
                                        )}
                                    </div>
                                    {session.reason && (
                                        <p className="text-[10px] text-[--text-muted] mt-0.5 truncate">📋 {session.reason}</p>
                                    )}
                                </div>

                                {/* Video indicator */}
                                {hadVideo && (
                                    <div className="shrink-0 text-[10px] font-black text-teal flex items-center gap-1 bg-teal/10 px-2 py-1 rounded-lg">
                                        <Video size={10}/> Video
                                    </div>
                                )}
                            </div>
                        );
                    })}

                    {history.length > 8 && (
                        <div className="px-5 py-3 text-center">
                            <span className="text-[11px] font-black text-[--text-muted]">+ {history.length - 8} more records</span>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};
