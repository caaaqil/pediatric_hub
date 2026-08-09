import React, { useState } from 'react';
import { Card, CardContent } from '../../components/ui/Card';
import { AlertCircle, Phone, MapPin, HeartPulse, ShieldAlert, Navigation, Share2, Loader2, CheckCircle, Building2, Clock, ExternalLink, ChevronDown, ChevronUp, Stethoscope } from 'lucide-react';
import { Button } from '../../components/ui/Button';

const FACILITIES = [
    { name: 'Banadir Health Center',      address: 'Banadir District, Mogadishu',        phone: '+252-1',           type: 'Health Center', open: '24/7',     distance: '2.1 km', lat: 2.0469, lng: 45.3182 },
    { name: 'Mogadishu General Hospital', address: 'Via Makka Al Mukarama, Mogadishu',   phone: '+252-612-000001',  type: 'Hospital',      open: '24/7',     distance: '3.4 km', lat: 2.0536, lng: 45.3417 },
    { name: 'Kalkaal Hospital',           address: 'KM4 Road, Mogadishu',                phone: '+252-615-000002',  type: 'Hospital',      open: '24/7',     distance: '5.2 km', lat: 2.0731, lng: 45.3064 },
    { name: 'Deynile Health Center',      address: 'Deynile District, Mogadishu',         phone: '+252-611-111111',  type: 'Health Center', open: '8am-10pm', distance: '7.8 km', lat: 2.1120, lng: 45.2869 },
];

const PROTOCOLS = [
    { step: 1, title: 'Severe Difficulty Breathing',          so: 'Neefsasho dhibaato xun',       body: 'Look for blue lips, rapid chest retractions, or gasping. Keep the child calm in an upright position and call emergency services immediately.' },
    { step: 2, title: 'Unresponsiveness or Seizures',         so: 'Daran / wareeg',                body: 'Roll the child onto their side to keep the airway clear. Do not put anything in their mouth or hold them down. Time the seizure and call for help.' },
    { step: 3, title: 'High Fever in Infants Under 3 Months', so: 'Xummad carruurta yar yar',      body: 'Any temperature over 38°C (100.4°F) in a baby under 3 months is a medical emergency. Go to the nearest hospital immediately — do not wait.' },
    { step: 4, title: 'Severe Dehydration',                   so: 'Biyo la\'aanta xun',            body: 'Signs: dry mouth, no tears, sunken eyes, no urination for 8+ hours. Give ORS if conscious and transport to clinic urgently.' },
    { step: 5, title: 'Choking or Airway Blockage',           so: 'Wax ku xidaya neefsashada',     body: 'For infants: 5 back blows + 5 chest thrusts. For children: Heimlich maneuver. Call 252-1 immediately if the child cannot breathe.' },
];

