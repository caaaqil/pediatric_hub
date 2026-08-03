import React, { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Heart, Shield, Users, Globe, Award, Target, CheckCircle } from 'lucide-react';

const STYLES = `
@keyframes a-fadeUp { from{opacity:0;transform:translateY(28px)} to{opacity:1;transform:translateY(0)} }
.a-reveal { opacity:0; transform:translateY(24px); transition:opacity 0.6s ease, transform 0.6s ease; }
.a-revealed { opacity:1; transform:translateY(0); }
`;

const TEAM = [
  {
    name: 'Dr. Amina Warsame', role: 'Chief Medical Officer',
    img: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&h=300&q=80',
    bio: 'Board-certified pediatrician with 15 years in East African healthcare systems.',
  },
  {
    name: 'Khalid Osman', role: 'Co-Founder & CEO',
    img: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&w=300&h=300&q=80',
    bio: 'Health tech entrepreneur passionate about digital solutions for underserved communities.',
  },
  {
    name: 'Ifrah Hassan', role: 'Head of Community Outreach',
    img: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=300&h=300&q=80',
    bio: 'Public health specialist bridging digital health and Somali community needs.',
  },
  {
    name: 'Dr. Yusuf Abdi', role: 'Lead Pediatric Advisor',
    img: 'https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=300&h=300&q=80',
    bio: 'WHO-certified growth and nutrition consultant serving 5,000+ children annually.',
  },
];

const VALUES = [
  { icon: Heart, color: 'rose', title: 'Child-First Philosophy', desc: 'Every decision we make centers on the well-being and health outcomes of children.' },
  { icon: Shield, color: 'blue', title: 'Privacy & Security', desc: 'Medical data is encrypted, HIPAA-ready, and never sold or shared without consent.' },
  { icon: Globe, color: 'teal', title: 'Community-Rooted', desc: 'Built with Somali families, in Somali language, reflecting our shared cultural values.' },
  { icon: Users, color: 'purple', title: 'Inclusive Access', desc: 'We believe every child — regardless of location or income — deserves quality care.' },
  { icon: Award, color: 'amber', title: 'Clinical Excellence', desc: 'All doctors on our platform are verified and credentialed by our medical board.' },
  { icon: Target, color: 'green', title: 'Measurable Impact', desc: 'We track vaccination rates, growth outcomes, and consultation quality continuously.' },
];

const COLOR = {
  rose: 'bg-rose-50 text-rose-500', blue: 'bg-blue-50 text-blue-500',
  teal: 'bg-teal-50 text-teal-600', purple: 'bg-purple-50 text-purple-500',
  amber: 'bg-amber-50 text-amber-500', green: 'bg-green-50 text-green-600',
};

const MILESTONES = [
  { year: '2020', title: 'Founded', desc: 'Started in Mogadishu with 3 doctors and 200 families.' },
  { year: '2021', title: 'Vaccine Module', desc: 'Launched the WHO-aligned vaccine tracker used by 10 clinics.' },
  { year: '2022', title: 'Teleconsult', desc: 'Introduced encrypted video consultations serving rural areas.' },
  { year: '2023', title: 'AI Assistant', desc: 'Deployed Somali-language AI health chatbot.' },
  { year: '2024', title: 'National Scale', desc: 'Expanded to Hargeisa, Kismayo, Bosaso, and Garowe.' },
  { year: '2025', title: '12K Families', desc: 'Crossed 12,000 registered families with 350+ verified doctors.' },
];

