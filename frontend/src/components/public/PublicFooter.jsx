import React from 'react';
import { Link } from 'react-router-dom';
import { Heart, Phone, Mail, MapPin, Facebook, Twitter, Instagram, Youtube } from 'lucide-react';

const LINKS = {
  Platform: [
    { label: 'Home', path: '/' },
    { label: 'About Us', path: '/about' },
    { label: 'Services', path: '/services' },
    { label: 'Find Doctors', path: '/doctors' },
    { label: 'Pricing', path: '/pricing' },
  ],
  Resources: [
    { label: 'Health Education', path: '/login' },
    { label: 'Vaccine Tracker', path: '/login' },
    { label: 'Growth Charts', path: '/login' },
    { label: 'Emergency Guide', path: '/login' },
    { label: 'AI Health Chat', path: '/login' },
  ],
  Legal: [
    { label: 'Privacy Policy', path: '/contact' },
    { label: 'Terms of Service', path: '/contact' },
    { label: 'Cookie Policy', path: '/contact' },
    { label: 'Contact Us', path: '/contact' },
  ],
};

const SOCIALS = [
  { icon: Facebook, href: '#', label: 'Facebook' },
  { icon: Twitter, href: '#', label: 'Twitter' },
  { icon: Instagram, href: '#', label: 'Instagram' },
  { icon: Youtube, href: '#', label: 'YouTube' },
];

export const PublicFooter = () => (
  <footer className="bg-slate-900 text-white">
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-16 pb-8">

      {/* Top grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-10 pb-12 border-b border-white/10">

        {/* Brand col */}
        <div className="lg:col-span-2">
          <Link to="/" className="flex items-center gap-2.5 mb-4">
            <div className="w-10 h-10 rounded-xl bg-linear-to-br from-teal-400 to-teal-600 flex items-center justify-center shadow-lg">
              <Heart size={20} className="text-white fill-white" />
            </div>
            <div>
              <span className="block font-black text-lg text-white">Pediatric Health Hub</span>
              <span className="block text-xs font-medium text-teal-400 tracking-widest uppercase">Daryeel Carruurta</span>
            </div>
          </Link>
          <p className="text-sm text-slate-400 leading-relaxed max-w-xs mb-6">
            Caafimaadka carruurta waa mas'uuliyad wadaag. Dedicated to serving Somali families with
            world-class pediatric care — connecting parents, doctors, and facilities across our community.
          </p>

          {/* Contact info */}
          <div className="space-y-2">
            {[
              { icon: Phone, text: '+252 61 123 4567' },
              { icon: Mail, text: 'support@pediatrichealthhub.so' },
              { icon: MapPin, text: 'Mogadishu, Somalia' },
            ].map(({ icon: Icon, text }) => (
              <div key={text} className="flex items-center gap-2.5 text-sm text-slate-400">
                <Icon size={14} className="text-teal-400 shrink-0" />
                {text}
              </div>
            ))}
          </div>

          {/* Socials */}
          <div className="flex items-center gap-3 mt-5">
            {SOCIALS.map(({ icon: Icon, href, label }) => (
              <a
                key={label}
                href={href}
                aria-label={label}
                className="w-8 h-8 rounded-lg bg-white/5 hover:bg-teal-500 flex items-center justify-center transition-colors"
              >
                <Icon size={15} />
              </a>
            ))}
          </div>
        </div>

        {/* Link cols */}
        {Object.entries(LINKS).map(([group, items]) => (
          <div key={group}>
            <h4 className="text-xs font-black text-white uppercase tracking-widest mb-4">{group}</h4>
            <ul className="space-y-2.5">
              {items.map(({ label, path }) => (
                <li key={label}>
                  <Link
                    to={path}
                    className="text-sm text-slate-400 hover:text-teal-400 transition-colors"
                  >
                    {label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      {/* Bottom row */}
      <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4">
        <p className="text-xs text-slate-500 text-center sm:text-left">
          © {new Date().getFullYear()} Pediatric Health Hub. All rights reserved. Made with{' '}
          <Heart size={11} className="inline text-teal-400 fill-teal-400" /> for Somali families.
        </p>
        <div className="flex items-center gap-1.5">
          <span className="w-2 h-2 rounded-full bg-teal-400 animate-pulse" />
          <span className="text-xs text-slate-500">All systems operational</span>
        </div>
      </div>
    </div>
  </footer>
);
