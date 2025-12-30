import React from 'react';
import DashboardLayout from '../components/layout/DashboardLayout';
import api from '../services/api';
import { Plus, Trash2 } from 'lucide-react';

const FlashSales = () => {
  const [loading, setLoading] = React.useState(false);
  const [sales, setSales] = React.useState([]);
  const [creating, setCreating] = React.useState(false);
  const [newSale, setNewSale] = React.useState({ title: '', startAt: '', endAt: '' });
  const [newItem, setNewItem] = React.useState({ productId: '', salePrice: '', maxQtyPerOrder: '', saleStock: '' });
  const [selectedSaleId, setSelectedSaleId] = React.useState('');

  const refresh = async () => {
    setLoading(true);
    try {
      const res = await api.get('/products/flashsales');
      setSales(res.data.data || []);
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  React.useEffect(() => { refresh(); }, []);

  const createSale = async () => {
    if (!newSale.title || !newSale.startAt || !newSale.endAt) {
      alert('Judul dan periode wajib diisi');
      return;
    }
    const start = new Date(newSale.startAt);
    const end = new Date(newSale.endAt);
    if (!(start < end)) {
      alert('Tanggal mulai harus sebelum tanggal berakhir');
      return;
    }
    setCreating(true);
    try {
      await api.post('/products/flashsales', { ...newSale, items: [] });
      setNewSale({ title: '', startAt: '', endAt: '' });
      await refresh();
    } catch (e) {
      alert('Gagal membuat flash sale');
    } finally {
      setCreating(false);
    }
  };

  const addItem = async () => {
    if (!selectedSaleId) return;
    if (!newItem.productId) {
      alert('Product ID wajib diisi');
      return;
    }
    const salePrice = parseFloat(newItem.salePrice);
    if (isNaN(salePrice) || salePrice <= 0) {
      alert('Harga sale harus angka dan lebih dari 0');
      return;
    }
    try {
      await api.post(`/products/flashsales/${selectedSaleId}/items`, {
        productId: newItem.productId,
        salePrice,
        maxQtyPerOrder: parseInt(newItem.maxQtyPerOrder || 0),
        saleStock: newItem.saleStock ? parseInt(newItem.saleStock) : null
      });
      setNewItem({ productId: '', salePrice: '', maxQtyPerOrder: '', saleStock: '' });
      await refresh();
    } catch (e) {
      alert('Gagal menambah item');
    }
  };

  const deleteItem = async (saleId, itemId) => {
    try {
      await api.delete(`/products/flashsales/${saleId}/items/${itemId}`);
      await refresh();
    } catch {
      // ignore
    }
  };

  const cancelSale = async (id) => {
    try {
      await api.put(`/products/flashsales/${id}/status`, { action: 'CANCEL' });
      await refresh();
    } catch {
      // ignore
    }
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">Flash Sales</h1>
            <p className="text-slate-500">Ajukan dan kelola flash sale toko Anda</p>
          </div>
          <button onClick={refresh} className="px-3 py-2 bg-slate-100 rounded-lg">Refresh</button>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-6">
          <h3 className="font-bold mb-4">Buat Flash Sale</h3>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
            <input className="border rounded p-2" placeholder="Judul"
                   value={newSale.title} onChange={e => setNewSale({ ...newSale, title: e.target.value })} />
            <input className="border rounded p-2" type="datetime-local"
                   value={newSale.startAt} onChange={e => setNewSale({ ...newSale, startAt: e.target.value })} />
            <input className="border rounded p-2" type="datetime-local"
                   value={newSale.endAt} onChange={e => setNewSale({ ...newSale, endAt: e.target.value })} />
            <button onClick={createSale} disabled={creating} className="px-3 py-2 bg-indigo-600 text-white rounded-lg flex items-center justify-center">
              <Plus size={16} className="mr-2" /> {creating ? 'Membuat...' : 'Buat'}
            </button>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-6">
          <h3 className="font-bold mb-4">Tambah Item ke Flash Sale</h3>
          <div className="grid grid-cols-1 md:grid-cols-5 gap-3">
            <select className="border rounded p-2" value={selectedSaleId} onChange={e => setSelectedSaleId(e.target.value)}>
              <option value="">Pilih Flash Sale</option>
              {sales.map(s => <option key={s.id} value={s.id}>{s.title}</option>)}
            </select>
            <input className="border rounded p-2" placeholder="Product ID"
                   value={newItem.productId} onChange={e => setNewItem({ ...newItem, productId: e.target.value })} />
            <input className="border rounded p-2" placeholder="Sale Price" type="number"
                   value={newItem.salePrice} onChange={e => setNewItem({ ...newItem, salePrice: e.target.value })} />
            <input className="border rounded p-2" placeholder="Max Qty/Order" type="number"
                   value={newItem.maxQtyPerOrder} onChange={e => setNewItem({ ...newItem, maxQtyPerOrder: e.target.value })} />
            <input className="border rounded p-2" placeholder="Sale Stock (opsional)" type="number"
                   value={newItem.saleStock} onChange={e => setNewItem({ ...newItem, saleStock: e.target.value })} />
          </div>
          <div className="mt-3">
            <button onClick={addItem} className="px-3 py-2 bg-indigo-600 text-white rounded-lg">Tambah Item</button>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-6">
          <h3 className="font-bold mb-4">Daftar Flash Sale Saya</h3>
          {loading ? (
            <div className="text-slate-400">Loading...</div>
          ) : sales.length === 0 ? (
            <div className="text-slate-400">Belum ada flash sale</div>
          ) : (
            <div className="space-y-4">
              {sales.map(sale => (
                <div key={sale.id} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="font-semibold">{sale.title}</div>
                      <div className="text-sm text-slate-500">{new Date(sale.startAt).toLocaleString()} — {new Date(sale.endAt).toLocaleString()}</div>
                      <div className="text-sm text-slate-600 mt-1">Status: {sale.status}</div>
                    </div>
                    <div className="flex gap-2">
                      <button onClick={() => cancelSale(sale.id)} className="px-3 py-2 bg-red-50 text-red-600 rounded-lg">Batalkan</button>
                    </div>
                  </div>
                  <div className="mt-3">
                    <div className="text-sm font-medium mb-2">Items</div>
                    {(sale.items || []).length === 0 ? (
                      <div className="text-slate-400">Belum ada item</div>
                    ) : (
                      <div className="space-y-2">
                        {sale.items.map(item => (
                          <div key={item.id} className="flex items-center justify-between bg-slate-50 rounded p-2">
                            <div>
                              <div className="font-medium">{item.product?.name || item.productId}</div>
                              <div className="text-sm text-slate-600">Harga: Rp {Math.round(item.salePrice).toLocaleString()} • Max/Order: {item.maxQtyPerOrder || 'unlimited'} • Stock: {item.saleStock ?? '-'}</div>
                            </div>
                            <button onClick={() => deleteItem(sale.id, item.id)} className="p-2 text-slate-500 hover:text-red-600">
                              <Trash2 size={16} />
                            </button>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

export default FlashSales;
