import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import { Plus, X, Trash2, Edit3, Stethoscope, Search, Phone, Upload, CheckCircle, Clock3, XCircle, BadgeCheck, FileText } from 'lucide-react';
import { Card, CardContent } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';

const SPECIALIZATIONS = [
    'Pediatrics (General)',
    'Pediatric Pulmonology',
    'Pediatric Cardiology',
    'Pediatric Neurology',
    'Pediatric Oncology',
    'Pediatric Surgery',
    'Neonatology',
    'Pediatric Endocrinology',
    'General Practice',
    'Family Medicine',
    'Other',
];

const STATUS_CONFIG = {
    ACTIVE:   { label: 'Active',   color: 'bg-emerald-100 text-emerald-700 border-emerald-200',  icon: <CheckCircle size={12}/> },
    PENDING:  { label: 'Pending',  color: 'bg-amber-100 text-amber-700 border-amber-200',         icon: <Clock3 size={12}/> },
    REJECTED: { label: 'Rejected', color: 'bg-red-100 text-red-700 border-red-200',               icon: <XCircle size={12}/> },
};

const EMPTY_FORM = {
    firstName: '', lastName: '', email: '', password: '', phoneNumber: '',
    licenseNumber: '', specialization: '', facilityId: '', verificationStatus: 'PENDING',
    qualificationFile: null, userId: '',
};

