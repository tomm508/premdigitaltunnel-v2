import React, { useState } from 'react';
import { 
  Server, ArrowRightLeft, Shield, Activity, 
  CheckCircle2, Copy, Check, Terminal, ExternalLink,
  Layers, RefreshCw, AlertCircle, ArrowRight
} from 'lucide-react';

interface VpsNode {
  id: string;
  name?: string;
  ip?: string;
  status?: string;
  onlineUsers?: number;
  cpuLoad?: number;
  ramUsage?: number;
}

export function LoadBalancerView({ nodes }: { nodes: VpsNode[] }) {
  const [sourceNodeId, setSourceNodeId] = useState<string>(nodes[0]?.id || 'vps-a');
  const [targetNodeId, setTargetNodeId] = useState<string>(nodes[1]?.id || 'vps-b');
  const [copiedIndex, setCopiedIndex] = useState<string | null>(null);

  const sourceNode = nodes.find(n => n.id === sourceNodeId) || { id: 'vps-a', name: 'VPS A (Masa Sewa Hampir Habis)', ip: '159.65.10.28' };
  const targetNode = nodes.find(n => n.id === targetNodeId) || { id: 'vps-b', name: 'VPS B (Server Baru)', ip: '128.199.112.55' };

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedIndex(id);
    setTimeout(() => setCopiedIndex(null), 2500);
  };

  const exportCmd = `bash /vps-scripts/migrate.sh --export`;
  const importCmd = `scp root@${sourceNode.ip || 'IP_VPS_A'}:/root/premdigital_backup.tar.gz /root/ && bash /vps-scripts/migrate.sh --import /root/premdigital_backup.tar.gz`;
  const installLbCmd = `bash /vps-scripts/setup-haproxy-lb.sh`;

  return (
    <div className="space-y-8 max-w-6xl">
      {/* Header Info */}
      <div className="bg-gradient-to-r from-slate-900 to-slate-800 text-white rounded-2xl p-6 shadow-md border border-slate-700">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2 text-cyan-400 text-xs font-semibold uppercase tracking-wider mb-1">
              <Layers className="w-4 h-4" />
              <span>Multi-Core Load Balancer & Zero-Downtime Migration</span>
            </div>
            <h2 className="text-2xl font-bold text-white">Sistem Load Balancer & Migrasi VPS</h2>
            <p className="text-slate-300 text-sm mt-1 max-w-2xl">
              Seimbangkan beban ribuan koneksi user SSH/WS & Xray, serta pindahkan seluruh akun pelanggan dari VPS lama ke VPS baru dengan 1 klik tanpa mengubah UUID atau password.
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <span className="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-medium bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
              <Activity className="w-3.5 h-3.5 mr-1.5 text-emerald-400" /> HAProxy LeastConn Ready
            </span>
          </div>
        </div>
      </div>

      {/* Grid 2 Kolom: 1. Internal HAProxy LB, 2. Migration Wizard */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Card 1: Internal HAProxy Load Balancer */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center space-x-3">
                <div className="p-2.5 bg-cyan-50 text-cyan-600 rounded-xl">
                  <Layers className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-slate-800 text-base">HAProxy Multi-Core Balancer</h3>
                  <p className="text-xs text-slate-500">Membagi koneksi masuk ke backend workers</p>
                </div>
              </div>
              <span className="px-2.5 py-1 text-xs font-semibold bg-cyan-100 text-cyan-700 rounded-full">
                Internal VPS
              </span>
            </div>

            <div className="mt-5 space-y-3.5">
              <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-500 font-medium">Algoritma Distribusi:</span>
                <span className="font-semibold text-slate-800">leastconn (Beban Paling Ringan)</span>
              </div>
              <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-500 font-medium">Port Masuk (Frontend):</span>
                <span className="font-semibold text-cyan-600">Port 80 (HTTP/WS) & 443 (HTTPS/TLS)</span>
              </div>
              <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-500 font-medium">Multi-Worker Backend:</span>
                <span className="font-semibold text-slate-700">WS Core 1, WS Core 2, Xray TLS</span>
              </div>
              <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-500 font-medium">Web Statistik Real-time:</span>
                <span className="font-semibold text-slate-700 font-mono">Port 8443 (admin:premdigital)</span>
              </div>
            </div>

            <div className="mt-5 p-4 bg-slate-900 rounded-xl text-left font-mono text-xs">
              <div className="flex items-center justify-between text-slate-400 mb-2">
                <span className="flex items-center">
                  <Terminal className="w-3.5 h-3.5 mr-1.5 text-cyan-400" /> Pasang / Update HAProxy di VPS:
                </span>
                <button 
                  onClick={() => copyToClipboard(installLbCmd, 'lb')} 
                  className="hover:text-white transition-colors"
                >
                  {copiedIndex === 'lb' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
              <p className="text-emerald-400 break-all select-all">{installLbCmd}</p>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between">
            <span className="text-xs text-slate-500">Tersedia di Menu VPS: <strong>[11] Load Balancer</strong></span>
            <span className="text-xs text-emerald-600 font-semibold flex items-center">
              <CheckCircle2 className="w-3.5 h-3.5 mr-1" /> Health Check Otomatis
            </span>
          </div>
        </div>

        {/* Card 2: Zero-Downtime Server Migration */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center space-x-3">
                <div className="p-2.5 bg-indigo-50 text-indigo-600 rounded-xl">
                  <ArrowRightLeft className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-slate-800 text-base">Migrasi VPS Tanpa Ganti Akun</h3>
                  <p className="text-xs text-slate-500">Pindah dari VPS lama saat masa sewa habis</p>
                </div>
              </div>
              <span className="px-2.5 py-1 text-xs font-semibold bg-indigo-100 text-indigo-700 rounded-full">
                Zero Downtime
              </span>
            </div>

            <div className="mt-5 space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Server Lama (VPS A):</label>
                  <select 
                    value={sourceNodeId} 
                    onChange={e => setSourceNodeId(e.target.value)}
                    className="w-full text-xs font-semibold bg-slate-50 border border-slate-200 rounded-lg p-2.5 outline-none focus:ring-1 focus:ring-indigo-500"
                  >
                    {nodes.map(n => <option key={n.id} value={n.id}>{n.name || n.id} ({n.ip})</option>)}
                    {nodes.length === 0 && <option value="vps-a">VPS A ({sourceNode.ip})</option>}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500 mb-1">Server Baru (VPS B):</label>
                  <select 
                    value={targetNodeId} 
                    onChange={e => setTargetNodeId(e.target.value)}
                    className="w-full text-xs font-semibold bg-slate-50 border border-slate-200 rounded-lg p-2.5 outline-none focus:ring-1 focus:ring-indigo-500"
                  >
                    {nodes.map(n => <option key={n.id} value={n.id}>{n.name || n.id} ({n.ip})</option>)}
                    {nodes.length === 0 && <option value="vps-b">VPS B ({targetNode.ip})</option>}
                  </select>
                </div>
              </div>

              {/* Step Flow */}
              <div className="space-y-2.5 pt-2">
                <div className="p-3 bg-amber-50/70 border border-amber-200/80 rounded-xl text-xs flex items-start space-x-2.5">
                  <div className="w-5 h-5 rounded-full bg-amber-200 text-amber-800 flex items-center justify-center font-bold text-[10px] shrink-0 mt-0.5">1</div>
                  <div>
                    <p className="font-semibold text-amber-900">Jalankan Export di VPS Lama (VPS A):</p>
                    <div className="mt-1 flex items-center justify-between font-mono bg-amber-100/70 px-2 py-1 rounded text-[11px] text-amber-950">
                      <span>{exportCmd}</span>
                      <button onClick={() => copyToClipboard(exportCmd, 'exp')} className="ml-2 hover:opacity-70">
                        {copiedIndex === 'exp' ? <Check className="w-3 h-3 text-emerald-600" /> : <Copy className="w-3 h-3" />}
                      </button>
                    </div>
                  </div>
                </div>

                <div className="p-3 bg-indigo-50/70 border border-indigo-200/80 rounded-xl text-xs flex items-start space-x-2.5">
                  <div className="w-5 h-5 rounded-full bg-indigo-200 text-indigo-800 flex items-center justify-center font-bold text-[10px] shrink-0 mt-0.5">2</div>
                  <div className="w-full">
                    <p className="font-semibold text-indigo-900">Tarik & Pulihkan Data di VPS Baru (VPS B):</p>
                    <div className="mt-1 flex items-center justify-between font-mono bg-indigo-100/70 px-2 py-1 rounded text-[11px] text-indigo-950 break-all">
                      <span className="truncate">{importCmd}</span>
                      <button onClick={() => copyToClipboard(importCmd, 'imp')} className="ml-2 shrink-0 hover:opacity-70">
                        {copiedIndex === 'imp' ? <Check className="w-3 h-3 text-emerald-600" /> : <Copy className="w-3 h-3" />}
                      </button>
                    </div>
                  </div>
                </div>

                <div className="p-3 bg-emerald-50/70 border border-emerald-200/80 rounded-xl text-xs flex items-start space-x-2.5">
                  <div className="w-5 h-5 rounded-full bg-emerald-200 text-emerald-800 flex items-center justify-center font-bold text-[10px] shrink-0 mt-0.5">3</div>
                  <div>
                    <p className="font-semibold text-emerald-900">Arahkan DNS Domain ke IP VPS Baru:</p>
                    <p className="text-emerald-700 mt-0.5">
                      Ganti A-Record domain di Cloudflare ke <strong>{targetNode.ip || 'IP_VPS_BARU'}</strong>. Semua pelanggan otomatis terhubung ke VPS baru tanpa perlu buat akun baru!
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>UUID & Password Pelanggan:</span>
            <span className="font-semibold text-emerald-600 flex items-center">
              <CheckCircle2 className="w-3.5 h-3.5 mr-1" /> 100% Identik & Awet
            </span>
          </div>
        </div>
      </div>

      {/* Visual Diagram Arsitektur */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
        <h3 className="font-bold text-slate-800 text-base mb-4 flex items-center">
          <Server className="w-4 h-4 mr-2 text-cyan-600" />
          Alur Failover & Distribusi Trafik
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-center">
          <div className="p-4 bg-slate-50 rounded-xl border border-slate-200 text-center">
            <span className="text-xs font-semibold text-slate-500">Domain Pelanggan</span>
            <h4 className="font-bold text-slate-800 mt-1">sgdo-premdigital.web.id</h4>
            <p className="text-xs text-slate-400 mt-1">DNS Round-Robin / Cloudflare</p>
          </div>

          <div className="flex justify-center text-cyan-500">
            <ArrowRight className="w-6 h-6 hidden md:block" />
            <span className="md:hidden text-xs text-slate-400">Terhubung ke</span>
          </div>

          <div className="p-4 bg-slate-50 rounded-xl border border-slate-200 text-center">
            <span className="text-xs font-semibold text-emerald-600">HAProxy Balancer</span>
            <h4 className="font-bold text-slate-800 mt-1">Multi-Worker LeastConn</h4>
            <p className="text-xs text-slate-400 mt-1">SSH/WS Port 10015 & Xray TLS Port 10443</p>
          </div>
        </div>
      </div>
    </div>
  );
}
