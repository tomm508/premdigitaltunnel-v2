import { useState, useEffect } from 'react';
import { LayoutDashboard, Users, Shield, Globe, Settings, Terminal, Plus, Activity } from 'lucide-react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { collection, onSnapshot, addDoc, doc } from 'firebase/firestore';
import { db } from './firebase';

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

interface VpsNode {
  id: string;
  name?: string;
  ip?: string;
  status?: string;
  onlineUsers?: number;
  cpuLoad?: number;
  ramUsage?: number;
  lastHeartbeat?: string;
}

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [nodes, setNodes] = useState<VpsNode[]>([]);
  const [selectedNode, setSelectedNode] = useState<string>('sg1-premium-01');

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'vps_nodes'), (snapshot) => {
      const newNodes: VpsNode[] = [];
      snapshot.forEach(doc => {
        newNodes.push({ id: doc.id, ...doc.data() });
      });
      setNodes(newNodes);
      
      // Auto-select the first node if none is selected
      if (newNodes.length > 0 && !newNodes.find(n => n.id === selectedNode)) {
        setSelectedNode(newNodes[0].id);
      }
    });
    return () => unsub();
  }, [selectedNode]);
  
  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Sidebar */}
      <aside className="w-64 bg-slate-900 text-slate-300 flex flex-col transition-all">
        <div className="h-16 flex items-center px-6 font-bold text-white text-lg tracking-wide border-b border-slate-800">
          <Globe className="w-5 h-5 mr-3 text-cyan-400" />
          PremDigital
        </div>
        
        <div className="flex-1 overflow-y-auto py-4">
          <nav className="px-3 space-y-1">
            <SidebarItem 
              icon={<LayoutDashboard className="w-5 h-5" />} 
              label="Dashboard" 
              active={activeTab === 'dashboard'} 
              onClick={() => setActiveTab('dashboard')} 
            />
            <div className="pt-4 pb-2 px-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Tunneling
            </div>
            <SidebarItem 
              icon={<Terminal className="w-5 h-5" />} 
              label="SSH / Websocket" 
              active={activeTab === 'ssh'} 
              onClick={() => setActiveTab('ssh')} 
            />
            <SidebarItem 
              icon={<Shield className="w-5 h-5" />} 
              label="VMess" 
              active={activeTab === 'vmess'} 
              onClick={() => setActiveTab('vmess')} 
            />
            <SidebarItem 
              icon={<Shield className="w-5 h-5" />} 
              label="VLESS" 
              active={activeTab === 'vless'} 
              onClick={() => setActiveTab('vless')} 
            />
            <SidebarItem 
              icon={<Shield className="w-5 h-5" />} 
              label="Trojan" 
              active={activeTab === 'trojan'} 
              onClick={() => setActiveTab('trojan')} 
            />
          </nav>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col overflow-hidden">
        <header className="h-16 bg-white border-b flex items-center justify-between px-8 shadow-sm">
          <h1 className="text-xl font-semibold text-slate-800 capitalize">
            {activeTab.replace('-', ' ')}
          </h1>
          
          <div className="flex items-center space-x-3">
             <span className="text-sm font-medium text-slate-500">Target Node:</span>
             <select 
               value={selectedNode}
               onChange={e => setSelectedNode(e.target.value)}
               className="text-sm border border-slate-300 rounded-md px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-cyan-500"
             >
                {nodes.length === 0 && <option value="sg1-premium-01">sg1-premium-01</option>}
                {nodes.map(node => (
                   <option key={node.id} value={node.id}>{node.name || node.id} ({node.ip})</option>
                ))}
             </select>
          </div>
        </header>

        <div className="flex-1 overflow-y-auto p-8">
          {activeTab === 'dashboard' && <DashboardView nodes={nodes} />}
          {(activeTab === 'vmess' || activeTab === 'vless' || activeTab === 'trojan' || activeTab === 'ssh') && (
            <CreateAccountView protocol={activeTab} selectedNode={selectedNode} />
          )}
        </div>
      </main>
    </div>
  );
}

function SidebarItem({ icon, label, active, onClick }: { icon: React.ReactNode, label: string, active: boolean, onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={cn(
        "w-full flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-colors",
        active 
          ? "bg-cyan-500/10 text-cyan-400" 
          : "hover:bg-slate-800 hover:text-white"
      )}
    >
      <span className="mr-3">{icon}</span>
      {label}
    </button>
  );
}