export const AdminDoctors = () => {
    const queryClient = useQueryClient();
    const [searchQuery, setSearchQuery] = useState('');
    const [createModal, setCreateModal] = useState(false);
    const [deleteModal, setDeleteModal] = useState(null);
    const [editModal, setEditModal]     = useState(null);
    const [viewModal, setViewModal]     = useState(null);
    const [formData, setFormData]       = useState({ ...EMPTY_FORM });
    const [fileLabel, setFileLabel]     = useState('');

    const { data: doctors, isLoading } = useQuery({
        queryKey: ['adminDoctors'],
        queryFn: async () => { const r = await api.get('/doctors'); return r.data.data.data || []; }
    });
    const { data: facilities } = useQuery({
        queryKey: ['adminFacilities'],
        queryFn: async () => { const r = await api.get('/facilities'); return r.data.data.data || []; }
    });
    const { data: usersInfo } = useQuery({
        queryKey: ['adminUsers'],
        queryFn: async () => { const r = await api.get('/users'); return r.data.data.data || []; }
    });

    const createMutation = useMutation({
        mutationFn: async (payload) => await api.post('/doctors', payload),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['adminDoctors'] });
            setCreateModal(false);
            setFormData({ ...EMPTY_FORM });
            setFileLabel('');
            alert('Doctor registered successfully!');
        },
        onError: (error) => {
            const errs = error.response?.data?.errors;
            const msg = errs?.length
                ? `Validation: '${errs[0].path?.join('.')}': ${errs[0].message}`
                : error.response?.data?.message || 'Registration failed.';
            alert(msg);
        }
    });
    const deleteMutation = useMutation({
        mutationFn: async (id) => await api.delete(`/doctors/${id}`),
        onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['adminDoctors'] }); setDeleteModal(null); }
    });
    const updateMutation = useMutation({
        mutationFn: async ({ id, data }) => await api.put(`/doctors/${id}`, data),
        onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['adminDoctors'] }); setEditModal(null); }
    });
    const verifyMutation = useMutation({
        mutationFn: async ({ id, status }) => await api.put(`/doctors/${id}`, { verificationStatus: status }),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['adminDoctors'] })
    });

    const displayDoctors = (doctors || []).filter(d =>
        `${d.firstName} ${d.lastName}`.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (d.specialization || '').toLowerCase().includes(searchQuery.toLowerCase())
    );
    const availableUsers = (usersInfo || []).filter(u => u.role === 'DOCTOR' && !doctors?.some(d => d.userId === u.id));

    const openCreate = () => { setFormData({ ...EMPTY_FORM }); setFileLabel(''); setCreateModal(true); };
    const openEdit = (doc) => {
        setFormData({ firstName: doc.firstName, lastName: doc.lastName, licenseNumber: doc.licenseNumber, specialization: doc.specialization, facilityId: doc.facilityId || '', phoneNumber: doc.phoneNumber || '', verificationStatus: doc.verificationStatus || 'PENDING' });
        setEditModal(doc);
    };

    const handleFileChange = (e) => {
        const file = e.target.files[0];
        if (file) { setFormData(p => ({ ...p, qualificationFile: file })); setFileLabel(file.name); }
    };

    const StatusBadge = ({ status }) => {
        const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.PENDING;
        return (
            <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border ${cfg.color}`}>
                {cfg.icon} {cfg.label}
            </span>
        );
    };

    const inputClass = 'w-full bg-(--surface) text-(--text-primary) border-2 border-(--border) rounded-lg px-4 py-2.5 focus:outline-none focus:border-blue-500 text-sm font-bold';
    const labelClass = 'text-[10px] font-black uppercase text-(--text-muted) block mb-1';

    return (
        <div className="w-full space-y-6 animate-fade-in font-sans">
            {/* Hero Banner */}
            <div className="bg-gradient-to-r from-blue-800 to-indigo-900 rounded-xl shadow-sm p-8 text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 w-72 h-72 bg-white/5 rounded-full blur-3xl -translate-y-1/4 translate-x-1/4 pointer-events-none" />
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 z-10 relative">
                    <div>
                        <h1 className="text-3xl font-black tracking-tight mb-1 flex items-center gap-3">
                            <Stethoscope size={28} className="text-teal-300" /> Doctor Registry (DOC Register)
                        </h1>
                        <p className="text-white/70 font-medium">Manage clinical profiles, licensure, specializations, qualifications and verification status.</p>
                    </div>
                    <Button onClick={openCreate} className="bg-white text-blue-800 hover:bg-blue-50 font-black shadow-md shrink-0">
                        <Plus size={16} className="mr-2" /> Register Doctor
                    </Button>
                </div>
            </div>

            {/* Search & Stats */}
            <div className="flex flex-col sm:flex-row gap-4 items-center">
                <div className="relative flex-1 max-w-md">
                    <Search size={16} className="absolute left-3.5 top-3 text-(--text-muted)" />
                    <input type="text" value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
                        placeholder="Search by name or specialization..."
                        className="w-full pl-10 pr-4 py-2.5 rounded-xl border-2 border-(--border) text-sm focus:outline-none focus:border-blue-500 bg-(--surface) text-(--text-primary)" />
                </div>
                <div className="flex gap-3 text-xs font-bold">
                    {Object.entries(STATUS_CONFIG).map(([key, cfg]) => (
                        <span key={key} className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full border ${cfg.color}`}>
                            {cfg.icon} {(doctors || []).filter(d => (d.verificationStatus || 'PENDING') === key).length} {cfg.label}
                        </span>
                    ))}
                </div>
            </div>

            {/* Table */}
            <Card className="shadow-sm overflow-hidden">
                <CardContent className="p-0">
                    {isLoading ? (
                        <div className="p-12 text-center text-(--text-muted) font-bold uppercase tracking-widest animate-pulse">Syncing Medical Database...</div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-(--surface-soft) border-b border-(--border) text-[10px] font-black uppercase tracking-widest text-(--text-secondary)">
                                        <th className="p-4">Doctor</th>
                                        <th className="p-4">Specialty & Contact</th>
                                        <th className="p-4">Facility / License</th>
                                        <th className="p-4">Verification</th>
                                        <th className="p-4 text-right">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {displayDoctors.map(doc => (
                                        <tr key={doc.id} className="border-b border-(--border) hover:bg-(--surface-soft) transition-colors">
                                            <td className="p-4">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-11 h-11 rounded-full overflow-hidden ring-2 ring-blue-100 shrink-0">
                                                        <img
                                                            src={`https://api.dicebear.com/7.x/personas/svg?seed=${encodeURIComponent(doc.firstName + doc.lastName)}&backgroundColor=b6e3f4,c0aede`}
                                                            alt={`Dr. ${doc.firstName}`}
                                                            className="w-full h-full object-cover"
                                                            onError={e => { e.target.outerHTML = `<div class="w-11 h-11 rounded-full bg-blue-600 flex items-center justify-center text-white font-black text-sm">${doc.firstName?.charAt(0) || 'D'}</div>`; }}
                                                        />
                                                    </div>
                                                    <div>
                                                        <div className="font-black text-(--text-primary)">Dr. {doc.firstName} {doc.lastName}</div>
                                                        <div className="text-[10px] font-bold text-(--text-muted) uppercase tracking-widest mt-0.5">ID: {doc.id?.slice(0,8)}...</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="p-4">
                                                <span className="text-xs font-bold bg-indigo-50 text-indigo-600 px-2.5 py-1 rounded-full border border-indigo-100 block w-max mb-1.5">
                                                    {doc.specialization || 'General'}
                                                </span>
                                                {doc.phoneNumber && (
                                                    <div className="flex items-center gap-1 text-xs text-(--text-secondary) font-semibold">
                                                        <Phone size={11}/> {doc.phoneNumber}
                                                    </div>
                                                )}
                                            </td>
                                            <td className="p-4">
                                                <div className="text-sm font-semibold text-(--text-primary)">{doc.facility?.name || <span className="text-(--text-muted) italic">Unassigned</span>}</div>
                                                <div className="text-xs text-(--text-secondary) mt-0.5 flex items-center gap-1"><FileText size={11}/> {doc.licenseNumber}</div>
                                            </td>
                                            <td className="p-4">
                                                <div className="flex flex-col gap-1.5">
                                                    <StatusBadge status={doc.verificationStatus || 'PENDING'} />
                                                    {(doc.verificationStatus || 'PENDING') === 'PENDING' && (
                                                        <div className="flex gap-1 mt-1">
                                                            <button onClick={() => verifyMutation.mutate({ id: doc.id, status: 'ACTIVE' })}
                                                                className="text-[9px] font-black uppercase px-2 py-0.5 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded hover:bg-emerald-100 transition-colors">
                                                                Approve
                                                            </button>
                                                            <button onClick={() => verifyMutation.mutate({ id: doc.id, status: 'REJECTED' })}
                                                                className="text-[9px] font-black uppercase px-2 py-0.5 bg-red-50 text-red-700 border border-red-200 rounded hover:bg-red-100 transition-colors">
                                                                Reject
                                                            </button>
                                                        </div>
                                                    )}
                                                </div>
                                            </td>
                                            <td className="p-4 text-right">
                                                <div className="flex items-center justify-end gap-2">
                                                    <button onClick={() => setViewModal(doc)} className="text-(--text-muted) hover:text-blue-500 hover:bg-blue-50 transition-colors p-2 rounded-lg" title="View Profile">
                                                        <BadgeCheck size={16} strokeWidth={2.5}/>
                                                    </button>
                                                    <button onClick={() => openEdit(doc)} className="text-(--text-muted) hover:text-blue-500 hover:bg-primary-50 transition-colors p-2 rounded-lg">
                                                        <Edit3 size={16} strokeWidth={2.5}/>
                                                    </button>
                                                    <button onClick={() => setDeleteModal(doc)} className="text-(--text-muted) hover:text-danger hover:bg-danger/10 transition-colors p-2 rounded-lg">
                                                        <Trash2 size={16} strokeWidth={2.5}/>
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                    {displayDoctors.length === 0 && (
                                        <tr><td colSpan="5" className="p-12 text-center text-(--text-muted) font-bold uppercase tracking-widest">No Profiles Found</td></tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* CREATE MODAL */}
            {createModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-(--surface) rounded-2xl shadow-2xl w-full max-w-2xl overflow-hidden relative flex flex-col max-h-[90vh]">
                        <div className="bg-gradient-to-r from-blue-700 to-indigo-800 p-6 text-white flex justify-between items-center">
                            <h2 className="text-xl font-black tracking-tight flex items-center gap-2"><Plus size={20}/> Register New Doctor</h2>
                            <button onClick={() => setCreateModal(false)} className="hover:bg-white/20 p-1.5 rounded-lg transition-colors"><X size={20}/></button>
                        </div>
                        <form onSubmit={e => { e.preventDefault(); const p = { ...formData }; delete p.qualificationFile; createMutation.mutate(p); }} className="p-6 space-y-4 overflow-y-auto">

                            {/* Link to existing user */}
                            <div>
                                <label className={labelClass}>Link to Existing Identity (Optional)</label>
                                <select value={formData.userId} onChange={e => setFormData(p => ({ ...p, userId: e.target.value }))}
                                    className={inputClass}>
                                    <option value="">-- Create New User Account --</option>
                                    {availableUsers.map(u => <option key={u.id} value={u.id}>{u.email} (Pending Profile)</option>)}
                                </select>
                            </div>

                            {/* Email + Password (only if no existing user) */}
                            {!formData.userId && (
                                <div className="grid grid-cols-2 gap-4 p-4 bg-blue-50 dark:bg-blue-950/30 rounded-xl border border-blue-100 dark:border-blue-900">
                                    <div>
                                        <label className={labelClass}>Doctor Email *</label>
                                        <input required type="email" value={formData.email} onChange={e => setFormData(p => ({ ...p, email: e.target.value }))} placeholder="dr@hospital.com" className={inputClass}/>
                                    </div>
                                    <div>
                                        <label className={labelClass}>Temporary Password *</label>
                                        <input required type="password" minLength="6" value={formData.password} onChange={e => setFormData(p => ({ ...p, password: e.target.value }))} placeholder="Min 6 characters" className={inputClass}/>
                                    </div>
                                </div>
                            )}

                            {/* Name row */}
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className={labelClass}>First Name *</label>
                                    <input required type="text" value={formData.firstName} onChange={e => setFormData(p => ({ ...p, firstName: e.target.value }))} className={inputClass}/>
                                </div>
                                <div>
                                    <label className={labelClass}>Last Name *</label>
                                    <input required type="text" value={formData.lastName} onChange={e => setFormData(p => ({ ...p, lastName: e.target.value }))} className={inputClass}/>
                                </div>
                            </div>

                            {/* Phone */}
                            <div>
                                <label className={labelClass}>Phone Number</label>
                                <div className="relative">
                                    <Phone size={15} className="absolute left-3.5 top-3 text-(--text-muted)"/>
                                    <input type="tel" value={formData.phoneNumber} onChange={e => setFormData(p => ({ ...p, phoneNumber: e.target.value }))} placeholder="+252-61-0000000" className={inputClass + ' pl-10'}/>
                                </div>
                            </div>

                            {/* Specialization dropdown */}
                            <div>
                                <label className={labelClass}>Specialty *</label>
                                <select required value={formData.specialization} onChange={e => setFormData(p => ({ ...p, specialization: e.target.value }))} className={inputClass}>
                                    <option value="">-- Select Specialty --</option>
                                    {SPECIALIZATIONS.map(s => <option key={s} value={s}>{s}</option>)}
                                </select>
                            </div>

                            {/* License Number */}
                            <div>
                                <label className={labelClass}>License / Certificate Number *</label>
                                <input required type="text" value={formData.licenseNumber} onChange={e => setFormData(p => ({ ...p, licenseNumber: e.target.value }))} placeholder="e.g. MD-123456789" className={inputClass}/>
                            </div>

                            {/* Qualification Document Upload */}
                            <div>
                                <label className={labelClass}>Qualification Document (PDF or Image)</label>
                                <label className="flex items-center gap-3 w-full border-2 border-dashed border-(--border) rounded-xl px-4 py-3 cursor-pointer hover:border-blue-400 hover:bg-blue-50 dark:hover:bg-blue-950/20 transition-colors">
                                    <Upload size={18} className="text-blue-500 shrink-0"/>
                                    <span className="text-sm font-semibold text-(--text-secondary) truncate">{fileLabel || 'Click to upload certificate or degree...'}</span>
                                    <input type="file" accept=".pdf,.jpg,.jpeg,.png" onChange={handleFileChange} className="hidden"/>
                                </label>
                                <p className="text-[10px] text-(--text-muted) mt-1 font-semibold">Accepted: PDF, JPG, PNG. Max 5MB.</p>
                            </div>

                            {/* Facility Assignment */}
                            <div>
                                <label className={labelClass}>Assign to Facility (Optional)</label>
                                <select value={formData.facilityId} onChange={e => setFormData(p => ({ ...p, facilityId: e.target.value }))} className={inputClass}>
                                    <option value="">-- No Facility --</option>
                                    {(facilities || []).map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
                                </select>
                            </div>

                            {/* Verification Status */}
                            <div>
                                <label className={labelClass}>Verification Status</label>
                                <div className="flex gap-3">
                                    {Object.entries(STATUS_CONFIG).map(([key, cfg]) => (
                                        <button key={key} type="button"
                                            onClick={() => setFormData(p => ({ ...p, verificationStatus: key }))}
                                            className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border-2 text-xs font-black uppercase tracking-wide transition-all ${formData.verificationStatus === key ? `${cfg.color} border-current` : 'border-(--border) text-(--text-muted) hover:border-(--text-muted)'}`}>
                                            {cfg.icon} {cfg.label}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            <div className="flex gap-3 pt-2">
                                <Button type="button" onClick={() => setCreateModal(false)} variant="outline" className="flex-1 py-6 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="submit" disabled={createMutation.isPending} className="flex-1 py-6 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold">
                                    {createMutation.isPending ? 'Registering...' : 'Register Doctor'}
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* VIEW PROFILE MODAL */}
            {viewModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-(--surface) rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
                        <div className="bg-gradient-to-r from-blue-700 to-indigo-800 p-6 text-white relative">
                            <button onClick={() => setViewModal(null)} className="absolute top-4 right-4 hover:bg-white/20 p-1.5 rounded-lg"><X size={20}/></button>
                            <div className="flex items-center gap-4">
                                <div className="w-16 h-16 rounded-full overflow-hidden ring-4 ring-white/30">
                                    <img src={`https://api.dicebear.com/7.x/personas/svg?seed=${encodeURIComponent(viewModal.firstName + viewModal.lastName)}&backgroundColor=b6e3f4`} alt="Avatar" className="w-full h-full object-cover"/>
                                </div>
                                <div>
                                    <h2 className="text-xl font-black">Dr. {viewModal.firstName} {viewModal.lastName}</h2>
                                    <p className="text-blue-200 text-sm font-semibold">{viewModal.specialization}</p>
                                </div>
                            </div>
                        </div>
                        <div className="p-6 space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="bg-(--surface-soft) p-3 rounded-xl border border-(--border)">
                                    <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-widest mb-1">License</div>
                                    <div className="font-bold text-sm text-(--text-primary)">{viewModal.licenseNumber}</div>
                                </div>
                                <div className="bg-(--surface-soft) p-3 rounded-xl border border-(--border)">
                                    <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-widest mb-1">Phone</div>
                                    <div className="font-bold text-sm text-(--text-primary)">{viewModal.phoneNumber || 'N/A'}</div>
                                </div>
                                <div className="bg-(--surface-soft) p-3 rounded-xl border border-(--border)">
                                    <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-widest mb-1">Facility</div>
                                    <div className="font-bold text-sm text-(--text-primary)">{viewModal.facility?.name || 'Unassigned'}</div>
                                </div>
                                <div className="bg-(--surface-soft) p-3 rounded-xl border border-(--border)">
                                    <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-widest mb-1">Status</div>
                                    <StatusBadge status={viewModal.verificationStatus || 'PENDING'} />
                                </div>
                            </div>
                            <div className="flex gap-2 pt-2">
                                {(viewModal.verificationStatus || 'PENDING') !== 'ACTIVE' && (
                                    <Button onClick={() => { verifyMutation.mutate({ id: viewModal.id, status: 'ACTIVE' }); setViewModal(null); }} className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white font-bold">Approve Doctor</Button>
                                )}
                                {(viewModal.verificationStatus || 'PENDING') !== 'REJECTED' && (
                                    <Button onClick={() => { verifyMutation.mutate({ id: viewModal.id, status: 'REJECTED' }); setViewModal(null); }} variant="outline" className="flex-1 border-red-300 text-red-600 font-bold hover:bg-red-50">Reject</Button>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* EDIT MODAL */}
            {editModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-(--surface) rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden">
                        <div className="bg-blue-600 p-6 text-white flex justify-between items-center">
                            <h2 className="text-xl font-black flex items-center gap-2"><Edit3 size={20}/> Edit Doctor Profile</h2>
                            <button onClick={() => setEditModal(null)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={20}/></button>
                        </div>
                        <form onSubmit={e => { e.preventDefault(); updateMutation.mutate({ id: editModal.id, data: { firstName: formData.firstName, lastName: formData.lastName, licenseNumber: formData.licenseNumber, specialization: formData.specialization, facilityId: formData.facilityId || null, phoneNumber: formData.phoneNumber || null, verificationStatus: formData.verificationStatus } }); }} className="p-6 space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className={labelClass}>First Name *</label><input required type="text" value={formData.firstName} onChange={e => setFormData(p => ({ ...p, firstName: e.target.value }))} className={inputClass}/></div>
                                <div><label className={labelClass}>Last Name *</label><input required type="text" value={formData.lastName} onChange={e => setFormData(p => ({ ...p, lastName: e.target.value }))} className={inputClass}/></div>
                            </div>
                            <div><label className={labelClass}>Phone Number</label><input type="tel" value={formData.phoneNumber} onChange={e => setFormData(p => ({ ...p, phoneNumber: e.target.value }))} className={inputClass}/></div>
                            <div>
                                <label className={labelClass}>Specialty *</label>
                                <select required value={formData.specialization} onChange={e => setFormData(p => ({ ...p, specialization: e.target.value }))} className={inputClass}>
                                    <option value="">-- Select Specialty --</option>
                                    {SPECIALIZATIONS.map(s => <option key={s} value={s}>{s}</option>)}
                                </select>
                            </div>
                            <div><label className={labelClass}>License Number *</label><input required type="text" value={formData.licenseNumber} onChange={e => setFormData(p => ({ ...p, licenseNumber: e.target.value }))} className={inputClass}/></div>
                            <div>
                                <label className={labelClass}>Assign to Facility</label>
                                <select value={formData.facilityId} onChange={e => setFormData(p => ({ ...p, facilityId: e.target.value }))} className={inputClass}>
                                    <option value="">-- No Facility --</option>
                                    {(facilities || []).map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
                                </select>
                            </div>
                            <div>
                                <label className={labelClass}>Verification Status</label>
                                <div className="flex gap-3">
                                    {Object.entries(STATUS_CONFIG).map(([key, cfg]) => (
                                        <button key={key} type="button" onClick={() => setFormData(p => ({ ...p, verificationStatus: key }))}
                                            className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border-2 text-xs font-black uppercase tracking-wide transition-all ${formData.verificationStatus === key ? `${cfg.color} border-current` : 'border-(--border) text-(--text-muted)'}`}>
                                            {cfg.icon} {cfg.label}
                                        </button>
                                    ))}
                                </div>
                            </div>
                            <div className="flex gap-3 pt-2">
                                <Button type="button" onClick={() => setEditModal(null)} variant="outline" className="flex-1 py-5 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="submit" disabled={updateMutation.isPending} className="flex-1 py-5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold">
                                    {updateMutation.isPending ? 'Saving...' : 'Save Changes'}
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* DELETE CONFIRM */}
            {deleteModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-(--surface) rounded-2xl shadow-2xl w-full max-w-sm text-center overflow-hidden">
                        <div className="p-8 pb-4">
                            <div className="mx-auto w-16 h-16 bg-danger/10 text-danger rounded-full flex items-center justify-center mb-4 ring-8 ring-red-50"><Trash2 size={32}/></div>
                            <h2 className="text-2xl font-black text-(--text-primary)">Archive Doctor?</h2>
                            <p className="text-(--text-secondary) font-medium text-sm mt-2">Dr. {deleteModal.firstName} {deleteModal.lastName} will be removed from scheduling.</p>
                        </div>
                        <div className="p-6 flex gap-3">
                            <Button variant="outline" onClick={() => setDeleteModal(null)} className="flex-1 py-5 rounded-xl border-2 font-bold">Cancel</Button>
                            <Button onClick={() => deleteMutation.mutate(deleteModal.id)} disabled={deleteMutation.isPending} className="flex-1 py-5 bg-danger hover:bg-red-600 text-white font-bold rounded-xl">Archive</Button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};
