import React, { useState, useEffect, useRef } from 'react';
import {
    Heart, Sun, Moon, ArrowRight, Shield, Users, Stethoscope, Activity,
    Calendar, Syringe, Phone, Bot, BookOpen, ChevronRight, Menu, X,
    CheckCircle, Star, MapPin, Clock, Video, Zap, Award, TrendingUp,
    Mail, MessageSquare, ChevronDown, Play, Baby, Sparkles, Globe
} from 'lucide-react';
import useThemeStore from '../../store/themeStore';
import { api } from '../../lib/axios';

/* ─── Keyframe animations ─────────────────────────────────────────────── */
const STYLES = `
@keyframes lp-float  { 0%,100%{transform:translateY(0)}  50%{transform:translateY(-12px)} }
@keyframes lp-fadeUp { from{opacity:0;transform:translateY(28px)} to{opacity:1;transform:translateY(0)} }
@keyframes lp-fadeIn { from{opacity:0} to{opacity:1} }
@keyframes lp-zoom   { from{transform:scale(1)} to{transform:scale(1.06)} }
@keyframes lp-ticker { from{transform:translateX(0)} to{transform:translateX(-50%)} }
@keyframes lp-pulse  { 0%,100%{opacity:1} 50%{opacity:.45} }
@keyframes lp-spin   { from{transform:rotate(0deg)} to{transform:rotate(360deg)} }
@keyframes lp-count  { from{opacity:0;transform:translateY(16px)} to{opacity:1;transform:translateY(0)} }

.lp-float   { animation: lp-float  3.5s ease-in-out infinite }
.lp-float2  { animation: lp-float  4.2s ease-in-out infinite; animation-delay:-2s }
.lp-float3  { animation: lp-float  5s ease-in-out infinite; animation-delay:-1s }
.lp-fade-up { animation: lp-fadeUp 0.65s ease both }
.lp-fade-in { animation: lp-fadeIn 0.5s ease both }
.lp-zoom-bg { animation: lp-zoom   14s ease-in-out infinite alternate }
.lp-ticker  { animation: lp-ticker 32s linear infinite }
.lp-pulse   { animation: lp-pulse  1.8s ease-in-out infinite }
.lp-count   { animation: lp-count  0.6s ease both }

.lp-card { transition: all .25s ease }
.lp-card:hover { transform:translateY(-6px); box-shadow:0 24px 56px rgba(0,0,0,.13) }
.lp-nav-link { position:relative; font-weight:700; font-size:14px; color:var(--text-secondary); transition:color .2s }
.lp-nav-link::after { content:''; position:absolute; bottom:-3px; left:0; width:0; height:2px; background:#2563EB; border-radius:2px; transition:width .25s }
.lp-nav-link:hover { color:#2563EB }
.lp-nav-link:hover::after { width:100% }
.lp-nav-link.active { color:#2563EB }
.lp-nav-link.active::after { width:100% }
`;

/* ─── Nav links ───────────────────────────────────────────────────────── */
const NAV_LINKS = [
    { label: 'Home',     href: '#home' },
    { label: 'About',    href: '#about' },
    { label: 'Services', href: '#services' },
    { label: 'Doctors',  href: '#doctors' },
    { label: 'Pricing',  href: '#pricing' },
    { label: 'Contact',  href: '#contact' },
];

/* ─── Ticker items ────────────────────────────────────────────────────── */
const TICKER = [
    '🏥 Somalia\'s Leading Pediatric Health Platform',
    '💉 Automated Vaccination Schedules',
    '📹 Secure Video Teleconsultation',
    '📊 WHO-Standard Growth Tracking',
    '🤖 AI-Powered Health Assistant',
    '🔒 HIPAA-Ready Encryption',
    '👶 Trusted by 50,000+ Families',
    '🌍 Available 24 / 7',
];

/* ─── Services ────────────────────────────────────────────────────────── */
const SERVICES = [
    {
        icon: Calendar,
        title: 'Smart Appointments',
        desc: 'Book visits with certified pediatricians instantly. Real-time availability, automated reminders, and zero paperwork.',
        color: 'text-blue-600',
        bg: 'bg-blue-50 dark:bg-blue-950/30',
        border: 'border-blue-100 dark:border-blue-900/50',
        img: 'https://images.unsplash.com/photo-1631217868264-e5b90bb7e133?auto=format&fit=crop&w=600&h=340&q=80',
    },
    {
        icon: Video,
        title: 'Teleconsultation',
        desc: 'Secure WebRTC video calls with your child\'s doctor from anywhere in Somalia. End-to-end encrypted sessions.',
        color: 'text-teal-600',
        bg: 'bg-teal-50 dark:bg-teal-950/30',
        border: 'border-teal-100 dark:border-teal-900/50',
        img: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=600&h=340&q=80',
    },
    {
        icon: Syringe,
        title: 'Vaccine Tracking',
        desc: 'Automated immunization schedules aligned with WHO protocols. Smart alerts before every upcoming dose.',
        color: 'text-violet-600',
        bg: 'bg-violet-50 dark:bg-violet-950/30',
        border: 'border-violet-100 dark:border-violet-900/50',
        img: 'https://images.unsplash.com/photo-1576765608866-5b51046452be?auto=format&fit=crop&w=600&h=340&q=80',
    },
    {
        icon: Activity,
        title: 'Growth Analytics',
        desc: 'WHO-standard growth charts with percentile tracking. Monitor height, weight, and developmental milestones.',
        color: 'text-emerald-600',
        bg: 'bg-emerald-50 dark:bg-emerald-950/30',
        border: 'border-emerald-100 dark:border-emerald-900/50',
        img: 'https://images.unsplash.com/photo-1530099486328-e021101a494a?auto=format&fit=crop&w=600&h=340&q=80',
    },
    {
        icon: Bot,
        title: 'AI Health Assistant',
        desc: 'Instant pediatric guidance powered by AI. Available in Somali and English, 24 hours a day.',
        color: 'text-amber-600',
        bg: 'bg-amber-50 dark:bg-amber-950/30',
        border: 'border-amber-100 dark:border-amber-900/50',
        img: 'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?auto=format&fit=crop&w=600&h=340&q=80',
    },
    {
        icon: BookOpen,
        title: 'Health Education',
        desc: 'Curated Somali-language library on child nutrition, development, hygiene, vaccination, and emergency care.',
        color: 'text-rose-600',
        bg: 'bg-rose-50 dark:bg-rose-950/30',
        border: 'border-rose-100 dark:border-rose-900/50',
        img: 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&w=600&h=340&q=80',
    },
];

