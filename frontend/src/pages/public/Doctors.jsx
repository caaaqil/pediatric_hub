import React, { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { Star, MapPin, Clock, Search, ArrowRight, BadgeCheck, Stethoscope } from 'lucide-react';

const STYLES = `
@keyframes d-fadeUp { from{opacity:0;transform:translateY(28px)} to{opacity:1;transform:translateY(0)} }
.d-reveal { opacity:0; transform:translateY(24px); transition:opacity 0.6s ease, transform 0.6s ease; }
.d-revealed { opacity:1; transform:translateY(0); }
`;

const SPECIALTIES = ['All', 'General Pediatrics', 'Neonatology', 'Cardiology', 'Nutrition', 'Neurology', 'Dermatology', 'Orthopedics'];

const DOCTORS = [
  { id: 1, name: 'Dr. Amina Warsame', specialty: 'General Pediatrics', location: 'Mogadishu', rating: 4.9, reviews: 312, available: true, langs: ['Somali', 'English', 'Arabic'], exp: '14 yrs', img: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&h=300&q=80', bio: 'Specialist in early childhood development and vaccinations.' },
  { id: 2, name: 'Dr. Abdirahman Ali', specialty: 'Neonatology', location: 'Hargeisa', rating: 4.8, reviews: 201, available: true, langs: ['Somali', 'English'], exp: '11 yrs', img: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&w=300&h=300&q=80', bio: 'Newborn care specialist with ICU experience across East Africa.' },
  { id: 3, name: 'Dr. Ifrah Hassan', specialty: 'Nutrition', location: 'Kismayo', rating: 4.9, reviews: 188, available: false, langs: ['Somali', 'English'], exp: '9 yrs', img: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=300&h=300&q=80', bio: 'Pediatric nutritionist focused on stunting prevention and maternal nutrition.' },
  { id: 4, name: 'Dr. Yusuf Abdi', specialty: 'Cardiology', location: 'Mogadishu', rating: 5.0, reviews: 95, available: true, langs: ['Somali', 'English', 'Italian'], exp: '18 yrs', img: 'https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=300&h=300&q=80', bio: 'Pediatric cardiologist trained in Italy, now serving Somali children.' },
  { id: 5, name: 'Dr. Faadumo Osman', specialty: 'Neurology', location: 'Bosaso', rating: 4.7, reviews: 144, available: true, langs: ['Somali', 'English'], exp: '12 yrs', img: 'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?auto=format&fit=crop&w=300&h=300&q=80', bio: 'Child neurologist specializing in epilepsy and developmental disorders.' },
  { id: 6, name: 'Dr. Mustafa Roble', specialty: 'General Pediatrics', location: 'Garowe', rating: 4.8, reviews: 267, available: true, langs: ['Somali', 'English'], exp: '10 yrs', img: 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&w=300&h=300&q=80', bio: 'Community pediatrician serving rural Puntland with outreach programs.' },
  { id: 7, name: 'Dr. Hodan Jama', specialty: 'Dermatology', location: 'Mogadishu', rating: 4.9, reviews: 178, available: false, langs: ['Somali', 'English'], exp: '8 yrs', img: 'https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?auto=format&fit=crop&w=300&h=300&q=80', bio: 'Pediatric dermatologist specializing in eczema, tinea, and skin infections.' },
  { id: 8, name: 'Dr. Ahmed Duale', specialty: 'Orthopedics', location: 'Hargeisa', rating: 4.7, reviews: 89, available: true, langs: ['Somali', 'English', 'Arabic'], exp: '15 yrs', img: 'https://images.unsplash.com/photo-1631815589968-fdb09a223b1e?auto=format&fit=crop&w=300&h=300&q=80', bio: 'Pediatric orthopedic surgeon, expert in congenital bone conditions.' },
];

export const Doctors = () => {
  const [search, setSearch] = useState('');
  const [specialty, setSpecialty] = useState('All');
  const revealRef = useRef([]);

  const filtered = DOCTORS.filter(d => {
    const matchSearch = d.name.toLowerCase().includes(search.toLowerCase()) ||
      d.location.toLowerCase().includes(search.toLowerCase()) ||
      d.specialty.toLowerCase().includes(search.toLowerCase());
    const matchSpec = specialty === 'All' || d.specialty === specialty;
    return matchSearch && matchSpec;
  });

  useEffect(() => {
    const io = new IntersectionObserver(
      es => es.forEach(e => { if (e.isIntersecting) e.target.classList.add('d-revealed'); }),
      { threshold: 0.08 }
    );
    revealRef.current.forEach(el => el && io.observe(el));
    return () => io.disconnect();
  }, []);

  const addRef = el => { if (el && !revealRef.current.includes(el)) revealRef.current.push(el); };

  return (
    <>
      <style>{STYLES}</style>

      {/* ── HERO ─────────────────────────────────────────────────────────── */}
      <section className="relative pt-32 pb-24 bg-slate-900 overflow-hidden">
        <div className="absolute inset-0">
          <img
            src="https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&w=1600&q=80"
            alt="African doctor"
            className="w-full h-full object-cover opacity-20"
          />
          <div className="absolute inset-0 bg-linear-to-b from-slate-900/60 to-slate-900" />
        </div>
        <div className="relative max-w-4xl mx-auto px-4 text-center">
          <span className="inline-block bg-teal-500/20 border border-teal-400/30 text-teal-300 text-xs font-black uppercase tracking-widest px-4 py-2 rounded-full mb-6">
            Dhakhaatiirta · Our Doctors
          </span>
          <h1 className="text-5xl sm:text-6xl font-black text-white mb-5 leading-tight">
            350+ Verified<br />
            <span className="bg-linear-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">Pediatric Specialists</span>
          </h1>
          <p className="text-lg text-white/60 max-w-2xl mx-auto mb-10">
            Every doctor on our platform is board-certified, background-checked, and credentialed by our medical review board. Serving Somali families across East Africa.
          </p>

          {/* Search bar */}
          <div className="relative max-w-xl mx-auto">
            <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search by name, city, or specialty..."
              className="w-full pl-11 pr-4 py-4 rounded-2xl bg-white/10 border border-white/20 text-white placeholder:text-white/40 text-sm focus:outline-none focus:ring-2 focus:ring-teal-400 backdrop-blur-sm"
            />
          </div>
        </div>
      </section>

      {/* ── FILTER + GRID ─────────────────────────────────────────────────── */}
      <section className="py-16 bg-slate-50 min-h-screen">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

          {/* Specialty pills */}
          <div ref={addRef} className="d-reveal flex flex-wrap gap-2 mb-10">
            {SPECIALTIES.map(s => (
              <button
                key={s}
                onClick={() => setSpecialty(s)}
                className={`px-4 py-2 rounded-full text-sm font-semibold border transition-all ${
                  specialty === s
                    ? 'bg-teal-500 text-white border-teal-500 shadow-md shadow-teal-500/30'
                    : 'bg-white text-slate-600 border-slate-200 hover:border-teal-300 hover:text-teal-600'
                }`}
              >
                {s}
              </button>
            ))}
          </div>

          {/* Count */}
          <p className="text-sm text-slate-500 mb-6">{filtered.length} doctor{filtered.length !== 1 ? 's' : ''} found</p>

          {/* Doctor cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {filtered.map((doc, i) => (
              <div
                key={doc.id}
                ref={addRef}
                className="d-reveal bg-white rounded-2xl border border-slate-100 overflow-hidden shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all group"
                style={{ transitionDelay: `${i * 60}ms` }}
              >
                {/* Photo */}
                <div className="relative h-52 overflow-hidden bg-slate-100">
                  <img src={doc.img} alt={doc.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                  {/* Available badge */}
                  <div className={`absolute top-3 right-3 flex items-center gap-1.5 text-[10px] font-black uppercase px-2.5 py-1 rounded-full ${doc.available ? 'bg-green-500 text-white' : 'bg-slate-400 text-white'}`}>
                    <span className={`w-1.5 h-1.5 rounded-full ${doc.available ? 'bg-white animate-pulse' : 'bg-white/60'}`} />
                    {doc.available ? 'Available' : 'Busy'}
                  </div>
                  {/* Verified */}
                  <div className="absolute top-3 left-3">
                    <BadgeCheck size={20} className="text-teal-400 drop-shadow-md" />
                  </div>
                </div>

                <div className="p-5">
                  <h3 className="font-black text-slate-900 text-sm mb-0.5">{doc.name}</h3>
                  <p className="text-xs text-teal-600 font-semibold mb-3">{doc.specialty}</p>

                  <div className="flex items-center gap-3 mb-3 text-xs text-slate-500">
                    <span className="flex items-center gap-1"><MapPin size={11} />{doc.location}</span>
                    <span className="flex items-center gap-1"><Clock size={11} />{doc.exp} exp</span>
                  </div>

                  <div className="flex items-center gap-1.5 mb-3">
                    <Star size={12} className="text-amber-400 fill-amber-400" />
                    <span className="text-sm font-black text-slate-800">{doc.rating}</span>
                    <span className="text-xs text-slate-400">({doc.reviews} reviews)</span>
                  </div>

                  <p className="text-xs text-slate-500 leading-relaxed mb-4 line-clamp-2">{doc.bio}</p>

                  <div className="flex flex-wrap gap-1 mb-4">
                    {doc.langs.map(l => (
                      <span key={l} className="text-[10px] bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full font-medium">{l}</span>
                    ))}
                  </div>

                  <Link
                    to="/login"
                    className={`flex items-center justify-center gap-1.5 w-full py-2.5 rounded-xl text-sm font-black transition-all ${
                      doc.available
                        ? 'bg-teal-500 text-white hover:bg-teal-600 shadow-md shadow-teal-500/30'
                        : 'bg-slate-100 text-slate-400 cursor-not-allowed'
                    }`}
                  >
                    {doc.available ? (<><Stethoscope size={14} /> Book Appointment</>) : 'Not Available'}
                  </Link>
                </div>
              </div>
            ))}
          </div>

          {filtered.length === 0 && (
            <div className="text-center py-20">
              <p className="text-slate-400 text-lg font-medium">No doctors match your search.</p>
              <button onClick={() => { setSearch(''); setSpecialty('All'); }} className="mt-4 text-teal-600 font-semibold hover:underline text-sm">
                Clear filters
              </button>
            </div>
          )}
        </div>
      </section>

      {/* ── CTA ──────────────────────────────────────────────────────────── */}
      <section className="py-20 bg-teal-600">
        <div className="max-w-2xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-black text-white mb-3">Are You a Pediatrician?</h2>
          <p className="text-teal-100 mb-8">Join 350+ doctors serving Somali families through our platform. Manage your schedule, consult patients online, and grow your practice.</p>
          <Link to="/contact" className="inline-flex items-center gap-2 px-7 py-4 bg-white text-teal-700 font-black rounded-2xl hover:-translate-y-0.5 transition-all shadow-xl">
            Apply to Join <ArrowRight size={18} />
          </Link>
        </div>
      </section>
    </>
  );
};