export const EmergencyGuidance = () => {
    const [locationState, setLocationState] = useState('idle');
    const [coords, setCoords] = useState(null);
    const [locationSent, setLocationSent] = useState(false);
    const [mapUrl, setMapUrl] = useState('');
    const [expandedFacility, setExpandedFacility] = useState(null);

    const getLocation = () => {
        if (!navigator.geolocation) {
            setLocationState('error');
            return;
        }
        setLocationState('loading');
        navigator.geolocation.getCurrentPosition(
            (pos) => {
                const { latitude, longitude } = pos.coords;
                setCoords({ lat: latitude, lng: longitude });
                setLocationState('success');
                setMapUrl(`https://www.openstreetmap.org/export/embed.html?bbox=${longitude-0.02},${latitude-0.02},${longitude+0.02},${latitude+0.02}&layer=mapnik&marker=${latitude},${longitude}`);
            },
            () => setLocationState('error'),
            { timeout: 10000 }
        );
    };

    const sendLocationToDoctor = () => {
        if (!coords) return;
        const mapsLink = `https://www.openstreetmap.org/?mlat=${coords.lat}&mlon=${coords.lng}#map=15/${coords.lat}/${coords.lng}`;
        const msg = `📍 Emergency Location: ${mapsLink}\nCoordinates: ${coords.lat.toFixed(5)}, ${coords.lng.toFixed(5)}`;
        // Copy to clipboard for sharing
        navigator.clipboard?.writeText(msg).catch(() => {});
        setLocationSent(true);
        setTimeout(() => setLocationSent(false), 4000);
    };

    const callAmbulance = () => window.location.href = 'tel:252';
    const callDoctor = () => window.location.href = 'tel:252';

    return (
        <div className="w-full mx-auto space-y-6 animate-fade-in font-sans">
            {/* Hero — Emergency Banner */}
            <div className="bg-[#dc2626] rounded-xl shadow-lg p-6 sm:p-10 text-white relative overflow-hidden">
                <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/4 pointer-events-none"/>
                <div className="relative z-10 flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
                    <div className="flex items-center gap-5">
                        <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center shrink-0 animate-pulse">
                            <ShieldAlert size={32}/>
                        </div>
                        <div>
                            <h1 className="text-3xl font-black tracking-tight">Emergency Guidance</h1>
                            <p className="text-white/90 font-medium mt-1 max-w-lg">If your child is experiencing a life-threatening emergency, act immediately. Do not wait.</p>
                            <p className="text-red-200 font-black text-sm mt-1">🇸🇴 Hadduu caruurtu jiraan xaaladda degdegga, degdeg wac!</p>
                        </div>
                    </div>
                    {/* Emergency Call Buttons */}
                    <div className="flex flex-col gap-3 shrink-0 w-full md:w-auto">
                        <Button onClick={callAmbulance}
                            className="bg-white text-[#dc2626] hover:bg-red-50 font-black px-8 py-5 text-lg shadow-xl rounded-2xl flex items-center justify-center gap-3 w-full md:w-auto">
                            <Phone size={22} fill="currentColor"/> CALL AMBULANCE · 252-1
                        </Button>
                        <Button onClick={callDoctor}
                            className="bg-white/20 hover:bg-white/30 border-2 border-white/40 text-white font-black px-8 py-4 rounded-2xl flex items-center justify-center gap-3 w-full md:w-auto">
                            <Phone size={18}/> Call Doctor On-Call
                        </Button>
                    </div>
                </div>
            </div>

            {/* Location + Map Section */}
            <Card className="border-(--border) shadow-sm overflow-hidden">
                <div className="p-5 border-b border-(--border) bg-(--surface-soft) flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div>
                        <h2 className="font-black text-(--text-primary) text-lg flex items-center gap-2"><Navigation size={20} className="text-primary-500"/> Auto Location Sharing</h2>
                        <p className="text-sm text-(--text-secondary) font-medium mt-0.5">Share your exact GPS location with the doctor or ambulance instantly.</p>
                        <p className="text-xs text-(--text-muted) font-semibold mt-0.5">🇸🇴 Meeshaada si toos ah u dir dhakhtarka ama ambalaanka</p>
                    </div>
                    <div className="flex gap-3 flex-wrap">
                        <Button onClick={getLocation} disabled={locationState === 'loading'}
                            className={`font-bold flex items-center gap-2 ${locationState === 'success' ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-primary-600 hover:bg-primary-700'} text-white rounded-xl px-5 py-3`}>
                            {locationState === 'loading' ? <><Loader2 size={16} className="animate-spin"/> Getting location...</> :
                             locationState === 'success' ? <><CheckCircle size={16}/> Location Found</> :
                             <><MapPin size={16}/> Get My Location</>}
                        </Button>
                        {coords && (
                            <Button onClick={sendLocationToDoctor}
                                className={`font-bold flex items-center gap-2 rounded-xl px-5 py-3 ${locationSent ? 'bg-emerald-600 text-white' : 'bg-amber-500 hover:bg-amber-600 text-white'}`}>
                                {locationSent ? <><CheckCircle size={16}/> Copied!</> : <><Share2 size={16}/> Share Location</>}
                            </Button>
                        )}
                    </div>
                </div>

                {/* Map Embed */}
                <div className="relative">
                    {locationState === 'success' && mapUrl ? (
                        <div className="space-y-0">
                            <iframe
                                src={mapUrl}
                                width="100%" height="320"
                                className="border-0 w-full"
                                title="Your Location"
                                loading="lazy"
                            />
                            <div className="p-4 bg-emerald-50 dark:bg-emerald-950/30 border-t border-emerald-200 flex items-center gap-3">
                                <CheckCircle size={18} className="text-emerald-600 shrink-0"/>
                                <div>
                                    <div className="font-black text-emerald-700 text-sm">Location detected</div>
                                    <div className="text-xs font-semibold text-emerald-600">{coords?.lat?.toFixed(5)}, {coords?.lng?.toFixed(5)}</div>
                                </div>
                                <div className="ml-auto">
                                    <a href={`https://www.openstreetmap.org/?mlat=${coords?.lat}&mlon=${coords?.lng}#map=15/${coords?.lat}/${coords?.lng}`}
                                        target="_blank" rel="noopener noreferrer"
                                        className="text-xs font-black text-emerald-700 hover:underline">Open in Maps →</a>
                                </div>
                            </div>
                        </div>
                    ) : locationState === 'error' ? (
                        <div className="p-8 text-center bg-red-50 dark:bg-red-950/20">
                            <AlertCircle size={32} className="mx-auto text-red-400 mb-3"/>
                            <p className="font-bold text-red-600">Could not access location. Please enable GPS and try again.</p>
                        </div>
                    ) : (
                        <div className="p-8 text-center bg-(--surface-soft)">
                            <MapPin size={40} className="mx-auto text-slate-300 mb-3"/>
                            <p className="font-bold text-(--text-muted)">Click "Get My Location" to show your position on the map</p>
                            <p className="text-sm text-(--text-muted) mt-1">Your location will be shared with emergency services when needed</p>
                        </div>
                    )}
                </div>
            </Card>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Emergency Protocols */}
                <Card className="col-span-1 lg:col-span-2 border-(--border) shadow-sm">
                    <CardContent className="p-6 sm:p-8">
                        <h2 className="text-lg font-black text-(--text-primary) mb-6 flex items-center gap-3">
                            <HeartPulse className="text-[#dc2626]" size={24}/> Immediate Action Protocols
                        </h2>
                        <div className="space-y-6">
                            {PROTOCOLS.map(p => (
                                <div key={p.step} className="flex gap-4">
                                    <div className="w-10 h-10 rounded-xl bg-danger/10 text-red-600 font-black flex items-center justify-center shrink-0 text-lg border border-red-200">{p.step}</div>
                                    <div className="flex-1">
                                        <h3 className="font-black text-(--text-primary) text-base">{p.title}</h3>
                                        <p className="text-xs font-bold text-red-500 italic mb-1">🇸🇴 {p.so}</p>
                                        <p className="text-sm text-(--text-secondary) font-medium leading-relaxed">{p.body}</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>

                {/* Nearest Facilities */}
                <div className="col-span-1 space-y-4">
                    <Card className="shadow-sm">
                        <CardContent className="p-5">
                            <h3 className="font-black text-(--text-primary) mb-4 text-sm flex items-center gap-2">
                                <Building2 size={16} className="text-teal"/> Nearest Approved Facilities
                            </h3>
                            <div className="space-y-3">
                                {FACILITIES.map((fac, i) => {
                                    const isExpanded = expandedFacility === i;
                                    const directionsUrl = `https://www.openstreetmap.org/directions?from=&to=${fac.lat},${fac.lng}`;
                                    return (
                                    <div key={i} className={`rounded-xl border-2 transition-all duration-200 overflow-hidden ${isExpanded ? 'border-red-400 shadow-md' : 'border-(--border) hover:border-red-300'}`}>
                                        {/* Header row — always visible */}
                                        <button className="w-full text-left p-4 bg-(--surface-soft) flex items-center gap-3"
                                            onClick={() => setExpandedFacility(isExpanded ? null : i)}>
                                            <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${fac.type === 'Hospital' ? 'bg-red-100 text-red-600' : 'bg-emerald-100 text-emerald-600'}`}>
                                                {fac.type === 'Hospital' ? <Building2 size={16}/> : <Stethoscope size={16}/>}
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <div className="font-black text-(--text-primary) text-sm truncate">{fac.name}</div>
                                                <div className="flex items-center gap-2 mt-0.5">
                                                    <span className="text-[10px] font-bold text-primary-500">{fac.distance}</span>
                                                    <span className="text-[10px] font-bold text-(--text-muted) flex items-center gap-0.5"><Clock size={9}/> {fac.open}</span>
                                                    <span className={`text-[9px] font-black uppercase px-1.5 py-0.5 rounded-full ${fac.type === 'Hospital' ? 'bg-red-100 text-red-700' : 'bg-emerald-100 text-emerald-700'}`}>{fac.type}</span>
                                                </div>
                                            </div>
                                            {isExpanded ? <ChevronUp size={16} className="text-(--text-muted) shrink-0"/> : <ChevronDown size={16} className="text-(--text-muted) shrink-0"/>}
                                        </button>

                                        {/* Expanded detail */}
                                        {isExpanded && (
                                            <div className="px-4 pb-4 bg-(--surface) border-t border-(--border) space-y-3 pt-3">
                                                {/* Address */}
                                                <div className="flex items-start gap-2 text-sm">
                                                    <MapPin size={14} className="text-(--text-muted) mt-0.5 shrink-0"/>
                                                    <span className="text-(--text-secondary) font-medium">{fac.address}</span>
                                                </div>
                                                {/* Phone */}
                                                <div className="flex items-center gap-2 text-sm">
                                                    <Phone size={14} className="text-(--text-muted) shrink-0"/>
                                                    <span className="font-black text-(--text-primary)">{fac.phone}</span>
                                                </div>
                                                {/* Action buttons */}
                                                <div className="grid grid-cols-2 gap-2 pt-1">
                                                    <button onClick={() => window.location.href = `tel:${fac.phone}`}
                                                        className="flex items-center justify-center gap-2 py-2.5 bg-red-600 hover:bg-red-700 text-white text-xs font-black rounded-xl transition-colors">
                                                        <Phone size={13} fill="currentColor"/> Call Now
                                                    </button>
                                                    <a href={directionsUrl} target="_blank" rel="noopener noreferrer"
                                                        className="flex items-center justify-center gap-2 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-black rounded-xl transition-colors">
                                                        <ExternalLink size={13}/> Directions
                                                    </a>
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                    );
                                })}
                            </div>
                        </CardContent>
                    </Card>

                    {/* Quick Emergency Contacts */}
                    <Card className="shadow-sm bg-red-50 dark:bg-red-950/20 border-red-200">
                        <CardContent className="p-5 space-y-3">
                            <h3 className="font-black text-red-700 text-sm flex items-center gap-2"><Phone size={15}/> Emergency Contacts</h3>
                            {[
                                { label: 'Ambulance',         number: '252-1',        color: 'bg-red-600' },
                                { label: 'Police Emergency',  number: '999',          color: 'bg-blue-600' },
                                { label: 'Banadir Hospital',  number: '+252-61-0000', color: 'bg-emerald-600' },
                            ].map(c => (
                                <button key={c.label} onClick={() => window.location.href = `tel:${c.number}`}
                                    className="w-full flex items-center gap-3 p-3 bg-white dark:bg-slate-900 rounded-xl border border-red-200 hover:shadow-sm transition-all">
                                    <div className={`w-8 h-8 rounded-full ${c.color} text-white flex items-center justify-center shrink-0`}>
                                        <Phone size={14}/>
                                    </div>
                                    <div className="text-left">
                                        <div className="font-black text-(--text-primary) text-xs">{c.label}</div>
                                        <div className="text-[10px] font-bold text-(--text-muted)">{c.number}</div>
                                    </div>
                                </button>
                            ))}
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
};
