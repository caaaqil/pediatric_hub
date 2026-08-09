import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import { Building, Stethoscope, Users, Calendar, HeartPulse, Plus, X, Edit3, Trash2, CheckCircle, XCircle, MapPin, Phone } from 'lucide-react';
import { Card, CardContent } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';

const TABS = [
    { key: 'doctors',      label: 'Doctors',      icon: Stethoscope },
    { key: 'patients',     label: 'Patients',     icon: Users },
    { key: 'appointments', label: 'Appointments', icon: Calendar },
    { key: 'services',     label: 'Health Services', icon: HeartPulse },
];

const inputCls = 'w-full bg-(--surface) text-(--text-primary) border-2 border-(--border) rounded-lg px-4 py-2.5 focus:outline-none focus:border-emerald-500 text-sm font-bold';

export const FacilityDashboard = () => {
    const qc = useQueryClient();
    const [tab, setTab] = useState('doctors');
    const [serviceModal, setServiceModal] = useState({ open: false, editing: null });
    const [serviceForm, setServiceForm] = useState({ name: '', description: '', price: '', isActive: true });

    const { data: scope, isLoading, isError } = useQuery({
        queryKey: ['facilityScope'],
        queryFn: async () => {
            const r = await api.get('/facilities/my-scope');
            return r.data.data;
        }
    });

    const svcCreate = useMutation({
        mutationFn: async (payload) => await api.post('/health-services', payload),
        onSuccess: () => { qc.invalidateQueries({ queryKey: ['facilityScope'] }); closeServiceModal(); },
        onError: (e) => alert(e.response?.data?.errors?.[0]?.message || e.response?.data?.message || 'Save failed'),
    });
    const svcUpdate = useMutation({
        mutationFn: async ({ id, payload }) => await api.put(`/health-services/${id}`, payload),
        onSuccess: () => { qc.invalidateQueries({ queryKey: ['facilityScope'] }); closeServiceModal(); },
        onError: (e) => alert(e.response?.data?.errors?.[0]?.message || e.response?.data?.message || 'Update failed'),
    });
    const svcDelete = useMutation({
        mutationFn: async (id) => await api.delete(`/health-services/${id}`),
        onSuccess: () => qc.invalidateQueries({ queryKey: ['facilityScope'] }),
    });

    const closeServiceModal = () => { setServiceModal({ open: false, editing: null }); setServiceForm({ name: '', description: '', price: '', isActive: true }); };
    const openServiceCreate = () => { setServiceForm({ name: '', description: '', price: '', isActive: true }); setServiceModal({ open: true, editing: null }); };
    const openServiceEdit = (s) => {
        setServiceForm({ name: s.name, description: s.description || '', price: s.price ?? '', isActive: s.isActive });
        setServiceModal({ open: true, editing: s });
    };
    const submitService = (e) => {
        e.preventDefault();
        const payload = {
            name: serviceForm.name.trim(),
            description: serviceForm.description.trim() || null,
            price: serviceForm.price === '' ? null : Number(serviceForm.price),
            isActive: !!serviceForm.isActive,
        };
        if (serviceModal.editing) svcUpdate.mutate({ id: serviceModal.editing.id, payload });
        else svcCreate.mutate(payload);
    };

    if (isLoading) return <div className="p-12 text-center font-bold text-(--text-muted) animate-pulse">Loading facility dashboard…</div>;
    if (isError) return <div className="p-8 text-danger font-bold text-center">Failed to load facility scope. Check that your account is linked to a facility.</div>;

    const { facility, counts, doctors = [], services = [], appointments = [], patients = [] } = scope || {};

    return (
        <div className="space-y-6 animate-fade-in font-sans">
            {/* Hero */}
            <div className="bg-gradient-to-r from-teal-800 to-emerald-900 rounded-xl shadow-sm p-8 text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 w-72 h-72 bg-white/5 rounded-full blur-3xl pointer-events-none"/>
                <div className="relative z-10 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                    <div>
                        <h1 className="text-3xl font-black tracking-tight mb-1 flex items-center gap-3">
                            <Building size={28} className="text-teal-300"/> {facility?.name || 'My Facility'}
                        </h1>
                        <p className="text-white/80 font-medium flex items-center gap-2 text-sm">
                            <MapPin size={14}/> {facility?.address}
                        </p>
                        <p className="text-white/70 font-medium flex items-center gap-2 text-sm mt-1">
                            <Phone size={14}/> {facility?.phoneNumber}
                        </p>
                    </div>
                    <div className="flex flex-col items-end gap-2">
                        <span className={`px-3 py-1 rounded-full text-xs font-black uppercase tracking-widest border ${facility?.facilityType === 'HOSPITAL' ? 'bg-red-100 text-red-700 border-red-200' : 'bg-blue-100 text-blue-700 border-blue-200'}`}>
                            {facility?.facilityType || 'CLINIC'}
                        </span>
                        <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-black uppercase tracking-widest border ${facility?.isActive ? 'bg-emerald-100 text-emerald-700 border-emerald-200' : 'bg-slate-100 text-slate-600 border-slate-200'}`}>
                            {facility?.isActive ? <CheckCircle size={12}/> : <XCircle size={12}/>} {facility?.isActive ? 'Active' : 'Inactive'}
                        </span>
                    </div>
                </div>
            </div>

            {/* Metric cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[
                    { key: 'doctors',      label: 'Total Doctors',     val: counts?.doctors || 0,      color: 'bg-emerald-50 text-emerald-700 border-emerald-200', icon: Stethoscope },
                    { key: 'patients',     label: 'Total Patients',    val: counts?.patients || 0,     color: 'bg-blue-50 text-blue-700 border-blue-200',         icon: Users },
                    { key: 'appointments', label: 'Total Appointments', val: counts?.appointments || 0, color: 'bg-amber-50 text-amber-700 border-amber-200',      icon: Calendar },
                    { key: 'services',     label: 'Health Services',   val: counts?.services || 0,     color: 'bg-indigo-50 text-indigo-700 border-indigo-200',   icon: HeartPulse },
                ].map(m => (
                    <button key={m.key} onClick={() => setTab(m.key)} className={`rounded-xl border p-4 text-left ${m.color} ${tab === m.key ? 'ring-2 ring-current' : ''}`}>
                        <div className="flex items-center justify-between mb-1"><m.icon size={16}/> <span className="text-[10px] font-black uppercase tracking-widest">{m.label}</span></div>
                        <div className="text-3xl font-black">{m.val}</div>
                    </button>
                ))}
            </div>

            {/* Tabs */}
            <div className="flex border-b border-(--border)">
                {TABS.map(t => (
                    <button key={t.key} onClick={() => setTab(t.key)}
                        className={`flex items-center gap-2 px-5 py-3 text-sm font-black uppercase tracking-widest border-b-2 -mb-px transition-colors ${tab === t.key ? 'border-emerald-600 text-emerald-700' : 'border-transparent text-(--text-muted) hover:text-(--text-primary)'}`}>
                        <t.icon size={16}/> {t.label}
                    </button>
                ))}
            </div>

            {/* Tab content */}
            {tab === 'doctors' && (
                <Card className="shadow-sm">
                    <CardContent className="p-0">
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-(--surface-soft) border-b border-(--border) text-[10px] font-black uppercase tracking-widest text-(--text-secondary)">
                                        <th className="p-4">Name</th><th className="p-4">Specialization</th><th className="p-4">License</th><th className="p-4">Email</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {doctors.length === 0 && <tr><td colSpan="4" className="p-8 text-center text-(--text-muted) font-bold uppercase tracking-widest">No doctors assigned</td></tr>}
                                    {doctors.map(d => (
                                        <tr key={d.id} className="border-b border-(--border) hover:bg-(--surface-soft)">
                                            <td className="p-4 font-bold text-(--text-primary)">Dr. {d.firstName} {d.lastName}</td>
                                            <td className="p-4"><span className="text-xs font-bold bg-emerald-50 text-emerald-700 px-2 py-1 rounded">{d.specialization}</span></td>
                                            <td className="p-4 text-sm">{d.licenseNumber}</td>
                                            <td className="p-4 text-xs text-(--text-secondary)">{d.user?.email}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </CardContent>
                </Card>
            )}

            {tab === 'patients' && (
                <Card className="shadow-sm">
                    <CardContent className="p-0">
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-(--surface-soft) border-b border-(--border) text-[10px] font-black uppercase tracking-widest text-(--text-secondary)">
                                        <th className="p-4">Child</th><th className="p-4">Date of Birth</th><th className="p-4">Gender</th><th className="p-4">Parent</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {patients.length === 0 && <tr><td colSpan="4" className="p-8 text-center text-(--text-muted) font-bold uppercase tracking-widest">No patients seen yet</td></tr>}
                                    {patients.map(p => (
                                        <tr key={p.id} className="border-b border-(--border) hover:bg-(--surface-soft)">
                                            <td className="p-4 font-bold text-(--text-primary)">{p.firstName} {p.lastName}</td>
                                            <td className="p-4 text-sm">{p.dateOfBirth ? new Date(p.dateOfBirth).toLocaleDateString() : '-'}</td>
                                            <td className="p-4 text-sm">{p.gender || '-'}</td>
                                            <td className="p-4 text-sm">{p.parent ? `${p.parent.firstName} ${p.parent.lastName}` : '-'}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </CardContent>
                </Card>
            )}

            {tab === 'appointments' && (
                <Card className="shadow-sm">
                    <CardContent className="p-0">
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-(--surface-soft) border-b border-(--border) text-[10px] font-black uppercase tracking-widest text-(--text-secondary)">
                                        <th className="p-4">Scheduled</th><th className="p-4">Child</th><th className="p-4">Doctor</th><th className="p-4">Status</th><th className="p-4">Reason</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {appointments.length === 0 && <tr><td colSpan="5" className="p-8 text-center text-(--text-muted) font-bold uppercase tracking-widest">No appointments yet</td></tr>}
                                    {appointments.map(a => (
                                        <tr key={a.id} className="border-b border-(--border) hover:bg-(--surface-soft)">
                                            <td className="p-4 text-sm">{new Date(a.scheduledAt).toLocaleString()}</td>
                                            <td className="p-4 font-bold text-(--text-primary)">{a.child?.firstName} {a.child?.lastName}</td>
                                            <td className="p-4 text-sm">Dr. {a.doctor?.lastName}</td>
                                            <td className="p-4"><span className="text-[10px] font-black px-2 py-0.5 rounded-full uppercase tracking-widest bg-slate-100 text-slate-700">{a.status}</span></td>
                                            <td className="p-4 text-xs text-(--text-secondary)">{a.reason || '-'}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </CardContent>
                </Card>
            )}

            {tab === 'services' && (
                <>
                    <div className="flex justify-end">
                        <Button onClick={openServiceCreate} className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold flex items-center gap-2"><Plus size={16}/> Add Service</Button>
                    </div>
                    <Card className="shadow-sm">
                        <CardContent className="p-0">
                            <div className="overflow-x-auto">
                                <table className="w-full text-left border-collapse">
                                    <thead>
                                        <tr className="bg-(--surface-soft) border-b border-(--border) text-[10px] font-black uppercase tracking-widest text-(--text-secondary)">
                                            <th className="p-4">Service</th><th className="p-4">Description</th><th className="p-4">Price</th><th className="p-4">Status</th><th className="p-4 text-right">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {services.length === 0 && <tr><td colSpan="5" className="p-8 text-center text-(--text-muted) font-bold uppercase tracking-widest">No services yet</td></tr>}
                                        {services.map(s => (
                                            <tr key={s.id} className="border-b border-(--border) hover:bg-(--surface-soft)">
                                                <td className="p-4 font-bold text-(--text-primary)">{s.name}</td>
                                                <td className="p-4 text-sm text-(--text-secondary) max-w-md">{s.description || '-'}</td>
                                                <td className="p-4 text-sm">{s.price != null ? `$${Number(s.price).toFixed(2)}` : '-'}</td>
                                                <td className="p-4"><span className={`text-[10px] font-black px-2 py-0.5 rounded-full uppercase tracking-widest ${s.isActive ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-600'}`}>{s.isActive ? 'Active' : 'Inactive'}</span></td>
                                                <td className="p-4 text-right">
                                                    <div className="flex justify-end gap-2">
                                                        <button onClick={() => openServiceEdit(s)} className="p-2 rounded hover:bg-emerald-50 text-emerald-600"><Edit3 size={15}/></button>
                                                        <button onClick={() => { if (confirm('Archive this service?')) svcDelete.mutate(s.id); }} className="p-2 rounded hover:bg-red-50 text-red-600"><Trash2 size={15}/></button>
                                                    </div>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </CardContent>
                    </Card>
                </>
            )}

            {/* Service modal */}
            {serviceModal.open && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-fade-in">
                    <div className="bg-(--surface) rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
                        <div className="bg-gradient-to-r from-teal-700 to-emerald-700 p-6 text-white flex justify-between items-center">
                            <h2 className="text-xl font-black flex items-center gap-2"><HeartPulse size={20}/> {serviceModal.editing ? 'Edit Service' : 'Add Health Service'}</h2>
                            <button onClick={closeServiceModal} className="hover:bg-white/20 p-1.5 rounded-lg"><X size={20}/></button>
                        </div>
                        <form onSubmit={submitService} className="p-6 space-y-4 overflow-y-auto">
                            <div>
                                <label className="block text-xs font-bold text-(--text-secondary) uppercase tracking-wide mb-1">Service Name *</label>
                                <input required minLength={1} value={serviceForm.name} onChange={e => setServiceForm(p => ({ ...p, name: e.target.value }))} className={inputCls}/>
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-(--text-secondary) uppercase tracking-wide mb-1">Description</label>
                                <textarea rows="3" value={serviceForm.description} onChange={e => setServiceForm(p => ({ ...p, description: e.target.value }))} className={inputCls}></textarea>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-xs font-bold text-(--text-secondary) uppercase tracking-wide mb-1">Price (USD)</label>
                                    <input type="number" min="0" step="0.01" value={serviceForm.price} onChange={e => setServiceForm(p => ({ ...p, price: e.target.value }))} className={inputCls}/>
                                </div>
                                <div>
                                    <label className="block text-xs font-bold text-(--text-secondary) uppercase tracking-wide mb-1">Status</label>
                                    <select value={serviceForm.isActive ? 'true' : 'false'} onChange={e => setServiceForm(p => ({ ...p, isActive: e.target.value === 'true' }))} className={inputCls}>
                                        <option value="true">Active</option><option value="false">Inactive</option>
                                    </select>
                                </div>
                            </div>
                            <div className="pt-2 flex gap-3">
                                <Button type="button" onClick={closeServiceModal} variant="outline" className="flex-1 py-5 rounded-xl border-2 font-bold">Cancel</Button>
                                <Button type="submit" isLoading={svcCreate.isPending || svcUpdate.isPending} className="flex-1 py-5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold">
                                    {serviceModal.editing ? 'Save Changes' : 'Add Service'}
                                </Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};
