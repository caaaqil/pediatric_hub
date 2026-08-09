import React, { useState } from 'react';
import { Button } from '../../components/ui/Button';
import {
    User, AlertCircle, Baby, Calendar as CalendarIcon, Clock,
    CheckCircle2, ChevronLeft, ChevronRight, Stethoscope, MapPin,
    Shield, Star, Zap, Video, Search, X, Heart, ArrowRight,
    FileText, Sparkles, CreditCard, Phone, Wallet, HeartPulse
} from 'lucide-react';
import { api } from '../../lib/axios';
import { useQuery } from '@tanstack/react-query';

/* ─── helpers ─────────────────────────────────────────────────────────── */
const getAge = (dob) => {
    const diff = Date.now() - new Date(dob).getTime();
    const years = Math.floor(diff / (1000 * 60 * 60 * 24 * 365.25));
    const months = Math.floor(diff / (1000 * 60 * 60 * 24 * 30.44));
    return years >= 1 ? `${years}yr` : `${months}mo`;
};
const fmtDate = (d) => new Date(d + 'T12:00:00').toLocaleDateString('en-US', {
    weekday: 'long', month: 'long', day: 'numeric'
});
const formatTime = (t) => {
    const [h, m] = t.split(':');
    const hr = parseInt(h) % 12 || 12;
    return `${hr}:${m} ${parseInt(h) >= 12 ? 'PM' : 'AM'}`;
};

const CONSULTATION_FEE = 0.01;

const STEPS = [
    { n: 0, label: 'Payment',      icon: <CreditCard size={15}/> },
    { n: 1, label: 'Choose Doctor', icon: <Stethoscope size={15}/> },
    { n: 2, label: 'Select Child',  icon: <Baby size={15}/> },
    { n: 3, label: 'Pick a Time',   icon: <Clock size={15}/> },
];

const AVATAR_COLORS = [
    'from-blue-500 to-indigo-600', 'from-teal-500 to-emerald-600',
    'from-purple-500 to-violet-600', 'from-rose-500 to-pink-600',
    'from-amber-500 to-orange-600', 'from-cyan-500 to-sky-600',
];

const initials = (first, last) => `${first?.[0] ?? ''}${last?.[0] ?? ''}`.toUpperCase();
const avatarColor = (id) => AVATAR_COLORS[(id?.charCodeAt(0) ?? 0) % AVATAR_COLORS.length];

const DOCTOR_RATINGS = [
    { stars: 5, score: '5.0', label: 'Top Rated' },
    { stars: 4, score: '4.2', label: 'Excellent' },
    { stars: 3, score: '3.5', label: 'Good' },
    { stars: 2, score: '2.8', label: 'Average' },
    { stars: 1, score: '1.9', label: 'New' },
];
const getDoctorRating = (idx) => DOCTOR_RATINGS[Math.min(idx, DOCTOR_RATINGS.length - 1)];

const SPECIALTIES = {
    'General Pediatrics': { color: 'bg-blue-100 text-blue-700 border-blue-200' },
    'Pediatrics (General)': { color: 'bg-blue-100 text-blue-700 border-blue-200' },
    'Neonatology':  { color: 'bg-purple-100 text-purple-700 border-purple-200' },
    'Cardiology':   { color: 'bg-rose-100 text-rose-700 border-rose-200' },
    'Neurology':    { color: 'bg-indigo-100 text-indigo-700 border-indigo-200' },
    'Nutrition':    { color: 'bg-green-100 text-green-700 border-green-200' },
    'Dermatology':  { color: 'bg-orange-100 text-orange-700 border-orange-200' },
};
const specialtyStyle = (s) => SPECIALTIES[s]?.color ?? 'bg-slate-100 text-slate-700 border-slate-200';

