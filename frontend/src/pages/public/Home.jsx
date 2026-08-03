import React, { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowRight, Shield, Users, Activity, Calendar,
  Syringe, Phone, Bot, BookOpen, Star, CheckCircle, Play
} from 'lucide-react';

const STYLES = `
@keyframes h-fadeUp {
  from { opacity: 0; transform: translateY(32px); }
  to   { opacity: 1; transform: translateY(0); }
}
@keyframes h-float {
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(-10px); }
}
@keyframes h-pulse-ring {
  0%   { transform: scale(1); opacity: 0.6; }
  100% { transform: scale(1.6); opacity: 0; }
}
@keyframes h-ticker {
  from { transform: translateX(0); }
  to   { transform: translateX(-50%); }
}
.h-fadeUp   { animation: h-fadeUp 0.7s ease both; }
.h-float    { animation: h-float 5s ease-in-out infinite; }
.h-reveal   { opacity: 0; transform: translateY(28px); transition: opacity 0.6s ease, transform 0.6s ease; }
.h-revealed { opacity: 1; transform: translateY(0); }
.h-ticker   { animation: h-ticker 28s linear infinite; }
`;

const STATS = [
  { value: '12,000+', label: 'Children Tracked' },
  { value: '350+', label: 'Certified Doctors' },
  { value: '98%', label: 'Parent Satisfaction' },
  { value: '24/7', label: 'Emergency Support' },
];

const FEATURES = [
  { icon: Syringe, color: 'teal', title: 'Vaccine Tracker', desc: 'Never miss a scheduled vaccine. Track every dose with smart reminders.' },
  { icon: Activity, color: 'purple', title: 'Growth Monitoring', desc: 'WHO-standard growth charts updated in real time at every clinic visit.' },
  { icon: Phone, color: 'blue', title: 'Teleconsultation', desc: 'Connect with certified pediatricians from home via encrypted video calls.' },
  { icon: Bot, color: 'rose', title: 'AI Health Assistant', desc: 'Ask health questions 24/7 in English or Somali — powered by AI.' },
  { icon: BookOpen, color: 'amber', title: 'Health Education', desc: 'Curated articles on child nutrition, development milestones, and first aid.' },
  { icon: Calendar, color: 'green', title: 'Smart Booking', desc: 'Book clinic visits or specialist appointments in under 2 minutes.' },
];

const COLOR = {
  teal: 'bg-teal-50 text-teal-600 border-teal-100',
  purple: 'bg-purple-50 text-purple-600 border-purple-100',
  blue: 'bg-blue-50 text-blue-600 border-blue-100',
  rose: 'bg-rose-50 text-rose-600 border-rose-100',
  amber: 'bg-amber-50 text-amber-600 border-amber-100',
  green: 'bg-green-50 text-green-600 border-green-100',
};

const TESTIMONIALS = [
  {
    name: 'Hodan Farah', role: 'Mother of 3, Mogadishu',
    avatar: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=80&h=80&fit=crop&crop=face&q=80',
    text: '"Nidaamkan waa barakaysan yahay. Carruurteena waa u nabadgalyo. The vaccine reminders saved us from missing my son\'s booster."',
    stars: 5,
  },
  {
    name: 'Dr. Abdirahman Ali', role: 'Pediatrician, Hargeisa',
    avatar: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=80&h=80&fit=crop&crop=face&q=80',
    text: '"The platform lets me serve patients across three cities. The teleconsult feature is seamlessly integrated and the records are always up to date."',
    stars: 5,
  },
  {
    name: 'Fadumo Isse', role: 'Parent, Kismayo',
    avatar: 'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=80&h=80&fit=crop&crop=face&q=80',
    text: '"I used to travel 2 hours to see a doctor for simple consultations. Now I join a video call from home. This is the future of healthcare."',
    stars: 5,
  },
];

