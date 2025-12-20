import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import AdminLayout from '../components/AdminLayout';
import api from '../api';
import Card from '../components/ui/Card';
import L from 'leaflet';
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

// Fix Leaflet Default Icon Issue in React
let DefaultIcon = L.icon({
    iconUrl: icon,
    shadowUrl: iconShadow,
    iconSize: [25, 41],
    iconAnchor: [12, 41]
});
L.Marker.prototype.options.icon = DefaultIcon;

const AcquisitionMap = () => {
    const [stores, setStores] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStores = async () => {
            try {
                const res = await api.get('/admin/merchants');
                // Filter stores that have valid coordinates
                const validStores = res.data.data.filter(s => s.latitude && s.longitude);
                setStores(validStores);
            } catch (error) {
                console.error("Failed to fetch stores", error);
            } finally {
                setLoading(false);
            }
        };
        fetchStores();
    }, []);

    // Default Position (Indonesia Center approx)
    const position = [-2.5489, 118.0149];

    return (
        <AdminLayout>
            <div className="mb-6">
                <h1 className="text-2xl font-semibold text-slate-900">Acquisition Map</h1>
                <p className="text-slate-500 mt-1">Visualize store distribution and acquired territories.</p>
            </div>

            <Card className="h-[600px] overflow-hidden rounded-xl border border-slate-200 shadow-sm relative z-0">
                {loading ? (
                    <div className="flex h-full items-center justify-center bg-slate-50 text-slate-400">
                        Loading Map...
                    </div>
                ) : (
                    <MapContainer center={position} zoom={5} style={{ height: '100%', width: '100%' }}>
                        <TileLayer
                            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        />
                        {stores.map((store) => (
                            <Marker key={store.id} position={[store.latitude, store.longitude]}>
                                <Popup>
                                    <div className="p-1">
                                        <h3 className="font-bold text-sm text-slate-900">{store.name}</h3>
                                        <p className="text-xs text-slate-500">{store.location || 'No address'}</p>
                                        <p className="text-xs text-primary-600 mt-1 font-medium">
                                            {store.tenant?.name}
                                        </p>
                                    </div>
                                </Popup>
                            </Marker>
                        ))}
                    </MapContainer>
                )}
                <div className="absolute bottom-4 left-4 bg-white p-3 rounded-lg shadow-md z-[1000] text-sm">
                    <p className="font-semibold text-slate-700">Map Analytics</p>
                    <div className="mt-1 flex items-center space-x-2">
                        <span className="w-3 h-3 rounded-full bg-blue-500"></span>
                        <span className="text-slate-600">Acquired Stores: <b>{stores.length}</b></span>
                    </div>
                </div>
            </Card>
        </AdminLayout>
    );
};

export default AcquisitionMap;
