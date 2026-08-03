import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ARTICLES } from './HealthEducation';
import {
    ArrowLeft, Clock, Eye, Stethoscope, BookOpen,
    Share2, Heart, ChevronRight, AlertTriangle,
    CheckCircle, Lightbulb, List, ChevronUp
} from 'lucide-react';

/* ─── Styles ──────────────────────────────────────────────────────────── */
const STYLES = `
@keyframes ad-up   { from { opacity:0; transform:translateY(20px) } to { opacity:1; transform:translateY(0) } }
@keyframes ad-fade { from { opacity:0 } to { opacity:1 } }
@keyframes ad-zoom { from { transform:scale(1) } to { transform:scale(1.05) } }
@keyframes ad-bar  { from { width:0 } to { width:var(--w) } }

.ad-up      { animation: ad-up   0.5s ease both }
.ad-fade    { animation: ad-fade 0.6s ease both }
.ad-zoom    { animation: ad-zoom 16s ease-in-out infinite alternate }

.ad-progress-bar { transition: width 0.3s ease }

/* Prose body text */
.ad-prose {
    font-size: 15px;
    line-height: 1.85;
    color: inherit;
    white-space: pre-wrap;
    word-break: break-word;
}

/* Section number badge */
.ad-num {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 28px;
    height: 28px;
    border-radius: 50%;
    font-size: 12px;
    font-weight: 900;
    flex-shrink: 0;
    margin-top: 1px;
}

/* Smooth scroll offset for sticky header */
html { scroll-padding-top: 80px }

/* Reading progress bar at top */
#ad-read-bar {
    position: fixed;
    top: 0; left: 0;
    height: 3px;
    background: linear-gradient(to right, #7c3aed, #a855f7, #ec4899);
    z-index: 9999;
    transition: width 0.1s linear;
}
`;

/* ─── Reading progress hook ─────────────────────────────────────────── */
function useReadingProgress() {
    const [pct, setPct] = useState(0);
    useEffect(() => {
        const el = document.querySelector('main');
        if (!el) return;
        const onScroll = () => {
            const scrolled = el.scrollTop;
            const total = el.scrollHeight - el.clientHeight;
            setPct(total > 0 ? Math.min(100, (scrolled / total) * 100) : 0);
        };
        el.addEventListener('scroll', onScroll, { passive: true });
        return () => el.removeEventListener('scroll', onScroll);
    }, []);
    return pct;
}

