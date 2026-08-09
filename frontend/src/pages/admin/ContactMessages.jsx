import React, { useState, useEffect } from 'react';
import { api } from '../../lib/axios';
import { Mail, CheckCircle, XCircle, Clock, Inbox, ChevronRight, UserPlus, ShieldAlert } from 'lucide-react';

const ContactMessages = () => {
    const [messages, setMessages] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedMessage, setSelectedMessage] = useState(null);
    const [actionLoading, setActionLoading] = useState(null);
    const [actionMessage, setActionMessage] = useState(null);

    const fetchMessages = async () => {
        try {
            setLoading(true);
            const response = await api.get('/contact');
            if (response.data.status === 'success') {
                setMessages(response.data.data);
            }
        } catch (error) {
            console.error('Failed to fetch contact messages:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchMessages();
    }, []);

    const handleMarkAsRead = async (id, isRead) => {
        try {
            const response = await api.patch(`/contact/${id}`, { isRead });
            if (response.data.status === 'success') {
                setMessages(messages.map(msg => 
                    msg.id === id ? { ...msg, isRead } : msg
                ));
                if (selectedMessage && selectedMessage.id === id) {
                    setSelectedMessage({ ...selectedMessage, isRead });
                }
            }
        } catch (error) {
            console.error('Failed to update message status:', error);
        }
    };

    const handleRequestVerification = async () => {
        try {
            setActionLoading('verify');
            setActionMessage(null);
            const response = await api.post(`/contact/${selectedMessage.id}/request-verification`);
            if (response.data.status === 'success') {
                setActionMessage({ type: 'success', text: 'Verification email sent successfully!' });
            }
        } catch (error) {
            setActionMessage({ type: 'error', text: error.response?.data?.message || 'Failed to send verification email' });
        } finally {
            setActionLoading(null);
            setTimeout(() => setActionMessage(null), 5000);
        }
    };

    const handleCreateAccount = async () => {
        try {
            setActionLoading('create');
            setActionMessage(null);
            const response = await api.post(`/contact/${selectedMessage.id}/create-account`);
            if (response.data.status === 'success') {
                setActionMessage({ type: 'success', text: 'Account created and credentials emailed successfully!' });
            }
        } catch (error) {
            setActionMessage({ type: 'error', text: error.response?.data?.message || 'Failed to create account' });
        } finally {
            setActionLoading(null);
            setTimeout(() => setActionMessage(null), 5000);
        }
    };

    const formatDate = (dateString) => {
        const options = { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' };
        return new Date(dateString).toLocaleDateString('en-US', options);
    };

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-(--text-primary) tracking-tight flex items-center gap-2">
                        <Inbox className="w-6 h-6 text-primary-600" />
                        Public Messages
                    </h1>
                    <p className="text-(--text-secondary) text-sm mt-1">Manage contact inquiries from the public landing page.</p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Message List */}
                <div className="lg:col-span-1 bg-(--surface) border border-(--border) rounded-(--radius-lg) overflow-hidden flex flex-col h-[600px]">
                    <div className="p-4 border-b border-(--border) bg-(--surface-soft) font-bold text-sm text-(--text-primary)">
                        Inbox ({messages.filter(m => !m.isRead).length} Unread)
                    </div>
                    <div className="flex-1 overflow-y-auto custom-scrollbar">
                        {loading ? (
                            <div className="p-8 text-center text-(--text-muted)">Loading messages...</div>
                        ) : messages.length === 0 ? (
                            <div className="p-8 text-center text-(--text-muted)">No messages found.</div>
                        ) : (
                            <div className="divide-y divide-(--border)">
                                {messages.map(msg => (
                                    <div 
                                        key={msg.id} 
                                        onClick={() => setSelectedMessage(msg)}
                                        className={`p-4 cursor-pointer transition-colors border-l-4 ${
                                            selectedMessage?.id === msg.id 
                                                ? 'bg-primary-50 dark:bg-primary-900/20 border-primary-500' 
                                                : msg.isRead 
                                                    ? 'hover:bg-(--surface-soft) border-transparent' 
                                                    : 'bg-(--surface-soft) hover:bg-(--surface-hover) border-primary-400'
                                        }`}
                                    >
                                        <div className="flex justify-between items-start mb-1">
                                            <h3 className={`text-sm truncate pr-2 ${!msg.isRead ? 'font-bold text-(--text-primary)' : 'font-semibold text-(--text-secondary)'}`}>
                                                {msg.firstName} {msg.lastName}
                                            </h3>
                                            <span className="text-[10px] text-(--text-muted) whitespace-nowrap">
                                                {new Date(msg.createdAt).toLocaleDateString()}
                                            </span>
                                        </div>
                                        <p className={`text-xs truncate ${!msg.isRead ? 'font-semibold text-(--text-primary)' : 'text-(--text-muted)'}`}>
                                            {msg.subject}
                                        </p>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>

                {/* Message Detail */}
                <div className="lg:col-span-2 bg-(--surface) border border-(--border) rounded-(--radius-lg) overflow-hidden flex flex-col h-[600px]">
                    {selectedMessage ? (
                        <>
                            <div className="p-6 border-b border-(--border) flex justify-between items-start bg-(--surface-soft)">
                                <div>
                                    <h2 className="text-xl font-bold text-(--text-primary) mb-2">{selectedMessage.subject}</h2>
                                    <div className="flex items-center gap-2 text-sm text-(--text-secondary)">
                                        <span className="font-semibold">{selectedMessage.firstName} {selectedMessage.lastName}</span>
                                        <span>&lt;{selectedMessage.email}&gt;</span>
                                    </div>
                                    <div className="text-xs text-(--text-muted) mt-1 flex items-center gap-1">
                                        <Clock className="w-3 h-3" />
                                        {formatDate(selectedMessage.createdAt)}
                                    </div>
                                </div>
                                    <div className="flex flex-col sm:flex-row items-end sm:items-center gap-2">
                                        {!selectedMessage.isRead ? (
                                            <button 
                                                onClick={() => handleMarkAsRead(selectedMessage.id, true)}
                                                className="px-3 py-1.5 bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:text-primary-300 text-xs font-bold rounded flex items-center gap-1 hover:bg-primary-200 transition-colors w-full sm:w-auto justify-center"
                                            >
                                                <CheckCircle className="w-4 h-4" />
                                                Mark as Read
                                            </button>
                                        ) : (
                                            <button 
                                                onClick={() => handleMarkAsRead(selectedMessage.id, false)}
                                                className="px-3 py-1.5 bg-(--surface) border border-(--border) text-(--text-muted) text-xs font-bold rounded flex items-center gap-1 hover:text-(--text-primary) transition-colors w-full sm:w-auto justify-center"
                                            >
                                                <XCircle className="w-4 h-4" />
                                                Mark as Unread
                                            </button>
                                        )}
                                    </div>
                                </div>

                            {/* Action Buttons */}
                            <div className="px-6 py-4 border-b border-(--border) bg-(--surface) flex flex-wrap gap-3">
                                <button
                                    onClick={handleRequestVerification}
                                    disabled={actionLoading !== null}
                                    className="px-4 py-2 bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 text-xs font-bold rounded-lg flex items-center gap-2 hover:bg-amber-200 dark:hover:bg-amber-900/50 transition-colors disabled:opacity-50"
                                >
                                    {actionLoading === 'verify' ? (
                                        <div className="w-4 h-4 border-2 border-amber-700/30 border-t-amber-700 rounded-full animate-spin" />
                                    ) : (
                                        <ShieldAlert className="w-4 h-4" />
                                    )}
                                    Request Verification
                                </button>
                                <button
                                    onClick={handleCreateAccount}
                                    disabled={actionLoading !== null}
                                    className="px-4 py-2 bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400 text-xs font-bold rounded-lg flex items-center gap-2 hover:bg-emerald-200 dark:hover:bg-emerald-900/50 transition-colors disabled:opacity-50"
                                >
                                    {actionLoading === 'create' ? (
                                        <div className="w-4 h-4 border-2 border-emerald-700/30 border-t-emerald-700 rounded-full animate-spin" />
                                    ) : (
                                        <UserPlus className="w-4 h-4" />
                                    )}
                                    Create Account & Send Credentials
                                </button>
                            </div>

                            {actionMessage && (
                                <div className={`px-6 py-3 border-b border-(--border) text-sm font-bold flex items-center gap-2 ${
                                    actionMessage.type === 'success' 
                                        ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-400'
                                        : 'bg-red-50 text-red-700 dark:bg-red-900/20 dark:text-red-400'
                                }`}>
                                    {actionMessage.type === 'success' ? <CheckCircle className="w-4 h-4" /> : <XCircle className="w-4 h-4" />}
                                    {actionMessage.text}
                                </div>
                            )}

                            <div className="p-6 flex-1 overflow-y-auto text-sm text-(--text-primary) whitespace-pre-wrap leading-relaxed">
                                {selectedMessage.message}
                            </div>
                        </>
                    ) : (
                        <div className="flex-1 flex flex-col items-center justify-center text-(--text-muted)">
                            <Mail className="w-16 h-16 mb-4 opacity-20" />
                            <p>Select a message to view details</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default ContactMessages;