/* ─── Doctors ─────────────────────────────────────────────────────────── */
const DOCTORS = [
    {
        name: 'Dr. Halima Warsame',
        specialty: 'General Pediatrics',
        exp: '12 years',
        rating: 4.9,
        reviews: 342,
        img: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=400&h=400&q=80',
        badge: 'Top Rated',
        badgeColor: 'bg-amber-100 text-amber-700',
    },
    {
        name: 'Dr. Abdi Mohamed',
        specialty: 'Neonatology',
        exp: '8 years',
        rating: 4.8,
        reviews: 218,
        img: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&w=400&h=400&q=80',
        badge: 'Expert',
        badgeColor: 'bg-blue-100 text-blue-700',
    },
    {
        name: 'Dr. Faadumo Hassan',
        specialty: 'Pediatric Nutrition',
        exp: '10 years',
        rating: 4.9,
        reviews: 287,
        img: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?auto=format&fit=crop&w=400&h=400&q=80',
        badge: 'Most Booked',
        badgeColor: 'bg-emerald-100 text-emerald-700',
    },
];

/* ─── Pricing ─────────────────────────────────────────────────────────── */
const PLANS = [
    {
        name: 'Basic',
        price: 'Free',
        period: 'Forever',
        desc: 'Perfect for families getting started with digital health.',
        features: [
            'Child health records',
            'Vaccine schedule tracking',
            'Basic health education',
            'AI chatbot (limited)',
            'Emergency guidance',
        ],
        cta: 'Get Started Free',
        highlight: false,
        color: 'border-[--border]',
    },
    {
        name: 'Family',
        price: '$9',
        period: 'per month',
        desc: 'Full access for active families who want the best care.',
        features: [
            'Everything in Basic',
            'Unlimited appointments',
            'Video teleconsultation',
            'Growth analytics & charts',
            'Direct doctor messaging',
            'Priority support',
        ],
        cta: 'Start Free Trial',
        highlight: true,
        color: 'border-primary-500',
    },
    {
        name: 'Clinic',
        price: '$49',
        period: 'per month',
        desc: 'For facilities and doctor practices managing many patients.',
        features: [
            'Everything in Family',
            'Multi-doctor management',
            'Admin & audit dashboard',
            'Facility portal access',
            'Advanced analytics',
            'Dedicated account manager',
        ],
        cta: 'Contact Sales',
        highlight: false,
        color: 'border-[--border]',
    },
];

/* ─── Testimonials ────────────────────────────────────────────────────── */
const TESTIMONIALS = [
    {
        name: 'Khadija Omar',
        role: 'Mother of 3, Mogadishu',
        img: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=100&h=100&q=80',
        text: '"Pediatric Health Hub changed how we manage our children\'s health. The vaccine reminders alone saved us from missing critical doses. The teleconsultation feature means we no longer need to travel across the city for a quick check-up."',
        stars: 5,
    },
    {
        name: 'Dr. Ismail Farah',
        role: 'Pediatrician, Hargeisa',
        img: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=100&h=100&q=80',
        text: '"As a doctor, the platform has dramatically reduced my administrative burden. I can now focus entirely on patient care while the system handles scheduling, records, and follow-ups automatically."',
        stars: 5,
    },
    {
        name: 'Safia Ahmed',
        role: 'Parent, Kismayo',
        img: 'https://images.unsplash.com/photo-1499952127939-9bbf5af6c51c?auto=format&fit=crop&w=100&h=100&q=80',
        text: '"The AI chatbot answered all my late-night questions about my daughter\'s fever in Somali. It was calm, accurate, and told me exactly when to go to the hospital. This platform is a lifeline for our community."',
        stars: 5,
    },
];

/* ─── Steps ───────────────────────────────────────────────────────────── */
const HOW_STEPS = [
    {
        n: '01',
        title: 'Create Your Account',
        desc: 'Register as a parent in minutes. Add your children\'s profiles with their health history.',
        icon: Users,
        color: 'bg-blue-600',
    },
    {
        n: '02',
        title: 'Connect with a Doctor',
        desc: 'Browse verified pediatricians, book an appointment, and message your doctor directly.',
        icon: Stethoscope,
        color: 'bg-teal-600',
    },
    {
        n: '03',
        title: 'Care, Anywhere',
        desc: 'Join secure video consultations, track vaccines, and access full health records anytime.',
        icon: Heart,
        color: 'bg-rose-600',
    },
];