/* ─── Component ─────────────────────────────────────────────────────── */
export const ArticleDetail = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const readPct = useReadingProgress();
    const [liked, setLiked] = useState(false);
    const [likeCount, setLikeCount] = useState(0);
    const [tocOpen, setTocOpen] = useState(false);
    const [copied, setCopied] = useState(false);

    const handleLike = () => {
        setLiked(l => {
            setLikeCount(c => l ? c - 1 : c + 1);
            return !l;
        });
    };

    const handleShare = async () => {
        const url = window.location.href;
        try {
            if (navigator.share) {
                await navigator.share({ title: article?.title, url });
            } else {
                await navigator.clipboard.writeText(url);
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
            }
        } catch {
            try {
                await navigator.clipboard.writeText(url);
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
            } catch {
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
            }
        }
    };

    const article = ARTICLES.find(a => String(a.id) === String(id));

    useEffect(() => { document.querySelector('main')?.scrollTo({ top: 0, behavior: 'instant' }); }, [id]);

    /* ── Not found ─────────────────────────────────────────────────── */
    if (!article) {
        return (
            <div className="flex flex-col items-center justify-center py-32 text-center px-6">
                <BookOpen size={56} className="text-slate-300 dark:text-slate-600 mb-5"/>
                <h2 className="text-2xl font-black text-slate-800 dark:text-slate-100 mb-2">
                    Maqaalkaan lama helin
                </h2>
                <p className="text-slate-500 dark:text-slate-400 text-sm mb-8">
                    Lambarka maqaalka khaldan yahay ama la tirtiray.
                </p>
                <button
                    onClick={() => navigate('/education')}
                    className="flex items-center gap-2 px-7 py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-2xl font-bold transition-colors shadow-lg"
                >
                    <ArrowLeft size={16}/> Ku Noqo Waxbarashada
                </button>
            </div>
        );
    }

    const related = ARTICLES
        .filter(a => a.category === article.category && a.id !== article.id)
        .slice(0, 3);

    /* ── Render ────────────────────────────────────────────────────── */
    return (
        <>
            <style>{STYLES}</style>

            {/* Reading progress bar */}
            <div id="ad-read-bar" style={{ width: `${readPct}%` }}/>

            <div className="max-w-4xl mx-auto pb-28 font-sans">

                {/* ── Back + TOC bar ── */}
                <div className="flex items-center justify-between mb-6">
                    <button
                        onClick={() => navigate('/education')}
                        className="flex items-center gap-2 text-slate-500 dark:text-slate-400 hover:text-purple-600 dark:hover:text-purple-400 text-sm font-bold transition-colors group"
                    >
                        <ArrowLeft size={15} className="group-hover:-translate-x-1 transition-transform"/>
                        Waxbarashada
                    </button>
                    <button
                        onClick={() => setTocOpen(o => !o)}
                        className="flex items-center gap-1.5 text-xs font-bold text-slate-500 dark:text-slate-400 hover:text-purple-600 dark:hover:text-purple-400 transition-colors"
                    >
                        <List size={14}/> Tusmada
                    </button>
                </div>

                {/* ── Table of Contents (collapsible) ── */}
                {tocOpen && (
                    <div className="mb-6 bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 rounded-2xl p-5 ad-up">
                        <p className="text-[11px] font-black uppercase tracking-widest text-slate-400 dark:text-slate-500 mb-3">
                            Tusmada
                        </p>
                        <ol className="space-y-2">
                            {article.sections.map((s, i) => (
                                <li key={i}>
                                    <a
                                        href={`#section-${i}`}
                                        onClick={() => setTocOpen(false)}
                                        className="flex items-start gap-2.5 text-sm font-semibold text-slate-700 dark:text-slate-300 hover:text-purple-600 dark:hover:text-purple-400 transition-colors leading-snug"
                                    >
                                        <span className="text-purple-500 font-black shrink-0">{i + 1}.</span>
                                        {s.heading}
                                    </a>
                                </li>
                            ))}
                        </ol>
                    </div>
                )}

                {/* ── Hero image ── */}
                <div className="relative rounded-3xl overflow-hidden shadow-2xl mb-0" style={{ height: 380 }}>
                    <div className="absolute inset-0 overflow-hidden">
                        <img
                            src={article.image}
                            alt={article.title}
                            className="w-full h-full object-cover ad-zoom"
                            style={{ transformOrigin: 'center center' }}
                        />
                    </div>
                    <div className={`absolute inset-0 bg-linear-to-br ${article.accent} opacity-50`}/>
                    <div className="absolute inset-0 bg-linear-to-t from-black/90 via-black/30 to-black/5"/>

                    {/* Category pill */}
                    <div className="absolute top-5 left-5">
                        <span className={`text-[10px] font-black uppercase px-3 py-1.5 rounded-full border inline-flex items-center gap-1.5 ${article.badge} bg-white/95 shadow-sm`}>
                            {article.icon} {article.category}
                        </span>
                    </div>

                    {/* Article number */}
                    <div className="absolute top-5 right-5 bg-black/30 backdrop-blur-sm rounded-full px-3 py-1.5">
                        <span className="text-white/70 text-[10px] font-bold">#{String(article.id).padStart(2, '0')}</span>
                    </div>

                    {/* Title & meta */}
                    <div className="absolute bottom-0 left-0 right-0 p-7 sm:p-9 ad-up">
                        <h1 className="text-2xl sm:text-3xl lg:text-4xl font-black text-white leading-tight mb-4 drop-shadow-lg">
                            {article.title}
                        </h1>
                        <div className="flex flex-wrap items-center gap-4">
                            <div className="flex items-center gap-1.5 text-white/65">
                                <Clock size={13}/>
                                <span className="text-xs font-bold">{article.readTime}</span>
                            </div>
                            <div className="flex items-center gap-1.5 text-white/65">
                                <Eye size={13}/>
                                <span className="text-xs font-bold">{article.views} aragti</span>
                            </div>
                            <div className="flex items-center gap-1.5 text-white/65">
                                <BookOpen size={13}/>
                                <span className="text-xs font-bold">{article.sections.length} qeybood</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* ── Article card (white/dark surface) ── */}
                <div className="bg-white dark:bg-slate-900 rounded-b-3xl shadow-xl border border-t-0 border-slate-100 dark:border-slate-800 px-6 sm:px-10 pt-8 pb-10">

                    {/* Lead paragraph */}
                    <p className="text-base sm:text-lg font-medium text-slate-600 dark:text-slate-300 leading-[1.8] italic border-l-[3px] border-purple-500 pl-5 mb-8 ad-fade">
                        {article.subtitle}
                    </p>

                    {/* Purple rule */}
                    <div className={`h-0.5 w-full bg-linear-to-r ${article.accent} rounded-full mb-10 opacity-40`}/>

                    {/* ── Sections ── */}
                    <div className="space-y-12">
                        {article.sections.map((section, i) => (
                            <div
                                key={i}
                                id={`section-${i}`}
                                className="ad-up scroll-mt-24"
                                style={{ animationDelay: `${0.08 * i}s` }}
                            >
                                {/* Section heading */}
                                <div className="flex items-start gap-3 mb-4">
                                    <span className={`ad-num bg-linear-to-br ${article.accent} text-white shadow-md`}>
                                        {i + 1}
                                    </span>
                                    <h2 className="text-xl sm:text-2xl font-black text-slate-900 dark:text-white leading-tight">
                                        {section.heading}
                                    </h2>
                                </div>

                                {/* Body text */}
                                <div className="pl-10">
                                    <div className="ad-prose text-slate-700 dark:text-slate-200">
                                        {section.body}
                                    </div>

                                    {/* Optional bullets */}
                                    {section.bullets && section.bullets.length > 0 && (
                                        <ul className="mt-5 space-y-2.5">
                                            {section.bullets.map((b, bi) => (
                                                <li key={bi} className="flex items-start gap-3 text-sm text-slate-700 dark:text-slate-200 font-medium leading-relaxed">
                                                    <span className={`w-2 h-2 rounded-full ${article.dot} mt-2 shrink-0`}/>
                                                    {b}
                                                </li>
                                            ))}
                                        </ul>
                                    )}

                                    {/* Tip box */}
                                    {section.tip && (
                                        <div className="mt-5 flex gap-3 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800/60 rounded-2xl p-5">
                                            <Lightbulb size={17} className="text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5"/>
                                            <p className="text-sm font-semibold text-emerald-800 dark:text-emerald-200 leading-relaxed">
                                                {section.tip}
                                            </p>
                                        </div>
                                    )}

                                    {/* Warning box */}
                                    {section.warning && (
                                        <div className="mt-5 flex gap-3 bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-800/60 rounded-2xl p-5">
                                            <AlertTriangle size={17} className="text-red-600 dark:text-red-400 shrink-0 mt-0.5"/>
                                            <p className="text-sm font-semibold text-red-800 dark:text-red-200 leading-relaxed">
                                                {section.warning}
                                            </p>
                                        </div>
                                    )}

                                    {/* Info box */}
                                    {section.info && (
                                        <div className="mt-5 flex gap-3 bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-800/60 rounded-2xl p-5">
                                            <CheckCircle size={17} className="text-blue-600 dark:text-blue-400 shrink-0 mt-0.5"/>
                                            <p className="text-sm font-semibold text-blue-800 dark:text-blue-200 leading-relaxed">
                                                {section.info}
                                            </p>
                                        </div>
                                    )}
                                </div>

                                {/* Section divider (not after last) */}
                                {i < article.sections.length - 1 && (
                                    <div className="mt-10 border-b border-slate-100 dark:border-slate-800"/>
                                )}
                            </div>
                        ))}
                    </div>

                    {/* ── Doctor CTA ── */}
                    <div className="mt-14 bg-linear-to-br from-amber-50 to-orange-50 dark:from-amber-950/25 dark:to-orange-950/20 border border-amber-200 dark:border-amber-800/50 rounded-3xl p-7 flex gap-5 items-start">
                        <div className="w-12 h-12 bg-amber-100 dark:bg-amber-900/40 rounded-2xl flex items-center justify-center shrink-0 shadow-sm">
                            <Stethoscope size={22} className="text-amber-600 dark:text-amber-400"/>
                        </div>
                        <div className="flex-1">
                            <h3 className="font-black text-amber-900 dark:text-amber-200 text-base mb-1.5">
                                Su'aal Gaar ah?
                            </h3>
                            <p className="text-sm font-medium text-amber-800 dark:text-amber-300 leading-relaxed mb-4">
                                Macluumaadkan waa hagaha guud ee caafimaadka. Su'aalaha gaar ah ee ku saabsan ilmahaaga, had iyo jeer la tasho dhakhtar. Isticmaal Portal-ka La-Tashaashada ama Buug Ballan.
                            </p>
                            <button
                                onClick={() => navigate('/appointments')}
                                className="inline-flex items-center gap-2 text-sm font-black text-amber-700 dark:text-amber-300 hover:text-amber-900 dark:hover:text-amber-100 transition-colors group"
                            >
                                Buug Ballan <ChevronRight size={15} className="group-hover:translate-x-1 transition-transform"/>
                            </button>
                        </div>
                    </div>

                    {/* ── Like / Share ── */}
                    <div className="mt-8 flex items-center justify-between border-t border-slate-100 dark:border-slate-800 pt-6">
                        <div className="flex items-center gap-1 text-[11px] font-black uppercase tracking-widest text-slate-400 dark:text-slate-600">
                            🇸🇴 Pediatric Health Hub
                        </div>
                        <div className="flex items-center gap-3">
                            <button
                                onClick={handleLike}
                                className={`cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all duration-200 select-none
                                    ${liked
                                        ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-500 border border-rose-200 dark:border-rose-800/60 scale-105'
                                        : 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 border border-slate-200 dark:border-slate-700 hover:bg-rose-50 dark:hover:bg-rose-950/30 hover:text-rose-500 hover:border-rose-200'
                                    }`}
                            >
                                <Heart
                                    size={14}
                                    className={`transition-all duration-200 ${liked ? 'fill-rose-500 text-rose-500 scale-110' : ''}`}
                                />
                                {liked ? 'Jecel' : 'Ku Jecel'}
                                {likeCount > 0 && (
                                    <span className="ml-0.5 font-black">{likeCount}</span>
                                )}
                            </button>
                            <button
                                onClick={handleShare}
                                className={`cursor-pointer flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all duration-200 select-none border
                                    ${copied
                                        ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800/60'
                                        : 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 border-slate-200 dark:border-slate-700 hover:bg-purple-50 dark:hover:bg-purple-950/30 hover:text-purple-600 dark:hover:text-purple-400 hover:border-purple-200'
                                    }`}
                            >
                                <Share2 size={14}/>
                                {copied ? 'La Koobiyeeyay!' : 'La Wadaag'}
                            </button>
                        </div>
                    </div>
                </div>

                {/* ── Related articles ── */}
                {related.length > 0 && (
                    <div className="mt-10">
                        <h2 className="text-base font-black text-slate-800 dark:text-slate-100 mb-5 flex items-center gap-2">
                            <BookOpen size={16} className="text-purple-500"/>
                            Maqaalada La Mid ah — {article.category}
                        </h2>
                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                            {related.map((rel) => (
                                <Link
                                    key={rel.id}
                                    to={'/education/' + rel.id}
                                    className="rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:shadow-lg hover:-translate-y-1 transition-all group block"
                                >
                                    <div className="relative h-32 overflow-hidden">
                                        <img
                                            src={rel.image}
                                            alt={rel.title}
                                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                                        />
                                        <div className={`absolute inset-0 bg-linear-to-t ${rel.accent} opacity-40`}/>
                                    </div>
                                    <div className="p-4">
                                        <p className="text-[13px] font-black text-slate-800 dark:text-slate-100 leading-snug group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors">
                                            {rel.title}
                                        </p>
                                        <div className="flex items-center gap-1 mt-2 text-slate-400">
                                            <Clock size={10}/>
                                            <span className="text-[10px] font-bold">{rel.readTime}</span>
                                        </div>
                                    </div>
                                </Link>
                            ))}
                        </div>
                    </div>
                )}

                {/* ── Bottom nav ── */}
                <div className="mt-10 flex items-center justify-between gap-4">
                    <button
                        onClick={() => navigate('/education')}
                        className="flex items-center gap-2 px-6 py-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-200 font-bold rounded-2xl hover:border-purple-400 hover:text-purple-600 dark:hover:text-purple-400 transition-all text-sm shadow-sm"
                    >
                        <ArrowLeft size={15}/> Dhammaan Maqaalada
                    </button>
                    <button
                        onClick={() => document.querySelector('main')?.scrollTo({ top: 0, behavior: 'smooth' })}
                        className="flex items-center gap-2 px-5 py-3 bg-purple-600 hover:bg-purple-700 text-white font-bold rounded-2xl transition-colors text-sm shadow-lg shadow-purple-200 dark:shadow-purple-900/30"
                    >
                        <ChevronUp size={15}/> Kor
                    </button>
                </div>
            </div>
        </>
    );
};
