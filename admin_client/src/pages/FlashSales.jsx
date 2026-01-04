import React from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Button from '../components/ui/button';

const FlashSales = () => {
  const [loading, setLoading] = React.useState(false);
  const [flashSales, setFlashSales] = React.useState([]);

  const [statusFilter, setStatusFilter] = React.useState('ALL');

  const filteredSales = flashSales.filter(fs => {
    if (statusFilter === 'ALL') return true;
    return fs.status === statusFilter;
  });

  const refresh = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/flashsales');
      setFlashSales(res.data.data || []);
    } catch (e) {
      alert('Failed to load flash sales');
    } finally {
      setLoading(false);
    }
  };

  React.useEffect(() => {
    refresh();
  }, []);

  const updateStatus = async (id, action) => {
    try {
      await api.put(`/admin/flashsales/${id}/status`, { action });
      await refresh();
    } catch {
      alert('Failed to update status');
    }
  };

  return (
    <AdminLayout>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Flash Sales</h1>
          <p className="text-slate-500 mt-1">Kelola pengajuan dan status flash sale.</p>
        </div>
        <Button onClick={refresh}>Refresh</Button>
      </div>

      <Card className="p-6">
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left border-b">
                <th className="py-2 px-3">Judul</th>
                <th className="py-2 px-3">Toko</th>
                <th className="py-2 px-3">Periode</th>
                <th className="py-2 px-3">Status</th>
                <th className="py-2 px-3">Item</th>
                <th className="py-2 px-3">Aksi</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td className="py-6 px-3 text-slate-400" colSpan={6}>Loading...</td></tr>
              ) : filteredSales.length === 0 ? (
                <tr><td className="py-6 px-3 text-slate-400" colSpan={6}>Tidak ada data</td></tr>
              ) : filteredSales.map(fs => (
                <tr key={fs.id} className="border-b">
                  <td className="py-2 px-3 font-medium text-slate-900">{fs.title}</td>
                  <td className="py-2 px-3">{fs.store?.name || '-'}</td>
                  <td className="py-2 px-3">{new Date(fs.startAt).toLocaleString()} — {new Date(fs.endAt).toLocaleString()}</td>
                  <td className="py-2 px-3">{fs.status}</td>
                  <td className="py-2 px-3">
                    {(fs.items || []).slice(0, 3).map(it => (
                      <div key={it.id} className="text-slate-700">
                        {it.product?.name} → Rp {Math.round(it.salePrice).toLocaleString()}
                      </div>
                    ))}
                    {(fs.items || []).length > 3 && <div className="text-slate-500">+{(fs.items || []).length - 3} lagi</div>}
                  </td>
                  <td className="py-2 px-3">
                    <div className="flex gap-2">
                      <Button variant="outline" onClick={() => updateStatus(fs.id, 'APPROVE')}>Approve</Button>
                      <Button variant="outline" onClick={() => updateStatus(fs.id, 'REJECT')}>Reject</Button>
                      <Button variant="outline" onClick={() => updateStatus(fs.id, 'ACTIVATE')}>Activate</Button>
                      <Button variant="outline" onClick={() => updateStatus(fs.id, 'END')}>End</Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </AdminLayout>
  );
};

export default FlashSales;
