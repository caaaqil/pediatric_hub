import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { api } from '../../lib/axios';
import { Card, CardHeader, CardTitle, CardContent } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Activity, Pill, ShieldAlert, FileText, Plus, User, Phone, Calendar, Baby, MapPin, Syringe, Clock, Users, Edit3, Trash2, HeartPulse } from 'lucide-react';
import useAuthStore from '../../store/authStore';

const RELATIONSHIP_OPTIONS = [
    { value: 'FATHER',         label: 'Father' },
    { value: 'MOTHER',         label: 'Mother' },
    { value: 'UNCLE',          label: 'Uncle' },
    { value: 'AUNT',           label: 'Aunt' },
    { value: 'MATERNAL_UNCLE', label: 'Maternal Uncle' },
    { value: 'MATERNAL_AUNT',  label: 'Maternal Aunt' },
    { value: 'GUARDIAN',       label: 'Guardian' },
    { value: 'OTHER',          label: 'Other' },
];

const relationshipLabel = (v) => RELATIONSHIP_OPTIONS.find(o => o.value === v)?.label || v;

const calcAge = (dob) => {
    if (!dob) return 'N/A';
    const d = new Date(dob);
    const now = new Date();
    const yrs = now.getFullYear() - d.getFullYear();
    const mos = now.getMonth() - d.getMonth();
    if (yrs === 0) return `${mos < 0 ? 0 : mos} month(s)`;
    return `${yrs} year${yrs !== 1 ? 's' : ''}`;
};

