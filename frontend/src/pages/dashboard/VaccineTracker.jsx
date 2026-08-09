import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useParams, Link } from 'react-router-dom';
import { api } from '../../lib/axios';
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Syringe, AlertTriangle, CheckCircle, Clock, Plus, X, Bell, Calendar, FileText, Award } from 'lucide-react';
import useAuthStore from '../../store/authStore';

const STATUS_STYLE = {
    COMPLETED: { cls: 'bg-emerald-100 text-emerald-700 border-emerald-300', icon: <CheckCircle size={12}/> },
    DUE:       { cls: 'bg-orange-100 text-orange-700 border-orange-300',    icon: <AlertTriangle size={12}/> },
    UPCOMING:  { cls: 'bg-blue-100 text-blue-700 border-blue-300',          icon: <Clock size={12}/> },
    MISSED:    { cls: 'bg-red-100 text-red-700 border-red-300',             icon: <AlertTriangle size={12}/> },
};

export const VaccineTracker = () => {
    const { id } = useParams();
    const queryClient = useQueryClient();
    const { user } = useAuthStore();
    const [syncing, setSyncing]         = useState(false);
    const [registerModal, setRegister]  = useState(false);
    const [noteModal, setNoteModal]     = useState(null);
    const [noteText, setNoteText]       = useState('');
    const [regForm, setRegForm]         = useState({ vaccineName: '', doseNumber: 1, scheduledDate: '', batchNumber: '', notes: '' });
    const [reminder, setReminder]       = useState(null);
    const isDoctor = user?.role === 'DOCTOR';
    const isParent = user?.role === 'PARENT';

    const { data: vaccines, isLoading } = useQuery({
        queryKey: ['vaccines', id],
        queryFn: async () => {
            const res = await api.get(`/vaccinations/child/${id}`);
            return res.data.data;
        }
    });

    const syncSchedule = async () => {
        setSyncing(true);
        try {
            await api.post(`/vaccinations/child/${id}/generate`);
            queryClient.invalidateQueries({ queryKey: ['vaccines', id] });
        } catch (err) { console.error('Sync failed', err); }
        finally { setSyncing(false); }
    };

    const markCompleted = useMutation({
        mutationFn: async (vacId) => api.patch(`/vaccinations/${vacId}/status`, { status: 'COMPLETED' }),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['vaccines', id] })
    });

    const registerVaccine = useMutation({
        mutationFn: async (data) => api.post('/vaccinations', { ...data, childId: id }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['vaccines', id] });
            setRegister(false);
            setRegForm({ vaccineName: '', doseNumber: 1, scheduledDate: '', batchNumber: '', notes: '' });
            alert('Vaccination registered successfully!');
        },
        onError: err => alert(err.response?.data?.message || 'Failed to register vaccination')
    });

    const saveNote = useMutation({
        mutationFn: async ({ vacId, notes }) => api.patch(`/vaccinations/${vacId}/notes`, { notes }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['vaccines', id] });
            setNoteModal(null);
            setNoteText('');
        }
    });

    if (isLoading) return <div className="p-8 text-center text-(--text-secondary) font-medium animate-pulse">Loading vaccine schedule...</div>;

    const due       = (vaccines || []).filter(v => ['UPCOMING','DUE'].includes(v.status));
    const history   = (vaccines || []).filter(v => ['COMPLETED','MISSED'].includes(v.status));
    const total     = (vaccines || []).length;
    const completed = history.filter(v => v.status === 'COMPLETED').length;
    const missed    = history.filter(v => v.status === 'MISSED').length;
    const pct       = total ? Math.round((completed / total) * 100) : 0;

    const printCertificate = () => {
        const html = `
            <html><head><title>Vaccination Certificate</title><style>
                body{font-family:Arial,sans-serif;padding:40px;max-width:700px;margin:auto}
                h1{color:#2563eb;border-bottom:3px solid #2563eb;padding-bottom:10px}
                table{width:100%;border-collapse:collapse;margin-top:20px}
                th,td{border:1px solid #ddd;padding:8px 12px;text-align:left}
                th{background:#f1f5f9;font-weight:bold;color:#334155}
                .sig{margin-top:60px;border-top:1px solid #ccc;padding-top:10px;color:#888;font-size:13px}
            </style></head><body>
                <h1>Pediatric Health Hub</h1>
                <h2>Vaccination Certificate</h2>
                <p>This certifies that the patient (ID: ${id}) has received the following vaccinations:</p>
                <table><tr><th>Vaccine</th><th>Dose</th><th>Date Given</th><th>Status</th></tr>
                ${(vaccines||[]).filter(v=>v.status==='COMPLETED').map(v=>`<tr><td>${v.vaccineName}</td><td>${v.doseNumber}</td><td>${v.administeredDate ? new Date(v.administeredDate).toLocaleDateString() : 'N/A'}</td><td>Completed</td></tr>`).join('')}
                </table>
                <div class="sig">Issued by Pediatric Health Hub · ${new Date().toLocaleDateString()}</div>
            </body></html>`;
        const w = window.open('', '_blank');
        w.document.write(html);
        w.document.close();
        w.print();
    };

    const inputCls = 'w-full bg-(--surface) text-(--text-primary) border-2 border-(--border) rounded-xl px-4 py-2.5 focus:outline-none focus:border-blue-500 text-sm font-semibold';

    return (
        <div className="space-y-6 max-w-5xl mx-auto animate-fade-in">
            {/* Header */}
            <div className="bg-gradient-to-r from-purple-600 to-indigo-700 rounded-xl p-6 text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl pointer-events-none"/>
                <div className="relative z-10 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                    <div>
                        <h1 className="text-2xl font-black flex items-center gap-2 mb-1"><Syringe size={24}/> Immunization Schedule</h1>
                        <p className="text-white/80 font-medium text-sm">Age-adjusted vaccination tracking with complete history and certification.</p>
                    </div>
                    <div className="flex gap-2 flex-wrap">
                        <Button onClick={syncSchedule} isLoading={syncing} variant="outline"
                            className="border-white/30 text-white hover:bg-white/20 font-bold text-sm bg-transparent">
                            {due.length === 0 && history.length === 0 ? 'Initialize Schedule' : 'Sync Templates'}
                        </Button>
                        {isDoctor && (
                            <Button onClick={() => setRegister(true)} className="bg-white text-purple-700 hover:bg-purple-50 font-bold text-sm flex items-center gap-2">
                                <Plus size={15}/> Register Vaccine
                            </Button>
                        )}
                    </div>
                </div>
            </div>

            {/* Progress Bar + Stats */}
            <div className="bg-(--surface) rounded-xl border border-(--border) shadow-sm p-6">
                <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-4">
                    <div>
                        <h3 className="font-black text-(--text-primary) text-lg">Vaccination Coverage</h3>
                        <p className="text-sm text-(--text-secondary)">{completed} of {total} vaccines completed</p>
                    </div>
                    <div className="flex gap-3">
                        {[
                            { label: 'Completed', val: completed, color: 'text-emerald-600 bg-emerald-50 border-emerald-200' },
                            { label: 'Upcoming',  val: due.length,  color: 'text-blue-600 bg-blue-50 border-blue-200' },
                            { label: 'Missed',    val: missed,      color: 'text-red-600 bg-red-50 border-red-200' },
                        ].map(s => (
                            <div key={s.label} className={`rounded-xl border px-4 py-2 text-center ${s.color}`}>
                                <div className="text-xl font-black">{s.val}</div>
                                <div className="text-[9px] font-black uppercase tracking-widest">{s.label}</div>
                            </div>
                        ))}
                    </div>
                </div>
                <div className="w-full bg-(--surface-soft) rounded-full h-3 border border-(--border) overflow-hidden">
                    <div className="h-3 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-full transition-all duration-700" style={{ width: `${pct}%` }}/>
                </div>
                <div className="flex justify-between text-xs font-bold text-(--text-muted) mt-1.5">
                    <span>0%</span>
                    <span className="text-emerald-600 font-black">{pct}% Protected</span>
                    <span>100%</span>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Scheduled / Due Vaccines */}
                <Card className="border-t-4 border-t-blue-500 shadow-md">
                    <CardHeader className="bg-(--surface-soft) border-b border-(--border)">
                        <CardTitle className="text-(--text-primary) flex items-center gap-2">
                            <Clock size={18} className="text-blue-500"/> Upcoming Vaccines
                            {isParent && due.length > 0 && (
                                <button onClick={() => setReminder(due[0])}
                                    className="ml-auto flex items-center gap-1 text-[10px] font-black uppercase px-2 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 hover:bg-amber-100 transition-colors">
                                    <Bell size={10}/> Set Reminder
                                </button>
                            )}
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="pt-5">
                        {due.length === 0 ? (
                            <div className="text-center py-6">
                                <CheckCircle size={32} className="mx-auto text-emerald-400 mb-2"/>
                                <p className="text-(--text-secondary) text-sm italic">All scheduled vaccines are up to date!</p>
                            </div>
                        ) : (
                            <div className="space-y-3">
                                {due.map(v => {
                                    const st = STATUS_STYLE[v.status] || STATUS_STYLE.UPCOMING;
                                    return (
                                        <div key={v.id} className="p-4 rounded-xl border border-(--border) bg-(--surface) hover:border-blue-300 transition-colors shadow-sm">
                                            <div className="flex justify-between items-start mb-2">
                                                <div>
                                                    <div className="font-bold text-(--text-primary)">{v.vaccineName}</div>
                                                    <div className="text-xs font-semibold text-(--text-secondary) mt-0.5 uppercase tracking-wider">
                                                        Dose {v.doseNumber} · Due: {new Date(v.scheduledDate).toLocaleDateString()}
                                                    </div>
                                                </div>
                                                <span className={`inline-flex items-center gap-1 text-[10px] font-black px-2 py-1 rounded-full border uppercase tracking-wide ${st.cls}`}>
                                                    {st.icon} {v.status}
                                                </span>
                                            </div>
                                            <div className="flex gap-2 flex-wrap">
                                                {isDoctor && (
                                                    <>
                                                        <button onClick={() => markCompleted.mutate(v.id)}
                                                            className="text-xs font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 px-3 py-1.5 rounded-lg transition-colors flex items-center gap-1">
                                                            <CheckCircle size={12}/> Mark Administered
                                                        </button>
                                                        <button onClick={() => { setNoteModal(v); setNoteText(v.notes || ''); }}
                                                            className="text-xs font-bold text-blue-600 bg-blue-50 hover:bg-blue-100 border border-blue-200 px-3 py-1.5 rounded-lg transition-colors flex items-center gap-1">
                                                            <FileText size={12}/> Add Note
                                                        </button>
                                                    </>
                                                )}
                                                {isParent && (
                                                    <Link to="/appointments" className="text-xs font-bold text-purple-600 bg-purple-50 hover:bg-purple-100 border border-purple-200 px-3 py-1.5 rounded-lg transition-colors flex items-center gap-1">
                                                        <Calendar size={12}/> Book Appointment
                                                    </Link>
                                                )}
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        )}
                    </CardContent>
                </Card>

                {/* Vaccination History */}
                <Card className="shadow-md">
                    <CardHeader className="bg-(--surface-soft) border-b border-(--border)">
                        <CardTitle className="text-(--text-primary) flex items-center gap-2">
                            <CheckCircle size={18} className="text-(--text-secondary)"/> Vaccination History
                            {history.length > 0 && (
                                <button onClick={printCertificate}
                                    className="ml-auto flex items-center gap-1 text-[10px] font-black uppercase px-2 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 hover:bg-amber-100 transition-colors">
                                    <Award size={10}/> Certificate
                                </button>
                            )}
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="pt-5">
                        {history.length === 0 ? (
                            <p className="text-(--text-secondary) text-sm italic">No past records yet.</p>
                        ) : (
                            <div className="space-y-3">
                                {history.map(v => {
                                    const st = STATUS_STYLE[v.status] || STATUS_STYLE.COMPLETED;
                                    return (
                                        <div key={v.id} className={`p-3 rounded-xl border ${v.status === 'MISSED' ? 'border-red-200 bg-red-50 dark:bg-red-950/20' : 'border-(--border) bg-(--surface-soft)'}`}>
                                            <div className="flex justify-between items-center">
                                                <div>
                                                    <div className="font-bold text-sm text-(--text-primary)">{v.vaccineName}
                                                        <span className="text-(--text-muted) text-xs font-medium ml-1">Dose {v.doseNumber}</span>
                                                    </div>
                                                    {v.status === 'COMPLETED' ? (
                                                        <div className="text-xs font-semibold text-emerald-600 mt-1 flex items-center gap-1.5">
                                                            <CheckCircle size={11}/> {v.administeredDate ? new Date(v.administeredDate).toLocaleDateString() : 'Date recorded'}
                                                        </div>
                                                    ) : (
                                                        <div className="text-xs font-semibold text-red-600 mt-1 flex items-center gap-1.5">
                                                            <AlertTriangle size={11}/> Missed — was due {v.scheduledDate ? new Date(v.scheduledDate).toLocaleDateString() : ''}
                                                        </div>
                                                    )}
                                                    {v.notes && <p className="text-xs text-(--text-secondary) mt-1 italic">{v.notes}</p>}
                                                </div>
                                                <span className={`inline-flex items-center gap-1 text-[9px] font-black px-2 py-0.5 rounded-full border uppercase ${st.cls}`}>
                                                    {st.icon} {v.status}
                                                </span>
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>

            {/* REGISTER VACCINE MODAL (Doctor only) */}
            {registerModal && isDoctor && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
                    <div className="bg-(--surface) rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
                        <div className="bg-purple-600 p-5 text-white flex justify-between items-center">
                            <h2 className="font-black text-lg flex items-center gap-2"><Plus size={20}/> Register Vaccination</h2>
                            <button onClick={() => setRegister(false)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={18}/></button>
                        </div>
                        <form onSubmit={e => { e.preventDefault(); registerVaccine.mutate({ ...regForm }); }} className="p-6 space-y-4">
                            <div>
                                <label className="text-[10px] font-black uppercase text-(--text-muted) block mb-1">Vaccine Name *</label>
                                <input required type="text" value={regForm.vaccineName} onChange={e => setRegForm(p=>({...p, vaccineName: e.target.value}))} placeholder="e.g. BCG, OPV, Pentavalent" className={inputCls}/>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="text-[10px] font-black uppercase text-(--text-muted) block mb-1">Dose Number *</label>
                                    <input required type="number" min="1" max="6" value={regForm.doseNumber} onChange={e => setRegForm(p=>({...p, doseNumber: e.target.value === '' ? '' : parseInt(e.target.value)}))} className={inputCls}/>
                                </div>
                                <div>
                                    <label className="text-[10px] font-black uppercase text-(--text-muted) block mb-1">Scheduled Date *</label>
                                    <input required type="date" value={regForm.scheduledDate} onChange={e => setRegForm(p=>({...p, scheduledDate: e.target.value}))} className={inputCls}/>
                                </div>
                            </div>
                            <div>
                                <label className="text-[10px] font-black uppercase text-(--text-muted) block mb-1">Batch Number (Optional)</label>
                                <input type="text" value={regForm.batchNumber} onChange={e => setRegForm(p=>({...p, batchNumber: e.target.value}))} placeholder="e.g. LOT-2024-001" className={inputCls}/>
                            </div>
                            <div>
                                <label className="text-[10px] font-black uppercase text-(--text-muted) block mb-1">Notes</label>
                                <textarea rows={3} value={regForm.notes} onChange={e => setRegForm(p=>({...p, notes: e.target.value}))} placeholder="Any observations or reactions..." className={inputCls + ' resize-none'}/>
                            </div>
                            <div className="flex gap-3 pt-2">
                                <Button type="button" onClick={() => setRegister(false)} variant="outline" className="flex-1 py-5 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="submit" disabled={registerVaccine.isPending} className="flex-1 py-5 rounded-xl bg-purple-600 hover:bg-purple-700 text-white font-bold">
                                    {registerVaccine.isPending ? 'Registering...' : 'Register'}
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* ADD NOTE MODAL */}
            {noteModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
                    <div className="bg-(--surface) rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden">
                        <div className="bg-blue-600 p-5 text-white flex justify-between items-center">
                            <h2 className="font-black text-lg flex items-center gap-2"><FileText size={18}/> Add Note — {noteModal.vaccineName}</h2>
                            <button onClick={() => setNoteModal(null)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={18}/></button>
                        </div>
                        <div className="p-5 space-y-4">
                            <textarea rows={4} value={noteText} onChange={e => setNoteText(e.target.value)} placeholder="Write your clinical note about this vaccine..." className={inputCls + ' resize-none'}/>
                            <div className="flex gap-3">
                                <Button type="button" onClick={() => setNoteModal(null)} variant="outline" className="flex-1 py-4 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button onClick={() => saveNote.mutate({ vacId: noteModal.id, notes: noteText })} disabled={saveNote.isPending} className="flex-1 py-4 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold">
                                    {saveNote.isPending ? 'Saving...' : 'Save Note'}
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* REMINDER MODAL (Parent) */}
            {reminder && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
                    <div className="bg-(--surface) rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden">
                        <div className="bg-amber-500 p-5 text-white flex justify-between items-center">
                            <h2 className="font-black text-lg flex items-center gap-2"><Bell size={18}/> Vaccination Reminder</h2>
                            <button onClick={() => setReminder(null)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={18}/></button>
                        </div>
                        <div className="p-5 space-y-4">
                            <div className="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 rounded-xl p-4">
                                <div className="font-black text-amber-700">{reminder.vaccineName} — Dose {reminder.doseNumber}</div>
                                <div className="text-sm text-amber-600 font-semibold mt-1">Due: {new Date(reminder.scheduledDate).toLocaleDateString()}</div>
                            </div>
                            <p className="text-sm text-(--text-secondary) font-medium">Set a reminder and book an appointment to get this vaccine on time.</p>
                            <div className="flex gap-3">
                                <Button onClick={() => setReminder(null)} variant="outline" className="flex-1 py-4 rounded-xl border-2 font-bold">Close</Button>
                                <Link to="/appointments" className="flex-1">
                                    <Button className="w-full py-4 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-bold flex items-center justify-center gap-2">
                                        <Calendar size={15}/> Book Now
                                    </Button>
                                </Link>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};
