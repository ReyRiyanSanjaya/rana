import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polygon, Tooltip as LeafletTooltip, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import AdminLayout from '../components/AdminLayout';
import api from '../api';
import Card from '../components/ui/Card';
import L from 'leaflet';
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';
import { Target, Map as MapIcon, Navigation } from 'lucide-react';

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
const MapController = ({ center, zoom }) => {
    const map = useMap();
    useEffect(() => {
        map.flyTo(center, zoom, { duration: 1.5 });
    }, [center, zoom, map]);
    return null;
};

const AcquisitionMap = () => {
    const [stores, setStores] = useState([]);
    const [activeCity, setActiveCity] = useState(CITIES.MEDAN);
    const [districtStats, setDistrictStats] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStores = async () => {
            try {
                const res = await api.get('/admin/merchants');
                const validStores = res.data.data.filter(s => s.latitude && s.longitude);
                setStores(validStores);
            } catch (error) {
                console.error("Failed to fetch stores", error); // Handle gracefully
            } finally {
                setLoading(false);
            }
        };
        fetchStores();
    }, []);

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

    return (
        <AdminLayout>
            <div className="absolute inset-0 bg-gradient-to-br from-slate-50 to-blue-50/30 z-[-1]" />

            <div className="mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-600">
                        Acquisition Map
                    </h1>
                    <p className="text-slate-500 mt-1 font-medium">Strategic intelligence & territory management.</p>
                </div>

                {/* City Switcher */}
                <div className="bg-white/80 backdrop-blur-md p-1.5 rounded-xl border border-white/50 shadow-sm flex items-center space-x-1">
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
                            <MapController center={activeCity.center} zoom={activeCity.zoom} />

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
                        </MapContainer>

                        {/* Floating Glass Panel - Stats */}
                        <div className="absolute top-6 right-6 w-64 bg-white/80 backdrop-blur-xl p-5 rounded-2xl shadow-lg border border-white/50 z-[1000] transition-all hover:bg-white/90">
                            <div className="flex items-center justify-between mb-4">
                                <h3 className="font-bold text-slate-800 flex items-center">
                                    <Target size={18} className="mr-2 text-indigo-500" />
                                    {activeCity.name} Insights
                                </h3>
                            </div>

                            <div className="space-y-3">
                                {districtStats.map(d => (
                                    <div key={d.name} className="flex items-center justify-between group cursor-default">
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
        </AdminLayout>
    );
};

export default AcquisitionMap;
