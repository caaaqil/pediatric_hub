import React, { useState, useEffect, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import useAuthStore from '../../store/authStore';
import { Send, MessageSquare, Inbox, Clock, Pill, Bell, RefreshCw, Paperclip, ChevronDown, AlertTriangle } from 'lucide-react';

const QUICK_TYPES = [
    { key: 'advice',       label: 'Advice',       icon: <MessageSquare size={13}/>, color: 'text-blue-600 bg-blue-50 border-blue-200 hover:bg-blue-100',       prefix: '💡 Medical Advice:\n' },
    { key: 'prescription', label: 'Prescription',  icon: <Pill size={13}/>,          color: 'text-purple-600 bg-purple-50 border-purple-200 hover:bg-purple-100', prefix: '💊 Prescription:\nMedication: \nDosage: \nDuration: \nInstructions: ' },
    { key: 'reminder',     label: 'Reminder',      icon: <Bell size={13}/>,          color: 'text-amber-600 bg-amber-50 border-amber-200 hover:bg-amber-100',     prefix: '🔔 Reminder:\n' },
    { key: 'followup',     label: 'Follow-up',     icon: <RefreshCw size={13}/>,     color: 'text-emerald-600 bg-emerald-50 border-emerald-200 hover:bg-emerald-100', prefix: '📋 Follow-up Message:\n' },
];

export const DoctorInbox = () => {
    const { user } = useAuthStore();
    const queryClient = useQueryClient();
    const messagesEndRef = useRef(null);
    const fileRef = useRef(null);

    const [activeContact, setActiveContact] = useState(null);
    const [messageInput, setMessageInput]   = useState('');
    const [showQuick, setShowQuick]         = useState(false);

    const { data: contacts, isLoading: loadingContacts } = useQuery({
        queryKey: ['chatContacts'],
        queryFn: async () => { const r = await api.get('/chat/contacts'); return r.data.data; }
    });

    const { data: messages } = useQuery({
        queryKey: ['chatMessages', activeContact?.id],
        queryFn: async () => {
            if (!activeContact) return [];
            const r = await api.get(`/chat/${activeContact.id}`);
            return r.data.data;
        },
        enabled: !!activeContact?.id,
        refetchInterval: 3000
    });

    const sendMessage = useMutation({
        mutationFn: async (content) => api.post('/chat', { receiverId: activeContact.id, content }),
        onSuccess: () => {
            queryClient.invalidateQueries(['chatMessages', activeContact?.id]);
            setMessageInput('');
            setShowQuick(false);
        }
    });

    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    const handleSend = (e) => {
        e.preventDefault();
        if (messageInput.trim() && activeContact) sendMessage.mutate(messageInput.trim());
    };

    const applyQuickType = (prefix) => {
        setMessageInput(prev => prefix + prev);
        setShowQuick(false);
    };

    const detectMessageType = (content) => {
        if (content?.startsWith('💊')) return 'prescription';
        if (content?.startsWith('🔔')) return 'reminder';
        if (content?.startsWith('📋')) return 'followup';
        if (content?.startsWith('💡')) return 'advice';
        if (content?.includes('EMERGENCY') || content?.includes('XAALAD DEGDEG')) return 'emergency';
        return 'normal';
    };

    const msgTypeBadge = (type) => {
        const map = {
            prescription: 'bg-purple-100 text-purple-700 border border-purple-200',
            reminder:     'bg-amber-100 text-amber-700 border border-amber-200',
            followup:     'bg-emerald-100 text-emerald-700 border border-emerald-200',
            advice:       'bg-blue-100 text-blue-700 border border-blue-200',
            emergency:    'bg-red-100 text-red-700 border border-red-200',
        };
        const labels = { prescription: '💊 Prescription', reminder: '🔔 Reminder', followup: '📋 Follow-up', advice: '💡 Advice', emergency: '🚨 Emergency' };
        if (!map[type]) return null;
        return <span className={`text-[9px] font-black uppercase tracking-widest px-2 py-0.5 rounded-full ${map[type]}`}>{labels[type]}</span>;
    };

    return (
        <div className="max-w-[1200px] w-full mx-auto space-y-6 animate-fade-in font-sans">
            {/* Header */}
            <div className="bg-[--surface] rounded-xl shadow-sm border border-[--border] p-6 sm:p-8 flex items-center gap-5 relative overflow-hidden">
                <div className="absolute top-0 right-0 w-72 h-72 bg-primary-50 dark:bg-primary-950/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/4 pointer-events-none"/>
                <div className="w-14 h-14 bg-blue-600/10 text-blue-600 rounded-2xl flex items-center justify-center shadow-sm z-10">
                    <Inbox size={28} strokeWidth={2.5}/>
                </div>
                <div className="z-10">
                    <h1 className="text-2xl font-black text-[--text-primary] tracking-tight">
                        {user?.role === 'DOCTOR' ? 'Messenger — Parent Messages' : 'Message Your Doctor'}
                    </h1>
                    <p className="text-[--text-secondary] font-medium text-sm mt-1">
                        {user?.role === 'DOCTOR'
                            ? 'Reply, send prescriptions, reminders, advice and follow-up messages.'
                            : 'Ask questions, send pictures, and receive replies from your pediatrician.'}
                    </p>
                    {user?.role === 'DOCTOR' && (
                        <div className="flex gap-2 mt-3 flex-wrap">
                            {QUICK_TYPES.map(t => (
                                <span key={t.key} className={`inline-flex items-center gap-1 text-[10px] font-black uppercase tracking-widest px-2 py-1 rounded-full border ${t.color}`}>
                                    {t.icon} {t.label}
                                </span>
                            ))}
                        </div>
                    )}
                </div>
            </div>

            {/* Messaging Panel */}
            <div className="bg-[--surface] rounded-xl border border-[--border] shadow-sm overflow-hidden">
                <div className="flex flex-col md:flex-row h-[580px]">
                    {/* Contacts Sidebar */}
                    <div className="w-full md:w-1/3 border-b md:border-b-0 md:border-r border-[--border] bg-[--surface-soft] flex flex-col">
                        <div className="p-4 border-b border-[--border] bg-[--surface-soft]/80">
                            <h3 className="font-black text-[--text-primary] text-sm flex items-center gap-2">
                                <MessageSquare size={15}/>
                                {user?.role === 'DOCTOR' ? "My Patients' Parents" : 'Available Doctors'}
                            </h3>
                        </div>
                        <div className="flex-1 overflow-y-auto">
                            {loadingContacts ? (
                                <div className="p-6 text-center text-[--text-muted] text-xs font-bold uppercase tracking-widest animate-pulse">Loading contacts...</div>
                            ) : contacts?.length > 0 ? contacts.map(c => (
                                <button key={c.id} onClick={() => setActiveContact(c)}
                                    className={`w-full text-left px-4 py-3.5 border-b border-[--border] transition-all ${activeContact?.id === c.id ? 'bg-primary-50 dark:bg-primary-950 border-l-4 border-l-blue-600' : 'hover:bg-[--surface] border-l-4 border-l-transparent'}`}>
                                    <div className="flex items-center gap-3">
                                        <div className="w-10 h-10 rounded-full overflow-hidden ring-2 ring-blue-100 shrink-0">
                                            <img
                                                src={`https://api.dicebear.com/7.x/${c.role === 'DOCTOR' ? 'personas' : 'micah'}/svg?seed=${encodeURIComponent(c.name)}&backgroundColor=b6e3f4,d1d4f9`}
                                                alt={c.name}
                                                className="w-full h-full object-cover"
                                                onError={e => { e.target.outerHTML = `<div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-black text-sm">${c.name?.charAt(0)}</div>`; }}
                                            />
                                        </div>
                                        <div className="min-w-0">
                                            <div className="font-bold text-sm text-[--text-primary] truncate">{c.name}</div>
                                            <div className="text-[10px] text-[--text-muted] font-semibold uppercase tracking-wider mt-0.5">{c.role}</div>
                                        </div>
                                        <div className="ml-auto w-2 h-2 rounded-full bg-green-400 shrink-0" title="Online"/>
                                    </div>
                                </button>
                            )) : (
                                <div className="p-8 text-center">
                                    <div className="w-12 h-12 bg-[--surface-soft] text-slate-300 rounded-full flex items-center justify-center mx-auto mb-3"><MessageSquare size={20}/></div>
                                    <p className="text-sm font-bold text-[--text-muted]">No contacts yet</p>
                                    <p className="text-xs text-[--text-muted] mt-1">
                                        {user?.role === 'DOCTOR' ? 'Parents will appear after appointments.' : 'Book an appointment to message a doctor.'}
                                    </p>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Chat Area */}
                    <div className="w-full md:w-2/3 flex flex-col">
                        {activeContact ? (
                            <>
                                {/* Chat Header */}
                                <div className="px-5 py-3 border-b border-[--border] bg-[--surface] flex items-center gap-3">
                                    <div className="w-9 h-9 rounded-full overflow-hidden ring-2 ring-blue-100 shrink-0">
                                        <img src={`https://api.dicebear.com/7.x/${activeContact.role === 'DOCTOR' ? 'personas' : 'micah'}/svg?seed=${encodeURIComponent(activeContact.name)}&backgroundColor=b6e3f4`} alt="" className="w-full h-full object-cover" onError={e=>{e.target.outerHTML=`<div class="w-9 h-9 rounded-full bg-blue-600 flex items-center justify-center text-white font-black text-sm">${activeContact.name?.charAt(0)}</div>`;}}/>
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="font-bold text-sm text-[--text-primary] truncate">{activeContact.name}</div>
                                        <div className="text-[10px] text-green-500 font-bold uppercase tracking-widest flex items-center gap-1">
                                            <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse"/> Online
                                        </div>
                                    </div>
                                </div>

                                {/* Messages */}
                                <div className="flex-1 overflow-y-auto flex flex-col gap-3 p-5 bg-[--surface-soft]/50">
                                    {(messages || []).length === 0 ? (
                                        <div className="m-auto flex flex-col items-center text-[--text-muted]">
                                            <Clock size={28} className="mb-2 text-slate-300"/>
                                            <span className="text-sm font-bold">No messages yet</span>
                                            <span className="text-xs mt-1">Start the conversation below.</span>
                                        </div>
                                    ) : messages.map(m => {
                                        const isMe = m.senderId === user.id;
                                        const mType = detectMessageType(m.content);
                                        return (
                                            <div key={m.id} className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}>
                                                <div className={`max-w-[78%] flex flex-col gap-1 ${isMe ? 'items-end' : 'items-start'}`}>
                                                    {!isMe && msgTypeBadge(mType)}
                                                    <div className={`p-3 px-4 rounded-2xl text-sm font-medium shadow-sm whitespace-pre-wrap ${
                                                        mType === 'emergency' ? 'bg-red-50 border-2 border-red-300 text-red-800' :
                                                        mType === 'prescription' ? 'bg-purple-50 border border-purple-200 text-purple-900' :
                                                        isMe ? 'bg-blue-600 text-white rounded-br-none' :
                                                        'bg-[--surface] border border-[--border] text-[--text-primary] rounded-bl-none'
                                                    }`}>
                                                        {m.content}
                                                        <div className={`text-[10px] mt-1.5 ${isMe ? 'text-blue-200' : 'text-[--text-muted]'}`}>
                                                            {new Date(m.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                        </div>
                                                    </div>
                                                    {isMe && msgTypeBadge(mType)}
                                                </div>
                                            </div>
                                        );
                                    })}
                                    <div ref={messagesEndRef}/>
                                </div>

                                {/* Quick Message Type Picker */}
                                {showQuick && user?.role === 'DOCTOR' && (
                                    <div className="px-4 py-2 border-t border-[--border] bg-[--surface-soft] flex flex-wrap gap-2">
                                        {QUICK_TYPES.map(t => (
                                            <button key={t.key} type="button" onClick={() => applyQuickType(t.prefix)}
                                                className={`inline-flex items-center gap-1.5 text-xs font-black uppercase px-3 py-1.5 rounded-full border transition-colors ${t.color}`}>
                                                {t.icon} {t.label}
                                            </button>
                                        ))}
                                    </div>
                                )}

                                {/* Input */}
                                <div className="p-4 border-t border-[--border] bg-[--surface]">
                                    <form onSubmit={handleSend} className="flex gap-2">
                                        {user?.role === 'DOCTOR' && (
                                            <button type="button" onClick={() => setShowQuick(!showQuick)}
                                                className={`px-3 h-[46px] rounded-xl border-2 transition-colors flex items-center gap-1 text-xs font-black ${showQuick ? 'bg-primary-600 text-white border-primary-600' : 'border-[--border] text-[--text-muted] hover:border-primary-400 hover:text-primary-600'}`}
                                                title="Message type">
                                                <Pill size={14}/> <ChevronDown size={12}/>
                                            </button>
                                        )}
                                        <input
                                            type="text" value={messageInput}
                                            onChange={e => setMessageInput(e.target.value)}
                                            placeholder={`Type a message to ${activeContact.name.split(' ')[0]}...`}
                                            className="flex-1 px-4 py-3 border-2 border-[--border] rounded-xl text-sm font-medium bg-[--surface] text-[--text-primary] placeholder:text-[--text-muted] focus:outline-none focus:border-primary-500 focus:ring-4 focus:ring-primary-500/10 transition-all"
                                            disabled={sendMessage.isPending}
                                        />
                                        <button
                                            type="submit"
                                            disabled={!messageInput.trim() || sendMessage.isPending}
                                            className="px-5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl transition-colors shadow-sm disabled:opacity-40 flex items-center justify-center">
                                            <Send size={17}/>
                                        </button>
                                    </form>
                                    {user?.role === 'PARENT' && (
                                        <p className="text-[10px] text-[--text-muted] font-semibold mt-2 text-center">You can ask questions, describe symptoms, or send reminders. Your doctor will reply shortly.</p>
                                    )}
                                </div>
                            </>
                        ) : (
                            <div className="flex-1 flex flex-col items-center justify-center text-[--text-muted] bg-[--surface-soft]/30">
                                <div className="w-20 h-20 bg-[--surface-soft] rounded-full flex items-center justify-center mb-4 border border-[--border]">
                                    <Inbox size={32} className="text-slate-300"/>
                                </div>
                                <span className="font-bold text-lg text-[--text-secondary] tracking-tight">Select a conversation</span>
                                <span className="text-sm mt-1">Choose a contact from the left to begin.</span>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};