/* ═════════════════════════════════════════════════════════════════════════ */
export const BookingFlow = () => {
    const [step, setStep]               = useState(0);
    const [selectedDoc, setSelectedDoc] = useState(null);
    const [selectedChild, setSelectedChild] = useState(null);
    const [selectedDate, setSelectedDate]   = useState(() => {
        const d = new Date(); d.setDate(d.getDate() + 1);
        return d.toISOString().split('T')[0];
    });
    const [selectedTime, setSelectedTime] = useState(null);
    const [reason, setReason]             = useState('');
    const [searchDoc, setSearchDoc]       = useState('');
    const [loading, setLoading]           = useState(false);
    const [errorMsg, setError]            = useState('');
    const [success, setSuccess]           = useState(false);

    /* Payment state */
    const [phoneNumber, setPhoneNumber] = useState('');
    const [payLoading, setPayLoading]   = useState(false);
    const [payError, setPayError]       = useState('');
    const [paidData, setPaidData]       = useState(null);

    const { data: doctors, isLoading: loadDocs } = useQuery({
        queryKey: ['availableDoctors'],
        queryFn: async () => (await api.get('/users/doctors')).data.data,
    });

    const { data: children, isLoading: loadChildren } = useQuery({
        queryKey: ['myChildren'],
        queryFn: async () => (await api.get('/children/my-children')).data.data,
    });

    const facilityId = selectedDoc?.facility?.id || selectedDoc?.facilityId;
    const { data: facilityServices = [], isLoading: loadServices } = useQuery({
        queryKey: ['facilityServices', facilityId],
        queryFn: async () => (await api.get(`/health-services/by-facility/${facilityId}`)).data.data,
        enabled: !!facilityId,
    });

    const filteredDocs = (doctors ?? []).filter(d =>
        !searchDoc ||
        `${d.firstName} ${d.lastName}`.toLowerCase().includes(searchDoc.toLowerCase()) ||
        d.specialization?.toLowerCase().includes(searchDoc.toLowerCase())
    );

    /* Slot generation — 9 AM to 4 PM */
    const slots = (() => {
        const s = [];
        for (let h = 9; h <= 16; h++) {
            s.push(`${String(h).padStart(2, '0')}:00`);
            if (h !== 16) s.push(`${String(h).padStart(2, '0')}:30`);
        }
        return s;
    })();
    const morningSlots   = slots.filter(t => parseInt(t) < 12);
    const afternoonSlots = slots.filter(t => parseInt(t) >= 12);

    /* Payment handler */
    const handlePayment = async () => {
        if (!phoneNumber.trim()) { setPayError('Please enter your EVC Plus phone number.'); return; }
        const cleaned = phoneNumber.replace(/\s+/g, '');
        if (!/^(252|0)\d{8,9}$/.test(cleaned)) {
            setPayError('Enter a valid Somali phone number (e.g. 2526XXXXXXXX or 06XXXXXXXX).');
            return;
        }
        setPayLoading(true); setPayError('');
        try {
            const res = await api.post('/payments', {
                accountNo: cleaned,
                amount: CONSULTATION_FEE,
                description: 'Pediatric Health Hub — Teleconsultation Fee',
            });
            if (res.data.success) {
                setPaidData(res.data.data);
                setStep(1);
            } else {
                setPayError('Payment was declined. Please check your EVC Plus balance and try again.');
            }
        } catch (err) {
            setPayError(err.response?.data?.message || 'Payment failed. Please try again.');
        } finally {
            setPayLoading(false);
        }
    };

    const handleBook = async () => {
        if (!selectedChild || !selectedDate || !selectedTime) {
            setError('Please select a date and time slot.');
            return;
        }
        setLoading(true); setError('');
        try {
            await api.post('/appointments', {
                childId: selectedChild.id,
                doctorId: selectedDoc.id,
                scheduledAt: new Date(`${selectedDate}T${selectedTime}:00`).toISOString(),
                reason: reason || undefined,
            });
            setSuccess(true);
        } catch (err) {
            setError(err.response?.status === 409
                ? 'This slot was just taken. Please choose another.'
                : 'Failed to book. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const resetAll = () => {
        setSuccess(false); setStep(0);
        setSelectedDoc(null); setSelectedChild(null);
        setSelectedTime(null); setReason('');
        setPhoneNumber(''); setPaidData(null); setPayError('');
    };

    /* ── Success Screen ─────────────────────────────────────────────── */
    if (success) return (
        <div className="min-h-[70vh] flex items-center justify-center px-4">
            <div className="max-w-md w-full text-center">
                {/* Animated ring */}
                <div className="relative w-28 h-28 mx-auto mb-8">
                    <div className="absolute inset-0 rounded-full bg-emerald-500/20 animate-ping"/>
                    <div className="absolute inset-2 rounded-full bg-emerald-500/10"/>
                    <div className="absolute inset-0 flex items-center justify-center">
                        <div className="w-20 h-20 bg-emerald-500 rounded-full flex items-center justify-center shadow-xl shadow-emerald-500/30">
                            <CheckCircle2 size={38} className="text-white" strokeWidth={2.5}/>
                        </div>
                    </div>
                </div>

                <div className="inline-flex items-center gap-2 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-400 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-5">
                    <Zap size={12}/> Request Sent
                </div>

                <h2 className="text-3xl font-black text-(--text-primary) mb-3 tracking-tight">Appointment Requested!</h2>
                <p className="text-sm font-medium text-(--text-secondary) leading-relaxed mb-2">
                    Your request has been sent to <span className="font-black text-(--text-primary)">Dr. {selectedDoc?.lastName}</span>.
                </p>
                <p className="text-xs font-medium text-(--text-muted) mb-8">
                    Once the doctor approves, you'll see a <strong>Join Call</strong> button in the Tele-Consultation section.
                </p>

                {/* Summary pill */}
                <div className="bg-(--surface-soft) border border-(--border) rounded-2xl p-5 text-left mb-8 space-y-3">
                    <div className="flex items-center justify-between text-xs font-bold">
                        <span className="text-(--text-muted)">Doctor</span>
                        <span className="text-(--text-primary)">Dr. {selectedDoc?.firstName} {selectedDoc?.lastName}</span>
                    </div>
                    <div className="flex items-center justify-between text-xs font-bold">
                        <span className="text-(--text-muted)">Patient</span>
                        <span className="text-(--text-primary)">{selectedChild?.firstName} {selectedChild?.lastName}</span>
                    </div>
                    <div className="flex items-center justify-between text-xs font-bold">
                        <span className="text-(--text-muted)">Date & Time</span>
                        <span className="text-(--text-primary)">{fmtDate(selectedDate)} · {formatTime(selectedTime)}</span>
                    </div>
                    <div className="flex items-center justify-between text-xs font-bold">
                        <span className="text-(--text-muted)">Payment</span>
                        <span className="flex items-center gap-1 text-emerald-600"><CheckCircle2 size={12}/> ${CONSULTATION_FEE.toFixed(2)} Paid</span>
                    </div>
                    <div className="flex items-center justify-between text-xs font-bold">
                        <span className="text-(--text-muted)">Status</span>
                        <span className="flex items-center gap-1 text-amber-600"><div className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse"/> Pending Approval</span>
                    </div>
                </div>

                <button onClick={resetAll}
                    className="px-6 py-3 bg-primary-600 hover:bg-primary-700 text-white text-sm font-black rounded-xl transition-colors shadow-md"
                >
                    Book Another Appointment
                </button>
            </div>
        </div>
    );

    return (
        <div className="max-w-5xl mx-auto pb-16 animate-fade-in">

            {/* ── Hero ──────────────────────────────────────────────────────── */}
            <div className="relative rounded-3xl overflow-hidden mb-8 shadow-xl" style={{ minHeight: 180 }}>
                <img
                    src="https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=1400&h=400&q=80"
                    alt="Pediatric clinic"
                    className="absolute inset-0 w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-r from-primary-900/95 via-primary-800/85 to-primary-700/60"/>
                <div className="relative z-10 p-8 sm:p-10 flex flex-col sm:flex-row items-start sm:items-center gap-6 justify-between">
                    <div>
                        <div className="inline-flex items-center gap-2 bg-white/10 border border-white/20 rounded-full px-3 py-1.5 mb-3">
                            <Video size={12} className="text-sky-300"/>
                            <span className="text-white/80 text-[10px] font-black uppercase tracking-widest">Teleconsultation Booking</span>
                        </div>
                        <h1 className="text-3xl font-black text-white tracking-tight leading-tight mb-2">
                            Book an Appointment
                        </h1>
                        <p className="text-white/70 text-sm font-medium max-w-md">
                            Connect your child with a certified pediatrician in 4 easy steps. Secure, private, and professional.
                        </p>
                    </div>
                    <div className="flex items-center gap-3 shrink-0">
                        <div className="bg-white/10 border border-white/20 rounded-2xl px-4 py-3 text-center">
                            <div className="text-white font-black text-xl">{doctors?.length ?? '—'}</div>
                            <div className="text-white/60 text-[10px] font-bold uppercase">Doctors</div>
                        </div>
                        <div className="bg-white/10 border border-white/20 rounded-2xl px-4 py-3 text-center">
                            <div className="text-white font-black text-xl">24/7</div>
                            <div className="text-white/60 text-[10px] font-bold uppercase">Access</div>
                        </div>
                    </div>
                </div>
            </div>

            {/* ── Step Progress Bar ─────────────────────────────────────────── */}
            <div className="bg-(--surface) border border-(--border) rounded-2xl p-5 mb-8 shadow-sm">
                <div className="flex items-center justify-between">
                    {STEPS.map((s, i) => {
                        const done    = step > s.n;
                        const current = step === s.n;
                        return (
                            <React.Fragment key={s.n}>
                                <div className="flex flex-col items-center gap-2">
                                    <div className={`w-10 h-10 rounded-full flex items-center justify-center font-black text-sm transition-all
                                        ${done    ? 'bg-emerald-500 text-white shadow-lg shadow-emerald-200 dark:shadow-emerald-900/30'
                                        : current ? 'bg-primary-600 text-white shadow-lg shadow-primary-200 dark:shadow-primary-900/30 ring-4 ring-primary-100 dark:ring-primary-900/30'
                                        :           'bg-(--surface-soft) text-(--text-muted) border-2 border-(--border)'}`}>
                                        {done ? <CheckCircle2 size={18}/> : s.icon}
                                    </div>
                                    <div className={`text-[11px] font-black tracking-tight text-center hidden sm:block
                                        ${current ? 'text-primary-600' : done ? 'text-emerald-600' : 'text-(--text-muted)'}`}>
                                        {s.label}
                                    </div>
                                </div>
                                {i < STEPS.length - 1 && (
                                    <div className="flex-1 mx-3 h-0.5 relative">
                                        <div className="absolute inset-0 bg-(--border) rounded-full"/>
                                        <div className={`absolute inset-0 rounded-full transition-all duration-500 ${done ? 'bg-emerald-500' : current ? 'bg-primary-400 w-1/2' : 'w-0'}`}/>
                                    </div>
                                )}
                            </React.Fragment>
                        );
                    })}
                </div>
            </div>

            <div className={`grid gap-6 ${step === 3 ? 'grid-cols-1 lg:grid-cols-3' : 'grid-cols-1'}`}>

                {/* ── MAIN CONTENT ────────────────────────────────────────── */}
                <div className={step === 3 ? 'lg:col-span-2' : ''}>

                    {/* STEP 0 — Payment */}
                    {step === 0 && (
                        <div className="bg-(--surface) border border-(--border) rounded-2xl shadow-sm overflow-hidden">
                            <div className="px-6 py-5 border-b border-(--border) bg-(--surface-soft)">
                                <h2 className="font-black text-(--text-primary) text-base flex items-center gap-2">
                                    <Wallet size={18} className="text-primary-600"/> Consultation Fee Payment
                                </h2>
                                <p className="text-xs text-(--text-muted) font-medium mt-0.5">
                                    Pay via EVC Plus (WaafiPay) to unlock appointment booking
                                </p>
                            </div>

                            <div className="p-6 space-y-6">
                                {/* Fee summary card */}
                                <div className="bg-gradient-to-br from-primary-50 to-indigo-50 dark:from-primary-950/30 dark:to-indigo-950/30 border border-primary-200 dark:border-primary-800 rounded-2xl p-5">
                                    <div className="flex items-center justify-between mb-3">
                                        <span className="text-sm font-black text-(--text-primary)">Teleconsultation Fee</span>
                                        <span className="text-2xl font-black text-primary-600">${CONSULTATION_FEE.toFixed(2)}</span>
                                    </div>
                                    <div className="space-y-1.5 text-xs text-(--text-muted) font-medium">
                                        <div className="flex items-center gap-2"><CheckCircle2 size={12} className="text-emerald-500"/> 30-minute video consultation</div>
                                        <div className="flex items-center gap-2"><CheckCircle2 size={12} className="text-emerald-500"/> Certified pediatric specialist</div>
                                        <div className="flex items-center gap-2"><CheckCircle2 size={12} className="text-emerald-500"/> Digital prescription if needed</div>
                                    </div>
                                </div>

                                {/* EVC Plus form */}
                                <div className="space-y-4">
                                    <div>
                                        <label className="flex items-center gap-2 text-xs font-black text-(--text-primary) uppercase tracking-widest mb-3">
                                            <Phone size={13} className="text-primary-600"/> EVC Plus Phone Number
                                        </label>
                                        <div className="relative">
                                            <div className="absolute left-4 top-1/2 -translate-y-1/2 flex items-center gap-2">
                                                <span className="text-sm font-black text-(--text-muted)">🇸🇴</span>
                                            </div>
                                            <input
                                                type="tel"
                                                value={phoneNumber}
                                                onChange={e => { setPhoneNumber(e.target.value); setPayError(''); }}
                                                placeholder="e.g. 2526XXXXXXXX"
                                                className="w-full pl-10 pr-4 py-3.5 border-2 border-(--border) rounded-xl bg-(--surface) text-(--text-primary) font-bold text-sm placeholder-(--text-muted) focus:outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-all"
                                            />
                                        </div>
                                        <p className="text-[10px] text-(--text-muted) font-medium mt-1.5">
                                            Enter your EVC Plus / Hormuud registered number
                                        </p>
                                    </div>

                                    {payError && (
                                        <div className="flex items-center gap-3 p-4 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800 rounded-xl">
                                            <AlertCircle size={16} className="text-red-500 shrink-0"/>
                                            <p className="text-xs font-semibold text-red-700 dark:text-red-400">{payError}</p>
                                        </div>
                                    )}

                                    <button
                                        onClick={handlePayment}
                                        disabled={payLoading || !phoneNumber.trim()}
                                        className="w-full py-4 bg-primary-600 hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-black rounded-xl transition-all shadow-lg shadow-primary-200 dark:shadow-primary-900/30 flex items-center justify-center gap-2 text-sm"
                                    >
                                        {payLoading ? (
                                            <><div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"/> Processing — check your EVC Plus app...</>
                                        ) : (
                                            <><CreditCard size={16}/> Pay ${CONSULTATION_FEE.toFixed(2)} via EVC Plus</>
                                        )}
                                    </button>
                                    {payLoading && (
                                        <p className="text-[11px] text-center text-primary-600 font-semibold animate-pulse">
                                            A payment prompt has been sent to your EVC Plus app. Please approve it.
                                        </p>
                                    )}
                                </div>

                                {/* Security note */}
                                <div className="flex items-center gap-3 p-4 bg-(--surface-soft) border border-(--border) rounded-xl">
                                    <Shield size={16} className="text-emerald-500 shrink-0"/>
                                    <p className="text-[10px] text-(--text-muted) font-medium leading-relaxed">
                                        Payment is securely processed by <strong>WaafiPay</strong>. Your phone number is only used to charge your EVC Plus wallet.
                                    </p>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* STEP 1 — Choose Doctor */}
                    {step === 1 && (
                        <div className="bg-(--surface) border border-(--border) rounded-2xl shadow-sm overflow-hidden">
                            {/* Payment success banner */}
                            {paidData && (
                                <div className="px-6 py-3 bg-emerald-50 dark:bg-emerald-950/20 border-b border-emerald-200 dark:border-emerald-800 flex items-center gap-2">
                                    <CheckCircle2 size={14} className="text-emerald-600"/>
                                    <span className="text-xs font-black text-emerald-700 dark:text-emerald-400">
                                        Payment confirmed — ${CONSULTATION_FEE.toFixed(2)} charged to {phoneNumber}
                                    </span>
                                </div>
                            )}

                            {/* Card header */}
                            <div className="px-6 py-5 border-b border-(--border) bg-(--surface-soft) flex items-center justify-between gap-4">
                                <div>
                                    <h2 className="font-black text-(--text-primary) text-base">Available Specialists</h2>
                                    <p className="text-xs text-(--text-muted) font-medium mt-0.5">All doctors are certified pediatric specialists</p>
                                </div>
                                <div className="relative">
                                    <Search size={15} className="absolute left-3 top-2.5 text-(--text-muted)"/>
                                    <input
                                        value={searchDoc}
                                        onChange={e => setSearchDoc(e.target.value)}
                                        placeholder="Search doctor or specialty..."
                                        className="pl-9 pr-4 py-2.5 text-xs font-medium bg-(--surface) border border-(--border) rounded-xl text-(--text-primary) placeholder-(--text-muted) focus:outline-none focus:border-primary-400 w-56"
                                    />
                                    {searchDoc && (
                                        <button onClick={() => setSearchDoc('')} className="absolute right-3 top-2.5 text-(--text-muted) hover:text-(--text-primary)">
                                            <X size={14}/>
                                        </button>
                                    )}
                                </div>
                            </div>

                            <div className="p-6">
                                {loadDocs ? (
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                        {[1,2,3,4].map(i => (
                                            <div key={i} className="h-32 rounded-2xl bg-(--surface-soft) border border-(--border) animate-pulse"/>
                                        ))}
                                    </div>
                                ) : filteredDocs.length === 0 ? (
                                    <div className="text-center py-16">
                                        <Stethoscope size={40} className="mx-auto text-(--text-muted)/30 mb-4"/>
                                        <p className="font-black text-(--text-secondary) mb-1">No doctors found</p>
                                        <p className="text-xs text-(--text-muted)">Try a different search term</p>
                                    </div>
                                ) : (
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                        {filteredDocs.map((d, idx) => (
                                            <button
                                                key={d.id}
                                                onClick={() => { setSelectedDoc(d); setStep(2); }}
                                                className="group text-left p-5 border-2 border-(--border) rounded-2xl hover:border-primary-400 hover:shadow-lg hover:-translate-y-1 transition-all duration-200 bg-(--surface) relative overflow-hidden"
                                            >
                                                {/* Accent top bar */}
                                                <div className={`absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r ${AVATAR_COLORS[idx % AVATAR_COLORS.length].replace('from-', 'from-').replace('to-', 'to-')} opacity-0 group-hover:opacity-100 transition-opacity`}/>

                                                <div className="flex items-start gap-4">
                                                    {/* Avatar */}
                                                    <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${avatarColor(d.id)} flex items-center justify-center text-white font-black text-lg shadow-md shrink-0`}>
                                                        {initials(d.firstName, d.lastName)}
                                                    </div>

                                                    <div className="flex-1 min-w-0">
                                                        <div className="flex items-center gap-2 flex-wrap mb-1">
                                                            <h3 className="font-black text-(--text-primary) text-sm">
                                                                Dr. {d.firstName} {d.lastName}
                                                            </h3>
                                                            {d.verificationStatus === 'ACTIVE' && (
                                                                <span className="flex items-center gap-1 text-[9px] font-black text-emerald-700 bg-emerald-100 border border-emerald-200 px-1.5 py-0.5 rounded-full">
                                                                    <Shield size={8}/> Verified
                                                                </span>
                                                            )}
                                                        </div>

                                                        <span className={`text-[10px] font-black px-2.5 py-1 rounded-full border inline-block mb-2 ${specialtyStyle(d.specialization)}`}>
                                                            {d.specialization}
                                                        </span>

                                                        {d.facility?.name && (
                                                            <div className="flex items-center gap-1 text-[10px] text-(--text-muted) font-medium">
                                                                <MapPin size={10}/> {d.facility.name}
                                                            </div>
                                                        )}

                                                        {/* Stars — ranked by position */}
                                                        {(() => { const r = getDoctorRating(idx); return (
                                                        <div className="flex items-center gap-0.5 mt-1.5">
                                                            {[1,2,3,4,5].map(s => (
                                                                <Star key={s} size={10} className={s <= r.stars ? 'text-amber-400 fill-amber-400' : 'text-(--text-muted)/30'}/>
                                                            ))}
                                                            <span className="text-[9px] text-(--text-muted) font-bold ml-1">{r.score}</span>
                                                            <span className={`text-[8px] font-black ml-1 px-1.5 py-0.5 rounded-full ${r.stars === 5 ? 'bg-amber-100 text-amber-700' : r.stars >= 3 ? 'bg-slate-100 text-slate-600' : 'bg-slate-50 text-slate-500'}`}>{r.label}</span>
                                                        </div>
                                                        ); })()}
                                                    </div>

                                                    <div className="shrink-0 self-center">
                                                        <div className="w-8 h-8 rounded-xl bg-primary-50 dark:bg-primary-950/40 flex items-center justify-center text-primary-600 group-hover:bg-primary-600 group-hover:text-white transition-all">
                                                            <ChevronRight size={16}/>
                                                        </div>
                                                    </div>
                                                </div>

                                                {/* Availability pill */}
                                                <div className="mt-3 pt-3 border-t border-(--border) flex items-center gap-2">
                                                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"/>
                                                    <span className="text-[10px] font-bold text-emerald-600">Available for booking</span>
                                                </div>
                                            </button>
                                        ))}
                                    </div>
                                )}
                            </div>
                        </div>
                    )}

                    {/* STEP 2 — Select Child */}
                    {step === 2 && (
                        <div className="bg-(--surface) border border-(--border) rounded-2xl shadow-sm overflow-hidden">
                            <div className="px-6 py-5 border-b border-(--border) bg-(--surface-soft) flex items-center justify-between">
                                <div>
                                    <h2 className="font-black text-(--text-primary) text-base">Select Child</h2>
                                    <p className="text-xs text-(--text-muted) font-medium mt-0.5">
                                        Who is this appointment for?
                                    </p>
                                </div>
                                <button
                                    onClick={() => setStep(1)}
                                    className="flex items-center gap-1.5 text-xs font-black text-primary-600 hover:text-primary-700 bg-primary-50 dark:bg-primary-950/40 px-3 py-2 rounded-xl transition-colors"
                                >
                                    <ChevronLeft size={14}/> Back
                                </button>
                            </div>

                            {/* Selected doctor recap */}
                            <div className="px-6 py-4 bg-primary-50/50 dark:bg-primary-950/20 border-b border-primary-100 dark:border-primary-900/30 flex items-center gap-3">
                                <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${avatarColor(selectedDoc?.id)} flex items-center justify-center text-white font-black text-sm shadow-md shrink-0`}>
                                    {initials(selectedDoc?.firstName, selectedDoc?.lastName)}
                                </div>
                                <div>
                                    <div className="text-xs font-black text-primary-700 dark:text-primary-300">Booking with</div>
                                    <div className="text-sm font-black text-(--text-primary)">Dr. {selectedDoc?.firstName} {selectedDoc?.lastName}</div>
                                </div>
                                <span className={`ml-auto text-[10px] font-black px-2 py-1 rounded-full border ${specialtyStyle(selectedDoc?.specialization)}`}>
                                    {selectedDoc?.specialization}
                                </span>
                            </div>

                            {/* Facility services offered */}
                            {facilityId && (
                                <div className="px-6 py-4 border-b border-(--border) bg-(--surface-soft)">
                                    <div className="flex items-center gap-2 mb-3">
                                        <HeartPulse size={14} className="text-emerald-600"/>
                                        <span className="text-[10px] font-black uppercase tracking-widest text-(--text-primary)">
                                            Services offered by {selectedDoc?.facility?.name || 'this facility'}
                                        </span>
                                    </div>
                                    {loadServices ? (
                                        <p className="text-xs text-(--text-muted) italic">Loading services…</p>
                                    ) : facilityServices.length === 0 ? (
                                        <p className="text-xs text-(--text-muted) italic">No published services yet.</p>
                                    ) : (
                                        <div className="flex flex-wrap gap-2">
                                            {facilityServices.map(s => (
                                                <div key={s.id} className="flex items-center gap-2 px-3 py-1.5 rounded-full border border-emerald-200 bg-emerald-50 text-emerald-800 text-xs font-bold">
                                                    <HeartPulse size={11}/>
                                                    <span>{s.name}</span>
                                                    {s.price != null && <span className="text-emerald-600 font-black">${Number(s.price).toFixed(2)}</span>}
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>
                            )}

                            <div className="p-6">
                                {loadChildren ? (
                                    <div className="space-y-3">
                                        {[1,2].map(i => <div key={i} className="h-24 rounded-2xl bg-(--surface-soft) border border-(--border) animate-pulse"/>)}
                                    </div>
                                ) : !children?.length ? (
                                    <div className="text-center py-16">
                                        <Baby size={40} className="mx-auto text-(--text-muted)/30 mb-4"/>
                                        <p className="font-black text-(--text-secondary) mb-1">No children registered</p>
                                        <p className="text-xs text-(--text-muted)">Add a child profile first to book appointments.</p>
                                    </div>
                                ) : (
                                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                        {children.map((c, idx) => (
                                            <button
                                                key={c.id}
                                                onClick={() => { setSelectedChild(c); setStep(3); }}
                                                className="group text-left p-5 border-2 border-(--border) rounded-2xl hover:border-violet-400 hover:shadow-lg hover:-translate-y-1 transition-all duration-200 bg-(--surface)"
                                            >
                                                <div className="flex items-center gap-4">
                                                    <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-violet-400 to-purple-600 flex items-center justify-center text-white font-black text-lg shadow-md shrink-0">
                                                        {initials(c.firstName, c.lastName)}
                                                    </div>
                                                    <div className="flex-1 min-w-0">
                                                        <h3 className="font-black text-(--text-primary) text-sm mb-1">
                                                            {c.firstName} {c.lastName}
                                                        </h3>
                                                        <div className="flex items-center gap-2 flex-wrap">
                                                            <span className="text-[10px] font-bold text-(--text-muted)">
                                                                🎂 {new Date(c.dateOfBirth).toLocaleDateString()}
                                                            </span>
                                                            <span className="text-[10px] font-black px-2 py-0.5 rounded-full bg-violet-100 text-violet-700 border border-violet-200">
                                                                {getAge(c.dateOfBirth)}
                                                            </span>
                                                            {c.gender && (
                                                                <span className="text-[10px] font-bold text-(--text-muted)">
                                                                    {c.gender === 'Male' ? '♂' : '♀'} {c.gender}
                                                                </span>
                                                            )}
                                                        </div>
                                                        {c.bloodType && (
                                                            <span className="text-[10px] font-black text-rose-600 mt-1 inline-block">🩸 {c.bloodType}</span>
                                                        )}
                                                    </div>
                                                    <div className="shrink-0">
                                                        <div className="w-8 h-8 rounded-xl bg-violet-50 dark:bg-violet-950/40 flex items-center justify-center text-violet-600 group-hover:bg-violet-600 group-hover:text-white transition-all">
                                                            <ArrowRight size={15}/>
                                                        </div>
                                                    </div>
                                                </div>
                                            </button>
                                        ))}
                                    </div>
                                )}
                            </div>
                        </div>
                    )}

                    {/* STEP 3 — Pick a Time */}
                    {step === 3 && selectedDoc && selectedChild && (
                        <div className="bg-(--surface) border border-(--border) rounded-2xl shadow-sm overflow-hidden">
                            <div className="px-6 py-5 border-b border-(--border) bg-(--surface-soft) flex items-center justify-between">
                                <div>
                                    <h2 className="font-black text-(--text-primary) text-base">Pick a Date & Time</h2>
                                    <p className="text-xs text-(--text-muted) font-medium mt-0.5">All slots are 30-minute sessions</p>
                                </div>
                                <button
                                    onClick={() => setStep(2)}
                                    className="flex items-center gap-1.5 text-xs font-black text-primary-600 hover:text-primary-700 bg-primary-50 dark:bg-primary-950/40 px-3 py-2 rounded-xl transition-colors"
                                >
                                    <ChevronLeft size={14}/> Back
                                </button>
                            </div>

                            <div className="p-6 space-y-6">
                                {errorMsg && (
                                    <div className="flex items-center gap-3 p-4 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800 rounded-xl">
                                        <AlertCircle size={18} className="text-red-500 shrink-0"/>
                                        <p className="text-sm font-semibold text-red-700 dark:text-red-400">{errorMsg}</p>
                                    </div>
                                )}

                                {/* Date picker */}
                                <div>
                                    <label className="flex items-center gap-2 text-xs font-black text-(--text-primary) uppercase tracking-widest mb-3">
                                        <CalendarIcon size={14} className="text-primary-600"/> Select Date
                                    </label>
                                    <div className="flex items-center gap-3">
                                        <input
                                            type="date"
                                            min={new Date().toISOString().split('T')[0]}
                                            value={selectedDate}
                                            onChange={e => { setSelectedDate(e.target.value); setSelectedTime(null); }}
                                            className="px-4 py-3 border-2 border-(--border) rounded-xl bg-(--surface) text-(--text-primary) font-bold text-sm focus:outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-all"
                                        />
                                        {selectedDate && (
                                            <div className="px-4 py-3 bg-primary-50 dark:bg-primary-950/30 border border-primary-200 dark:border-primary-800 rounded-xl">
                                                <p className="text-xs font-black text-primary-700 dark:text-primary-300">{fmtDate(selectedDate)}</p>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                <div className="h-px bg-(--border)"/>

                                {/* Time slots */}
                                <div>
                                    <label className="flex items-center gap-2 text-xs font-black text-(--text-primary) uppercase tracking-widest mb-4">
                                        <Clock size={14} className="text-primary-600"/> Available Time Slots
                                    </label>

                                    <div className="space-y-4">
                                        {/* Morning */}
                                        <div>
                                            <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-widest mb-2 flex items-center gap-2">
                                                ☀️ Morning
                                            </div>
                                            <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                                                {morningSlots.map(t => {
                                                    const sel = selectedTime === t;
                                                    return (
                                                        <button key={t} onClick={() => setSelectedTime(t)}
                                                            className={`py-2.5 px-3 rounded-xl text-xs font-black border-2 transition-all
                                                                ${sel
                                                                    ? 'bg-primary-600 text-white border-primary-600 shadow-lg shadow-primary-200 dark:shadow-primary-900/30 scale-105'
                                                                    : 'bg-(--surface) text-(--text-secondary) border-(--border) hover:border-primary-400 hover:bg-primary-50 dark:hover:bg-primary-950/30'
                                                                }`}>
                                                            {formatTime(t)}
                                                        </button>
                                                    );
                                                })}
                                            </div>
                                        </div>
                                        {/* Afternoon */}
                                        <div>
                                            <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-widest mb-2">
                                                🌤 Afternoon
                                            </div>
                                            <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                                                {afternoonSlots.map(t => {
                                                    const sel = selectedTime === t;
                                                    return (
                                                        <button key={t} onClick={() => setSelectedTime(t)}
                                                            className={`py-2.5 px-3 rounded-xl text-xs font-black border-2 transition-all
                                                                ${sel
                                                                    ? 'bg-primary-600 text-white border-primary-600 shadow-lg shadow-primary-200 dark:shadow-primary-900/30 scale-105'
                                                                    : 'bg-(--surface) text-(--text-secondary) border-(--border) hover:border-primary-400 hover:bg-primary-50 dark:hover:bg-primary-950/30'
                                                                }`}>
                                                            {formatTime(t)}
                                                        </button>
                                                    );
                                                })}
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div className="h-px bg-(--border)"/>

                                {/* Reason */}
                                <div>
                                    <label className="flex items-center gap-2 text-xs font-black text-(--text-primary) uppercase tracking-widest mb-3">
                                        <FileText size={14} className="text-primary-600"/> Reason for Visit
                                        <span className="text-(--text-muted) normal-case font-medium">(optional)</span>
                                    </label>
                                    <textarea
                                        value={reason}
                                        onChange={e => setReason(e.target.value)}
                                        rows={3}
                                        placeholder="e.g. Routine checkup, fever since 2 days, vaccination visit..."
                                        className="w-full px-4 py-3 border-2 border-(--border) rounded-xl bg-(--surface) text-(--text-primary) text-sm font-medium placeholder-(--text-muted) focus:outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-all resize-none"
                                    />
                                </div>
                            </div>
                        </div>
                    )}
                </div>

                {/* ── BOOKING SUMMARY SIDEBAR (step 3 only) ─────────────────── */}
                {step === 3 && (
                    <div className="space-y-4">
                        <div className="bg-(--surface) border border-(--border) rounded-2xl shadow-sm overflow-hidden sticky top-6">
                            <div className="px-5 py-4 border-b border-(--border) bg-(--surface-soft)">
                                <h3 className="font-black text-sm text-(--text-primary)">Booking Summary</h3>
                            </div>
                            <div className="p-5 space-y-4">
                                {/* Doctor */}
                                <div className="flex items-center gap-3">
                                    <div className={`w-11 h-11 rounded-xl bg-gradient-to-br ${avatarColor(selectedDoc?.id)} flex items-center justify-center text-white font-black text-sm shadow-md shrink-0`}>
                                        {initials(selectedDoc?.firstName, selectedDoc?.lastName)}
                                    </div>
                                    <div>
                                        <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-wide">Doctor</div>
                                        <div className="text-sm font-black text-(--text-primary)">Dr. {selectedDoc?.firstName} {selectedDoc?.lastName}</div>
                                        <div className={`text-[10px] font-bold px-2 py-0.5 rounded-full border inline-block mt-0.5 ${specialtyStyle(selectedDoc?.specialization)}`}>
                                            {selectedDoc?.specialization}
                                        </div>
                                    </div>
                                </div>

                                <div className="h-px bg-(--border)"/>

                                {/* Child */}
                                <div className="flex items-center gap-3">
                                    <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-violet-400 to-purple-600 flex items-center justify-center text-white font-black text-sm shadow-md shrink-0">
                                        {initials(selectedChild?.firstName, selectedChild?.lastName)}
                                    </div>
                                    <div>
                                        <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-wide">Patient</div>
                                        <div className="text-sm font-black text-(--text-primary)">{selectedChild?.firstName} {selectedChild?.lastName}</div>
                                        <div className="text-[10px] text-(--text-muted) font-medium mt-0.5">{getAge(selectedChild?.dateOfBirth)} old</div>
                                    </div>
                                </div>

                                <div className="h-px bg-(--border)"/>

                                {/* Date/Time */}
                                <div className="space-y-2">
                                    <div className="flex items-center justify-between text-xs">
                                        <span className="font-black text-(--text-muted) flex items-center gap-1.5"><CalendarIcon size={11}/> Date</span>
                                        <span className="font-black text-(--text-primary)">{fmtDate(selectedDate)}</span>
                                    </div>
                                    <div className="flex items-center justify-between text-xs">
                                        <span className="font-black text-(--text-muted) flex items-center gap-1.5"><Clock size={11}/> Time</span>
                                        <span className={`font-black ${selectedTime ? 'text-primary-600' : 'text-(--text-muted) italic'}`}>
                                            {selectedTime ? formatTime(selectedTime) : 'Not selected'}
                                        </span>
                                    </div>
                                    <div className="flex items-center justify-between text-xs">
                                        <span className="font-black text-(--text-muted) flex items-center gap-1.5"><Video size={11}/> Type</span>
                                        <span className="font-black text-teal">Video Call</span>
                                    </div>
                                    <div className="flex items-center justify-between text-xs">
                                        <span className="font-black text-(--text-muted) flex items-center gap-1.5"><CreditCard size={11}/> Fee</span>
                                        <span className="font-black text-emerald-600 flex items-center gap-1"><CheckCircle2 size={10}/> ${CONSULTATION_FEE.toFixed(2)} Paid</span>
                                    </div>
                                </div>

                                <div className="h-px bg-(--border)"/>

                                {/* Facility services */}
                                {facilityId && facilityServices.length > 0 && (
                                    <>
                                        <div className="h-px bg-(--border)"/>
                                        <div>
                                            <div className="text-[10px] font-black text-(--text-muted) uppercase tracking-wide flex items-center gap-1.5 mb-2">
                                                <HeartPulse size={11} className="text-emerald-600"/> Facility Services
                                            </div>
                                            <ul className="space-y-1.5">
                                                {facilityServices.map(s => (
                                                    <li key={s.id} className="flex items-center justify-between text-[11px]">
                                                        <span className="font-bold text-(--text-primary) truncate mr-2">{s.name}</span>
                                                        {s.price != null && <span className="font-black text-emerald-600 shrink-0">${Number(s.price).toFixed(2)}</span>}
                                                    </li>
                                                ))}
                                            </ul>
                                        </div>
                                    </>
                                )}

                                <div className="h-px bg-(--border)"/>

                                {/* Status */}
                                <div className="bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800 rounded-xl p-3">
                                    <p className="text-[10px] font-bold text-amber-700 dark:text-amber-400 leading-relaxed">
                                        ⚠️ After booking, the doctor reviews and approves your request before the video call is unlocked.
                                    </p>
                                </div>

                                {/* Book button */}
                                <button
                                    onClick={handleBook}
                                    disabled={!selectedTime || loading}
                                    className="w-full py-3.5 bg-primary-600 hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed text-white text-sm font-black rounded-xl transition-all shadow-lg shadow-primary-200 dark:shadow-primary-900/30 flex items-center justify-center gap-2"
                                >
                                    {loading ? (
                                        <><div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"/> Booking...</>
                                    ) : (
                                        <><Sparkles size={16}/> Confirm Appointment</>
                                    )}
                                </button>

                                <p className="text-[10px] text-center text-(--text-muted) font-medium flex items-center justify-center gap-1">
                                    <Shield size={10}/> Secure & encrypted booking
                                </p>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};
