import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polygon, Circle, Tooltip as LeafletTooltip, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import AdminLayout from '../components/AdminLayout';
import api from '../api';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import L from 'leaflet';
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';
import { Target, Map as MapIcon, Navigation, Eye, Flame, Download } from 'lucide-react';

// Fix Leaflet Default Icon
let DefaultIcon = L.icon({
    iconUrl: icon,
    shadowUrl: iconShadow,
    iconSize: [25, 41],
    iconAnchor: [12, 41]
});
L.Marker.prototype.options.icon = DefaultIcon;

// --- CONFIGURATION ---

const CITIES = {
    MEDAN: {
        name: 'Medan',
        center: [3.5952, 98.6722],
        zoom: 12,
        districts: [
            { name: 'Medan Baru', color: '#60A5FA', bounds: [[3.5650, 98.6450], [3.5850, 98.6650]] }, // Soft Blue
            { name: 'Medan Petisah', color: '#F87171', bounds: [[3.5850, 98.6550], [3.6000, 98.6700]] }, // Soft Red
            { name: 'Medan Kota', color: '#34D399', bounds: [[3.5700, 98.6800], [3.5900, 98.7000]] }, // Soft Emerald
            { name: 'Medan Johor', color: '#FBBF24', bounds: [[3.5200, 98.6600], [3.5500, 98.6900]] }, // Soft Amber
            { name: 'Medan Sunggal', color: '#A78BFA', bounds: [[3.5600, 98.6000], [3.5900, 98.6300]] }, // Soft Violet
        ]
    },
    JAKARTA: {
        name: 'Jakarta',
        center: [-6.2088, 106.8456],
        zoom: 11,
        districts: [
            { name: 'Menteng', color: '#60A5FA', bounds: [[-6.2000, 106.8300], [-6.1900, 106.8500]] },
            { name: 'Kebayoran Baru', color: '#34D399', bounds: [[-6.2400, 106.7900], [-6.2200, 106.8100]] },
            { name: 'Kelapa Gading', color: '#FFB4C2', bounds: [[-6.1600, 106.9000], [-6.1400, 106.9200]] }, // Soft Pink
        ]
    }
};

// Component to handle map view changes
const MapController = ({ center, zoom, bounds }) => {
    const map = useMap();
    useEffect(() => {
        if (bounds) {
            map.fitBounds(bounds, { animate: true, duration: 1.0, padding: [20, 20] });
        } else {
            map.flyTo(center, zoom, { duration: 1.5 });
        }
    }, [center, zoom, bounds, map]);
    return null;
};

