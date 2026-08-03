import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import { Calendar, Clock, Video, Stethoscope, CheckCircle, XCircle, Clock3, Sun, Sunset, Moon, MapPin, Zap, User } from 'lucide-react';
import { Card, CardContent } from '../../components/ui/Card';
import { useNavigate } from 'react-router-dom';

const SHIFT_CONFIG = {
    morning:   { label: 'Morning',   icon: <Sun size={16}/>,    range: 'Before 12:00 PM', color: 'text-amber-600',   bg: 'bg-amber-50 border-amber-200 dark:bg-amber-950/30 dark:border-amber-900' },
    afternoon: { label: 'Afternoon', icon: <Sunset size={16}/>, range: '12:00 – 17:00',   color: 'text-orange-500',  bg: 'bg-orange-50 border-orange-200 dark:bg-orange-950/30 dark:border-orange-900' },
    night:     { label: 'Night',     icon: <Moon size={16}/>,   range: 'After 17:00',     color: 'text-indigo-500',  bg: 'bg-indigo-50 border-indigo-200 dark:bg-indigo-950/30 dark:border-indigo-900' },
};

const getShift = (dateStr) => {
    const h = new Date(dateStr).getHours();
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'night';
};

export const DoctorSchedule = () => {
    const queryClient = useQueryClient();
    const navigate = useNavigate();
    const [activeFilter, setActiveFilter] = useState('ALL');
    const [viewMode, setViewMode] = useState('timeslot'); // 'timeslot' | 'list'

    const { data: schedule, isLoading } = useQuery({
        queryKey: ['doctorSchedule'],
        queryFn: async () => {
            const res = await api.get('/appointments/my-schedule');
            return res.data.data.appointments || [];
        },
        refetchInterval: 10000
    });

    const updateStatus = useMutation({
        mutationFn: async ({ id, status }) => await api.patch(`/appointments/${id}/status`, { status }),
        onSuccess: () => {
            queryClient.invalidateQueries(['doctorSchedule']);
            queryClient.invalidateQueries(['teleconsultAppointments']);
        }
    });

    const today = new Date().toDateString();
    const todayAppts = (schedule || []).filter(a => new Date(a.scheduledAt).toDateString() === today);
    const filtered = activeFilter === 'ALL' ? (schedule || []) : (schedule || []).filter(a => a.status === activeFilter);

    // Group by shift
    const byShift = { morning: [], afternoon: [], night: [] };
    filtered.forEach(a => { const s = getShift(a.scheduledAt); byShift[s].push(a); });

    const StatusChip = ({ status }) => {
        const map = {
            PENDING:   'bg-amber-100 text-amber-700 border-amber-300',
            CONFIRMED: 'bg-emerald-100 text-emerald-700 border-emerald-300',
            COMPLETED: 'bg-slate-100 text-slate-500 border-slate-200',
            CANCELLED: 'bg-red-100 text-red-600 border-red-300',
        };
        const icons = { PENDING: <Clock3 size={11}/>, CONFIRMED: <CheckCircle size={11}/>, COMPLETED: <CheckCircle size={11}/>, CANCELLED: <XCircle size={11}/> };
        return (
            <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-widest border ${map[status] || map.PENDING}`}>
                {icons[status]} {status}
            </span>
        );
    };

    const AppointmentRow = ({ appt }) => {
        const isPending   = appt.status === 'PENDING';
        const isConfirmed = appt.status === 'CONFIRMED';
        const isOnline    = true;
        const time = new Date(appt.scheduledAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        return (
            <div className="flex flex-col sm:flex-row sm:items-center gap-4 p-4 bg-[--surface] rounded-xl border border-[--border] hover:border-primary-300 hover:shadow-sm transition-all group">
                {/* Time pill */}
                <div className="flex items-center gap-3 shrink-0">
                    <div className="w-16 text-center">
                        <div className="text-lg font-black text-[--text-primary] leading-none">{time}</div>
                        <div className="text-[9px] font-bold uppercase text-[--text-muted] tracking-widest mt-0.5">
                            {new Date(appt.scheduledAt).toLocaleDateString([], { month: 'short', day: 'numeric' })}
                        </div>
                    </div>
                    <div className="w-px h-12 bg-[--border] hidden sm:block"/>
                </div>

                {/* Patient info */}
                <div className="flex items-center gap-3 flex-1 min-w-0">
                    <div className="w-10 h-10 rounded-full overflow-hidden ring-2 ring-blue-100 shrink-0">
                        <img
                            src={`https://api.dicebear.com/7.x/micah/svg?seed=${encodeURIComponent((appt.child?.firstName || '') + (appt.child?.lastName || ''))}&backgroundColor=b6e3f4,ffd5dc`}
                            alt={appt.child?.firstName}
                            className="w-full h-full object-cover"
                            onError={e => { e.target.outerHTML = `<div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-black text-sm">${appt.child?.firstName?.charAt(0) || 'P'}</div>`; }}
                        />
                    </div>
                    <div className="min-w-0">
                        <div className="font-black text-[--text-primary] truncate">
                            {appt.child?.firstName} {appt.child?.lastName}
                        </div>
                        <div className="text-xs text-[--text-secondary] font-medium truncate flex items-center gap-1 mt-0.5">
                            <User size={10}/> {appt.reason || 'General Consultation'}
                        </div>
                    </div>
                </div>

                {/* Visit type */}
                <div className="shrink-0">
                    <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border ${isOnline ? 'bg-indigo-50 text-indigo-600 border-indigo-200' : 'bg-teal-50 text-teal-700 border-teal-200'}`}>
                        {isOnline ? <><Video size={11}/> Online</> : <><MapPin size={11}/> Clinic Visit</>}
                    </span>
                </div>

                {/* Status */}
                <div className="shrink-0"><StatusChip status={appt.status}/></div>

                {/* Actions */}
                <div className="flex items-center gap-2 shrink-0">
                    {isPending && (
                        <>
                            <button onClick={() => updateStatus.mutate({ id: appt.id, status: 'CONFIRMED' })}
                                className="px-3 py-1.5 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-lg text-xs font-black uppercase hover:bg-emerald-100 transition-colors flex items-center gap-1">
                                <CheckCircle size={12}/> Approve
                            </button>
                            <button onClick={() => updateStatus.mutate({ id: appt.id, status: 'CANCELLED' })}
                                className="px-3 py-1.5 bg-red-50 text-red-600 border border-red-200 rounded-lg text-xs font-black uppercase hover:bg-red-100 transition-colors flex items-center gap-1">
                                <XCircle size={12}/> Decline
                            </button>
                        </>
                    )}
                    {isConfirmed && (
                        <button onClick={() => navigate('/teleconsult')}
                            className="px-3 py-1.5 bg-indigo-600 text-white rounded-lg text-xs font-black uppercase hover:bg-indigo-700 transition-colors flex items-center gap-1 shadow-sm">
                            <Zap size={12}/> Join Session
                        </button>
                    )}
                    {appt.status === 'COMPLETED' && (
                        <button onClick={() => navigate(`/child/${appt.childId}`)}
                            className="px-3 py-1.5 bg-[--surface-soft] text-[--text-muted] border border-[--border] rounded-lg text-xs font-black uppercase hover:text-primary-600 transition-colors">
                            View Record
                        </button>
                    )}
                </div>
            </div>
        );
    };

    return (
        <div className="w-full space-y-6 animate-fade-in font-sans">
            {/* Hero */}
            <div className="bg-gradient-to-r from-blue-700 to-indigo-800 rounded-xl shadow-sm p-8 text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 w-72 h-72 bg-white/5 rounded-full blur-3xl pointer-events-none"/>
                <div className="relative z-10 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                    <div>
                        <h1 className="text-3xl font-black tracking-tight mb-1 flex items-center gap-3">
                            <Stethoscope size={28} className="text-teal-300"/> Clinical Schedule
                        </h1>
                        <p className="text-white/70 font-medium">Manage daily appointments, approve requests, and launch teleconsultation sessions.</p>
                    </div>
                    <div className="flex items-center gap-3 bg-white/10 rounded-xl px-4 py-3 text-sm font-black border border-white/20">
                        <Calendar size={16} className="text-teal-300"/>
                        {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
                    </div>
                </div>
            </div>

            {/* Today's Stats */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[
                    { label: "Today's Appointments", val: todayAppts.length, color: 'text-primary-600', bg: 'bg-primary-50 border-primary-200' },
                    { label: 'Pending Approval',     val: (schedule||[]).filter(a=>a.status==='PENDING').length,   color: 'text-amber-600',   bg: 'bg-amber-50 border-amber-200' },
                    { label: 'Confirmed',             val: (schedule||[]).filter(a=>a.status==='CONFIRMED').length, color: 'text-emerald-600', bg: 'bg-emerald-50 border-emerald-200' },
                    { label: 'Completed',             val: (schedule||[]).filter(a=>a.status==='COMPLETED').length, color: 'text-slate-600',   bg: 'bg-slate-50 border-slate-200' },
                ].map(s => (
                    <div key={s.label} className={`rounded-xl border p-4 ${s.bg}`}>
                        <div className="text-[10px] font-black uppercase tracking-widest text-[--text-muted] mb-1">{s.label}</div>
                        <div className={`text-3xl font-black ${s.color}`}>{s.val}</div>
                    </div>
                ))}
            </div>

            {/* Filter Bar */}
            <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-center justify-between">
                <div className="flex gap-2 flex-wrap">
                    {['ALL','PENDING','CONFIRMED','COMPLETED'].map(f => (
                        <button key={f} onClick={() => setActiveFilter(f)}
                            className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wide border-2 transition-all ${activeFilter === f ? 'bg-primary-600 text-white border-primary-600 shadow-sm' : 'border-[--border] text-[--text-muted] hover:border-primary-400'}`}>
                            {f}
                        </button>
                    ))}
                </div>
                <div className="flex gap-2">
                    <button onClick={() => setViewMode('timeslot')}
                        className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wide border-2 transition-all flex items-center gap-1.5 ${viewMode==='timeslot' ? 'bg-indigo-600 text-white border-indigo-600' : 'border-[--border] text-[--text-muted] hover:border-indigo-400'}`}>
                        <Clock size={13}/> By Shift
                    </button>
                    <button onClick={() => setViewMode('list')}
                        className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wide border-2 transition-all ${viewMode==='list' ? 'bg-indigo-600 text-white border-indigo-600' : 'border-[--border] text-[--text-muted] hover:border-indigo-400'}`}>
                        List
                    </button>
                </div>
            </div>

            {isLoading ? (
                <div className="p-12 text-center text-[--text-muted] font-bold uppercase tracking-widest animate-pulse">Syncing Schedule...</div>
            ) : viewMode === 'timeslot' ? (
                /* SHIFT VIEW */
                <div className="space-y-6">
                    {Object.entries(SHIFT_CONFIG).map(([shift, cfg]) => (
                        <div key={shift}>
                            <div className={`flex items-center gap-3 px-4 py-2.5 rounded-xl border mb-3 ${cfg.bg}`}>
                                <span className={cfg.color}>{cfg.icon}</span>
                                <span className={`font-black text-sm uppercase tracking-widest ${cfg.color}`}>{cfg.label} Shift</span>
                                <span className="text-[--text-muted] text-xs font-semibold">{cfg.range}</span>
                                <span className={`ml-auto text-xs font-black px-2 py-0.5 rounded-full bg-white/70 ${cfg.color}`}>
                                    {byShift[shift].length} appointment{byShift[shift].length !== 1 ? 's' : ''}
                                </span>
                            </div>
                            {byShift[shift].length === 0 ? (
                                <div className="text-sm text-[--text-muted] italic px-4 py-3 border border-dashed border-[--border] rounded-xl text-center">
                                    No appointments in this shift
                                </div>
                            ) : (
                                <div className="space-y-3">
                                    {byShift[shift]
                                        .sort((a, b) => new Date(a.scheduledAt) - new Date(b.scheduledAt))
                                        .map(a => <AppointmentRow key={a.id} appt={a}/>)}
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            ) : (
                /* LIST VIEW — table */
                <Card className="shadow-sm overflow-hidden">
                    <CardContent className="p-0">
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-[--surface-soft] border-b border-[--border] text-[10px] font-black uppercase tracking-widest text-[--text-secondary]">
                                        <th className="p-4">Patient</th>
                                        <th className="p-4">Time Slot</th>
                                        <th className="p-4">Visit Type</th>
                                        <th className="p-4">Status</th>
                                        <th className="p-4 text-right">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {filtered.sort((a,b) => new Date(a.scheduledAt)-new Date(b.scheduledAt)).map(appt => (
                                        <tr key={appt.id} className="border-b border-[--border] hover:bg-[--surface-soft] transition-colors">
                                            <td className="p-4">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-9 h-9 rounded-full overflow-hidden ring-2 ring-blue-100 shrink-0">
                                                        <img src={`https://api.dicebear.com/7.x/micah/svg?seed=${encodeURIComponent((appt.child?.firstName||'')+(appt.child?.lastName||''))}&backgroundColor=b6e3f4`} alt="" className="w-full h-full object-cover" onError={e=>{e.target.outerHTML=`<div class="w-9 h-9 rounded-full bg-blue-500 flex items-center justify-center text-white font-black text-xs">${appt.child?.firstName?.charAt(0)||'P'}</div>`;}}/>
                                                    </div>
                                                    <div>
                                                        <div className="font-black text-[--text-primary]">{appt.child?.firstName} {appt.child?.lastName}</div>
                                                        <div className="text-[10px] text-[--text-muted] uppercase tracking-widest font-bold mt-0.5">{appt.reason || 'General Routine'}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="p-4">
                                                <div className="font-black text-[--text-primary] text-sm flex items-center gap-1.5">
                                                    <Clock size={14} className="text-[--text-muted]"/>
                                                    {new Date(appt.scheduledAt).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}
                                                </div>
                                                <div className="text-xs font-semibold text-[--text-secondary] mt-0.5">
                                                    {new Date(appt.scheduledAt).toLocaleDateString()}
                                                </div>
                                            </td>
                                            <td className="p-4">
                                                <span className="inline-flex items-center gap-1.5 bg-indigo-50 text-indigo-600 px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border border-indigo-100">
                                                    <Video size={11}/> Online Consultation
                                                </span>
                                            </td>
                                            <td className="p-4"><StatusChip status={appt.status}/></td>
                                            <td className="p-4 text-right">
                                                <div className="flex items-center justify-end gap-2">
                                                    {appt.status === 'PENDING' && (
                                                        <button onClick={() => updateStatus.mutate({id: appt.id, status:'CONFIRMED'})}
                                                            className="text-xs font-black text-amber-600 hover:text-amber-800 bg-amber-50 hover:bg-amber-100 px-3 py-1.5 rounded-lg border border-amber-200 transition-colors">
                                                            Approve
                                                        </button>
                                                    )}
                                                    {appt.status === 'CONFIRMED' && (
                                                        <button onClick={() => navigate('/teleconsult')}
                                                            className="text-xs font-black text-emerald-600 hover:text-emerald-800 bg-emerald-50 hover:bg-emerald-100 px-3 py-1.5 rounded-lg border border-emerald-200 transition-colors flex items-center gap-1">
                                                            <Video size={12}/> Open Hub
                                                        </button>
                                                    )}
                                                    {appt.status === 'COMPLETED' && (
                                                        <span className="text-xs font-bold text-[--text-muted] uppercase tracking-widest">Archived</span>
                                                    )}
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                    {filtered.length === 0 && (
                                        <tr><td colSpan="5" className="p-12 text-center">
                                            <div className="w-16 h-16 bg-[--surface-soft] rounded-full flex items-center justify-center mx-auto mb-4 text-slate-300"><Calendar size={32}/></div>
                                            <h3 className="text-lg font-black text-[--text-primary]">No Appointments</h3>
                                            <p className="text-sm text-[--text-secondary] font-medium mt-1">Your schedule is clear.</p>
                                        </td></tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </CardContent>
                </Card>
            )}
        </div>
    );
};
