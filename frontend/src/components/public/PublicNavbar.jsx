import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X, Heart, ChevronDown } from 'lucide-react';

const NAV_LINKS = [
  { label: 'Home', path: '/' },
  { label: 'About', path: '/about' },
  { label: 'Services', path: '/services' },
  { label: 'Doctors', path: '/doctors' },
  { label: 'Pricing', path: '/pricing' },
  { label: 'Contact', path: '/contact' },
];

export const PublicNavbar = () => {
  const { pathname } = useLocation();
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => { setMenuOpen(false); }, [pathname]);

  return (
    <>
      <nav
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
          scrolled
            ? 'bg-white/95 backdrop-blur-xl shadow-lg shadow-slate-900/8 border-b border-slate-200/60'
            : 'bg-transparent'
        }`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-18 py-3">

            {/* Logo */}
            <Link to="/" className="flex items-center gap-2.5 group">
              <div className="w-9 h-9 rounded-xl bg-linear-to-br from-teal-500 to-teal-700 flex items-center justify-center shadow-md group-hover:scale-105 transition-transform">
                <Heart size={18} className="text-white fill-white" />
              </div>
              <div className="leading-none">
                <span className={`block font-black text-base tracking-tight transition-colors ${scrolled ? 'text-slate-900' : 'text-white'}`}>
                  Pediatric
                </span>
                <span className={`block text-[10px] font-semibold tracking-widest uppercase transition-colors ${scrolled ? 'text-teal-600' : 'text-teal-300'}`}>
                  Health Hub
                </span>
              </div>
            </Link>

            {/* Desktop nav */}
            <div className="hidden lg:flex items-center gap-1">
              {NAV_LINKS.map(link => {
                const active = link.path === '/' ? pathname === '/' : pathname.startsWith(link.path);
                return (
                  <Link
                    key={link.path}
                    to={link.path}
                    className={`relative px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 ${
                      active
                        ? scrolled
                          ? 'text-teal-600 bg-teal-50'
                          : 'text-teal-300 bg-white/10'
                        : scrolled
                          ? 'text-slate-600 hover:text-teal-600 hover:bg-slate-50'
                          : 'text-white/80 hover:text-white hover:bg-white/10'
                    }`}
                  >
                    {link.label}
                    {active && (
                      <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-teal-500" />
                    )}
                  </Link>
                );
              })}
            </div>

            {/* CTA buttons */}
            <div className="hidden lg:flex items-center gap-3">
              <Link
                to="/login"
                className={`px-4 py-2 text-sm font-semibold rounded-lg transition-all ${
                  scrolled
                    ? 'text-slate-700 hover:text-teal-600 hover:bg-slate-50'
                    : 'text-white/80 hover:text-white hover:bg-white/10'
                }`}
              >
                Log in
              </Link>
              <Link
                to="/login"
                className="px-5 py-2.5 bg-teal-500 hover:bg-teal-600 text-white text-sm font-black rounded-xl shadow-md shadow-teal-500/30 hover:shadow-teal-500/50 hover:-translate-y-0.5 transition-all"
              >
                Get Started Free
              </Link>
            </div>

            {/* Mobile hamburger */}
            <button
              onClick={() => setMenuOpen(v => !v)}
              className={`lg:hidden p-2 rounded-lg transition-colors ${
                scrolled ? 'text-slate-700 hover:bg-slate-100' : 'text-white hover:bg-white/10'
              }`}
            >
              {menuOpen ? <X size={22} /> : <Menu size={22} />}
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        <div
          className={`lg:hidden overflow-hidden transition-all duration-300 ${
            menuOpen ? 'max-h-96 opacity-100' : 'max-h-0 opacity-0'
          } bg-white border-t border-slate-100 shadow-xl`}
        >
          <div className="px-4 py-3 space-y-1">
            {NAV_LINKS.map(link => {
              const active = link.path === '/' ? pathname === '/' : pathname.startsWith(link.path);
              return (
                <Link
                  key={link.path}
                  to={link.path}
                  className={`flex items-center px-4 py-3 rounded-xl text-sm font-semibold transition-all ${
                    active
                      ? 'text-teal-600 bg-teal-50'
                      : 'text-slate-700 hover:text-teal-600 hover:bg-slate-50'
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}
            <div className="pt-3 border-t border-slate-100 flex flex-col gap-2">
              <Link to="/login" className="flex items-center justify-center px-4 py-3 rounded-xl text-sm font-semibold text-slate-700 border border-slate-200 hover:bg-slate-50 transition-all">
                Log in
              </Link>
              <Link to="/login" className="flex items-center justify-center px-4 py-3 rounded-xl text-sm font-black text-white bg-teal-500 hover:bg-teal-600 transition-all shadow-md">
                Get Started Free
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Spacer only on non-hero pages */}
    </>
  );
};
