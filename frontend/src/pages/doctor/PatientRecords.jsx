import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import { HeartPulse, FolderOpen, Activity, Syringe, Search, Pill, FileText, Award, Plus, X, Clock, Calendar, User, Phone } from 'lucide-react';
import { Card, CardContent } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';

const calcAge = (dob) => {
    if (!dob) return 'N/A';
    const d = new Date(dob);
    const now = new Date();
    const yrs = now.getFullYear() - d.getFullYear();
    const mos = now.getMonth() - d.getMonth();
    if (yrs === 0) return `${mos < 0 ? 0 : mos} mo`;
    return `${yrs} yr${yrs !== 1 ? 's' : ''}`;
};

export const PatientRecords = () => {
    const navigate = useNavigate();
    const queryClient = useQueryClient();
    const [searchQuery, setSearchQuery]     = useState('');
    const [selectedPatient, setSelected]    = useState(null);
    const [prescModal, setPrescModal]        = useState(false);
    const [certModal, setCertModal]          = useState(false);
    const [noteModal, setNoteModal]          = useState(false);
    const [prescForm, setPrescForm]          = useState({ medicationName: '', instructions: '', duration: '' });
    const [noteText, setNoteText]            = useState('');
    const [certType, setCertType]            = useState('Health Certificate');

    const { data: patients, isLoading } = useQuery({
        queryKey: ['doctorPatients'],
        queryFn: async () => {
            const res = await api.get('/children');
            return res.data.data || [];
        }
    });

    const { data: patientDetail } = useQuery({
        queryKey: ['patientDetail', selectedPatient?.id],
        queryFn: async () => {
            if (!selectedPatient?.id) return null;
            const [baseline, vaccines] = await Promise.all([
                api.get(`/health-records/child/${selectedPatient.id}/baseline`),
                api.get(`/vaccinations/child/${selectedPatient.id}`)
            ]);
            return { baseline: baseline.data.data, vaccines: vaccines.data.data };
        },
        enabled: !!selectedPatient?.id
    });

    const logConsultation = useMutation({
        mutationFn: async ({ childId, notes }) =>
            api.post('/health-records/consultations', { childId, notes }),
        onSuccess: () => { queryClient.invalidateQueries(['patientDetail', selectedPatient?.id]); setNoteModal(false); setNoteText(''); }
    });

    const addMedication = useMutation({
        mutationFn: async (data) => api.post('/health-records/medications', { ...data, startDate: new Date().toISOString() }),
        onSuccess: () => {
            queryClient.invalidateQueries(['patientDetail', selectedPatient?.id]);
            setPrescModal(false);
            setPrescForm({ medicationName: '', instructions: '', duration: '' });
            alert('Prescription issued successfully!');
        },
        onError: (err) => alert('Failed to issue prescription: ' + (err.response?.data?.message || err.message))
    });

    const markVaccine = useMutation({
        mutationFn: async (vacId) => api.patch(`/vaccinations/${vacId}/status`, { status: 'COMPLETED' }),
        onSuccess: () => queryClient.invalidateQueries(['patientDetail', selectedPatient?.id])
    });

    const displayed = (patients || []).filter(p =>
        `${p.firstName} ${p.lastName}`.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const printCertificate = () => {
        const p = selectedPatient;
        const html = `
            <html><head><title>${certType}</title><style>
                body{font-family:Arial,sans-serif;padding:40px;max-width:700px;margin:auto}
                h1{color:#2563eb;border-bottom:3px solid #2563eb;padding-bottom:10px}
                .field{margin:12px 0}.label{font-weight:bold;color:#555;font-size:12px;text-transform:uppercase;letter-spacing:1px}
                .value{font-size:16px;margin-top:4px}.sig{margin-top:60px;border-top:1px solid #ccc;padding-top:10px;font-size:13px;color:#888}
            </style></head><body>
                <h1>Pediatric Health Hub</h1>
                <h2>${certType}</h2>
                <div class="field"><div class="label">Patient Name</div><div class="value">${p.firstName} ${p.lastName}</div></div>
                <div class="field"><div class="label">Date of Birth</div><div class="value">${new Date(p.dateOfBirth).toLocaleDateString()}</div></div>
                <div class="field"><div class="label">Age</div><div class="value">${calcAge(p.dateOfBirth)}</div></div>
                <div class="field"><div class="label">Blood Type</div><div class="value">${p.bloodType || 'Not recorded'}</div></div>
                <div class="field"><div class="label">Date Issued</div><div class="value">${new Date().toLocaleDateString()}</div></div>
                <p style="margin-top:30px;line-height:1.8">This certificate is issued by Pediatric Health Hub certifying that the above-named patient has been examined and their health records are maintained in our system.</p>
                <div class="sig">Dr. [Physician Name] &nbsp;&nbsp;|&nbsp;&nbsp; Pediatric Health Hub &nbsp;&nbsp;|&nbsp;&nbsp; ${new Date().toLocaleDateString()}</div>
            </body></html>`;
        const w = window.open('', '_blank');
        w.document.write(html);
        w.document.close();
        w.print();
        setCertModal(false);
    };

    const inputCls = 'w-full bg-[--surface] text-[--text-primary] border-2 border-[--border] rounded-xl px-4 py-2.5 focus:outline-none focus:border-teal-500 text-sm font-semibold';

    return (
        <div className="w-full space-y-6 animate-fade-in font-sans">
            {/* Hero */}
            <div className="bg-gradient-to-r from-teal-600 to-emerald-700 rounded-xl shadow-sm p-8 text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 w-72 h-72 bg-white/5 rounded-full blur-3xl pointer-events-none"/>
                <div className="relative z-10">
                    <h1 className="text-3xl font-black tracking-tight mb-1 flex items-center gap-3">
                        <HeartPulse size={28} className="text-teal-200"/> Patient Clinical Records
                    </h1>
                    <p className="text-white/80 font-medium">Full longitudinal health records, prescriptions, vaccinations, notes and certificates.</p>
                </div>
            </div>

            {/* Search */}
            <div className="relative max-w-md">
                <Search size={16} className="absolute left-3.5 top-3 text-[--text-muted]"/>
                <input type="text" value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
                    placeholder="Search patients by name..."
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl border-2 border-[--border] bg-[--surface] text-[--text-primary] text-sm focus:outline-none focus:border-teal-500"/>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {isLoading ? (
                    <div className="col-span-3 p-12 text-center text-[--text-muted] font-bold uppercase tracking-widest animate-pulse">Loading Patients...</div>
                ) : displayed.map((patient) => (
                    <Card key={patient.id} className="border-[--border] group hover:shadow-lg hover:-translate-y-0.5 transition-all duration-200">
                        <CardContent className="p-6">
                            {/* Patient Avatar + Info */}
                            <div className="flex items-center gap-4 mb-5">
                                <div className="w-14 h-14 rounded-full overflow-hidden ring-2 ring-teal-100 shrink-0">
                                    <img
                                        src={`https://api.dicebear.com/7.x/micah/svg?seed=${encodeURIComponent(patient.firstName + patient.lastName)}&backgroundColor=b6e3f4,ffd5dc,d1d4f9`}
                                        alt={patient.firstName}
                                        className="w-full h-full object-cover"
                                        onError={e => { e.target.outerHTML = `<div class="w-14 h-14 rounded-full bg-teal-500 flex items-center justify-center text-white font-black text-xl">${patient.firstName?.charAt(0)}</div>`; }}
                                    />
                                </div>
                                <div className="flex-1 min-w-0">
                                    <h3 className="font-black text-[--text-primary] text-lg leading-tight truncate">{patient.firstName} {patient.lastName}</h3>
                                    <div className="flex items-center gap-2 mt-1 flex-wrap">
                                        <span className="text-[10px] font-black bg-teal-50 text-teal-700 border border-teal-200 px-2 py-0.5 rounded-full uppercase tracking-widest">
                                            Age: {calcAge(patient.dateOfBirth)}
                                        </span>
                                        {patient.bloodType && (
                                            <span className="text-[10px] font-black bg-red-50 text-red-600 border border-red-200 px-2 py-0.5 rounded-full uppercase tracking-widest">
                                                {patient.bloodType}
                                            </span>
                                        )}
                                    </div>
                                </div>
                            </div>

                            {/* Child Info Grid */}
                            <div className="grid grid-cols-2 gap-2 mb-5">
                                <div className="bg-[--surface-soft] rounded-lg p-3 border border-[--border]">
                                    <div className="text-[9px] font-black uppercase text-[--text-muted] tracking-widest mb-1 flex items-center gap-1"><Calendar size={9}/> D.O.B</div>
                                    <div className="font-bold text-[--text-primary] text-xs">{new Date(patient.dateOfBirth).toLocaleDateString()}</div>
                                </div>
                                <div className="bg-[--surface-soft] rounded-lg p-3 border border-[--border]">
                                    <div className="text-[9px] font-black uppercase text-[--text-muted] tracking-widest mb-1 flex items-center gap-1"><User size={9}/> Gender</div>
                                    <div className="font-bold text-[--text-primary] text-xs capitalize">{patient.gender || 'N/A'}</div>
                                </div>
                            </div>

                            {/* Quick Actions */}
                            <div className="grid grid-cols-4 gap-1.5 border-t border-[--border] pt-4">
                                <ActionBtn icon={<FolderOpen size={15}/>} label="History" color="teal" onClick={() => navigate(`/child/${patient.id}`)}/>
                                <ActionBtn icon={<Activity size={15}/>}   label="Growth"  color="blue" onClick={() => navigate(`/child/${patient.id}/growth`)}/>
                                <ActionBtn icon={<Syringe size={15}/>}    label="Vaccines" color="purple" onClick={() => navigate(`/child/${patient.id}/vaccines`)}/>
                                <ActionBtn icon={<HeartPulse size={15}/>} label="Detail"  color="emerald" onClick={() => setSelected(patient)}/>
                            </div>
                        </CardContent>
                    </Card>
                ))}
                {!isLoading && displayed.length === 0 && (
                    <div className="col-span-3 p-12 text-center border-2 border-dashed border-[--border] rounded-xl">
                        <HeartPulse size={32} className="mx-auto text-slate-300 mb-3"/>
                        <p className="font-bold text-[--text-secondary]">No patients found</p>
                    </div>
                )}
            </div>

            {/* Patient Detail Side Panel */}
            {selectedPatient && (
                <div className="fixed inset-0 z-[100] flex justify-end bg-slate-900/50 backdrop-blur-sm animate-fade-in">
                    <div className="w-full max-w-2xl bg-[--surface] h-full overflow-y-auto shadow-2xl flex flex-col">
                        {/* Panel Header */}
                        <div className="bg-gradient-to-r from-teal-600 to-emerald-700 p-6 text-white sticky top-0 z-10">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-4">
                                    <div className="w-14 h-14 rounded-full overflow-hidden ring-4 ring-white/30">
                                        <img src={`https://api.dicebear.com/7.x/micah/svg?seed=${encodeURIComponent(selectedPatient.firstName+selectedPatient.lastName)}&backgroundColor=b6e3f4`} alt="" className="w-full h-full object-cover" onError={e=>{e.target.outerHTML=`<div class="w-14 h-14 rounded-full bg-teal-800 flex items-center justify-center text-white font-black text-xl">${selectedPatient.firstName?.charAt(0)}</div>`;}}/>
                                    </div>
                                    <div>
                                        <h2 className="text-xl font-black">{selectedPatient.firstName} {selectedPatient.lastName}</h2>
                                        <p className="text-teal-200 text-sm">Age: {calcAge(selectedPatient.dateOfBirth)} · DOB: {new Date(selectedPatient.dateOfBirth).toLocaleDateString()}</p>
                                    </div>
                                </div>
                                <button onClick={() => setSelected(null)} className="hover:bg-white/20 p-2 rounded-xl transition-colors"><X size={20}/></button>
                            </div>
                        </div>

                        <div className="flex-1 p-6 space-y-6">
                            {/* Doctor Actions */}
                            <div>
                                <h3 className="text-[10px] font-black uppercase tracking-widest text-[--text-muted] mb-3">Doctor Actions</h3>
                                <div className="grid grid-cols-2 gap-3">
                                    <button onClick={() => setPrescModal(true)} className="flex items-center gap-3 p-4 bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-900 rounded-xl hover:bg-blue-100 transition-colors text-left">
                                        <Pill size={20} className="text-blue-600 shrink-0"/>
                                        <div><div className="font-black text-blue-700 text-sm">Prescribe Medication</div><div className="text-[10px] text-blue-500 font-semibold">Issue prescription</div></div>
                                    </button>
                                    <button onClick={() => setNoteModal(true)} className="flex items-center gap-3 p-4 bg-teal-50 dark:bg-teal-950/40 border border-teal-200 dark:border-teal-900 rounded-xl hover:bg-teal-100 transition-colors text-left">
                                        <FileText size={20} className="text-teal-600 shrink-0"/>
                                        <div><div className="font-black text-teal-700 text-sm">Write Notes</div><div className="text-[10px] text-teal-500 font-semibold">Consultation notes</div></div>
                                    </button>
                                    <button onClick={() => navigate(`/child/${selectedPatient.id}/vaccines`)} className="flex items-center gap-3 p-4 bg-purple-50 dark:bg-purple-950/40 border border-purple-200 dark:border-purple-900 rounded-xl hover:bg-purple-100 transition-colors text-left">
                                        <Syringe size={20} className="text-purple-600 shrink-0"/>
                                        <div><div className="font-black text-purple-700 text-sm">Vaccination Schedule</div><div className="text-[10px] text-purple-500 font-semibold">View & confirm vaccines</div></div>
                                    </button>
                                    <button onClick={() => setCertModal(true)} className="flex items-center gap-3 p-4 bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900 rounded-xl hover:bg-amber-100 transition-colors text-left">
                                        <Award size={20} className="text-amber-600 shrink-0"/>
                                        <div><div className="font-black text-amber-700 text-sm">Issue Certificate</div><div className="text-[10px] text-amber-500 font-semibold">Health / fit-to-school</div></div>
                                    </button>
                                </div>
                            </div>

                            {/* Child Info */}
                            <Section title="Child's Information" icon={<User size={14}/>}>
                                <InfoGrid items={[
                                    { label: 'Full Name',   val: `${selectedPatient.firstName} ${selectedPatient.lastName}` },
                                    { label: 'Age',         val: calcAge(selectedPatient.dateOfBirth) },
                                    { label: 'Date of Birth', val: new Date(selectedPatient.dateOfBirth).toLocaleDateString() },
                                    { label: 'Gender',      val: selectedPatient.gender || 'N/A' },
                                    { label: 'Blood Type',  val: selectedPatient.bloodType || 'N/A' },
                                    { label: 'Patient ID',  val: selectedPatient.id?.slice(0, 8) + '...' },
                                ]}/>
                            </Section>

                            {/* Allergies */}
                            {patientDetail && (
                                <Section title="Allergies" icon={<HeartPulse size={14}/>}>
                                    {patientDetail.baseline.allergies.length === 0 ? (
                                        <p className="text-sm text-[--text-muted] italic">No known allergies recorded.</p>
                                    ) : patientDetail.baseline.allergies.map(a => (
                                        <div key={a.id} className="flex items-center justify-between py-2 border-b border-[--border] last:border-0">
                                            <span className="font-semibold text-sm text-[--text-primary]">{a.allergen}</span>
                                            <span className={`text-[10px] font-black px-2 py-0.5 rounded-full uppercase tracking-widest ${a.severity === 'Severe' ? 'bg-red-100 text-red-700' : a.severity === 'Moderate' ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'}`}>{a.severity}</span>
                                        </div>
                                    ))}
                                </Section>
                            )}

                            {/* Medical History / Past Illnesses */}
                            {patientDetail && (
                                <Section title="Medical History / Past Illnesses" icon={<Activity size={14}/>}>
                                    {patientDetail.baseline.illnesses.length === 0 ? (
                                        <p className="text-sm text-[--text-muted] italic">Clean history — no past illnesses recorded.</p>
                                    ) : patientDetail.baseline.illnesses.map(i => (
                                        <div key={i.id} className="flex items-center justify-between py-2 border-b border-[--border] last:border-0">
                                            <div>
                                                <div className="font-bold text-sm text-[--text-primary]">{i.illnessName}</div>
                                                {i.notes && <div className="text-xs text-[--text-secondary] mt-0.5">{i.notes}</div>}
                                            </div>
                                            <span className="text-[10px] font-bold text-[--text-muted] uppercase tracking-widest">{new Date(i.diagnosisDate).toLocaleDateString()}</span>
                                        </div>
                                    ))}
                                </Section>
                            )}

                            {/* Current Medications (Prescriptions) */}
                            {patientDetail && (
                                <Section title="Prescriptions / Medications" icon={<Pill size={14}/>}>
                                    {patientDetail.baseline.medications.length === 0 ? (
                                        <p className="text-sm text-[--text-muted] italic">No active medications.</p>
                                    ) : patientDetail.baseline.medications.map(m => (
                                        <div key={m.id} className="py-2 border-b border-[--border] last:border-0">
                                            <div className="font-bold text-sm text-[--text-primary]">{m.name}</div>
                                            <div className="text-xs text-[--text-secondary] mt-0.5">{m.dosage}</div>
                                        </div>
                                    ))}
                                    <button onClick={() => setPrescModal(true)} className="mt-3 w-full flex items-center justify-center gap-2 py-2 border-2 border-dashed border-blue-300 rounded-xl text-blue-600 text-xs font-black uppercase hover:bg-blue-50 transition-colors">
                                        <Plus size={13}/> Add Prescription
                                    </button>
                                </Section>
                            )}

                            {/* Vaccination Summary */}
                            {patientDetail && (
                                <Section title="Vaccination Status" icon={<Syringe size={14}/>}>
                                    <div className="grid grid-cols-3 gap-3 mb-3">
                                        {['COMPLETED','UPCOMING','MISSED'].map(s => (
                                            <div key={s} className={`rounded-xl p-3 text-center border ${s==='COMPLETED'?'bg-emerald-50 border-emerald-200 text-emerald-700':s==='UPCOMING'?'bg-blue-50 border-blue-200 text-blue-700':'bg-red-50 border-red-200 text-red-700'}`}>
                                                <div className="text-xl font-black">{(patientDetail.vaccines||[]).filter(v=>v.status===s).length}</div>
                                                <div className="text-[9px] font-black uppercase tracking-widest mt-0.5">{s}</div>
                                            </div>
                                        ))}
                                    </div>
                                    <button onClick={() => navigate(`/child/${selectedPatient.id}/vaccines`)} className="w-full py-2 border border-[--border] rounded-xl text-xs font-black uppercase text-[--text-muted] hover:text-purple-600 hover:border-purple-300 transition-colors">
                                        View Full Schedule →
                                    </button>
                                </Section>
                            )}
                        </div>
                    </div>
                </div>
            )}

            {/* PRESCRIBE MODAL */}
            {prescModal && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center bg-slate-900/70 backdrop-blur-sm p-4">
                    <div className="bg-[--surface] rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
                        <div className="bg-blue-600 p-5 text-white flex justify-between items-center">
                            <h2 className="font-black text-lg flex items-center gap-2"><Pill size={20}/> Issue Prescription</h2>
                            <button onClick={() => setPrescModal(false)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={18}/></button>
                        </div>
                        <form onSubmit={e => { e.preventDefault(); addMedication.mutate({ childId: selectedPatient?.id, name: prescForm.medicationName, dosage: `${prescForm.instructions} · Duration: ${prescForm.duration}` }); }} className="p-6 space-y-4">
                            <div>
                                <label className="text-[10px] font-black uppercase text-[--text-muted] block mb-1">Medication Name *</label>
                                <input required type="text" value={prescForm.medicationName} onChange={e => setPrescForm(p => ({ ...p, medicationName: e.target.value }))} placeholder="e.g. Amoxicillin 250mg" className={inputCls}/>
                            </div>
                            <div>
                                <label className="text-[10px] font-black uppercase text-[--text-muted] block mb-1">Instructions (How to Use) *</label>
                                <textarea required rows={3} value={prescForm.instructions} onChange={e => setPrescForm(p => ({ ...p, instructions: e.target.value }))} placeholder="e.g. 5ml twice daily, after meals" className={inputCls + ' resize-none'}/>
                            </div>
                            <div>
                                <label className="text-[10px] font-black uppercase text-[--text-muted] block mb-1">Duration *</label>
                                <input required type="text" value={prescForm.duration} onChange={e => setPrescForm(p => ({ ...p, duration: e.target.value }))} placeholder="e.g. 7 days" className={inputCls}/>
                            </div>
                            <div className="flex gap-3 pt-2">
                                <Button type="button" onClick={() => setPrescModal(false)} variant="outline" className="flex-1 py-5 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="submit" disabled={addMedication.isPending} className="flex-1 py-5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold">
                                    {addMedication.isPending ? 'Saving...' : 'Issue Prescription'}
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* WRITE NOTES MODAL */}
            {noteModal && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center bg-slate-900/70 backdrop-blur-sm p-4">
                    <div className="bg-[--surface] rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
                        <div className="bg-teal-600 p-5 text-white flex justify-between items-center">
                            <h2 className="font-black text-lg flex items-center gap-2"><FileText size={20}/> Write Consultation Notes</h2>
                            <button onClick={() => setNoteModal(false)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={18}/></button>
                        </div>
                        <form onSubmit={e => { e.preventDefault(); logConsultation.mutate({ childId: selectedPatient?.id, notes: noteText }); }} className="p-6 space-y-4">
                            <div>
                                <label className="text-[10px] font-black uppercase text-[--text-muted] block mb-1">Notes *</label>
                                <textarea required rows={5} value={noteText} onChange={e => setNoteText(e.target.value)} placeholder="Write your clinical observations, diagnosis, and follow-up plan..." className={inputCls + ' resize-none'}/>
                            </div>
                            <div className="flex gap-3 pt-1">
                                <Button type="button" onClick={() => setNoteModal(false)} variant="outline" className="flex-1 py-5 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="submit" disabled={logConsultation.isPending} className="flex-1 py-5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white font-bold">
                                    {logConsultation.isPending ? 'Saving...' : 'Save Notes'}
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* CERTIFICATE MODAL */}
            {certModal && (
                <div className="fixed inset-0 z-[200] flex items-center justify-center bg-slate-900/70 backdrop-blur-sm p-4">
                    <div className="bg-[--surface] rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden">
                        <div className="bg-amber-500 p-5 text-white flex justify-between items-center">
                            <h2 className="font-black text-lg flex items-center gap-2"><Award size={20}/> Issue Certificate</h2>
                            <button onClick={() => setCertModal(false)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={18}/></button>
                        </div>
                        <div className="p-6 space-y-4">
                            <div>
                                <label className="text-[10px] font-black uppercase text-[--text-muted] block mb-2">Certificate Type</label>
                                <div className="space-y-2">
                                    {['Health Certificate','Fit-to-School Certificate','Vaccination Certificate','Medical Clearance'].map(t => (
                                        <button key={t} type="button" onClick={() => setCertType(t)}
                                            className={`w-full text-left px-4 py-2.5 rounded-xl border-2 text-sm font-bold transition-all ${certType === t ? 'border-amber-500 bg-amber-50 text-amber-700' : 'border-[--border] text-[--text-secondary] hover:border-amber-300'}`}>
                                            {t}
                                        </button>
                                    ))}
                                </div>
                            </div>
                            <div className="flex gap-3 pt-2">
                                <Button type="button" onClick={() => setCertModal(false)} variant="outline" className="flex-1 py-4 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="button" onClick={printCertificate} className="flex-1 py-4 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-bold">
                                    Print / Download
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

const ActionBtn = ({ icon, label, color, onClick }) => {
    const colors = { teal: 'text-teal-600 hover:bg-teal-50 hover:text-teal-700', blue: 'text-blue-500 hover:bg-blue-50 hover:text-blue-700', purple: 'text-purple-500 hover:bg-purple-50 hover:text-purple-700', emerald: 'text-emerald-600 hover:bg-emerald-50 hover:text-emerald-700' };
    return (
        <button type="button" onClick={onClick} className={`flex flex-col items-center justify-center py-2.5 rounded-xl transition-colors cursor-pointer ${colors[color]}`}>
            {icon}
            <span className="text-[9px] font-black uppercase tracking-widest mt-1">{label}</span>
        </button>
    );
};

const Section = ({ title, icon, children }) => (
    <div className="bg-[--surface-soft] rounded-xl border border-[--border] overflow-hidden">
        <div className="flex items-center gap-2 px-4 py-3 bg-[--surface] border-b border-[--border]">
            <span className="text-teal-500">{icon}</span>
            <h4 className="text-[11px] font-black uppercase tracking-widest text-[--text-secondary]">{title}</h4>
        </div>
        <div className="p-4">{children}</div>
    </div>
);

const InfoGrid = ({ items }) => (
    <div className="grid grid-cols-2 gap-3">
        {items.map(({ label, val }) => (
            <div key={label} className="bg-[--surface] p-3 rounded-xl border border-[--border]">
                <div className="text-[9px] font-black uppercase tracking-widest text-[--text-muted] mb-1">{label}</div>
                <div className="font-bold text-sm text-[--text-primary]">{val}</div>
            </div>
        ))}
    </div>
);

const inputCls = 'w-full bg-[--surface] text-[--text-primary] border-2 border-[--border] rounded-xl px-4 py-2.5 focus:outline-none focus:border-teal-500 text-sm font-semibold';