export const About = () => {
  const revealRef = useRef([]);

  useEffect(() => {
    const io = new IntersectionObserver(
      es => es.forEach(e => { if (e.isIntersecting) e.target.classList.add('a-revealed'); }),
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
      <section className="relative pt-32 pb-20 bg-slate-900 overflow-hidden">
        <div className="absolute inset-0">
          <img
            src="https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?auto=format&fit=crop&w=1600&q=80"
            alt="African family in healthcare"
            className="w-full h-full object-cover opacity-25"
          />
          <div className="absolute inset-0 bg-linear-to-b from-slate-900/80 to-slate-900/60" />
        </div>
        <div className="relative max-w-4xl mx-auto px-4 sm:px-6 text-center">
          <span className="inline-block bg-teal-500/20 border border-teal-400/30 text-teal-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-6">
            Nagu saabsan · About Us
          </span>
          <h1 className="text-5xl sm:text-6xl font-black text-white mb-6 leading-tight">
            Healthcare Built for<br />
            <span className="bg-linear-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">Somali Families</span>
          </h1>
          <p className="text-lg text-white/60 max-w-2xl mx-auto leading-relaxed">
            We are a mission-driven team of doctors, technologists, and community leaders
            committed to transforming pediatric healthcare across the Somali region.
          </p>
        </div>
      </section>

      {/* ── MISSION / VISION ─────────────────────────────────────────────── */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            <div ref={addRef} className="a-reveal">
              <span className="text-xs font-black text-teal-600 uppercase tracking-widest">Our Mission</span>
              <h2 className="text-4xl font-black text-slate-900 mt-2 mb-6 leading-tight">
                "Caafimaadka<br />Carruurta — Child Health<br />is Sacred"
              </h2>
              <p className="text-slate-600 leading-relaxed mb-5">
                Pediatric Health Hub exists to make world-class child healthcare accessible to every Somali family — whether they live in a major city or a remote village. We believe that geography and income should never determine a child's health outcomes.
              </p>
              <p className="text-slate-600 leading-relaxed mb-8">
                Our platform bridges the gap between families and qualified medical professionals, providing tools that work in low-bandwidth environments, in multiple languages, and with sensitivity to local cultural practices.
              </p>
              <div className="space-y-3">
                {['WHO-aligned vaccination protocols', 'Somali & English language support', 'Works offline and on 2G networks', 'Free core features, always'].map(item => (
                  <div key={item} className="flex items-center gap-2.5 text-sm text-slate-700">
                    <CheckCircle size={16} className="text-teal-500 shrink-0" />
                    {item}
                  </div>
                ))}
              </div>
            </div>
            <div ref={addRef} className="a-reveal relative rounded-3xl overflow-hidden shadow-2xl">
              <img
                src="https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&w=700&q=80"
                alt="Child receiving care"
                className="w-full h-[460px] object-cover"
              />
              <div className="absolute bottom-0 left-0 right-0 bg-linear-to-t from-slate-900 to-transparent p-8">
                <p className="text-white font-black text-xl">"Nabad iyo caano" — Peace and prosperity for all children</p>
                <p className="text-white/60 text-sm mt-1">Our guiding principle</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── TIMELINE ─────────────────────────────────────────────────────── */}
      <section className="py-20 bg-slate-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div ref={addRef} className="a-reveal text-center mb-14">
            <span className="text-xs font-black text-teal-600 uppercase tracking-widest">Our Journey</span>
            <h2 className="text-4xl font-black text-slate-900 mt-2">Growing With Our Community</h2>
          </div>
          <div className="relative">
            <div className="absolute left-4 top-0 bottom-0 w-px bg-teal-200 lg:left-1/2" />
            <div className="space-y-10">
              {MILESTONES.map((m, i) => (
                <div key={m.year} ref={addRef} className={`a-reveal relative flex items-start gap-8 ${i % 2 === 0 ? 'lg:flex-row' : 'lg:flex-row-reverse'}`} style={{ transitionDelay: `${i * 80}ms` }}>
                  <div className="flex-1 hidden lg:block" />
                  <div className="absolute left-4 lg:left-1/2 w-8 h-8 -translate-x-1/2 bg-teal-500 rounded-full flex items-center justify-center shrink-0 z-10 shadow-lg shadow-teal-500/40">
                    <span className="w-3 h-3 bg-white rounded-full" />
                  </div>
                  <div className="flex-1 ml-14 lg:ml-0 lg:max-w-sm bg-white rounded-2xl border border-slate-100 p-6 shadow-sm">
                    <span className="text-xs font-black text-teal-600 uppercase tracking-widest">{m.year}</span>
                    <h3 className="text-lg font-black text-slate-900 mt-1">{m.title}</h3>
                    <p className="text-sm text-slate-500 mt-1">{m.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ── VALUES ───────────────────────────────────────────────────────── */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div ref={addRef} className="a-reveal text-center mb-14">
            <span className="text-xs font-black text-teal-600 uppercase tracking-widest">What We Stand For</span>
            <h2 className="text-4xl font-black text-slate-900 mt-2">Our Core Values</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {VALUES.map((v, i) => (
              <div key={v.title} ref={addRef} className="a-reveal bg-slate-50 rounded-2xl p-7 border border-slate-100 hover:border-teal-200 hover:shadow-lg transition-all" style={{ transitionDelay: `${i * 70}ms` }}>
                <div className={`w-11 h-11 rounded-xl flex items-center justify-center mb-4 ${COLOR[v.color]}`}>
                  <v.icon size={20} />
                </div>
                <h3 className="font-black text-slate-900 mb-2">{v.title}</h3>
                <p className="text-sm text-slate-500 leading-relaxed">{v.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── TEAM ─────────────────────────────────────────────────────────── */}
      <section className="py-20 bg-slate-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div ref={addRef} className="a-reveal text-center mb-14">
            <span className="text-xs font-black text-teal-600 uppercase tracking-widest">The People Behind It</span>
            <h2 className="text-4xl font-black text-slate-900 mt-2">Meet Our Team</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {TEAM.map((member, i) => (
              <div key={member.name} ref={addRef} className="a-reveal bg-white rounded-2xl overflow-hidden border border-slate-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all" style={{ transitionDelay: `${i * 80}ms` }}>
                <div className="h-56 overflow-hidden">
                  <img src={member.img} alt={member.name} className="w-full h-full object-cover hover:scale-105 transition-transform duration-500" />
                </div>
                <div className="p-5">
                  <h3 className="font-black text-slate-900">{member.name}</h3>
                  <p className="text-xs text-teal-600 font-semibold mb-2">{member.role}</p>
                  <p className="text-xs text-slate-500 leading-relaxed">{member.bio}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA ──────────────────────────────────────────────────────────── */}
      <section className="py-20 bg-teal-600">
        <div className="max-w-2xl mx-auto px-4 text-center">
          <h2 ref={addRef} className="a-reveal text-4xl font-black text-white mb-4">Join Our Mission</h2>
          <p className="text-teal-100 mb-8">Be part of transforming pediatric healthcare in the Somali region — as a family, a doctor, or a partner facility.</p>
          <div className="flex flex-wrap gap-4 justify-center">
            <Link to="/login" className="inline-flex items-center gap-2 px-6 py-3 bg-white text-teal-700 font-black rounded-xl hover:-translate-y-0.5 transition-all shadow-lg">
              Get Started Free <ArrowRight size={16} />
            </Link>
            <Link to="/contact" className="inline-flex items-center gap-2 px-6 py-3 bg-white/10 text-white font-semibold rounded-xl border border-white/20 hover:bg-white/20 transition-all">
              Partner With Us
            </Link>
          </div>
        </div>
      </section>
    </>
  );
};
