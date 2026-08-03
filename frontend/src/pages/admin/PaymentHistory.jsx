import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import {
    CreditCard, CheckCircle2, XCircle, Clock, Search, Download,
    TrendingUp, DollarSign, AlertCircle, RefreshCw
} from 'lucide-react';

const STATUS_CONFIG = {
    PAID:    { label: 'Paid',    color: 'bg-emerald-100 text-emerald-700 border-emerald-200', icon: <CheckCircle2 size={11}/> },
    PENDING: { label: 'Pending', color: 'bg-amber-100 text-amber-700 border-amber-200',   icon: <Clock size={11}/> },
    FAILED:  { label: 'Failed',  color: 'bg-red-100 text-red-700 border-red-200',          icon: <XCircle size={11}/> },
};

const fmtDate = (d) => new Date(d).toLocaleString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
});

export const PaymentHistory = () => {
    const [search, setSearch] = useState('');
    const [filterStatus, setFilterStatus] = useState('ALL');

    const { data: payments = [], isLoading, refetch } = useQuery({
        queryKey: ['admin-payments'],
        queryFn: async () => (await api.get('/payments')).data.data,
    });

    const filtered = payments.filter(p => {
        const matchStatus = filterStatus === 'ALL' || p.status === filterStatus;
        const term = search.toLowerCase();
        const name = `${p.user?.parentProfile?.firstName ?? ''} ${p.user?.parentProfile?.lastName ?? ''}`.toLowerCase();
        const matchSearch = !search || name.includes(term) || p.accountNo?.includes(term) || p.transactionId?.includes(term);
        return matchStatus && matchSearch;
    });

    const totalPaid = payments.filter(p => p.status === 'PAID').reduce((s, p) => s + p.amount, 0);
    const totalFailed = payments.filter(p => p.status === 'FAILED').length;
    const totalPending = payments.filter(p => p.status === 'PENDING').length;

    return (
        <div className="max-w-6xl mx-auto pb-16 space-y-6 animate-fade-in">

            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-black text-[--text-primary] tracking-tight">Payment History</h1>
                    <p className="text-sm text-[--text-muted] font-medium mt-0.5">All EVC Plus / WaafiPay transactions</p>
                </div>
                <button
                    onClick={() => refetch()}
                    className="flex items-center gap-2 px-4 py-2.5 bg-[--surface] border border-[--border] rounded-xl text-xs font-black text-[--text-secondary] hover:text-primary-600 hover:border-primary-400 transition-all"
                >
                    <RefreshCw size={13}/> Refresh
                </button>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="bg-[--surface] border border-[--border] rounded-2xl p-5 shadow-sm">
                    <div className="flex items-center gap-3 mb-3">
                        <div className="w-10 h-10 rounded-xl bg-emerald-100 dark:bg-emerald-950/30 flex items-center justify-center">
                            <DollarSign size={18} className="text-emerald-600"/>
                        </div>
                        <span className="text-xs font-black text-[--text-muted] uppercase tracking-wide">Total Revenue</span>
                    </div>
                    <div className="text-3xl font-black text-[--text-primary]">${totalPaid.toFixed(2)}</div>
                    <div className="text-[10px] text-emerald-600 font-bold mt-1">{payments.filter(p => p.status === 'PAID').length} successful payments</div>
                </div>

                <div className="bg-[--surface] border border-[--border] rounded-2xl p-5 shadow-sm">
                    <div className="flex items-center gap-3 mb-3">
                        <div className="w-10 h-10 rounded-xl bg-amber-100 dark:bg-amber-950/30 flex items-center justify-center">
                            <Clock size={18} className="text-amber-600"/>
                        </div>
                        <span className="text-xs font-black text-[--text-muted] uppercase tracking-wide">Pending</span>
                    </div>
                    <div className="text-3xl font-black text-[--text-primary]">{totalPending}</div>
                    <div className="text-[10px] text-amber-600 font-bold mt-1">Awaiting confirmation</div>
                </div>

                <div className="bg-[--surface] border border-[--border] rounded-2xl p-5 shadow-sm">
                    <div className="flex items-center gap-3 mb-3">
                        <div className="w-10 h-10 rounded-xl bg-red-100 dark:bg-red-950/30 flex items-center justify-center">
                            <XCircle size={18} className="text-red-500"/>
                        </div>
                        <span className="text-xs font-black text-[--text-muted] uppercase tracking-wide">Failed</span>
                    </div>
                    <div className="text-3xl font-black text-[--text-primary]">{totalFailed}</div>
                    <div className="text-[10px] text-red-500 font-bold mt-1">Declined transactions</div>
                </div>
            </div>

            {/* Filters */}
            <div className="bg-[--surface] border border-[--border] rounded-2xl p-4 shadow-sm flex flex-col sm:flex-row items-start sm:items-center gap-3">
                <div className="relative flex-1 min-w-0">
                    <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[--text-muted]"/>
                    <input
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                        placeholder="Search by payer name, phone, or transaction ID..."
                        className="w-full pl-9 pr-4 py-2.5 text-xs font-medium bg-[--surface-soft] border border-[--border] rounded-xl text-[--text-primary] placeholder-[--text-muted] focus:outline-none focus:border-primary-400 transition-all"
                    />
                </div>
                <div className="flex items-center gap-2">
                    {['ALL', 'PAID', 'PENDING', 'FAILED'].map(s => (
                        <button key={s}
                            onClick={() => setFilterStatus(s)}
                            className={`px-3 py-2 rounded-xl text-[10px] font-black border transition-all ${filterStatus === s ? 'bg-primary-600 text-white border-primary-600' : 'bg-[--surface-soft] text-[--text-secondary] border-[--border] hover:border-primary-400'}`}
                        >
                            {s}
                        </button>
                    ))}
                </div>
            </div>

            {/* Table */}
            <div className="bg-[--surface] border border-[--border] rounded-2xl shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-[--border] bg-[--surface-soft] flex items-center justify-between">
                    <h2 className="font-black text-sm text-[--text-primary]">
                        Transactions <span className="text-[--text-muted] font-medium">({filtered.length})</span>
                    </h2>
                </div>

                {isLoading ? (
                    <div className="p-6 space-y-3">
                        {[1,2,3,4].map(i => <div key={i} className="h-14 rounded-xl bg-[--surface-soft] animate-pulse"/>)}
                    </div>
                ) : filtered.length === 0 ? (
                    <div className="text-center py-20">
                        <CreditCard size={40} className="mx-auto text-[--text-muted]/30 mb-4"/>
                        <p className="font-black text-[--text-secondary] mb-1">No transactions found</p>
                        <p className="text-xs text-[--text-muted]">Payments will appear here once parents book appointments</p>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="border-b border-[--border]">
                                    {['Payer', 'Phone (EVC+)', 'Amount', 'Transaction ID', 'Date', 'Status'].map(h => (
                                        <th key={h} className="px-6 py-3 text-left text-[10px] font-black text-[--text-muted] uppercase tracking-widest">{h}</th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-[--border]">
                                {filtered.map(p => {
                                    const cfg = STATUS_CONFIG[p.status] ?? STATUS_CONFIG.PENDING;
                                    const name = p.user?.parentProfile
                                        ? `${p.user.parentProfile.firstName} ${p.user.parentProfile.lastName}`
                                        : p.user?.email ?? 'Unknown';
                                    return (
                                        <tr key={p.id} className="hover:bg-[--surface-soft] transition-colors">
                                            <td className="px-6 py-4">
                                                <div className="font-black text-xs text-[--text-primary]">{name}</div>
                                                <div className="text-[10px] text-[--text-muted]">{p.user?.email}</div>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className="text-xs font-bold text-[--text-secondary]">{p.accountNo}</span>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className="text-sm font-black text-[--text-primary]">${p.amount.toFixed(2)}</span>
                                                <span className="text-[10px] text-[--text-muted] ml-1">{p.currency}</span>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className="text-[10px] font-mono text-[--text-muted] bg-[--surface-soft] px-2 py-1 rounded-lg">
                                                    {p.transactionId ? p.transactionId.slice(0, 20) + '…' : '—'}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className="text-xs text-[--text-muted] font-medium">{fmtDate(p.createdAt)}</span>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`inline-flex items-center gap-1 text-[10px] font-black px-2.5 py-1 rounded-full border ${cfg.color}`}>
                                                    {cfg.icon} {cfg.label}
                                                </span>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
};