export const Home = () => {
  const revealRef = useRef([]);

  useEffect(() => {
    const io = new IntersectionObserver(
      entries => entries.forEach(e => { if (e.isIntersecting) e.target.classList.add('h-revealed'); }),
      { threshold: 0.12 }
    );
    revealRef.current.forEach(el => el && io.observe(el));
    return () => io.disconnect();
  }, []);

  const addRef = el => { if (el && !revealRef.current.includes(el)) revealRef.current.push(el); };

  return (
    <>
      <style>{STYLES}</style>

      {/* ── HERO ─────────────────────────────────────────────────────────── */}
      <section className="relative min-h-screen flex items-center overflow-hidden bg-slate-900">
        {/* Background image */}
        <div className="absolute inset-0">
          <img
            src="https://images.unsplash.com/photo-1631815589968-fdb09a223b1e?auto=format&fit=crop&w=1600&q=80"
            alt="African mother with child at clinic"
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-linear-to-r from-slate-900/95 via-slate-900/75 to-slate-900/30" />
        </div>

        {/* Floating badge */}
        <div className="absolute top-32 right-10 lg:right-24 h-float hidden md:block">
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl px-5 py-4 text-white shadow-2xl">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-teal-400/20 flex items-center justify-center">
                <Shield size={18} className="text-teal-400" />
              </div>
              <div>
                <p className="text-xs text-white/60 font-medium">Active Today</p>
                <p className="text-base font-black">2,400+ Parents</p>
              </div>
            </div>
          </div>
        </div>

        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-32">
          <div className="max-w-2xl">
            {/* Somali badge */}
            <div className="inline-flex items-center gap-2 bg-teal-500/20 border border-teal-400/30 rounded-full px-4 py-2 mb-6">
              <span className="w-2 h-2 rounded-full bg-teal-400 animate-pulse" />
              <span className="text-teal-300 text-xs font-black tracking-widest uppercase">Ku soo dhawow · Somali Families</span>
            </div>

            <h1 className="h-fadeUp text-5xl sm:text-6xl lg:text-7xl font-black text-white leading-[1.05] tracking-tight mb-6">
              Caafimaadka{' '}
              <span className="bg-linear-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">
                Carruurta
              </span>
              <br />
              <span className="text-white/90 text-4xl sm:text-5xl lg:text-6xl">in Your Hands</span>
            </h1>

            <p className="h-fadeUp text-lg text-white/70 leading-relaxed mb-10 max-w-xl" style={{ animationDelay: '0.15s' }}>
              The complete digital health platform for Somali families — vaccine tracking, growth monitoring,
              teleconsultations, and AI-powered health guidance in English and Somali.
            </p>

            <div className="h-fadeUp flex flex-wrap gap-4" style={{ animationDelay: '0.28s' }}>
              <Link
                to="/login"
                className="inline-flex items-center gap-2 px-7 py-4 bg-teal-500 hover:bg-teal-400 text-white font-black rounded-2xl shadow-xl shadow-teal-500/40 hover:-translate-y-1 transition-all"
              >
                Start for Free <ArrowRight size={18} />
              </Link>
              <Link
                to="/services"
                className="inline-flex items-center gap-2 px-7 py-4 bg-white/10 hover:bg-white/20 text-white font-semibold rounded-2xl border border-white/20 backdrop-blur-sm transition-all"
              >
                <Play size={16} className="fill-white" /> Explore Services
              </Link>
            </div>

            {/* Trust indicators */}
            <div className="h-fadeUp flex flex-wrap gap-4 mt-10" style={{ animationDelay: '0.4s' }}>
              {['No credit card required', 'HIPAA-ready', 'Somali language support'].map(t => (
                <span key={t} className="flex items-center gap-1.5 text-xs text-white/60 font-medium">
                  <CheckCircle size={13} className="text-teal-400" /> {t}
                </span>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ── STATS TICKER ─────────────────────────────────────────────────── */}
      <section className="bg-teal-600 py-5 overflow-hidden">
        <div className="flex whitespace-nowrap h-ticker">
          {[...STATS, ...STATS].map((s, i) => (
            <div key={i} className="inline-flex items-center gap-8 mx-12">
              <span className="text-2xl font-black text-white">{s.value}</span>
              <span className="text-sm font-medium text-teal-100">{s.label}</span>
              <span className="text-teal-400">·</span>
            </div>
          ))}
        </div>
      </section>

      {/* ── FEATURES ─────────────────────────────────────────────────────── */}
      <section className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div ref={addRef} className="h-reveal text-center mb-16">
            <span className="text-xs font-black text-teal-600 uppercase tracking-widest">Everything You Need</span>
            <h2 className="text-4xl font-black text-slate-900 mt-2 mb-4">
              Complete Pediatric Care Platform
            </h2>
            <p className="text-slate-500 max-w-xl mx-auto">
              From your baby's first vaccine to teleconsultations with specialists — all in one secure platform designed for Somali families.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {FEATURES.map((f, i) => (
              <div
                key={f.title}
                ref={addRef}
                className="h-reveal group bg-white border border-slate-100 rounded-2xl p-7 hover:border-teal-200 hover:shadow-xl hover:shadow-teal-500/8 hover:-translate-y-1 transition-all cursor-pointer"
                style={{ transitionDelay: `${i * 80}ms` }}
              >
                <div className={`w-12 h-12 rounded-xl border flex items-center justify-center mb-5 ${COLOR[f.color]}`}>
                  <f.icon size={22} />
                </div>
                <h3 className="text-lg font-black text-slate-900 mb-2">{f.title}</h3>
                <p className="text-sm text-slate-500 leading-relaxed">{f.desc}</p>
                <div className="mt-5 flex items-center gap-1 text-teal-600 text-sm font-semibold opacity-0 group-hover:opacity-100 transition-opacity">
                  Learn more <ArrowRight size={14} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── COMMUNITY SHOWCASE ───────────────────────────────────────────── */}
      <section className="py-24 bg-slate-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            <div ref={addRef} className="h-reveal">
              <span className="text-xs font-black text-teal-600 uppercase tracking-widest">Built for Our Community</span>
              <h2 className="text-4xl font-black text-slate-900 mt-2 mb-6 leading-tight">
                Serving Somali Families<br />Across East Africa
              </h2>
              <p className="text-slate-600 leading-relaxed mb-6">
                <span className="font-bold text-slate-800">Pediatric Health Hub</span> was built from the ground up with the Somali community in mind. Our platform supports both English and Somali languages, connecting parents in Mogadishu, Hargeisa, Kismayo, and beyond with qualified pediatric care.
              </p>
              <p className="text-slate-600 leading-relaxed mb-8">
                <em className="text-teal-700 font-semibold not-italic">"Caafimaadka carruurta waa mas'uuliyad wadaag"</em> — Child health is a shared responsibility. We make that responsibility easier to fulfill.
              </p>
              <div className="flex flex-wrap gap-4">
                {[['12K+', 'Registered Families'], ['350+', 'Certified Doctors'], ['15', 'Partner Hospitals']].map(([n, l]) => (
                  <div key={l} className="bg-white rounded-2xl border border-slate-200 px-6 py-4 text-center shadow-sm">
                    <div className="text-2xl font-black text-teal-600">{n}</div>
                    <div className="text-xs text-slate-500 font-medium mt-0.5">{l}</div>
                  </div>
                ))}
              </div>
            </div>
            <div ref={addRef} className="h-reveal relative">
              <div className="grid grid-cols-2 gap-4">
                <img
                  src="https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=500&q=80"
                  alt="Doctor with patient"
                  className="rounded-2xl w-full h-56 object-cover shadow-lg"
                />
                <img
                  src="https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&w=500&q=80"
                  alt="Child at clinic"
                  className="rounded-2xl w-full h-56 object-cover shadow-lg mt-8"
                />
                <img
                  src="https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?auto=format&fit=crop&w=500&q=80"
                  alt="African family at hospital"
                  className="rounded-2xl w-full h-48 object-cover shadow-lg -mt-4"
                />
                <img
                  src="https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=500&q=80"
                  alt="Healthcare professional"
                  className="rounded-2xl w-full h-48 object-cover shadow-lg mt-4"
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── TESTIMONIALS ─────────────────────────────────────────────────── */}
      <section className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div ref={addRef} className="h-reveal text-center mb-14">
            <span className="text-xs font-black text-teal-600 uppercase tracking-widest">Community Voices</span>
            <h2 className="text-4xl font-black text-slate-900 mt-2">Trusted by Families & Doctors</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {TESTIMONIALS.map((t, i) => (
              <div key={t.name} ref={addRef} className="h-reveal bg-slate-50 rounded-2xl p-7 border border-slate-100" style={{ transitionDelay: `${i * 100}ms` }}>
                <div className="flex gap-0.5 mb-4">
                  {Array(t.stars).fill(0).map((_, j) => <Star key={j} size={14} className="text-amber-400 fill-amber-400" />)}
                </div>
                <p className="text-slate-700 text-sm leading-relaxed mb-6 italic">{t.text}</p>
                <div className="flex items-center gap-3">
                  <img src={t.avatar} alt={t.name} className="w-10 h-10 rounded-full object-cover" />
                  <div>
                    <p className="text-sm font-bold text-slate-900">{t.name}</p>
                    <p className="text-xs text-slate-500">{t.role}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA BANNER ───────────────────────────────────────────────────── */}
      <section className="relative py-24 overflow-hidden bg-teal-600">
        <div className="absolute inset-0">
          <img
            src="https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=1400&q=80"
            alt="Somali community"
            className="w-full h-full object-cover opacity-10"
          />
        </div>
        <div className="relative max-w-3xl mx-auto px-4 text-center">
          <h2 ref={addRef} className="h-reveal text-4xl sm:text-5xl font-black text-white mb-4 leading-tight">
            Bilow Maanta — Start Today<br />
            <span className="text-teal-200">It's Free Forever</span>
          </h2>
          <p className="text-teal-100 mb-10 text-lg">Join 12,000+ Somali families already using Pediatric Health Hub to keep their children healthy.</p>
          <Link
            to="/login"
            className="inline-flex items-center gap-2 px-8 py-4 bg-white text-teal-700 font-black text-lg rounded-2xl shadow-2xl hover:shadow-white/25 hover:-translate-y-1 transition-all"
          >
            Create Free Account <ArrowRight size={20} />
          </Link>
        </div>
      </section>
    </>
  );
};