function DashboardView({ nodes }: { nodes: VpsNode[] }) {
  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-slate-800">Server Nodes Status</h2>
      
      {nodes.length === 0 ? (
        <div className="p-8 text-center text-slate-500 bg-white rounded-xl border border-dashed">
          Menunggu telemetri dari VPS... Pastikan script report_status.sh berjalan di server Anda.
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6">
          {nodes.map(node => (
             <div key={node.id} className="bg-white rounded-xl shadow-sm border p-6">
                <div className="flex justify-between items-center mb-6">
                  <div>
                    <h3 className="text-xl font-bold text-slate-800">{node.name || node.id}</h3>
                    <p className="text-sm text-slate-500">{node.ip}</p>
                  </div>
                  <span className={cn(
                    "px-3 py-1 rounded-full text-xs font-semibold",
                    node.status === 'Online' ? "bg-emerald-100 text-emerald-700" : "bg-red-100 text-red-700"
                  )}>
                    {node.status || 'Offline'}
                  </span>
                </div>
                
                <div className="grid grid-cols-3 gap-6">
                  <StatCard title="Online Users" value={`${node.onlineUsers || 0}`} icon={<Users className="text-blue-500" />} />
                  <StatCard title="CPU Load" value={`${node.cpuLoad || 0}%`} icon={<Activity className="text-emerald-500" />} />
                  <StatCard title="RAM Usage" value={`${node.ramUsage || 0}%`} icon={<Terminal className="text-purple-500" />} />
                </div>
                
                <p className="text-xs text-slate-400 mt-6 text-right">
                  Last Heartbeat: {node.lastHeartbeat ? new Date(node.lastHeartbeat).toLocaleString() : 'N/A'}
                </p>
             </div>
          ))}
        </div>
      )}
    </div>
  );
}

function StatCard({ title, value, icon }: { title: string, value: string, icon: React.ReactNode }) {
  return (
    <div className="bg-slate-50 p-4 rounded-xl border flex items-center space-x-4">
      <div className="p-3 bg-white rounded-lg shadow-sm border">
        {icon}
      </div>
      <div>
        <p className="text-sm font-medium text-slate-500">{title}</p>
        <p className="text-xl font-bold text-slate-800 mt-1">{value}</p>
      </div>
    </div>
  );
}

function CreateAccountView({ protocol, selectedNode }: { protocol: string, selectedNode: string }) {
  const [username, setUsername] = useState('');
  const [days, setDays] = useState('30');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [created, setCreated] = useState(false);

  const handleCreate = async () => {
    if (!username || !selectedNode) return;
    
    setLoading(true);
    try {
      await addDoc(collection(db, 'vps_commands'), {
        serverId: selectedNode,
        status: 'pending',
        command: 'create_account',
        username,
        password: password || username,
        protocol,
        activeDays: parseInt(days),
        createdAt: new Date().toISOString()
      });
      
      setCreated(true);
      setTimeout(() => {
        setCreated(false);
        setUsername('');
        setPassword('');
      }, 5000);
    } catch (e) {
      console.error(e);
      alert('Gagal mengirim perintah. Pastikan konfigurasi Firebase benar.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl bg-white rounded-xl shadow-sm border overflow-hidden">
      <div className="px-6 py-5 border-b bg-slate-50/50">
        <h2 className="text-lg font-semibold text-slate-800 capitalize">Buat Akun {protocol}</h2>
        <p className="text-sm text-slate-500 mt-1">Mengirim perintah ke node <strong>{selectedNode}</strong></p>
      </div>
      
      <div className="p-6 space-y-5">
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Username</label>
          <input 
            type="text" 
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 outline-none transition-all"
            placeholder="Masukkan username"
          />
        </div>
        
        {protocol === 'ssh' && (
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Password</label>
            <input 
              type="text" 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 outline-none transition-all"
              placeholder="Masukkan password"
            />
          </div>
        )}
        
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Durasi (Hari)</label>
          <input 
            type="number" 
            value={days}
            onChange={(e) => setDays(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 outline-none transition-all"
            placeholder="30"
          />
        </div>

        <button 
          onClick={handleCreate}
          disabled={loading || !username}
          className="w-full bg-cyan-600 hover:bg-cyan-700 disabled:opacity-50 text-white font-medium py-2.5 rounded-lg transition-colors flex items-center justify-center"
        >
          {loading ? 'Mengirim Perintah...' : (
             <>
               <Plus className="w-5 h-5 mr-2" /> Create Account di {selectedNode}
             </>
          )}
        </button>

        {created && (
          <div className="mt-6 p-4 bg-emerald-50 border border-emerald-200 rounded-lg">
            <h3 className="font-semibold text-emerald-800 mb-2">Perintah Terkirim!</h3>
            <p className="text-sm text-emerald-700">
              VPS {selectedNode} akan memproses pembuatan akun {protocol} dalam beberapa detik.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