export const ChildProfile = () => {
    const { id } = useParams();
    const { user } = useAuthStore();
    const navigate = useNavigate();
    const queryClient = useQueryClient();

    const [modalConfig, setModalConfig] = useState({ isOpen: false, type: '' });
    const [formData, setFormData] = useState({});
    const [parentModal, setParentModal] = useState({ open: false, editing: null });
    const [parentForm, setParentForm] = useState({ fullName: '', phoneNumber: '', address: '', healthStatus: '', relationship: 'FATHER' });

    const closeModal = () => { setModalConfig({ isOpen: false, type: '' }); setFormData({}); };
    const closeParentModal = () => { setParentModal({ open: false, editing: null }); setParentForm({ fullName: '', phoneNumber: '', address: '', healthStatus: '', relationship: 'FATHER' }); };
    const openParentCreate = () => { setParentForm({ fullName: '', phoneNumber: '', address: '', healthStatus: '', relationship: 'FATHER' }); setParentModal({ open: true, editing: null }); };
    const openParentEdit = (p) => {
        setParentForm({
            fullName: p.fullName || '',
            phoneNumber: p.phoneNumber || '',
            address: p.address || '',
            healthStatus: p.healthStatus || '',
            relationship: p.relationship || 'FATHER',
        });
        setParentModal({ open: true, editing: p });
    };

    const { data, isLoading, isError } = useQuery({
        queryKey: ['childRecords', id],
        queryFn: async () => {
            const [baseline, consultations, childInfo, vaccines, appointments] = await Promise.all([
                api.get(`/health-records/child/${id}/baseline`),
                api.get(`/health-records/child/${id}/consultations`),
                api.get(`/children/${id}`).catch(() => ({ data: { data: null } })),
                api.get(`/vaccinations/child/${id}`).catch(() => ({ data: { data: [] } })),
                api.get(`/appointments/my-schedule`).catch(() => ({ data: { data: { appointments: [] } } })),
            ]);
            return {
                baseline: baseline.data.data,
                consultations: consultations.data.data,
                child: childInfo.data.data,
                vaccines: vaccines.data.data || [],
                appointments: (appointments.data.data?.appointments || []).filter(a => a.childId === id),
            };
        }
    });

    const { data: parentInfos = [], isLoading: parentsLoading } = useQuery({
        queryKey: ['parentInfo', id],
        queryFn: async () => {
            const r = await api.get('/parent-info', { params: { childId: id } });
            return r.data.data || [];
        },
        enabled: !!id,
    });

    const parentCreate = useMutation({
        mutationFn: async (payload) => await api.post('/parent-info', payload),
        onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['parentInfo', id] }); closeParentModal(); },
        onError: (err) => alert(err.response?.data?.errors?.[0]?.message || err.response?.data?.message || 'Failed to save'),
    });
    const parentUpdate = useMutation({
        mutationFn: async ({ pid, payload }) => await api.put(`/parent-info/${pid}`, payload),
        onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['parentInfo', id] }); closeParentModal(); },
        onError: (err) => alert(err.response?.data?.errors?.[0]?.message || err.response?.data?.message || 'Failed to update'),
    });
    const parentDelete = useMutation({
        mutationFn: async (pid) => await api.delete(`/parent-info/${pid}`),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['parentInfo', id] }),
        onError: (err) => alert(err.response?.data?.message || 'Failed to delete'),
    });

    const handleParentSubmit = (e) => {
        e.preventDefault();
        const payload = {
            fullName: parentForm.fullName.trim(),
            phoneNumber: parentForm.phoneNumber.trim(),
            address: parentForm.address.trim(),
            healthStatus: parentForm.healthStatus.trim() || null,
            relationship: parentForm.relationship,
        };
        if (parentModal.editing) {
            parentUpdate.mutate({ pid: parentModal.editing.id, payload });
        } else {
            parentCreate.mutate({ childId: id, ...payload });
        }
    };

    const submitRecord = useMutation({
        mutationFn: async ({ endpoint, payload }) => await api.post(endpoint, payload),
        onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['childRecords', id] }); closeModal(); },
        onError: (err) => alert('Failed: ' + (err.response?.data?.message || err.message))
    });

    const handleSubmit = (e) => {
        e.preventDefault();
        const payload = { childId: id, ...formData };
        let endpoint = '';
        if (modalConfig.type === 'allergy') endpoint = '/health-records/allergies';
        if (modalConfig.type === 'medication') { endpoint = '/health-records/medications'; payload.startDate = formData.startDate ? new Date(formData.startDate).toISOString() : new Date().toISOString(); }
        if (modalConfig.type === 'illness') { endpoint = '/health-records/illnesses'; payload.diagnosisDate = formData.diagnosisDate ? new Date(formData.diagnosisDate).toISOString() : new Date().toISOString(); }
        if (modalConfig.type === 'consultation') endpoint = '/health-records/consultations';
        submitRecord.mutate({ endpoint, payload });
    };

    if (isLoading) return <div className="p-8 flex items-center justify-center"><Activity className="animate-spin text-primary-600"/></div>;
    if (isError) return <div className="p-8 text-danger font-medium text-center">Failed to load medical records. Check your permissions.</div>;

    const { baseline, consultations, child, vaccines, appointments } = data;
    const isParent = user?.role === 'PARENT' || user?.role === 'ADMIN';
    const isDoctor = user?.role === 'DOCTOR';

    const doneVaccines    = (vaccines || []).filter(v => v.status === 'COMPLETED');
    const pendingVaccines = (vaccines || []).filter(v => ['UPCOMING','DUE'].includes(v.status));

    const inputCls = 'w-full bg-[--surface] text-[--text-primary] border-2 border-[--border] rounded-lg px-4 py-2.5 focus:outline-none focus:border-primary-500 text-sm font-bold';

    return (
        <div className="space-y-6 animate-fade-in relative">
            {/* Child Banner */}
            <div className="bg-gradient-to-r from-primary-600 to-indigo-700 rounded-xl p-6 text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl pointer-events-none"/>
                <div className="flex flex-col sm:flex-row items-start sm:items-center gap-5 relative z-10">
                    <div className="w-20 h-20 rounded-full overflow-hidden ring-4 ring-white/30 shrink-0">
                        <img
                            src={`https://api.dicebear.com/7.x/micah/svg?seed=${encodeURIComponent((child?.firstName || 'Child') + (child?.lastName || ''))}&backgroundColor=b6e3f4,ffd5dc,d1d4f9`}
                            alt={child?.firstName || 'Child'}
                            className="w-full h-full object-cover"
                            onError={e => { e.target.outerHTML = `<div class="w-20 h-20 rounded-full bg-indigo-800 flex items-center justify-center text-white font-black text-3xl">${(child?.firstName || 'C').charAt(0)}</div>`; }}
                        />
                    </div>
                    <div className="flex-1">
                        <h1 className="text-2xl font-black tracking-tight">{child?.firstName || 'Child'} {child?.lastName || ''}</h1>
                        <div className="flex flex-wrap gap-3 mt-2">
                            <span className="inline-flex items-center gap-1.5 bg-white/20 px-3 py-1 rounded-full text-sm font-bold">
                                <Baby size={14}/> Age: {calcAge(child?.dateOfBirth)}
                            </span>
                            {child?.gender && (
                                <span className="inline-flex items-center gap-1.5 bg-white/20 px-3 py-1 rounded-full text-sm font-bold">
                                    <User size={14}/> {child.gender}
                                </span>
                            )}
                            {child?.bloodType && (
                                <span className="inline-flex items-center gap-1.5 bg-red-400/40 px-3 py-1 rounded-full text-sm font-bold">
                                    {child.bloodType}
                                </span>
                            )}
                        </div>
                    </div>
                    <div className="flex gap-2 shrink-0">
                        <button onClick={() => navigate(`/child/${id}/vaccines`)} className="px-4 py-2 bg-white/20 hover:bg-white/30 rounded-xl text-sm font-black border border-white/30 transition-colors flex items-center gap-2">
                            <Syringe size={15}/> Vaccines
                        </button>
                        <button onClick={() => navigate(`/child/${id}/growth`)} className="px-4 py-2 bg-white/20 hover:bg-white/30 rounded-xl text-sm font-black border border-white/30 transition-colors flex items-center gap-2">
                            <Activity size={15}/> Growth
                        </button>
                    </div>
                </div>
            </div>

            {/* Child Info Section */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <Card>
                    <CardHeader className="bg-[--surface-soft] border-b border-[--border] pb-3">
                        <CardTitle className="flex items-center gap-2 text-md text-[--text-primary]"><Baby size={18} className="text-primary-500"/> Child's Information</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-5">
                        <div className="grid grid-cols-2 gap-3">
                            {[
                                { label: 'Full Name',     val: `${child?.firstName || ''} ${child?.lastName || ''}`.trim() || 'N/A' },
                                { label: 'Date of Birth', val: child?.dateOfBirth ? new Date(child.dateOfBirth).toLocaleDateString() : 'N/A' },
                                { label: 'Age',           val: calcAge(child?.dateOfBirth) },
                                { label: 'Gender',        val: child?.gender || 'N/A' },
                                { label: 'Blood Type',    val: child?.bloodType || 'N/A' },
                                { label: "Parent's Phone", val: child?.parent?.phoneNumber || child?.parentProfile?.phoneNumber || 'N/A' },
                            ].map(({ label, val }) => (
                                <div key={label} className="bg-[--surface-soft] p-3 rounded-xl border border-[--border]">
                                    <div className="text-[9px] font-black uppercase tracking-widest text-[--text-muted] mb-1">{label}</div>
                                    <div className="font-bold text-sm text-[--text-primary]">{val}</div>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>

                {/* Vaccination Summary */}
                <Card>
                    <CardHeader className="bg-[--surface-soft] border-b border-[--border] pb-3">
                        <CardTitle className="flex items-center gap-2 text-md text-[--text-primary]"><Syringe size={18} className="text-purple-500"/> Vaccination Summary</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-5 space-y-3">
                        <div className="grid grid-cols-3 gap-2">
                            <div className="bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 rounded-xl p-3 text-center">
                                <div className="text-2xl font-black text-emerald-600">{doneVaccines.length}</div>
                                <div className="text-[9px] font-black uppercase tracking-widest text-emerald-500 mt-0.5">Given</div>
                            </div>
                            <div className="bg-blue-50 dark:bg-blue-950/30 border border-blue-200 rounded-xl p-3 text-center">
                                <div className="text-2xl font-black text-blue-600">{pendingVaccines.length}</div>
                                <div className="text-[9px] font-black uppercase tracking-widest text-blue-500 mt-0.5">Remaining</div>
                            </div>
                            <div className="bg-red-50 dark:bg-red-950/30 border border-red-200 rounded-xl p-3 text-center">
                                <div className="text-2xl font-black text-red-600">{(vaccines||[]).filter(v=>v.status==='MISSED').length}</div>
                                <div className="text-[9px] font-black uppercase tracking-widest text-red-500 mt-0.5">Missed</div>
                            </div>
                        </div>
                        {pendingVaccines.slice(0,2).map(v => (
                            <div key={v.id} className="flex justify-between items-center p-2.5 rounded-lg bg-[--surface-soft] border border-[--border] text-sm">
                                <span className="font-bold text-[--text-primary]">{v.vaccineName}</span>
                                <span className="text-[10px] font-black text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full">{new Date(v.scheduledDate).toLocaleDateString()}</span>
                            </div>
                        ))}
                        <Link to={`/child/${id}/vaccines`} className="block text-center text-xs font-black text-primary-600 hover:underline pt-1">
                            View Full Vaccine Schedule →
                        </Link>
                    </CardContent>
                </Card>
            </div>

            {/* Parent Information */}
            <Card>
                <CardHeader className="bg-[--surface-soft] border-b border-[--border] flex flex-row items-center justify-between">
                    <CardTitle className="flex items-center gap-2 text-md text-[--text-primary]"><Users size={18} className="text-emerald-600"/> Parent Information</CardTitle>
                    {isParent && (
                        <Button onClick={openParentCreate} className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold py-2 px-3 rounded-lg flex items-center gap-2">
                            <Plus size={14}/> Add Parent
                        </Button>
                    )}
                </CardHeader>
                <CardContent className="pt-5">
                    {parentsLoading ? (
                        <p className="text-sm text-[--text-secondary] italic">Loading parent records...</p>
                    ) : parentInfos.length === 0 ? (
                        <p className="text-sm text-[--text-secondary] italic">No parent information linked yet.</p>
                    ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {parentInfos.map(p => (
                                <div key={p.id} className="border border-[--border] rounded-xl p-4 bg-[--surface-soft]">
                                    <div className="flex items-start justify-between gap-3 mb-2">
                                        <div>
                                            <div className="font-black text-[--text-primary] text-sm">{p.fullName}</div>
                                            <span className="inline-flex items-center gap-1 text-[10px] font-black uppercase tracking-widest bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full mt-1">
                                                {relationshipLabel(p.relationship)}
                                            </span>
                                        </div>
                                        {isParent && (
                                            <div className="flex gap-1 shrink-0">
                                                <button onClick={() => openParentEdit(p)} className="p-1.5 rounded hover:bg-emerald-50 text-emerald-600" title="Edit"><Edit3 size={14}/></button>
                                                <button onClick={() => { if (confirm('Delete this parent record?')) parentDelete.mutate(p.id); }} className="p-1.5 rounded hover:bg-red-50 text-red-600" title="Delete"><Trash2 size={14}/></button>
                                            </div>
                                        )}
                                    </div>
                                    <div className="text-xs text-[--text-secondary] font-medium space-y-1">
                                        <div className="flex items-center gap-1.5"><Phone size={12}/> {p.phoneNumber}</div>
                                        <div className="flex items-start gap-1.5"><MapPin size={12} className="mt-0.5"/> <span className="flex-1">{p.address}</span></div>
                                        {p.healthStatus && (
                                            <div className="flex items-start gap-1.5 pt-1 border-t border-[--border] mt-2"><HeartPulse size={12} className="mt-0.5 text-red-500"/> <span className="flex-1">{p.healthStatus}</span></div>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* Medical History */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {/* Allergies */}
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between pb-2 bg-[--surface-soft] border-b border-[--border]">
                        <CardTitle className="flex items-center gap-2 text-md text-[--text-primary]"><ShieldAlert size={18} className="text-danger"/> Allergies</CardTitle>
                        {isParent && <button onClick={() => setModalConfig({isOpen:true, type:'allergy'})} className="text-danger hover:bg-danger/10 p-1.5 rounded transition-colors"><Plus size={16}/></button>}
                    </CardHeader>
                    <CardContent className="pt-4">
                        {baseline.allergies.length === 0 ? <p className="text-sm text-[--text-secondary] italic">No known allergies</p> : (
                            <ul className="space-y-3">
                                {baseline.allergies.map(a => (
                                    <li key={a.id} className="border-b border-[--border] pb-2 last:border-0">
                                        <div className="font-medium text-[--text-primary]">{a.allergen} <span className={`text-[10px] font-black px-2 py-0.5 rounded-full uppercase ml-1 tracking-wider ${a.severity==='Severe'?'bg-red-100 text-red-700':a.severity==='Moderate'?'bg-amber-100 text-amber-700':'bg-green-100 text-green-700'}`}>{a.severity}</span></div>
                                        {a.notes && <p className="text-xs text-[--text-secondary] mt-1">{a.notes}</p>}
                                    </li>
                                ))}
                            </ul>
                        )}
                    </CardContent>
                </Card>

                {/* Medications / Prescriptions */}
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between pb-2 bg-[--surface-soft] border-b border-[--border]">
                        <CardTitle className="flex items-center gap-2 text-md text-[--text-primary]"><Pill size={18} className="text-primary-500"/> Medications</CardTitle>
                        {isParent && <button onClick={() => setModalConfig({isOpen:true, type:'medication'})} className="text-primary-500 hover:bg-primary-50 p-1.5 rounded transition-colors"><Plus size={16}/></button>}
                    </CardHeader>
                    <CardContent className="pt-4">
                        {baseline.medications.length === 0 ? <p className="text-sm text-[--text-secondary] italic">No active medications</p> : (
                            <ul className="space-y-3">
                                {baseline.medications.map(m => (
                                    <li key={m.id} className="border-b border-[--border] pb-2 last:border-0">
                                        <div className="font-bold text-[--text-primary]">{m.name}</div>
                                        <div className="text-xs font-semibold text-[--text-secondary] tracking-wide">{m.dosage}</div>
                                    </li>
                                ))}
                            </ul>
                        )}
                    </CardContent>
                </Card>

                {/* Past Illnesses */}
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between pb-2 bg-[--surface-soft] border-b border-[--border]">
                        <CardTitle className="flex items-center gap-2 text-md text-[--text-primary]"><Activity size={18} className="text-warning"/> Past Illnesses</CardTitle>
                        {isParent && <button onClick={() => setModalConfig({isOpen:true, type:'illness'})} className="text-warning hover:bg-warning/10 p-1.5 rounded transition-colors"><Plus size={16}/></button>}
                    </CardHeader>
                    <CardContent className="pt-4">
                        {baseline.illnesses.length === 0 ? <p className="text-sm text-[--text-secondary] italic">Clean history</p> : (
                            <ul className="space-y-3">
                                {baseline.illnesses.map(i => (
                                    <li key={i.id} className="flex flex-col border-b border-[--border] pb-2 last:border-0">
                                        <div className="flex justify-between items-center text-sm">
                                            <span className="font-bold text-[--text-primary]">{i.illnessName}</span>
                                            <span className="text-[--text-muted] font-bold uppercase tracking-widest text-[10px]">{new Date(i.diagnosisDate).toLocaleDateString()}</span>
                                        </div>
                                        {i.notes && <p className="text-xs text-[--text-secondary] mt-1">{i.notes}</p>}
                                    </li>
                                ))}
                            </ul>
                        )}
                    </CardContent>
                </Card>
            </div>

            {/* Previous Hospitals / Appointments */}
            <Card className="border-l-4 border-l-amber-500">
                <CardHeader className="bg-[--surface-soft] flex flex-row items-center justify-between">
                    <CardTitle className="flex items-center gap-2 text-[--text-primary]"><MapPin size={20} className="text-amber-500"/> Appointment History</CardTitle>
                </CardHeader>
                <CardContent className="pt-4">
                    {appointments.length === 0 ? (
                        <p className="text-[--text-secondary] italic text-sm">No past appointments recorded.</p>
                    ) : (
                        <div className="space-y-3">
                            {appointments.slice(0,5).map(a => (
                                <div key={a.id} className="flex items-center gap-4 p-3 rounded-xl bg-[--surface-soft] border border-[--border]">
                                    <div className="w-10 h-10 bg-amber-50 text-amber-600 rounded-xl flex items-center justify-center shrink-0"><Calendar size={18}/></div>
                                    <div className="flex-1 min-w-0">
                                        <div className="font-bold text-[--text-primary] text-sm">Dr. {a.doctor?.firstName} {a.doctor?.lastName}</div>
                                        <div className="text-xs text-[--text-secondary] font-medium mt-0.5">{a.reason || 'General Consultation'}</div>
                                    </div>
                                    <div className="text-right shrink-0">
                                        <div className="text-xs font-bold text-[--text-muted]">{new Date(a.scheduledAt).toLocaleDateString()}</div>
                                        <span className={`text-[9px] font-black uppercase tracking-widest px-2 py-0.5 rounded-full ${a.status==='COMPLETED'?'bg-emerald-100 text-emerald-700':a.status==='CONFIRMED'?'bg-blue-100 text-blue-700':'bg-amber-100 text-amber-700'}`}>{a.status}</span>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* Doctor Consultation Notes */}
            <Card className="mt-2 border-l-4 border-l-primary-600 shadow-md">
                <CardHeader className="bg-[--surface-soft] flex flex-row items-center justify-between">
                    <CardTitle className="flex items-center gap-2 text-[--text-primary]"><FileText size={20} className="text-primary-600"/> Doctor's Notes & Prescriptions</CardTitle>
                    {isDoctor && (
                        <Button onClick={() => setModalConfig({isOpen:true, type:'consultation'})} className="bg-primary-600 hover:bg-primary-700 flex gap-2">
                            <Plus size={16}/> Log Note
                        </Button>
                    )}
                </CardHeader>
                <CardContent className="pt-6">
                    {consultations.length === 0 ? (
                        <p className="text-[--text-secondary] italic text-sm">No formal doctor notes recorded yet.</p>
                    ) : (
                        <div className="space-y-6">
                            {consultations.map(note => (
                                <div key={note.id} className="bg-[--surface] p-5 rounded-xl border border-[--border] shadow-sm hover:border-primary-300 transition-colors">
                                    <div className="flex justify-between items-start mb-4 border-b border-[--border] pb-3">
                                        <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 rounded-full overflow-hidden ring-2 ring-primary-100">
                                                <img src={`https://api.dicebear.com/7.x/personas/svg?seed=${encodeURIComponent(note.doctor?.lastName || 'Doctor')}&backgroundColor=b6e3f4`} alt="" className="w-full h-full object-cover" onError={e=>{e.target.outerHTML=`<div class="w-10 h-10 rounded-full bg-primary-600 flex items-center justify-center text-white font-black">${note.doctor?.lastName?.charAt(0)||'D'}</div>`;}}/>
                                            </div>
                                            <div>
                                                <div className="font-black text-[--text-primary]">Dr. {note.doctor?.lastName}</div>
                                                <div className="text-xs font-black tracking-widest uppercase text-primary-500">{note.doctor?.specialization}</div>
                                            </div>
                                        </div>
                                        <div className="text-[10px] font-black uppercase tracking-widest text-[--text-muted] bg-[--surface-soft] px-3 py-1.5 rounded-lg border border-[--border]">
                                            <Clock size={10} className="inline mr-1"/>{new Date(note.createdAt).toLocaleString()}
                                        </div>
                                    </div>
                                    <p className="text-sm text-[--text-primary] whitespace-pre-wrap leading-relaxed">{note.notes}</p>
                                    {note.treatmentPlan && (
                                        <div className="mt-5 pt-4 border-t border-dashed border-[--border]">
                                            <div className="text-[10px] font-black tracking-widest text-teal uppercase mb-2 flex items-center gap-2"><Pill size={12}/> Treatment Protocol</div>
                                            <p className="text-sm text-[--text-primary] bg-teal/10 p-4 rounded-lg border border-teal/20">{note.treatmentPlan}</p>
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* Parent Info Modal */}
            {parentModal.open && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm animate-fade-in">
                    <div className="bg-[--surface] rounded-xl shadow-xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
                        <div className="p-6 border-b border-[--border] flex justify-between items-center bg-gradient-to-r from-emerald-600 to-teal-700 text-white">
                            <h2 className="text-xl font-black flex items-center gap-2"><Users size={20}/> {parentModal.editing ? 'Edit Parent Information' : 'Add Parent Information'}</h2>
                            <button onClick={closeParentModal} className="hover:bg-white/20 p-1.5 rounded-lg">✕</button>
                        </div>
                        <form onSubmit={handleParentSubmit} className="p-6 space-y-4 overflow-y-auto">
                            <div>
                                <label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Parent Full Name *</label>
                                <input required minLength={2} type="text" value={parentForm.fullName} onChange={e => setParentForm(p => ({ ...p, fullName: e.target.value }))} placeholder="e.g. Cabdiraxmaan Maxamed" className={inputCls}/>
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Phone Number *</label>
                                <input required minLength={5} type="tel" value={parentForm.phoneNumber} onChange={e => setParentForm(p => ({ ...p, phoneNumber: e.target.value }))} placeholder="+252 612 345 678" className={inputCls}/>
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Address / Residential Location *</label>
                                <input required minLength={2} type="text" value={parentForm.address} onChange={e => setParentForm(p => ({ ...p, address: e.target.value }))} placeholder="Mogadishu, Hodan District" className={inputCls}/>
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Health Status (Optional)</label>
                                <textarea value={parentForm.healthStatus} onChange={e => setParentForm(p => ({ ...p, healthStatus: e.target.value }))} rows="2" placeholder="Any known medical condition or illness" className={inputCls}></textarea>
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Relationship to Child *</label>
                                <select required value={parentForm.relationship} onChange={e => setParentForm(p => ({ ...p, relationship: e.target.value }))} className={inputCls}>
                                    {RELATIONSHIP_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                                </select>
                            </div>
                            <div className="pt-2 flex gap-3">
                                <Button type="button" onClick={closeParentModal} variant="secondary" className="flex-1 font-bold py-5 rounded-xl">Cancel</Button>
                                <Button type="submit" isLoading={parentCreate.isPending || parentUpdate.isPending} className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-5 rounded-xl">
                                    {parentModal.editing ? 'Save Changes' : 'Save Parent'}
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Modals */}
            {modalConfig.isOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-fade-in">
                    <div className="bg-[--surface] rounded-xl shadow-xl w-full max-w-lg overflow-hidden flex flex-col">
                        <div className="p-6 border-b border-[--border] flex justify-between items-center bg-[--surface-soft]">
                            <h2 className="text-xl font-bold text-[--text-primary] capitalize">Add {modalConfig.type}</h2>
                            <button onClick={closeModal} className="text-[--text-muted] hover:text-danger font-bold transition-colors">✕</button>
                        </div>
                        <form onSubmit={handleSubmit} className="p-6 space-y-4">
                            {modalConfig.type === 'allergy' && (<>
                                <div><label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Allergen</label><input required type="text" value={formData.allergen || ''} onChange={e => setFormData({...formData, allergen: e.target.value})} className={inputCls}/></div>
                                <div><label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Severity</label>
                                    <select value={formData.severity || ''} onChange={e => setFormData({...formData, severity: e.target.value})} className={inputCls}>
                                        <option value="">Select</option><option>Mild</option><option>Moderate</option><option>Severe</option>
                                    </select>
                                </div>
                            </>)}
                            {modalConfig.type === 'medication' && (<>
                                <div><label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Medication Name</label><input required type="text" value={formData.name || ''} onChange={e => setFormData({...formData, name: e.target.value})} className={inputCls}/></div>
                                <div><label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Dosage Details</label><input required type="text" value={formData.dosage || ''} onChange={e => setFormData({...formData, dosage: e.target.value})} placeholder="e.g. 5ml twice daily" className={inputCls}/></div>
                            </>)}
                            {modalConfig.type === 'illness' && (<>
                                <div><label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Illness Name</label><input required type="text" value={formData.illnessName || ''} onChange={e => setFormData({...formData, illnessName: e.target.value})} className={inputCls}/></div>
                                <div><label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Date Diagnosed</label><input required type="date" value={formData.diagnosisDate || ''} onChange={e => setFormData({...formData, diagnosisDate: e.target.value})} className={inputCls}/></div>
                            </>)}
                            {(modalConfig.type === 'allergy' || modalConfig.type === 'illness' || modalConfig.type === 'consultation') && (
                                <div><label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">{modalConfig.type === 'consultation' ? 'Notes (Required)' : 'Additional Notes (Optional)'}</label>
                                    <textarea required={modalConfig.type === 'consultation'} value={formData.notes || ''} onChange={e => setFormData({...formData, notes: e.target.value})} rows="4" className={inputCls}></textarea>
                                </div>
                            )}
                            {modalConfig.type === 'consultation' && (
                                <div><label className="block text-xs font-bold text-[--text-secondary] uppercase tracking-wide mb-1">Treatment Plan (Optional)</label>
                                    <textarea value={formData.treatmentPlan || ''} onChange={e => setFormData({...formData, treatmentPlan: e.target.value})} rows="3" className={inputCls + ' border-teal/30 bg-teal/5'}></textarea>
                                </div>
                            )}
                            <div className="pt-4 flex gap-3">
                                <Button type="button" onClick={closeModal} variant="secondary" className="flex-1 font-bold py-5 rounded-xl">Discard</Button>
                                <Button type="submit" isLoading={submitRecord.isPending} className="flex-1 bg-primary-600 hover:bg-primary-700 text-white font-bold py-5 rounded-xl">Submit</Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};
