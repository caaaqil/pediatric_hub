import React, { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import {
  Syringe, Activity, Video, Bot, BookOpen, Calendar,
  Phone, MapPin, Shield, Clock, ArrowRight, CheckCircle
} from 'lucide-react';

const STYLES = `
@keyframes s-fadeUp { from{opacity:0;transform:translateY(28px)} to{opacity:1;transform:translateY(0)} }
.s-reveal { opacity:0; transform:translateY(24px); transition:opacity 0.6s ease, transform 0.6s ease; }
.s-revealed { opacity:1; transform:translateY(0); }
`;

const SERVICES = [
  {
    icon: Syringe,
    color: 'teal',
    gradient: 'from-teal-500 to-cyan-400',
    bg: 'bg-teal-50',
    title: 'Vaccine Tracker',
    titleSo: 'Raadraaca Talaalka',
    desc: 'Track every vaccine your child has received and every one that is due. Our system follows WHO and Ministry of Health schedules with smart, personalized reminders sent via SMS and app notification.',
    features: ['WHO-standard schedule', 'SMS reminders 7 days before', 'Multi-child management', 'Certificate generation', 'Clinic sync in real time'],
    img: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80',
  },
  {
    icon: Activity,
    color: 'purple',
    gradient: 'from-purple-500 to-violet-400',
    bg: 'bg-purple-50',
    title: 'Growth Monitoring',
    titleSo: 'Kormeerka Kobaca',
    desc: 'Plot your child\'s height, weight, and head circumference on WHO-certified growth charts. Identify nutrition concerns early and share charts directly with your pediatrician at every visit.',
    features: ['WHO growth percentile charts', 'Malnutrition risk alerts', 'Doctor annotation support', 'Historical trend graphs', 'Export to PDF for school'],
    img: 'https://images.unsplash.com/photo-1631815589968-fdb09a223b1e?auto=format&fit=crop&w=600&q=80',
  },
  {
    icon: Video,
    color: 'blue',
    gradient: 'from-blue-500 to-indigo-400',
    bg: 'bg-blue-50',
    title: 'Teleconsultation',
    titleSo: 'Guryaha Kala Hadlidda',
    desc: 'Join a secure, encrypted video call with a verified pediatrician from anywhere in Somalia. No travel required — ideal for follow-ups, advice, and non-emergency consultations.',
    features: ['End-to-end encrypted video', 'Book within 2 minutes', 'Works on 2G networks', 'Recorded for medical records', 'Doctor sends prescriptions digitally'],
    img: 'https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?auto=format&fit=crop&w=600&q=80',
  },
  {
    icon: Bot,
    color: 'rose',
    gradient: 'from-rose-500 to-pink-400',
    bg: 'bg-rose-50',
    title: 'AI Health Assistant',
    titleSo: 'Kaaliyaha Caafimaadka',
    desc: 'Ask health questions at any hour — in English or Somali. Our AI assistant, trained on pediatric medical guidelines, provides evidence-based guidance and knows when to escalate to a real doctor.',
    features: ['24/7 availability', 'Somali & English language', 'Pediatric-specialized AI', 'Emergency escalation', 'Conversation history saved'],
    img: 'https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=600&q=80',
  },
  {
    icon: BookOpen,
    color: 'amber',
    gradient: 'from-amber-500 to-orange-400',
    bg: 'bg-amber-50',
    title: 'Health Education Library',
    titleSo: 'Maktabadda Caafimaadka',
    desc: 'Access a curated library of medically reviewed articles on nutrition, developmental milestones, first aid, dental health, and mental well-being — written for Somali parents.',
    features: ['200+ reviewed articles', 'Nutrition & meal guides', 'Developmental milestone trackers', 'Emergency first aid guides', 'Video content (coming soon)'],
    img: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=600&q=80',
  },
  {
    icon: Calendar,
    color: 'green',
    gradient: 'from-green-500 to-emerald-400',
    bg: 'bg-green-50',
    title: 'Smart Appointment Booking',
    titleSo: 'Balanta Casriga ah',
    desc: 'Book clinic visits, specialist consultations, or follow-up appointments in 2 minutes. Choose your doctor, select a time, and receive instant confirmation with a map link to the facility.',
    features: ['Real-time availability', 'Specialist filtering', 'Child profile auto-fill', 'Cancellation & rescheduling', 'Reminders the day before'],
    img: 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&w=600&q=80',
  },
];

const HOW = [
  { step: '01', title: 'Create Your Account', desc: 'Register free in under 2 minutes. Add your children\'s profiles with basic health info.' },
  { step: '02', title: 'Find Your Doctor', desc: 'Browse verified pediatricians by specialty, location, and availability.' },
  { step: '03', title: 'Book or Consult', desc: 'Book a clinic visit or start a teleconsultation — all from one dashboard.' },
  { step: '04', title: 'Track & Learn', desc: 'Monitor vaccines, growth, and access health education — all in Somali and English.' },
];

export const Services = () => {
  const revealRef = useRef([]);

  useEffect(() => {
    const io = new IntersectionObserver(
      es => es.forEach(e => { if (e.isIntersecting) e.target.classList.add('s-revealed'); }),
      { threshold: 0.1 }
    );
    revealRef.current.forEach(el => el && io.observe(el));
    return () => io.disconnect();
  }, []);

  const addRef = el => { if (el && !revealRef.current.includes(el)) revealRef.current.push(el); };

  return (
    <>
      <style>{STYLES}</style>

      {/* ── HERO ─────────────────────────────────────────────────────────── */}
      <section className="relative pt-32 pb-20 bg-slate-900 overflow-hidden">
        <div className="absolute inset-0">
          <img
            src="https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=1600&q=80"
            alt="Medical professional with child"
            className="w-full h-full object-cover opacity-20"
          />
          <div className="absolute inset-0 bg-linear-to-b from-slate-900/70 to-slate-900" />
        </div>
        <div className="relative max-w-4xl mx-auto px-4 text-center">
          <span className="inline-block bg-teal-500/20 border border-teal-400/30 text-teal-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-6">
            Adeegyadayada · Our Services
          </span>
          <h1 className="text-5xl sm:text-6xl font-black text-white mb-5 leading-tight">
            Everything Your Child<br />
            <span className="bg-linear-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">Needs to Thrive</span>
          </h1>
          <p className="text-lg text-white/60 max-w-2xl mx-auto">
            Six powerful services. One unified platform. Built specifically for Somali families and the pediatric healthcare professionals who serve them.
          </p>
        </div>
      </section>

      {/* ── HOW IT WORKS ─────────────────────────────────────────────────── */}
      <section className="py-16 bg-teal-600">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
            {HOW.map((h, i) => (
              <div key={h.step} ref={addRef} className="s-reveal text-white" style={{ transitionDelay: `${i * 80}ms` }}>
                <span className="text-4xl font-black text-white/20 block mb-2">{h.step}</span>
                <h3 className="font-black text-lg mb-2">{h.title}</h3>
                <p className="text-sm text-teal-100 leading-relaxed">{h.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── SERVICE CARDS ────────────────────────────────────────────────── */}
      <section className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-20">
          {SERVICES.map((svc, i) => (
            <div
              key={svc.title}
              ref={addRef}
              className={`s-reveal grid lg:grid-cols-2 gap-12 items-center ${i % 2 !== 0 ? 'lg:grid-flow-dense' : ''}`}
              style={{ transitionDelay: '0ms' }}
            >
              {/* Image */}
              <div className={`relative rounded-3xl overflow-hidden shadow-xl ${i % 2 !== 0 ? 'lg:col-start-2' : ''}`}>
                <img src={svc.img} alt={svc.title} className="w-full h-72 object-cover" />
                <div className={`absolute inset-0 bg-linear-to-t ${svc.gradient} opacity-20`} />
                <div className={`absolute top-4 left-4 w-12 h-12 rounded-2xl bg-linear-to-br ${svc.gradient} flex items-center justify-center shadow-lg`}>
                  <svc.icon size={22} className="text-white" />
                </div>
              </div>

              {/* Content */}
              <div className={i % 2 !== 0 ? 'lg:col-start-1 lg:row-start-1' : ''}>
                <div className={`inline-block text-xs font-black uppercase tracking-widest px-3 py-1.5 rounded-full mb-3 ${svc.bg} text-${svc.color}-600`}>
                  {svc.titleSo}
                </div>
                <h2 className="text-3xl font-black text-slate-900 mb-4">{svc.title}</h2>
                <p className="text-slate-600 leading-relaxed mb-6">{svc.desc}</p>
                <ul className="space-y-2.5 mb-7">
                  {svc.features.map(f => (
                    <li key={f} className="flex items-center gap-2.5 text-sm text-slate-700">
                      <CheckCircle size={15} className="text-teal-500 shrink-0" />
                      {f}
                    </li>
                  ))}
                </ul>
                <Link
                  to="/login"
                  className="inline-flex items-center gap-2 px-5 py-3 bg-teal-500 text-white font-black rounded-xl hover:bg-teal-600 hover:-translate-y-0.5 transition-all shadow-md shadow-teal-500/30"
                >
                  Try {svc.title} Free <ArrowRight size={16} />
                </Link>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ── CTA ──────────────────────────────────────────────────────────── */}
      <section className="py-20 bg-slate-900">
        <div className="max-w-3xl mx-auto px-4 text-center">
          <h2 className="text-4xl font-black text-white mb-4">All Services. One Platform. Free.</h2>
          <p className="text-slate-400 mb-8 text-lg">Start with our free plan — no credit card needed. Upgrade when you need more.</p>
          <div className="flex flex-wrap gap-4 justify-center">
            <Link to="/login" className="inline-flex items-center gap-2 px-7 py-4 bg-teal-500 text-white font-black rounded-2xl hover:bg-teal-400 transition-all shadow-xl shadow-teal-500/30">
              Get Started Free <ArrowRight size={18} />
            </Link>
            <Link to="/pricing" className="inline-flex items-center gap-2 px-7 py-4 bg-white/10 text-white font-semibold rounded-2xl border border-white/20 hover:bg-white/20 transition-all">
              View Pricing
            </Link>
          </div>
        </div>
      </section>
    </>
  );
};
