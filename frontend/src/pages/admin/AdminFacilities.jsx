import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import { Plus, X, Trash2, Building, Search, Phone, Mail, MapPin, Edit3, CheckCircle, Clock3, XCircle, Stethoscope, Users } from 'lucide-react';
import { Card, CardContent } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';

const FACILITY_TYPES = ['Clinic', 'Hospital', 'Health Center', 'Pharmacy', 'Diagnostic Lab'];

const STATUS_CONFIG = {
    ACTIVE:   { label: 'Active',   color: 'bg-emerald-100 text-emerald-700 border-emerald-200', icon: <CheckCircle size={12}/> },
    INACTIVE: { label: 'Inactive', color: 'bg-slate-100 text-slate-600 border-slate-200',       icon: <XCircle size={12}/> },
    PENDING:  { label: 'Pending',  color: 'bg-amber-100 text-amber-700 border-amber-200',        icon: <Clock3 size={12}/> },
};

const TYPE_COLORS = {
    'Clinic':         'bg-blue-50 text-blue-700 border-blue-200',
    'Hospital':       'bg-red-50 text-red-700 border-red-200',
    'Health Center':  'bg-emerald-50 text-emerald-700 border-emerald-200',
    'Pharmacy':       'bg-purple-50 text-purple-700 border-purple-200',
    'Diagnostic Lab': 'bg-amber-50 text-amber-700 border-amber-200',
};

const EMPTY_FORM = { name: '', address: '', phoneNumber: '', email: '', password: '', facilityType: 'Clinic', status: 'ACTIVE', userId: '' };

