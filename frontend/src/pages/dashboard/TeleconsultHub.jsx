import React, { useState, useEffect, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/axios';
import { Button } from '../../components/ui/Button';
import { Video, Calendar, Zap, Phone, PhoneCall } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import useAuthStore from '../../store/authStore';
import { DirectMessageClient } from '../../components/chat/DirectMessageClient';

export const TeleconsultHub = () => {
    const { user } = useAuthStore();
    const navigate = useNavigate();
    const queryClient = useQueryClient();
    const isDoctor = user?.role === 'DOCTOR';

    const [activeCall, setActiveCall] = useState(null);
    const [activatingId, setActivatingId] = useState(null);
    const ringtoneRef = useRef(null);

    /* ── Incoming call detection for doctors ────────────────────────── */
    const { data: upcomingSessions } = useQuery({
        queryKey: ['teleconsultRing'],
        queryFn: async () => {
            const res = await api.get('/appointments/my-schedule');
            return res.data.data.appointments?.filter(a =>
                a.status === 'PENDING' || a.status === 'CONFIRMED'
            ) || [];
        },
        refetchInterval: 3000,
        enabled: isDoctor,
    });

    useEffect(() => {
        if (!isDoctor || !upcomingSessions) return;
        const incomingCall = upcomingSessions.find(s => s.teleconsultation && !s.teleconsultation.endedAt);

        if (incomingCall && !activeCall) {
            setActiveCall(incomingCall);
            if (!ringtoneRef.current) {
                try {
                    const AudioContext = window.AudioContext || window.webkitAudioContext;
                    const ctx = new AudioContext();
                    const playRing = () => {
                        if (ctx.state === 'closed') return;
                        const osc = ctx.createOscillator();
                        const gain = ctx.createGain();
                        osc.type = 'sine';
                        osc.frequency.setValueAtTime(440, ctx.currentTime);
                        osc.frequency.setValueAtTime(480, ctx.currentTime + 0.1);
                        gain.gain.setValueAtTime(0, ctx.currentTime);
                        gain.gain.linearRampToValueAtTime(0.5, ctx.currentTime + 0.05);
                        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 2);
                        osc.connect(gain);
                        gain.connect(ctx.destination);
                        osc.start();
                        osc.stop(ctx.currentTime + 2);
                    };
                    ringtoneRef.current = setInterval(playRing, 2500);
                    playRing();
                } catch (e) { /* audio blocked */ }
            }
        } else if (!incomingCall && activeCall) {
            setActiveCall(null);
            if (ringtoneRef.current) { clearInterval(ringtoneRef.current); ringtoneRef.current = null; }
        }

        return () => { if (ringtoneRef.current) { clearInterval(ringtoneRef.current); ringtoneRef.current = null; } };
    }, [upcomingSessions, isDoctor, activeCall]);

    const startSession = useMutation({
        mutationFn: async (appointmentId) => {
            setActivatingId(appointmentId);
            const res = await api.post('/teleconsultations/generate', { appointmentId });
            return { appointmentId, ...res.data };
        },
        onSuccess: (data) => {
            navigate(`/teleconsult/${data.appointmentId}`);
            queryClient.invalidateQueries(['teleconsultRing']);
        },
        onError: () => setActivatingId(null),
    });

    return (
        <div className="max-w-300 w-full mx-auto space-y-6 animate-fade-in font-sans">

            {/* ── Hero Banner ──────────────────────────────────────────────── */}
            <div className="bg-(--surface) rounded-2xl shadow-sm border border-(--border) p-6 sm:p-10 flex flex-col sm:flex-row items-center gap-6 relative overflow-hidden">
                <div className="absolute top-0 right-0 w-72 h-72 bg-teal/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/4 pointer-events-none"/>
                <div className="absolute bottom-0 left-0 w-72 h-72 bg-primary-600/5 rounded-full blur-3xl translate-y-1/3 -translate-x-1/4 pointer-events-none"/>

                <div className="w-16 h-16 bg-teal/10 text-teal rounded-2xl flex items-center justify-center shrink-0 z-10">
                    <Video size={30} strokeWidth={2}/>
                </div>

                <div className="flex-1 z-10 text-center sm:text-left">
                    <h1 className="text-2xl font-black text-(--text-primary) tracking-tight mb-1">
                        Teleconsultation Hub
                    </h1>
                    <p className="text-sm font-medium text-(--text-secondary) leading-relaxed max-w-xl">
                        {isDoctor
                            ? 'Message patients, start encrypted video sessions, and review your complete consultation history below.'
                            : 'Message your doctors, join approved video calls, and view your complete call history — all in one place.'}
                    </p>
                    <div className="flex items-center gap-2 mt-3 justify-center sm:justify-start">
                        <span className="flex items-center gap-1.5 text-[10px] font-black text-teal bg-teal/10 border border-teal/20 px-3 py-1.5 rounded-full">
                            <Zap size={11}/> WebRTC Encrypted
                        </span>
                        <span className="flex items-center gap-1.5 text-[10px] font-black text-primary-600 bg-primary-50 dark:bg-primary-950/40 border border-primary-200 dark:border-primary-800 px-3 py-1.5 rounded-full">
                            <Phone size={11}/> Peer-to-Peer
                        </span>
                    </div>
                </div>

                {!isDoctor && (
                    <Link to="/appointments" className="z-10 shrink-0">
                        <Button className="bg-teal hover:opacity-90 text-white font-black shadow-md px-6 py-3 rounded-xl whitespace-nowrap">
                            <Calendar size={16} className="mr-2"/> Book Appointment
                        </Button>
                    </Link>
                )}
            </div>

            {/* ── Incoming Call Overlay (DOCTOR ONLY) ─────────────────────── */}
            {isDoctor && activeCall && (
                <div className="fixed inset-0 z-100 flex items-center justify-center bg-slate-900/80 backdrop-blur-md p-4 animate-fade-in">
                    <div className="bg-[#161b22] border border-white/10 rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden text-center p-8 relative">
                        <div className="absolute top-0 left-0 w-full h-1.5 bg-teal animate-pulse"/>
                        <div className="w-24 h-24 bg-teal/20 rounded-full flex items-center justify-center mx-auto mb-6 relative">
                            <div className="absolute inset-0 border-4 border-teal rounded-full animate-ping opacity-20"/>
                            <PhoneCall size={40} className="text-teal animate-bounce"/>
                        </div>
                        <h2 className="text-2xl font-black text-white mb-2">Incoming Call</h2>
                        <p className="text-(--text-secondary) font-medium mb-8">
                            Patient: <span className="text-white font-bold">{activeCall.child?.firstName} {activeCall.child?.lastName}</span>
                        </p>
                        <Button
                            onClick={() => startSession.mutate(activeCall.id)}
                            className="w-full bg-teal hover:bg-teal/90 text-white font-black h-12 shadow-lg"
                        >
                            <Phone size={18} className="mr-2"/> Accept Call
                        </Button>
                    </div>
                </div>
            )}

            {/* ── Communication Hub (Messages + Virtual Call + History) ──── */}
            <DirectMessageClient />
        </div>
    );
};