const AcquisitionMap = () => {
    const [stores, setStores] = useState([]);
    const [activeCity, setActiveCity] = useState(CITIES.MEDAN);
    const [districtStats, setDistrictStats] = useState([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState('');
    const [planFilter, setPlanFilter] = useState('');
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');
    const [showMarkers, setShowMarkers] = useState(true);
    const [showHeat, setShowHeat] = useState(false);
    const [focusBounds, setFocusBounds] = useState(null);

    useEffect(() => {
        const fetchStores = async () => {
            try {
                setLoading(true);
                const params = new URLSearchParams();
                params.append('city', activeCity.name);
                if (statusFilter) params.append('status', statusFilter);
                if (planFilter) params.append('plan', planFilter);
                if (dateFrom) params.append('createdFrom', dateFrom);
                if (dateTo) params.append('createdTo', dateTo);
                const res = await api.get(`/admin/merchants?${params.toString()}`);
                const validStores = res.data.data.filter(s => s.latitude && s.longitude);
                setStores(validStores);
            } catch (error) {
                console.error("Failed to fetch stores", error);
            } finally {
                setLoading(false);
            }
        };
        fetchStores();
        setFocusBounds(null);
    }, [activeCity, statusFilter, planFilter, dateFrom, dateTo]);

    // Recalculate stats when city or stores change
    useEffect(() => {
        if (stores.length === 0) return;

        const stats = activeCity.districts.map(district => {
            const [sw, ne] = district.bounds;
            const count = stores.filter(s =>
                s.latitude >= sw[0] && s.latitude <= ne[0] &&
                // Handle longitude wraparound if necessary (unlikely for Indonesia)
                s.longitude >= sw[1] && s.longitude <= ne[1]
            ).length;
            return { ...district, count };
        });
        setDistrictStats(stats);
    }, [activeCity, stores]);

    const exportCsv = () => {
        const params = new URLSearchParams();
        params.append('format', 'csv');
        params.append('city', activeCity.name);
        if (statusFilter) params.append('status', statusFilter);
        if (planFilter) params.append('plan', planFilter);
        if (dateFrom) params.append('createdFrom', dateFrom);
        if (dateTo) params.append('createdTo', dateTo);
        window.open(`/api/admin/merchants/export?${params.toString()}`, '_blank');
    };

    const boundsFromDistrict = (district) => {
        const [sw, ne] = district.bounds;
        return [sw, ne];
    };

    return (
        <AdminLayout>
            <div className="relative overflow-x-hidden w-full">
            <div className="absolute inset-0 bg-gradient-to-br from-slate-50 to-blue-50/30 z-[-1]" />

            <div className="mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-600">
                        Acquisition Map
                    </h1>
                    <p className="text-slate-500 mt-1 font-medium">Strategic intelligence & territory management.</p>
                </div>

                {/* City Switcher */}
                <div className="bg-white/80 backdrop-blur-md p-1.5 rounded-xl border border-white/50 shadow-sm flex items-center space-x-1 flex-wrap">
                    {Object.values(CITIES).map(city => (
                        <button
                            key={city.name}
                            onClick={() => setActiveCity(city)}
                            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-300 flex items-center ${activeCity.name === city.name
                                    ? 'bg-white text-blue-600 shadow-sm ring-1 ring-slate-100'
                                    : 'text-slate-500 hover:bg-slate-50 hover:text-slate-700'
                                }`}
                        >
                            <Navigation size={14} className={`mr-2 ${activeCity.name === city.name ? 'fill-current' : ''}`} />
                            {city.name}
                        </button>
                    ))}
                </div>
            </div>

            <Card className="mb-4">
                <div className="p-3 flex flex-col md:flex-row md:flex-wrap gap-3 items-center">
                    <select
                        className="px-3 py-2 border border-primary-300 rounded-lg text-sm bg-white"
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                    >
                        <option value="">All Status</option>
                        <option value="ACTIVE">Active</option>
                        <option value="TRIAL">Trial</option>
                        <option value="EXPIRED">Expired</option>
                        <option value="CANCELLED">Cancelled</option>
                    </select>
                    <select
                        className="px-3 py-2 border border-primary-300 rounded-lg text-sm bg-white"
                        value={planFilter}
                        onChange={(e) => setPlanFilter(e.target.value)}
                    >
                        <option value="">All Plans</option>
                        <option value="FREE">Free</option>
                        <option value="PREMIUM">Premium</option>
                        <option value="ENTERPRISE">Enterprise</option>
                    </select>
                    <input
                        type="date"
                        className="px-3 py-2 border border-primary-300 rounded-lg text-sm bg-white"
                        value={dateFrom}
                        onChange={(e) => setDateFrom(e.target.value)}
                    />
                    <input
                        type="date"
                        className="px-3 py-2 border border-primary-300 rounded-lg text-sm bg-white"
                        value={dateTo}
                        onChange={(e) => setDateTo(e.target.value)}
                    />
                    <div className="flex-1" />
                    <Button variant="outline" icon={Download} onClick={exportCsv}>Export CSV</Button>
                    <Button variant={showMarkers ? 'secondary' : 'outline'} icon={Eye} onClick={() => setShowMarkers(v => !v)}>
                        {showMarkers ? 'Hide Markers' : 'Show Markers'}
                    </Button>
                    <Button variant={showHeat ? 'secondary' : 'outline'} icon={Flame} onClick={() => setShowHeat(v => !v)}>
                        {showHeat ? 'Hide Heat' : 'Show Heat'}
                    </Button>
                </div>
            </Card>

            <Card className="h-[650px] overflow-hidden rounded-2xl border border-white/60 shadow-xl relative z-0 bg-white/40 backdrop-blur-sm">
                {loading ? (
                    <div className="flex h-full flex-col items-center justify-center text-slate-400">
                        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-500 mb-4"></div>
                        <p className="font-medium animate-pulse">Loading Geospatial Data...</p>
                    </div>
                ) : (
                    <>
                        <MapContainer
                            center={activeCity.center}
                            zoom={activeCity.zoom}
                            style={{ height: '100%', width: '100%', background: 'transparent' }}
                            zoomControl={false}
                        >
                            <MapController center={activeCity.center} zoom={activeCity.zoom} bounds={focusBounds} />

                            {/* Dark/Light Mode compatible elegant tiles */}
                            <TileLayer
                                attribution='&copy; OpenStreetMap'
                                url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
                            />

                            {/* District Polygons (Soft UI) */}
                            {districtStats.map((district) => {
                                const [sw, ne] = district.bounds;
                                const polygonCoords = [sw, [ne[0], sw[1]], ne, [sw[0], ne[1]]];

                                return (
                                    <Polygon
                                        key={district.name}
                                        positions={polygonCoords}
                                        pathOptions={{
                                            color: district.color,
                                            fillOpacity: 0.15,
                                            weight: 0, // No border for cleaner look
                                            className: 'focus:outline-none'
                                        }}
                                        eventHandlers={{
                                            mouseover: (e) => {
                                                e.target.setStyle({ fillOpacity: 0.35, weight: 1 });
                                            },
                                            mouseout: (e) => {
                                                e.target.setStyle({ fillOpacity: 0.15, weight: 0 });
                                            },
                                            click: () => {
                                                setFocusBounds(boundsFromDistrict(district));
                                            }
                                        }}
                                    >
                                        <LeafletTooltip direction="center" opacity={1} permanent={true} className="!bg-transparent !border-0 !shadow-none">
                                            <div className="flex flex-col items-center justify-center p-2">
                                                <div
                                                    className="w-10 h-10 rounded-full flex items-center justify-center shadow-lg border-2 border-white backdrop-blur-md transition-transform hover:scale-110 cursor-default"
                                                    style={{ backgroundColor: `${district.color}40` }} // 40 hex = 25% opacity
                                                >
                                                    <span className="font-bold text-slate-800 text-sm">{district.count}</span>
                                                </div>
                                                <span
                                                    className="mt-1 text-[10px] font-bold uppercase tracking-wider text-slate-500 px-2 py-0.5 bg-white/70 rounded-full backdrop-blur-sm"
                                                >
                                                    {district.name}
                                                </span>
                                            </div>
                                        </LeafletTooltip>
                                    </Polygon>
                                );
                            })}
                            {showHeat && stores.map((s) => (
                                <Circle
                                    key={s.id}
                                    center={[s.latitude, s.longitude]}
                                    radius={120}
                                    pathOptions={{ color: '#669BBC', fillColor: '#669BBC', fillOpacity: 0.2, weight: 0 }}
                                />
                            ))}
                            {showMarkers && stores.map((s) => (
                                <Marker key={s.id} position={[s.latitude, s.longitude]}>
                                    <Popup>
                                        <div className="text-sm">
                                            <div className="font-semibold">{s.name}</div>
                                            <div className="text-slate-500">{s.location}</div>
                                            <div className="mt-1 text-xs">Plan: {s.tenant?.plan} • Status: {s.tenant?.subscriptionStatus}</div>
                                        </div>
                                    </Popup>
                                </Marker>
                            ))}
                        </MapContainer>

                        {/* Floating Glass Panel - Stats */}
                        <div className="absolute top-4 right-4 w-64 max-w-[90vw] bg-white/80 backdrop-blur-xl p-5 rounded-2xl shadow-lg border border-white/50 z-[1000] transition-all hover:bg-white/90">
                            <div className="flex items-center justify-between mb-4">
                                <h3 className="font-bold text-slate-800 flex items-center">
                                    <Target size={18} className="mr-2 text-indigo-500" />
                                    {activeCity.name} Insights
                                </h3>
                            </div>

                            <div className="space-y-3">
                                {districtStats.map(d => (
                                    <div
                                        key={d.name}
                                        className="flex items-center justify-between group cursor-pointer"
                                        onClick={() => setFocusBounds(boundsFromDistrict(d))}
                                    >
                                        <div className="flex items-center">
                                            <div
                                                className="w-2.5 h-2.5 rounded-full mr-3 shadow-sm transition-all group-hover:scale-125"
                                                style={{ backgroundColor: d.color }}
                                            ></div>
                                            <span className="text-sm text-slate-600 font-medium">{d.name}</span>
                                        </div>
                                        <span className="text-sm font-bold text-slate-800">{d.count}</span>
                                    </div>
                                ))}
                            </div>

                            <div className="mt-6 pt-4 border-t border-slate-200/60">
                                <div className="flex justify-between items-end">
                                    <span className="text-xs text-slate-400 font-medium">Total Acquired</span>
                                    <span className="text-2xl font-black text-slate-800 bg-clip-text text-transparent bg-gradient-to-br from-indigo-600 to-indigo-800">
                                        {stores.length}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </Card>
            </div>
        </AdminLayout>
    );
};

export default AcquisitionMap;