export const AdminFacilities = () => {
    const queryClient = useQueryClient();
    const [searchQuery, setSearchQuery] = useState('');
    const [createModal, setCreateModal] = useState(false);
    const [deleteModal, setDeleteModal] = useState(null);
    const [editModal, setEditModal]     = useState(null);
    const [viewModal, setViewModal]     = useState(null);
    const [formData, setFormData]       = useState({ ...EMPTY_FORM });

    const { data: facilities, isLoading } = useQuery({
        queryKey: ['adminFacilities'],
        queryFn: async () => { const r = await api.get('/facilities'); return r.data.data.data || []; }
    });
    const { data: doctors } = useQuery({
        queryKey: ['adminDoctors'],
        queryFn: async () => { const r = await api.get('/doctors'); return r.data.data.data || []; }
    });
    const { data: usersInfo } = useQuery({
        queryKey: ['adminUsers'],
        queryFn: async () => { const r = await api.get('/users'); return r.data.data.data || []; }
    });

    const createMutation = useMutation({
        mutationFn: async (payload) => await api.post('/facilities', payload),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['adminFacilities'] });
            setCreateModal(false);
            setFormData({ ...EMPTY_FORM });
            alert('Facility registered successfully!');
        },
        onError: (error) => {
            const errs = error.response?.data?.errors;
            alert(errs?.length ? `Validation: '${errs[0].path?.join('.')}': ${errs[0].message}` : error.response?.data?.message || 'Registration failed.');
        }
    });
    const deleteMutation = useMutation({
        mutationFn: async (id) => await api.delete(`/facilities/${id}`),
        onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['adminFacilities'] }); setDeleteModal(null); }
    });
    const updateMutation = useMutation({
        mutationFn: async ({ id, data }) => await api.put(`/facilities/${id}`, data),
        onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['adminFacilities'] }); setEditModal(null); }
    });

    const displayFacilities = (facilities || []).filter(f => (f.name || '').toLowerCase().includes(searchQuery.toLowerCase()));
    const availableUsers = (usersInfo || []).filter(u => u.role === 'FACILITY' && !facilities?.some(f => f.userId === u.id));

    const getDoctorsForFacility = (facilityId) => (doctors || []).filter(d => d.facilityId === facilityId);

    const inputClass = 'w-full bg-[--surface] text-[--text-primary] border-2 border-[--border] rounded-lg px-4 py-2.5 focus:outline-none focus:border-emerald-500 text-sm font-bold';
    const labelClass = 'text-[10px] font-black uppercase text-[--text-muted] block mb-1';

    const StatusBadge = ({ status }) => {
        const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.PENDING;
        return <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border ${cfg.color}`}>{cfg.icon} {cfg.label}</span>;
    };

    return (
        <div className="w-full space-y-6 animate-fade-in font-sans">
            {/* Hero */}
            <div className="bg-gradient-to-r from-teal-800 to-emerald-900 rounded-xl shadow-sm p-8 text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 w-72 h-72 bg-white/5 rounded-full blur-3xl pointer-events-none" />
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 relative z-10">
                    <div>
                        <h1 className="text-3xl font-black tracking-tight mb-1 flex items-center gap-3">
                            <Building size={28} className="text-teal-300" /> Facility Registry
                        </h1>
                        <p className="text-white/70 font-medium">Manage clinics, hospitals, health centers — link doctors and monitor patient flow.</p>
                    </div>
                    <Button onClick={() => { setFormData({ ...EMPTY_FORM }); setCreateModal(true); }} className="bg-white text-emerald-800 hover:bg-emerald-50 font-black shadow-md shrink-0">
                        <Plus size={16} className="mr-2"/> Add Facility
                    </Button>
                </div>
            </div>

            {/* Summary Cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {Object.entries(STATUS_CONFIG).map(([key, cfg]) => (
                    <div key={key} className={`rounded-xl border p-4 ${cfg.color}`}>
                        <div className="text-[10px] font-black uppercase tracking-widest mb-1">{cfg.label} Facilities</div>
                        <div className="text-2xl font-black">{(facilities || []).filter(f => (f.status || 'ACTIVE') === key).length}</div>
                    </div>
                ))}
                <div className="rounded-xl border p-4 bg-indigo-50 text-indigo-700 border-indigo-200">
                    <div className="text-[10px] font-black uppercase tracking-widest mb-1">Total Doctors</div>
                    <div className="text-2xl font-black">{(doctors || []).length}</div>
                </div>
            </div>

            {/* Search */}
            <div className="relative max-w-md">
                <Search size={16} className="absolute left-3.5 top-3 text-[--text-muted]"/>
                <input type="text" value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
                    placeholder="Search by facility name..."
                    className="w-full pl-10 pr-4 py-2.5 rounded-xl border-2 border-[--border] text-sm focus:outline-none focus:border-emerald-500 bg-[--surface] text-[--text-primary]"/>
            </div>

            {/* Table */}
            <Card className="shadow-sm overflow-hidden">
                <CardContent className="p-0">
                    {isLoading ? (
                        <div className="p-12 text-center text-[--text-muted] font-bold uppercase tracking-widest animate-pulse">Syncing Facility Database...</div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-[--surface-soft] border-b border-[--border] text-[10px] font-black uppercase tracking-widest text-[--text-secondary]">
                                        <th className="p-4">Facility</th>
                                        <th className="p-4">Type</th>
                                        <th className="p-4">Contact</th>
                                        <th className="p-4">Doctors Linked</th>
                                        <th className="p-4">Status</th>
                                        <th className="p-4 text-right">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {displayFacilities.map(fac => {
                                        const facDoctors = getDoctorsForFacility(fac.id);
                                        const typeColor = TYPE_COLORS[fac.facilityType] || TYPE_COLORS['Clinic'];
                                        return (
                                            <tr key={fac.id} className="border-b border-[--border] hover:bg-[--surface-soft] transition-colors">
                                                <td className="p-4">
                                                    <div className="flex items-center gap-3">
                                                        <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center font-black text-lg shrink-0">
                                                            {fac.name?.charAt(0) || 'F'}
                                                        </div>
                                                        <div>
                                                            <div className="font-black text-[--text-primary]">{fac.name}</div>
                                                            <div className="text-[10px] font-bold text-[--text-muted] uppercase tracking-widest mt-0.5 flex items-center gap-1">
                                                                <MapPin size={10}/> {fac.address || 'No address'}
                                                            </div>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td className="p-4">
                                                    <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border ${typeColor}`}>
                                                        {fac.facilityType || 'Clinic'}
                                                    </span>
                                                </td>
                                                <td className="p-4">
                                                    <div className="flex items-center gap-1.5 text-sm font-semibold text-[--text-primary] mb-1">
                                                        <Phone size={12} className="text-[--text-muted]"/> {fac.phoneNumber || 'N/A'}
                                                    </div>
                                                    <div className="flex items-center gap-1.5 text-xs text-[--text-secondary] font-medium">
                                                        <Mail size={11}/> {fac.user?.email || 'N/A'}
                                                    </div>
                                                </td>
                                                <td className="p-4">
                                                    <button onClick={() => setViewModal(fac)} className="flex items-center gap-2 text-sm font-bold text-indigo-600 hover:text-indigo-800 transition-colors">
                                                        <div className="flex -space-x-2">
                                                            {facDoctors.slice(0,3).map((d, i) => (
                                                                <div key={i} className="w-7 h-7 rounded-full overflow-hidden ring-2 ring-white" title={`Dr. ${d.firstName}`}>
                                                                    <img src={`https://api.dicebear.com/7.x/personas/svg?seed=${encodeURIComponent(d.firstName+d.lastName)}&backgroundColor=b6e3f4`} alt="" className="w-full h-full object-cover" onError={e => { e.target.outerHTML = `<div class="w-7 h-7 rounded-full bg-indigo-500 flex items-center justify-center text-white text-[10px] font-black">${d.firstName?.charAt(0)}</div>`; }}/>
                                                                </div>
                                                            ))}
                                                        </div>
                                                        <span>{facDoctors.length} Doctor{facDoctors.length !== 1 ? 's' : ''}</span>
                                                    </button>
                                                </td>
                                                <td className="p-4">
                                                    <StatusBadge status={fac.status || 'ACTIVE'}/>
                                                </td>
                                                <td className="p-4 text-right">
                                                    <div className="flex items-center justify-end gap-2">
                                                        <button onClick={() => { setFormData({ name: fac.name, address: fac.address, phoneNumber: fac.phoneNumber, facilityType: fac.facilityType || 'Clinic', status: fac.status || 'ACTIVE' }); setEditModal(fac); }} className="text-[--text-muted] hover:text-emerald-600 hover:bg-emerald-50 transition-colors p-2 rounded-lg"><Edit3 size={16} strokeWidth={2.5}/></button>
                                                        <button onClick={() => setDeleteModal(fac)} className="text-[--text-muted] hover:text-danger hover:bg-danger/10 transition-colors p-2 rounded-lg"><Trash2 size={16} strokeWidth={2.5}/></button>
                                                    </div>
                                                </td>
                                            </tr>
                                        );
                                    })}
                                    {displayFacilities.length === 0 && (
                                        <tr><td colSpan="6" className="p-12 text-center text-[--text-muted] font-bold uppercase tracking-widest">No Facilities Found</td></tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* VIEW DOCTORS MODAL */}
            {viewModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-[--surface] rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden">
                        <div className="bg-gradient-to-r from-teal-700 to-emerald-700 p-6 text-white flex justify-between items-center">
                            <div>
                                <h2 className="text-xl font-black flex items-center gap-2"><Users size={20}/> {viewModal.name}</h2>
                                <p className="text-teal-200 text-sm mt-1">{getDoctorsForFacility(viewModal.id).length} doctor(s) assigned</p>
                            </div>
                            <button onClick={() => setViewModal(null)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={20}/></button>
                        </div>
                        <div className="p-6 space-y-3 max-h-96 overflow-y-auto">
                            {getDoctorsForFacility(viewModal.id).length === 0 ? (
                                <div className="text-center py-8 text-[--text-muted]">
                                    <Stethoscope size={32} className="mx-auto mb-2 text-slate-300"/>
                                    <p className="font-bold">No doctors linked to this facility yet.</p>
                                    <p className="text-sm mt-1">Use Doctor Registry to assign doctors.</p>
                                </div>
                            ) : getDoctorsForFacility(viewModal.id).map(doc => (
                                <div key={doc.id} className="flex items-center gap-3 p-3 bg-[--surface-soft] rounded-xl border border-[--border]">
                                    <div className="w-10 h-10 rounded-full overflow-hidden ring-2 ring-emerald-100 shrink-0">
                                        <img src={`https://api.dicebear.com/7.x/personas/svg?seed=${encodeURIComponent(doc.firstName+doc.lastName)}&backgroundColor=b6e3f4`} alt="" className="w-full h-full object-cover" onError={e => { e.target.outerHTML = `<div class="w-10 h-10 rounded-full bg-emerald-600 flex items-center justify-center text-white font-black">${doc.firstName?.charAt(0)}</div>`; }}/>
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="font-black text-[--text-primary]">Dr. {doc.firstName} {doc.lastName}</div>
                                        <div className="text-xs text-[--text-secondary] font-semibold truncate">{doc.specialization}</div>
                                    </div>
                                    <span className={`text-[10px] font-black uppercase px-2 py-1 rounded-full border ${STATUS_CONFIG[doc.verificationStatus || 'PENDING']?.color || 'bg-amber-100 text-amber-700 border-amber-200'}`}>
                                        {doc.verificationStatus || 'PENDING'}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            )}

            {/* CREATE MODAL */}
            {createModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-[--surface] rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
                        <div className="bg-gradient-to-r from-teal-700 to-emerald-700 p-6 text-white flex justify-between items-center">
                            <h2 className="text-xl font-black flex items-center gap-2"><Plus size={20}/> Register New Facility</h2>
                            <button onClick={() => setCreateModal(false)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={20}/></button>
                        </div>
                        <form onSubmit={e => { e.preventDefault(); createMutation.mutate(formData); }} className="p-6 space-y-4 overflow-y-auto">

                            <div>
                                <label className={labelClass}>Link to Existing Identity (Optional)</label>
                                <select value={formData.userId} onChange={e => setFormData(p => ({ ...p, userId: e.target.value }))} className={inputClass}>
                                    <option value="">-- Create New User Account --</option>
                                    {availableUsers.map(u => <option key={u.id} value={u.id}>{u.email} (Pending Profile)</option>)}
                                </select>
                            </div>

                            {!formData.userId && (
                                <div className="grid grid-cols-2 gap-4 p-4 bg-emerald-50 dark:bg-emerald-950/30 rounded-xl border border-emerald-100 dark:border-emerald-900">
                                    <div>
                                        <label className={labelClass}>Account Email *</label>
                                        <input required type="email" value={formData.email} onChange={e => setFormData(p => ({ ...p, email: e.target.value }))} placeholder="clinic@example.com" className={inputClass}/>
                                    </div>
                                    <div>
                                        <label className={labelClass}>Temporary Password *</label>
                                        <input required type="password" minLength="6" value={formData.password} onChange={e => setFormData(p => ({ ...p, password: e.target.value }))} placeholder="Min 6 chars" className={inputClass}/>
                                    </div>
                                </div>
                            )}

                            <div>
                                <label className={labelClass}>Facility Name *</label>
                                <input required type="text" value={formData.name} onChange={e => setFormData(p => ({ ...p, name: e.target.value }))} placeholder="e.g. Banadir Pediatric Hospital" className={inputClass}/>
                            </div>

                            {/* Facility Type */}
                            <div>
                                <label className={labelClass}>Facility Type *</label>
                                <div className="grid grid-cols-3 gap-2">
                                    {FACILITY_TYPES.map(type => (
                                        <button key={type} type="button"
                                            onClick={() => setFormData(p => ({ ...p, facilityType: type }))}
                                            className={`py-2 px-3 rounded-xl border-2 text-xs font-black uppercase tracking-wide transition-all ${formData.facilityType === type ? `${TYPE_COLORS[type]} border-current` : 'border-[--border] text-[--text-muted] hover:border-[--text-muted]'}`}>
                                            {type}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            <div>
                                <label className={labelClass}>Location / Address *</label>
                                <div className="relative">
                                    <MapPin size={15} className="absolute left-3.5 top-3 text-[--text-muted]"/>
                                    <input required type="text" value={formData.address} onChange={e => setFormData(p => ({ ...p, address: e.target.value }))} placeholder="e.g. 123 Health Ave, Mogadishu" className={inputClass + ' pl-10'}/>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className={labelClass}>Phone Number *</label>
                                    <div className="relative">
                                        <Phone size={15} className="absolute left-3.5 top-3 text-[--text-muted]"/>
                                        <input required type="tel" value={formData.phoneNumber} onChange={e => setFormData(p => ({ ...p, phoneNumber: e.target.value }))} placeholder="+252-61-0000000" className={inputClass + ' pl-10'}/>
                                    </div>
                                </div>
                                <div>
                                    <label className={labelClass}>Status</label>
                                    <select value={formData.status} onChange={e => setFormData(p => ({ ...p, status: e.target.value }))} className={inputClass}>
                                        <option value="ACTIVE">Active</option>
                                        <option value="PENDING">Pending</option>
                                        <option value="INACTIVE">Inactive</option>
                                    </select>
                                </div>
                            </div>

                            <div className="flex gap-3 pt-2">
                                <Button type="button" onClick={() => setCreateModal(false)} variant="outline" className="flex-1 py-5 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="submit" disabled={createMutation.isPending} className="flex-1 py-5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold">
                                    {createMutation.isPending ? 'Registering...' : 'Register Facility'}
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* EDIT MODAL */}
            {editModal && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-[--surface] rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
                        <div className="bg-emerald-600 p-6 text-white flex justify-between items-center">
                            <h2 className="text-xl font-black flex items-center gap-2"><Edit3 size={20}/> Edit Facility</h2>
                            <button onClick={() => setEditModal(null)} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={20}/></button>
                        </div>
                        <form onSubmit={e => { e.preventDefault(); updateMutation.mutate({ id: editModal.id, data: { name: formData.name, address: formData.address, phoneNumber: formData.phoneNumber, facilityType: formData.facilityType, status: formData.status } }); }} className="p-6 space-y-4 overflow-y-auto">
                            <div>
                                <label className={labelClass}>Facility Name *</label>
                                <input required type="text" value={formData.name} onChange={e => setFormData(p => ({ ...p, name: e.target.value }))} className={inputClass}/>
                            </div>
                            <div>
                                <label className={labelClass}>Facility Type</label>
                                <div className="grid grid-cols-3 gap-2">
                                    {FACILITY_TYPES.map(type => (
                                        <button key={type} type="button" onClick={() => setFormData(p => ({ ...p, facilityType: type }))}
                                            className={`py-2 px-3 rounded-xl border-2 text-xs font-black uppercase tracking-wide transition-all ${formData.facilityType === type ? `${TYPE_COLORS[type]} border-current` : 'border-[--border] text-[--text-muted]'}`}>
                                            {type}
                                        </button>
                                    ))}
                                </div>
                            </div>
                            <div>
                                <label className={labelClass}>Address *</label>
                                <input required type="text" value={formData.address} onChange={e => setFormData(p => ({ ...p, address: e.target.value }))} className={inputClass}/>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className={labelClass}>Phone *</label>
                                    <input required type="tel" value={formData.phoneNumber} onChange={e => setFormData(p => ({ ...p, phoneNumber: e.target.value }))} className={inputClass}/>
                                </div>
                                <div>
                                    <label className={labelClass}>Status</label>
                                    <select value={formData.status} onChange={e => setFormData(p => ({ ...p, status: e.target.value }))} className={inputClass}>
                                        <option value="ACTIVE">Active</option>
                                        <option value="PENDING">Pending</option>
                                        <option value="INACTIVE">Inactive</option>
                                    </select>
                                </div>
                            </div>
                            <div className="flex gap-3 pt-2">
                                <Button type="button" onClick={() => setEditModal(null)} variant="outline" className="flex-1 py-5 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="submit" disabled={updateMutation.isPending} className="flex-1 py-5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold">
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
                    <div className="bg-[--surface] rounded-2xl shadow-2xl w-full max-w-sm text-center overflow-hidden">
                        <div className="p-8 pb-4">
                            <div className="mx-auto w-16 h-16 bg-danger/10 text-danger rounded-full flex items-center justify-center mb-4 ring-8 ring-red-50"><Trash2 size={32}/></div>
                            <h2 className="text-2xl font-black text-[--text-primary]">Archive Facility?</h2>
                            <p className="text-[--text-secondary] font-medium text-sm mt-2">{deleteModal.name} will be removed from the active registry.</p>
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