/* ═══════════════════════════════════════════════════════════════════════ */
export const Landing = () => {
    const { isDark, toggleTheme } = useThemeStore();
    const [menuOpen, setMenuOpen] = useState(false);
    const [scrolled, setScrolled] = useState(false);
    const [activeSection, setActiveSection] = useState('home');
    const [visibleSections, setVisibleSections] = useState(new Set());

    // Contact Form State
    const [contactForm, setContactForm] = useState({ firstName: '', lastName: '', email: '', subject: '', message: '' });
    const [contactStatus, setContactStatus] = useState({ loading: false, success: false, error: null });

    const handleContactSubmit = async (e) => {
        e.preventDefault();
        setContactStatus({ loading: true, success: false, error: null });
        try {
            const response = await api.post('/contact', contactForm);
            if (response.data.status === 'success') {
                setContactStatus({ loading: false, success: true, error: null });
                setContactForm({ firstName: '', lastName: '', email: '', subject: '', message: '' });
                setTimeout(() => setContactStatus(prev => ({ ...prev, success: false })), 5000);
            }
        } catch (error) {
            setContactStatus({ loading: false, success: false, error: error.response?.data?.message || 'Failed to send message.' });
        }
    };

    /* Scroll effects */
    useEffect(() => {
        const onScroll = () => {
            setScrolled(window.scrollY > 60);
            // Active section detection
            const sections = ['home', 'about', 'services', 'doctors', 'pricing', 'contact'];
            for (const id of [...sections].reverse()) {
                const el = document.getElementById(id);
                if (el && window.scrollY >= el.offsetTop - 120) {
                    setActiveSection(id);
                    break;
                }
            }
        };
        window.addEventListener('scroll', onScroll, { passive: true });
        return () => window.removeEventListener('scroll', onScroll);
    }, []);

    /* Section reveal */
    useEffect(() => {
        const io = new IntersectionObserver(
            entries => entries.forEach(e => {
                if (e.isIntersecting) setVisibleSections(prev => new Set([...prev, e.target.id]));
            }),
            { threshold: 0.1 }
        );
        document.querySelectorAll('[data-reveal]').forEach(el => io.observe(el));
        return () => io.disconnect();
    }, []);

    const scrollTo = (href) => {
        const id = href.replace('#', '');
        document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
        setMenuOpen(false);
    };

    const isVisible = (id) => visibleSections.has(id);

    return (
        <>
            <style>{STYLES}</style>
            <div className="min-h-screen bg-[--bg] font-sans overflow-x-hidden">

                {/* ══ NAVBAR ═════════════════════════════════════════════════════ */}
                <nav className={`fixed top-0 inset-x-0 z-50 transition-all duration-300
                    ${scrolled
                        ? 'bg-[--surface]/95 backdrop-blur-xl border-b border-[--border] shadow-sm'
                        : 'bg-transparent'}`}>
                    <div className="max-w-7xl mx-auto px-6 h-18 flex items-center justify-between" style={{ height: 72 }}>
                        {/* Logo */}
                        <a href="#home" onClick={e => { e.preventDefault(); scrollTo('#home'); }} className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-primary-600 flex items-center justify-center shadow-lg shadow-primary-600/30">
                                <Heart className="w-5 h-5 text-white" fill="currentColor"/>
                            </div>
                            <div>
                                <div className={`font-black text-base leading-none transition-colors ${scrolled ? 'text-[--text-primary]' : 'text-white'}`}>
                                    Pediatric Health Hub
                                </div>
                                <div className={`text-[10px] font-bold transition-colors ${scrolled ? 'text-[--text-muted]' : 'text-white/60'}`}>
                                    Somalia's #1 Child Health Platform
                                </div>
                            </div>
                        </a>

                        {/* Desktop Nav */}
                        <div className="hidden lg:flex items-center gap-8">
                            {NAV_LINKS.map(link => (
                                <a
                                    key={link.href}
                                    href={link.href}
                                    onClick={e => { e.preventDefault(); scrollTo(link.href); }}
                                    className={`lp-nav-link ${activeSection === link.href.replace('#','') ? 'active' : ''}
                                        ${!scrolled ? '!text-white/80 hover:!text-white' : ''}`}
                                >
                                    {link.label}
                                </a>
                            ))}
                        </div>

                        {/* Right actions */}
                        <div className="flex items-center gap-3">
                            <button
                                onClick={toggleTheme}
                                className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all
                                    ${scrolled
                                        ? 'border border-[--border] bg-[--surface] text-[--text-muted] hover:text-primary-600'
                                        : 'bg-white/10 border border-white/20 text-white/80 hover:text-white'}`}
                            >
                                {isDark ? <Sun size={17}/> : <Moon size={17}/>}
                            </button>
                            <a href="/login"
                                className={`hidden sm:inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl font-black text-sm transition-all
                                    ${scrolled
                                        ? 'border border-[--border] text-[--text-primary] hover:border-primary-400 hover:text-primary-600'
                                        : 'bg-white/10 border border-white/25 text-white hover:bg-white/20'}`}>
                                Sign In
                            </a>
                            <a href="/login"
                                className="hidden sm:inline-flex items-center gap-1.5 px-5 py-2.5 bg-primary-600 hover:bg-primary-700 text-white rounded-xl font-black text-sm shadow-lg shadow-primary-600/25 transition-all hover:-translate-y-0.5">
                                Get Started <ArrowRight size={15}/>
                            </a>
                            {/* Mobile hamburger */}
                            <button
                                onClick={() => setMenuOpen(!menuOpen)}
                                className={`lg:hidden w-9 h-9 rounded-xl flex items-center justify-center transition-all
                                    ${scrolled ? 'border border-[--border] bg-[--surface] text-[--text-primary]' : 'bg-white/10 border border-white/20 text-white'}`}
                            >
                                {menuOpen ? <X size={18}/> : <Menu size={18}/>}
                            </button>
                        </div>
                    </div>

                    {/* Mobile menu */}
                    {menuOpen && (
                        <div className="lg:hidden bg-[--surface] border-b border-[--border] px-6 py-5 space-y-2 shadow-xl">
                            {NAV_LINKS.map(link => (
                                <a key={link.href} href={link.href}
                                    onClick={e => { e.preventDefault(); scrollTo(link.href); }}
                                    className="flex items-center justify-between py-3 px-4 rounded-xl hover:bg-[--surface-soft] font-bold text-sm text-[--text-primary] transition-colors">
                                    {link.label} <ChevronRight size={15} className="text-[--text-muted]"/>
                                </a>
                            ))}
                            <div className="pt-3 flex gap-3">
                                <a href="/login" className="flex-1 text-center py-3 border-2 border-[--border] rounded-xl font-black text-sm text-[--text-primary]">Sign In</a>
                                <a href="/login" className="flex-1 text-center py-3 bg-primary-600 text-white rounded-xl font-black text-sm">Get Started</a>
                            </div>
                        </div>
                    )}
                </nav>

                {/* ══ HERO ═══════════════════════════════════════════════════════ */}
                <section id="home" className="relative min-h-screen flex items-center overflow-hidden">
                    {/* BG Image */}
                    <div className="absolute inset-0 overflow-hidden">
                        <img
                            src="https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1800&h=1100&q=85"
                            alt="Pediatric doctor"
                            className="w-full h-full object-cover lp-zoom-bg"
                            style={{ transformOrigin: 'center top' }}
                        />
                        <div className="absolute inset-0 bg-gradient-to-br from-slate-950/97 via-primary-950/90 to-teal-950/80"/>
                    </div>

                    {/* Decorative blobs */}
                    <div className="absolute top-32 right-8 w-80 h-80 bg-primary-500/10 rounded-full blur-3xl lp-float"/>
                    <div className="absolute bottom-20 left-12 w-64 h-64 bg-teal/10 rounded-full blur-3xl lp-float2"/>

                    <div className="relative z-10 max-w-7xl mx-auto px-6 pt-24 pb-16 grid lg:grid-cols-2 gap-16 items-center w-full">
                        {/* Left — Text */}
                        <div className="space-y-7">
                            {/* Badge */}
                            <div className="lp-fade-up inline-flex items-center gap-2.5 bg-white/10 border border-white/20 rounded-full px-5 py-2.5 backdrop-blur-sm" style={{ animationDelay: '0s' }}>
                                <span className="w-2 h-2 rounded-full bg-emerald-400 lp-pulse"/>
                                <span className="text-white/90 text-xs font-black uppercase tracking-widest">🇸🇴 Somalia's #1 Pediatric Platform</span>
                            </div>

                            <div className="lp-fade-up" style={{ animationDelay: '0.1s' }}>
                                <h1 className="text-5xl sm:text-6xl lg:text-7xl font-black text-white leading-[1.05] tracking-tight">
                                    Smart Care
                                    <br/>
                                    <span className="text-transparent bg-clip-text" style={{
                                        backgroundImage: 'linear-gradient(135deg, #60A5FA, #2DD4BF, #818CF8)'
                                    }}>
                                        for Every Child
                                    </span>
                                </h1>
                            </div>

                            <p className="lp-fade-up text-white/70 text-lg font-medium leading-relaxed max-w-lg" style={{ animationDelay: '0.2s' }}>
                                The comprehensive clinical platform connecting parents with certified pediatricians — from appointments to AI-powered health guidance, all in one place.
                            </p>

                            {/* CTAs */}
                            <div className="lp-fade-up flex flex-col sm:flex-row gap-4" style={{ animationDelay: '0.3s' }}>
                                <a href="/login"
                                    className="group inline-flex items-center justify-center gap-2.5 px-8 py-4 bg-primary-600 hover:bg-primary-500 text-white rounded-2xl font-black text-base shadow-2xl shadow-primary-600/40 transition-all hover:-translate-y-1">
                                    Get Started Free
                                    <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform"/>
                                </a>
                                <button
                                    onClick={() => scrollTo('#services')}
                                    className="inline-flex items-center justify-center gap-2.5 px-8 py-4 bg-white/10 hover:bg-white/20 border border-white/25 text-white rounded-2xl font-black text-base transition-all backdrop-blur-sm">
                                    <Play size={16} className="fill-white"/> See How It Works
                                </button>
                            </div>

                            {/* Stats row */}
                            <div className="lp-fade-up grid grid-cols-3 gap-6 pt-4 border-t border-white/10" style={{ animationDelay: '0.4s' }}>
                                {[
                                    { value: '50K+', label: 'Families' },
                                    { value: '200+', label: 'Doctors' },
                                    { value: '98%',  label: 'Satisfaction' },
                                ].map((s, i) => (
                                    <div key={i}>
                                        <div className="text-3xl font-black text-white">{s.value}</div>
                                        <div className="text-white/50 text-xs font-bold mt-0.5">{s.label}</div>
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Right — Floating UI cards */}
                        <div className="hidden lg:block relative" style={{ height: 500 }}>
                            {/* Main card */}
                            <div className="absolute top-10 right-0 w-80 bg-white/10 backdrop-blur-xl border border-white/15 rounded-3xl p-5 shadow-2xl lp-float">
                                <div className="flex items-center gap-3 mb-4">
                                    <img src="https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=60&h=60&q=80"
                                        alt="Doctor" className="w-11 h-11 rounded-full object-cover ring-2 ring-white/30"/>
                                    <div>
                                        <div className="text-white font-black text-sm">Dr. Halima Warsame</div>
                                        <div className="text-white/60 text-[11px] font-medium">General Pediatrics</div>
                                    </div>
                                    <div className="ml-auto w-2.5 h-2.5 rounded-full bg-emerald-400 lp-pulse"/>
                                </div>
                                <div className="bg-white/10 rounded-2xl p-3 mb-3">
                                    <div className="text-white/60 text-[10px] font-bold uppercase mb-2">Today's Schedule</div>
                                    {['09:00 · Vaccine Check', '10:30 · Growth Review', '14:00 · Teleconsult'].map((item, i) => (
                                        <div key={i} className="flex items-center gap-2 py-1.5">
                                            <div className="w-1.5 h-1.5 rounded-full bg-teal-400"/>
                                            <span className="text-white text-[11px] font-semibold">{item}</span>
                                        </div>
                                    ))}
                                </div>
                                <button className="w-full py-2.5 bg-primary-500 hover:bg-primary-400 text-white text-xs font-black rounded-xl transition-colors">
                                    Book Now
                                </button>
                            </div>

                            {/* Stat card top-left */}
                            <div className="absolute top-0 left-0 bg-emerald-500 rounded-2xl p-4 shadow-xl lp-float2">
                                <div className="text-white/70 text-[10px] font-black uppercase tracking-wider mb-1">Active Patients</div>
                                <div className="text-white font-black text-3xl">12,847</div>
                                <div className="flex items-center gap-1 mt-1 text-emerald-200 text-[10px] font-bold">
                                    <TrendingUp size={10}/> +18% this month
                                </div>
                            </div>

                            {/* Vaccine card */}
                            <div className="absolute bottom-20 left-8 bg-white/10 backdrop-blur-xl border border-white/15 rounded-2xl p-4 shadow-xl lp-float3">
                                <div className="flex items-center gap-2 mb-2">
                                    <Syringe size={16} className="text-violet-400"/>
                                    <span className="text-white font-black text-xs">Vaccine Due</span>
                                </div>
                                <div className="text-white/80 text-[11px] font-medium">Pentavalent Dose 2</div>
                                <div className="text-violet-300 text-[10px] font-bold mt-1 flex items-center gap-1">
                                    <Clock size={10}/> Tomorrow at 9:00 AM
                                </div>
                            </div>

                            {/* Rating card */}
                            <div className="absolute bottom-8 right-6 bg-white/10 backdrop-blur-xl border border-white/15 rounded-2xl p-3.5 shadow-xl lp-float">
                                <div className="flex items-center gap-1 mb-1">
                                    {[1,2,3,4,5].map(s => <Star key={s} size={13} className="text-amber-400 fill-amber-400"/>)}
                                </div>
                                <div className="text-white font-black text-sm">4.9 / 5.0</div>
                                <div className="text-white/50 text-[10px] font-medium">Based on 12,480 reviews</div>
                            </div>
                        </div>
                    </div>

                    {/* Scroll indicator */}
                    <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2">
                        <span className="text-white/40 text-[10px] font-bold uppercase tracking-widest">Scroll</span>
                        <div className="w-5 h-8 border-2 border-white/20 rounded-full flex justify-center pt-1.5">
                            <div className="w-1 h-2 bg-white/50 rounded-full lp-pulse"/>
                        </div>
                    </div>
                </section>

                {/* ══ TICKER ════════════════════════════════════════════════════ */}
                <div className="bg-primary-600 overflow-hidden py-3.5 border-y border-primary-500">
                    <div className="lp-ticker whitespace-nowrap text-white text-xs font-black tracking-wide">
                        {[...TICKER, ...TICKER].map((t, i) => (
                            <span key={i} className="mr-16 inline-block">{t}</span>
                        ))}
                    </div>
                </div>

                {/* ══ ABOUT ═════════════════════════════════════════════════════ */}
                <section id="about" data-reveal className="py-24 lg:py-32 px-6 bg-[--surface-soft]">
                    <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 lg:gap-24 items-center">
                        {/* Images grid */}
                        <div className={`relative ${isVisible('about') ? 'lp-fade-up' : 'opacity-0'}`}>
                            <div className="grid grid-cols-2 gap-4">
                                <img src="https://images.unsplash.com/photo-1588776814546-1ffbb39ac5e8?auto=format&fit=crop&w=400&h=500&q=80"
                                    alt="Pediatric care" className="w-full rounded-3xl object-cover shadow-xl" style={{ height: 280 }}/>
                                <img src="https://images.unsplash.com/photo-1609220136736-443140cffec6?auto=format&fit=crop&w=400&h=300&q=80"
                                    alt="Child nutrition" className="w-full rounded-3xl object-cover shadow-xl mt-12" style={{ height: 220 }}/>
                                <img src="https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=400&h=280&q=80"
                                    alt="Medical care" className="w-full rounded-3xl object-cover shadow-xl -mt-8" style={{ height: 200 }}/>
                                <img src="https://images.unsplash.com/photo-1530099486328-e021101a494a?auto=format&fit=crop&w=400&h=320&q=80"
                                    alt="Children" className="w-full rounded-3xl object-cover shadow-xl" style={{ height: 240 }}/>
                            </div>
                            {/* Floating stat */}
                            <div className="absolute -bottom-6 -right-4 bg-primary-600 text-white rounded-2xl p-5 shadow-2xl shadow-primary-600/30 lp-float">
                                <div className="font-black text-3xl">98%</div>
                                <div className="text-primary-200 text-xs font-bold mt-0.5">Parent Satisfaction</div>
                            </div>
                        </div>

                        {/* Text */}
                        <div className={`space-y-6 ${isVisible('about') ? 'lp-fade-up' : 'opacity-0'}`} style={{ animationDelay: '0.15s' }}>
                            <div className="inline-flex items-center gap-2 bg-primary-50 dark:bg-primary-950/40 border border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full">
                                <Heart size={12} fill="currentColor"/> About Us
                            </div>

                            <h2 className="text-4xl sm:text-5xl font-black text-[--text-primary] leading-tight tracking-tight">
                                Redefining Pediatric
                                <span className="block text-primary-600"> Care in Somalia</span>
                            </h2>

                            <p className="text-[--text-secondary] font-medium leading-relaxed text-base">
                                Pediatric Health Hub was founded with a single mission: make world-class child healthcare accessible to every Somali family, regardless of location or income level.
                            </p>
                            <p className="text-[--text-secondary] font-medium leading-relaxed text-base">
                                We combine modern technology with deep cultural understanding to deliver a platform that speaks your language — literally. Our Somali-first approach ensures parents in Mogadishu, Hargeisa, and Kismayo receive the same quality of care.
                            </p>

                            <div className="grid grid-cols-2 gap-4 pt-2">
                                {[
                                    { icon: Globe,   value: '4+ Cities',   label: 'Across Somalia' },
                                    { icon: Award,   value: '200+',        label: 'Verified Doctors' },
                                    { icon: Shield,  value: 'HIPAA',       label: 'Compliant' },
                                    { icon: Clock,   value: '24/7',        label: 'AI Support' },
                                ].map((s, i) => (
                                    <div key={i} className="flex items-center gap-3 p-4 bg-[--surface] border border-[--border] rounded-2xl">
                                        <div className="w-10 h-10 bg-primary-50 dark:bg-primary-950/40 rounded-xl flex items-center justify-center shrink-0">
                                            <s.icon size={18} className="text-primary-600"/>
                                        </div>
                                        <div>
                                            <div className="font-black text-[--text-primary] text-sm">{s.value}</div>
                                            <div className="text-[--text-muted] text-[11px] font-medium">{s.label}</div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </section>

                {/* ══ HOW IT WORKS ══════════════════════════════════════════════ */}
                <section id="how" data-reveal className="py-24 px-6 bg-[--bg]">
                    <div className="max-w-7xl mx-auto">
                        <div className={`text-center mb-16 ${isVisible('how') ? 'lp-fade-up' : 'opacity-0'}`}>
                            <div className="inline-flex items-center gap-2 bg-teal/10 border border-teal/20 text-teal text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-5">
                                <Zap size={12}/> How It Works
                            </div>
                            <h2 className="text-4xl sm:text-5xl font-black text-[--text-primary] tracking-tight mb-4">
                                3 Steps to Better Care
                            </h2>
                            <p className="text-[--text-secondary] font-medium max-w-xl mx-auto text-base">
                                Getting started takes less than 5 minutes. No paperwork, no waiting rooms.
                            </p>
                        </div>

                        <div className="grid md:grid-cols-3 gap-8 relative">
                            {/* Connecting line */}
                            <div className="hidden md:block absolute top-12 left-1/4 right-1/4 h-0.5 bg-gradient-to-r from-blue-300 via-teal-300 to-rose-300"/>

                            {HOW_STEPS.map((s, i) => (
                                <div key={i}
                                    className={`relative text-center ${isVisible('how') ? 'lp-fade-up' : 'opacity-0'}`}
                                    style={{ animationDelay: `${i * 0.15}s` }}>
                                    <div className={`w-20 h-20 ${s.color} rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-xl relative z-10`}>
                                        <s.icon size={32} className="text-white" strokeWidth={2}/>
                                        <div className="absolute -top-3 -right-3 w-7 h-7 bg-[--surface] border-2 border-[--border] rounded-full flex items-center justify-center font-black text-[11px] text-[--text-primary]">
                                            {s.n}
                                        </div>
                                    </div>
                                    <h3 className="font-black text-xl text-[--text-primary] mb-3">{s.title}</h3>
                                    <p className="text-[--text-secondary] font-medium text-sm leading-relaxed">{s.desc}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* ══ SERVICES ══════════════════════════════════════════════════ */}
                <section id="services" data-reveal className="py-24 lg:py-32 px-6 bg-[--surface-soft]">
                    <div className="max-w-7xl mx-auto">
                        <div className={`text-center mb-16 ${isVisible('services') ? 'lp-fade-up' : 'opacity-0'}`}>
                            <div className="inline-flex items-center gap-2 bg-violet-50 dark:bg-violet-950/30 border border-violet-200 dark:border-violet-800 text-violet-700 dark:text-violet-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-5">
                                <Sparkles size={12}/> Our Services
                            </div>
                            <h2 className="text-4xl sm:text-5xl font-black text-[--text-primary] tracking-tight mb-4">
                                Everything Your Child Needs
                            </h2>
                            <p className="text-[--text-secondary] font-medium max-w-2xl mx-auto text-base">
                                A full-spectrum pediatric management system designed for modern healthcare delivery across Somalia.
                            </p>
                        </div>

                        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                            {SERVICES.map((s, i) => (
                                <div key={i}
                                    className={`lp-card rounded-3xl overflow-hidden bg-[--surface] border border-[--border] shadow-sm group cursor-pointer
                                        ${isVisible('services') ? 'lp-fade-up' : 'opacity-0'}`}
                                    style={{ animationDelay: `${i * 0.08}s` }}>
                                    {/* Image */}
                                    <div className="h-44 overflow-hidden relative">
                                        <img src={s.img} alt={s.title}
                                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"/>
                                        <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent"/>
                                        <div className={`absolute top-4 left-4 w-10 h-10 ${s.bg} ${s.border} border rounded-2xl flex items-center justify-center backdrop-blur-sm`}>
                                            <s.icon size={18} className={s.color}/>
                                        </div>
                                    </div>
                                    {/* Body */}
                                    <div className="p-5">
                                        <h3 className="font-black text-[--text-primary] text-base mb-2 group-hover:text-primary-600 transition-colors">
                                            {s.title}
                                        </h3>
                                        <p className="text-sm text-[--text-secondary] font-medium leading-relaxed">
                                            {s.desc}
                                        </p>
                                        <div className={`flex items-center gap-1 mt-4 text-xs font-black ${s.color}`}>
                                            Learn more <ChevronRight size={14}/>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* ══ DOCTORS ═══════════════════════════════════════════════════ */}
                <section id="doctors" data-reveal className="py-24 lg:py-32 px-6 bg-[--bg]">
                    <div className="max-w-7xl mx-auto">
                        <div className={`text-center mb-16 ${isVisible('doctors') ? 'lp-fade-up' : 'opacity-0'}`}>
                            <div className="inline-flex items-center gap-2 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-5">
                                <Stethoscope size={12}/> Our Specialists
                            </div>
                            <h2 className="text-4xl sm:text-5xl font-black text-[--text-primary] tracking-tight mb-4">
                                Meet Our Top Doctors
                            </h2>
                            <p className="text-[--text-secondary] font-medium max-w-xl mx-auto text-base">
                                Every specialist on our platform is verified, certified, and committed to delivering excellence.
                            </p>
                        </div>

                        <div className="grid md:grid-cols-3 gap-8">
                            {DOCTORS.map((d, i) => (
                                <div key={i}
                                    className={`lp-card rounded-3xl overflow-hidden bg-[--surface] border border-[--border] shadow-sm text-center
                                        ${isVisible('doctors') ? 'lp-fade-up' : 'opacity-0'}`}
                                    style={{ animationDelay: `${i * 0.1}s` }}>
                                    {/* Cover */}
                                    <div className="relative h-60 overflow-hidden">
                                        <img src={d.img} alt={d.name} className="w-full h-full object-cover object-top group-hover:scale-105 transition-transform duration-500"/>
                                        <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"/>
                                        <span className={`absolute top-4 right-4 text-[10px] font-black px-3 py-1.5 rounded-full ${d.badgeColor}`}>
                                            ★ {d.badge}
                                        </span>
                                    </div>
                                    {/* Info */}
                                    <div className="p-6">
                                        <h3 className="font-black text-[--text-primary] text-lg mb-1">{d.name}</h3>
                                        <p className="text-primary-600 font-bold text-sm mb-1">{d.specialty}</p>
                                        <p className="text-[--text-muted] text-xs font-medium mb-4">{d.exp} experience</p>

                                        {/* Stars */}
                                        <div className="flex items-center justify-center gap-1 mb-4">
                                            {[1,2,3,4,5].map(s => (
                                                <Star key={s} size={14} className={s <= Math.floor(d.rating) ? 'text-amber-400 fill-amber-400' : 'text-slate-200 fill-slate-200'}/>
                                            ))}
                                            <span className="text-xs font-black text-[--text-primary] ml-1">{d.rating}</span>
                                            <span className="text-[10px] text-[--text-muted] ml-0.5">({d.reviews})</span>
                                        </div>

                                        <a href="/login"
                                            className="block w-full py-3 bg-primary-600 hover:bg-primary-700 text-white text-sm font-black rounded-xl transition-all hover:-translate-y-0.5 shadow-md">
                                            Book Appointment
                                        </a>
                                    </div>
                                </div>
                            ))}
                        </div>

                        <div className="text-center mt-12">
                            <a href="/login"
                                className="inline-flex items-center gap-2 px-8 py-4 border-2 border-primary-600 text-primary-600 hover:bg-primary-600 hover:text-white rounded-2xl font-black text-sm transition-all">
                                View All Doctors <ArrowRight size={16}/>
                            </a>
                        </div>
                    </div>
                </section>

                {/* ══ TESTIMONIALS ══════════════════════════════════════════════ */}
                <section data-reveal id="testimonials" className="py-24 lg:py-32 px-6 relative overflow-hidden bg-[--surface-soft]">
                    <div className="absolute inset-0">
                        <img src="https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=1600&h=800&q=70"
                            alt="bg" className="w-full h-full object-cover opacity-5"/>
                    </div>
                    <div className="relative max-w-7xl mx-auto">
                        <div className={`text-center mb-16 ${isVisible('testimonials') ? 'lp-fade-up' : 'opacity-0'}`}>
                            <div className="inline-flex items-center gap-2 bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 text-amber-700 dark:text-amber-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-5">
                                <Star size={12} fill="currentColor"/> Testimonials
                            </div>
                            <h2 className="text-4xl sm:text-5xl font-black text-[--text-primary] tracking-tight mb-4">
                                Trusted by Families
                            </h2>
                            <p className="text-[--text-secondary] font-medium max-w-xl mx-auto">
                                Real stories from parents and doctors across Somalia.
                            </p>
                        </div>

                        <div className="grid md:grid-cols-3 gap-6">
                            {TESTIMONIALS.map((t, i) => (
                                <div key={i}
                                    className={`lp-card bg-[--surface] border border-[--border] rounded-3xl p-7 shadow-sm
                                        ${isVisible('testimonials') ? 'lp-fade-up' : 'opacity-0'}`}
                                    style={{ animationDelay: `${i * 0.1}s` }}>
                                    {/* Stars */}
                                    <div className="flex gap-1 mb-4">
                                        {[1,2,3,4,5].map(s => <Star key={s} size={14} className="text-amber-400 fill-amber-400"/>)}
                                    </div>
                                    <p className="text-[--text-secondary] text-sm font-medium leading-relaxed mb-6 italic">
                                        {t.text}
                                    </p>
                                    <div className="flex items-center gap-3">
                                        <img src={t.img} alt={t.name} className="w-11 h-11 rounded-full object-cover ring-2 ring-primary-100 dark:ring-primary-900"/>
                                        <div>
                                            <div className="font-black text-[--text-primary] text-sm">{t.name}</div>
                                            <div className="text-[--text-muted] text-[11px] font-medium">{t.role}</div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* ══ PRICING ═══════════════════════════════════════════════════ */}
                <section id="pricing" data-reveal className="py-24 lg:py-32 px-6 bg-[--bg]">
                    <div className="max-w-6xl mx-auto">
                        <div className={`text-center mb-16 ${isVisible('pricing') ? 'lp-fade-up' : 'opacity-0'}`}>
                            <div className="inline-flex items-center gap-2 bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-800 text-rose-700 dark:text-rose-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-5">
                                <Zap size={12}/> Pricing
                            </div>
                            <h2 className="text-4xl sm:text-5xl font-black text-[--text-primary] tracking-tight mb-4">
                                Simple, Transparent Pricing
                            </h2>
                            <p className="text-[--text-secondary] font-medium max-w-xl mx-auto">
                                Start for free, upgrade when you need more. No hidden fees ever.
                            </p>
                        </div>

                        <div className="grid md:grid-cols-3 gap-6 items-stretch">
                            {PLANS.map((plan, i) => (
                                <div key={i}
                                    className={`relative rounded-3xl border-2 overflow-hidden bg-[--surface] shadow-sm flex flex-col
                                        ${plan.highlight ? 'border-primary-500 shadow-2xl shadow-primary-500/15' : plan.color}
                                        ${isVisible('pricing') ? 'lp-fade-up' : 'opacity-0'}`}
                                    style={{ animationDelay: `${i * 0.1}s` }}>

                                    {plan.highlight && (
                                        <div className="bg-primary-600 text-white text-[10px] font-black uppercase tracking-widest text-center py-2">
                                            ⭐ Most Popular
                                        </div>
                                    )}

                                    <div className="p-7 flex flex-col flex-1">
                                        <div className="mb-6">
                                            <h3 className="font-black text-[--text-primary] text-xl mb-1">{plan.name}</h3>
                                            <p className="text-[--text-muted] text-sm font-medium mb-4">{plan.desc}</p>
                                            <div className="flex items-end gap-1">
                                                <span className={`text-5xl font-black tracking-tight ${plan.highlight ? 'text-primary-600' : 'text-[--text-primary]'}`}>
                                                    {plan.price}
                                                </span>
                                                <span className="text-[--text-muted] font-medium text-sm mb-2">/{plan.period}</span>
                                            </div>
                                        </div>

                                        <div className="space-y-3 flex-1 mb-7">
                                            {plan.features.map((f, fi) => (
                                                <div key={fi} className="flex items-center gap-3">
                                                    <CheckCircle size={16} className={`shrink-0 ${plan.highlight ? 'text-primary-500' : 'text-emerald-500'}`}/>
                                                    <span className="text-sm font-medium text-[--text-secondary]">{f}</span>
                                                </div>
                                            ))}
                                        </div>

                                        <a href="/login"
                                            className={`block text-center py-3.5 rounded-2xl font-black text-sm transition-all hover:-translate-y-0.5
                                                ${plan.highlight
                                                    ? 'bg-primary-600 hover:bg-primary-700 text-white shadow-lg shadow-primary-600/25'
                                                    : 'border-2 border-[--border] text-[--text-primary] hover:border-primary-400 hover:text-primary-600'
                                                }`}>
                                            {plan.cta}
                                        </a>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* ══ CONTACT ═══════════════════════════════════════════════════ */}
                <section id="contact" data-reveal className="py-24 lg:py-32 px-6 bg-[--surface-soft]">
                    <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-start">
                        {/* Left */}
                        <div className={`${isVisible('contact') ? 'lp-fade-up' : 'opacity-0'}`}>
                            <div className="inline-flex items-center gap-2 bg-primary-50 dark:bg-primary-950/40 border border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-6">
                                <Mail size={12}/> Contact Us
                            </div>
                            <h2 className="text-4xl sm:text-5xl font-black text-[--text-primary] tracking-tight leading-tight mb-5">
                                Get in Touch<br className="hidden sm:block"/>
                                <span className="text-primary-600"> With Our Team</span>
                            </h2>
                            <p className="text-[--text-secondary] font-medium leading-relaxed mb-8">
                                Whether you're a parent, a doctor wanting to join our network, or a clinic seeking to integrate — our team is ready to help you get started.
                            </p>

                            <div className="space-y-4">
                                {[
                                    { icon: Mail,        label: 'Email',    value: 'support@pediatrichealthhub.so' },
                                    { icon: Phone,       label: 'Phone',    value: '+252 61 000 0000' },
                                    { icon: MapPin,      label: 'Address',  value: 'Mogadishu, Somalia' },
                                    { icon: Clock,       label: 'Hours',    value: '24/7 AI · 8AM–8PM Human Support' },
                                ].map((c, i) => (
                                    <div key={i} className="flex items-center gap-4 p-4 bg-[--surface] border border-[--border] rounded-2xl">
                                        <div className="w-10 h-10 bg-primary-50 dark:bg-primary-950/40 rounded-xl flex items-center justify-center shrink-0">
                                            <c.icon size={18} className="text-primary-600"/>
                                        </div>
                                        <div>
                                            <div className="text-[10px] font-black text-[--text-muted] uppercase tracking-wide">{c.label}</div>
                                            <div className="text-sm font-bold text-[--text-primary]">{c.value}</div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Right — Form */}
                        <div className={`bg-[--surface] border border-[--border] rounded-3xl p-8 shadow-sm ${isVisible('contact') ? 'lp-fade-up' : 'opacity-0'}`}
                            style={{ animationDelay: '0.15s' }}>
                            <h3 className="font-black text-[--text-primary] text-xl mb-6">Send Us a Message</h3>
                            
                            {contactStatus.success && (
                                <div className="mb-6 p-4 bg-emerald-50 dark:bg-emerald-900/30 border border-emerald-200 dark:border-emerald-800 rounded-xl flex items-center gap-3 text-emerald-700 dark:text-emerald-400">
                                    <CheckCircle size={20} />
                                    <p className="text-sm font-bold">Your message has been sent successfully!</p>
                                </div>
                            )}

                            {contactStatus.error && (
                                <div className="mb-6 p-4 bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-800 rounded-xl text-red-700 dark:text-red-400 text-sm font-bold">
                                    {contactStatus.error}
                                </div>
                            )}

                            <form onSubmit={handleContactSubmit} className="space-y-4">
                                <div className="grid sm:grid-cols-2 gap-4">
                                    <div>
                                        <label className="text-xs font-black text-[--text-muted] uppercase tracking-wide block mb-2">First Name</label>
                                        <input type="text" placeholder="First Name" required
                                            value={contactForm.firstName} onChange={(e) => setContactForm({...contactForm, firstName: e.target.value})}
                                            className="w-full px-4 py-3 border-2 border-[--border] rounded-xl bg-[--surface-soft] text-[--text-primary] text-sm font-medium placeholder-[--text-muted] focus:outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-all"/>
                                    </div>
                                    <div>
                                        <label className="text-xs font-black text-[--text-muted] uppercase tracking-wide block mb-2">Last Name</label>
                                        <input type="text" placeholder="Last Name" required
                                            value={contactForm.lastName} onChange={(e) => setContactForm({...contactForm, lastName: e.target.value})}
                                            className="w-full px-4 py-3 border-2 border-[--border] rounded-xl bg-[--surface-soft] text-[--text-primary] text-sm font-medium placeholder-[--text-muted] focus:outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-all"/>
                                    </div>
                                </div>
                                <div>
                                    <label className="text-xs font-black text-[--text-muted] uppercase tracking-wide block mb-2">Email Address</label>
                                    <input type="email" placeholder="your@email.com" required
                                        value={contactForm.email} onChange={(e) => setContactForm({...contactForm, email: e.target.value})}
                                        className="w-full px-4 py-3 border-2 border-[--border] rounded-xl bg-[--surface-soft] text-[--text-primary] text-sm font-medium placeholder-[--text-muted] focus:outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-all"/>
                                </div>
                                <div>
                                    <label className="text-xs font-black text-[--text-muted] uppercase tracking-wide block mb-2">Subject</label>
                                    <input type="text" placeholder="How can we help?" required
                                        value={contactForm.subject} onChange={(e) => setContactForm({...contactForm, subject: e.target.value})}
                                        className="w-full px-4 py-3 border-2 border-[--border] rounded-xl bg-[--surface-soft] text-[--text-primary] text-sm font-medium placeholder-[--text-muted] focus:outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-all"/>
                                </div>
                                <div>
                                    <label className="text-xs font-black text-[--text-muted] uppercase tracking-wide block mb-2">Message</label>
                                    <textarea rows={4} placeholder="Tell us about your needs..." required
                                        value={contactForm.message} onChange={(e) => setContactForm({...contactForm, message: e.target.value})}
                                        className="w-full px-4 py-3 border-2 border-[--border] rounded-xl bg-[--surface-soft] text-[--text-primary] text-sm font-medium placeholder-[--text-muted] focus:outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-all resize-none"/>
                                </div>
                                <button type="submit" disabled={contactStatus.loading} className="w-full py-4 bg-primary-600 hover:bg-primary-700 disabled:opacity-70 text-white font-black text-sm rounded-xl transition-all hover:-translate-y-0.5 shadow-lg shadow-primary-600/25 flex items-center justify-center gap-2">
                                    {contactStatus.loading ? (
                                        <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"/>
                                    ) : (
                                        <><MessageSquare size={16}/> Send Message</>
                                    )}
                                </button>
                            </form>
                        </div>
                    </div>
                </section>

                {/* ══ CTA BANNER ════════════════════════════════════════════════ */}
                <section className="py-20 px-6 bg-[--bg]">
                    <div className="max-w-5xl mx-auto relative rounded-3xl overflow-hidden" style={{
                        background: 'linear-gradient(135deg, #1E3A8A 0%, #2563EB 50%, #0F766E 100%)'
                    }}>
                        <div className="absolute inset-0">
                            <img src="https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1200&h=400&q=60"
                                alt="" className="w-full h-full object-cover opacity-10"/>
                        </div>
                        <div className="absolute top-0 right-0 w-96 h-96 rounded-full bg-white/5 blur-3xl"/>
                        <div className="relative z-10 py-16 px-10 text-center">
                            <h2 className="text-4xl sm:text-5xl font-black text-white tracking-tight mb-4">
                                Ready to Transform<br/>Pediatric Care?
                            </h2>
                            <p className="text-blue-100/80 text-lg font-medium max-w-xl mx-auto mb-8">
                                Join thousands of families and healthcare providers who trust Pediatric Health Hub.
                            </p>
                            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                                <a href="/login"
                                    className="inline-flex items-center gap-2 px-8 py-4 bg-white text-primary-700 rounded-2xl font-black text-base shadow-2xl hover:shadow-xl hover:-translate-y-1 transition-all">
                                    Get Started Free <ArrowRight size={18}/>
                                </a>
                                <button
                                    onClick={() => scrollTo('#contact')}
                                    className="inline-flex items-center gap-2 px-8 py-4 bg-white/10 border border-white/25 text-white rounded-2xl font-black text-base hover:bg-white/20 transition-all">
                                    <Phone size={16}/> Talk to Sales
                                </button>
                            </div>
                        </div>
                    </div>
                </section>

                {/* ══ FOOTER ════════════════════════════════════════════════════ */}
                <footer className="bg-slate-950 text-slate-300 px-6 pt-16 pb-8">
                    <div className="max-w-7xl mx-auto">
                        <div className="grid sm:grid-cols-2 lg:grid-cols-5 gap-10 mb-12">
                            {/* Brand */}
                            <div className="lg:col-span-2 space-y-5">
                                <div className="flex items-center gap-3">
                                    <div className="w-10 h-10 rounded-xl bg-primary-600 flex items-center justify-center">
                                        <Heart className="w-5 h-5 text-white" fill="currentColor"/>
                                    </div>
                                    <div>
                                        <div className="font-black text-white">Pediatric Health Hub</div>
                                        <div className="text-slate-400 text-[11px]">Somalia's #1 Child Health Platform</div>
                                    </div>
                                </div>
                                <p className="text-sm text-slate-400 leading-relaxed max-w-xs">
                                    Connecting families with certified pediatricians across Somalia. Modern, secure, and always accessible.
                                </p>
                                <div className="flex gap-3">
                                    {['FB', 'TW', 'IG', 'LI'].map(s => (
                                        <div key={s} className="w-9 h-9 bg-slate-800 hover:bg-primary-600 rounded-xl flex items-center justify-center text-[10px] font-black text-slate-400 hover:text-white transition-all cursor-pointer">
                                            {s}
                                        </div>
                                    ))}
                                </div>
                            </div>

                            {/* Links */}
                            {[
                                { title: 'Platform', links: ['Book Appointment', 'Teleconsultation', 'Vaccine Tracking', 'Growth Charts', 'AI Assistant'] },
                                { title: 'Portals',  links: ['Parent Portal', 'Doctor Portal', 'Facility Portal', 'Admin Portal'] },
                                { title: 'Company',  links: ['About Us', 'Pricing', 'Contact', 'Privacy Policy', 'Terms of Service'] },
                            ].map((col, i) => (
                                <div key={i}>
                                    <h4 className="font-black text-white text-sm mb-5">{col.title}</h4>
                                    <ul className="space-y-3">
                                        {col.links.map((link, j) => (
                                            <li key={j}>
                                                <a href="/login" className="text-sm text-slate-400 hover:text-white transition-colors">{link}</a>
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            ))}
                        </div>

                        {/* Bottom bar */}
                        <div className="pt-8 border-t border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-4">
                            <p className="text-sm text-slate-500">© 2026 Pediatric Health Hub. All rights reserved.</p>
                            <div className="flex items-center gap-2 text-xs font-black text-slate-500 uppercase tracking-wider">
                                <div className="w-2 h-2 rounded-full bg-emerald-500 lp-pulse"/>
                                All Systems Operational
                            </div>
                        </div>
                    </div>
                </footer>
            </div>
        </>
    );
};
