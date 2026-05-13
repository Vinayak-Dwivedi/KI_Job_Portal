import { useState } from "react"
import { useQuery } from "@tanstack/react-query"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Users, Briefcase, HardHat, Loader2, Download, ChevronDown, FileText, TableProperties, CreditCard, Activity, TrendingUp } from "lucide-react"
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer
} from "recharts"
import { fetchDashboardStats, exportComprehensiveAnalytics } from "@/lib/api/dashboard"
import { exportToPDF, exportToCSV } from "@/lib/exportUtils"
import { Button } from "@/components/ui/button"

export default function Dashboard() {
  const [isExporting, setIsExporting] = useState(false);
  const [showExportMenu, setShowExportMenu] = useState(false);

  const { data: stats, isLoading } = useQuery({
    queryKey: ["dashboard_stats"],
    queryFn: fetchDashboardStats,
  });

  const handleExport = async (format: 'pdf' | 'csv') => {
    setIsExporting(true);
    setShowExportMenu(false);
    try {
      const data = await exportComprehensiveAnalytics();
      
      if (format === 'pdf') {
        const columns = [
          { header: "Name", dataKey: "name" },
          { header: "Role", dataKey: "role" },
          { header: "Joined On", dataKey: "joinDate" },
          { header: "Posts", dataKey: "postsCount" },
          { header: "Tokens", dataKey: "credits" },
          { header: "Active Connections", dataKey: "activeWork" }
        ];

        const pdfData = data.map(u => ({
          name: u.name,
          role: u.role,
          joinDate: u.joinDate,
          postsCount: u.postsCount,
          credits: u.credits,
          activeWork: u.activeWork.join(', ') || 'None'
        }));

        exportToPDF("Comprehensive User Analytics", columns, pdfData, "ki_platform_analytics.pdf");
      } else {
        const csvData = data.map(u => ({
          Name: u.name,
          Email: u.email,
          Role: u.role,
          "Joined On": u.joinDate,
          "Posts Count": u.postsCount,
          "Token Balance": u.credits,
          "Active Work Connections": u.activeWork.join(', ') || 'None'
        }));
        exportToCSV(csvData, "ki_platform_analytics.csv");
      }
    } catch (error) {
      console.error("Export failed:", error);
    } finally {
      setIsExporting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="h-[80vh] flex items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-10 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
         <div>
            <h2 className="text-3xl font-black tracking-tight text-white uppercase">Platform Analytics</h2>
            <p className="text-zinc-500 font-medium mt-1">Real-time health and growth indicators</p>
         </div>
         
         <div className="relative">
            <Button 
               variant="outline" 
               className="gap-3 h-12 bg-white/5 border-white/10 hover:bg-white/10 text-white rounded-2xl px-6 transition-all"
               onClick={() => setShowExportMenu(!showExportMenu)}
               disabled={isExporting}
            >
               {isExporting ? <Loader2 className="w-4 h-4 animate-spin text-primary" /> : <Download className="w-4 h-4 text-primary" />}
               <span className="font-bold">EXPORT DATA</span>
               <ChevronDown className="w-4 h-4 opacity-50" />
            </Button>

            {showExportMenu && (
              <div className="absolute right-0 top-full mt-3 w-56 rounded-2xl border border-white/10 bg-[#161B22] shadow-2xl z-50 overflow-hidden animate-in slide-in-from-top-2">
                <button onClick={() => handleExport('pdf')} className="w-full flex items-center gap-3 px-5 py-4 text-sm font-bold text-zinc-300 hover:text-white hover:bg-white/5 transition-all">
                  <FileText className="w-5 h-5 text-red-500" /> Export as PDF
                </button>
                <div className="h-px bg-white/5 w-full" />
                <button onClick={() => handleExport('csv')} className="w-full flex items-center gap-3 px-5 py-4 text-sm font-bold text-zinc-300 hover:text-white hover:bg-white/5 transition-all">
                  <TableProperties className="w-5 h-5 text-emerald-500" /> Export as CSV
                </button>
              </div>
            )}
         </div>
      </div>

      {/* Top Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard 
          title="Total Users" 
          value={stats?.totalUsers} 
          icon={Users} 
          color="blue" 
          description="Platform registrations"
        />
        <StatCard 
          title="Total Workers" 
          value={stats?.totalWorkers} 
          icon={HardHat} 
          color="emerald" 
          description="Verified taskers"
        />
        <StatCard 
          title="Total Employers" 
          value={stats?.totalEmployers} 
          icon={Briefcase} 
          color="indigo" 
          description="Registered hirers"
        />
        <StatCard 
          title="Subscribers" 
          value={stats?.totalSubscribers} 
          icon={CreditCard} 
          color="amber" 
          description="Active paid plans"
        />
      </div>

      {/* Main Chart Section */}
      <Card className="bg-[#0F131A] border border-white/5 rounded-[32px] overflow-hidden shadow-2xl">
        <CardHeader className="p-8 pb-0">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-xl font-black text-white flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-primary" />
                USER GROWTH TRAJECTORY
              </CardTitle>
              <p className="text-zinc-500 text-sm font-medium mt-1">Comparative growth across all user segments</p>
            </div>
            <div className="flex items-center gap-4 text-[10px] font-black uppercase tracking-widest">
              <div className="flex items-center gap-1.5 text-primary"><div className="w-2 h-2 rounded-full bg-primary" /> Total</div>
              <div className="flex items-center gap-1.5 text-emerald-500"><div className="w-2 h-2 rounded-full bg-emerald-500" /> Workers</div>
              <div className="flex items-center gap-1.5 text-indigo-500"><div className="w-2 h-2 rounded-full bg-indigo-500" /> Employers</div>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-8">
          <div className="h-[450px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={stats?.userGrowth} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorPrimary" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                <XAxis 
                  dataKey="name" 
                  stroke="rgba(255,255,255,0.3)" 
                  fontSize={10} 
                  fontWeight="bold"
                  tickLine={false} 
                  axisLine={false} 
                  tickMargin={15}
                />
                <YAxis 
                  stroke="rgba(255,255,255,0.3)" 
                  fontSize={10} 
                  fontWeight="bold"
                  tickLine={false} 
                  axisLine={false} 
                  tickFormatter={(value) => `${value}`} 
                />
                <Tooltip 
                  contentStyle={{ 
                    borderRadius: '20px', 
                    background: '#161B22', 
                    border: '1px solid rgba(255,255,255,0.1)', 
                    boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)',
                    padding: '16px'
                  }}
                  itemStyle={{ fontWeight: 'bold', fontSize: '12px' }}
                />
                <Area type="monotone" dataKey="users" stroke="hsl(var(--primary))" fillOpacity={1} fill="url(#colorPrimary)" strokeWidth={4} />
                <Area type="monotone" dataKey="workers" stroke="#10b981" fill="transparent" strokeWidth={2} />
                <Area type="monotone" dataKey="employers" stroke="#6366f1" fill="transparent" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

function StatCard({ title, value, icon: Icon, color, description }: any) {
  const colorMap: any = {
    blue: "text-blue-400 bg-blue-500/10 border-blue-500/20",
    emerald: "text-emerald-400 bg-emerald-500/10 border-emerald-500/20",
    indigo: "text-indigo-400 bg-indigo-500/10 border-indigo-500/20",
    amber: "text-amber-400 bg-amber-500/10 border-amber-500/20",
  }

  return (
    <Card className="bg-[#0F131A] border border-white/5 rounded-[24px] p-6 hover:border-primary/50 transition-all group overflow-hidden relative">
      <div className="absolute top-[-20px] right-[-20px] h-32 w-32 rounded-full bg-primary/5 blur-3xl pointer-events-none group-hover:bg-primary/10 transition-all" />
      
      <div className="flex flex-row items-center justify-between mb-6">
        <div className={`p-3 rounded-2xl border ${colorMap[color]}`}>
           <Icon className="h-5 w-5" />
        </div>
        <div className="flex items-center gap-1 text-primary">
          <Activity className="h-3 w-3 animate-pulse" />
          <span className="text-[10px] font-black uppercase tracking-widest">Live</span>
        </div>
      </div>
      
      <div>
        <div className="text-4xl font-black text-white tracking-tighter">
          {value?.toLocaleString() || "0"}
        </div>
        <p className="text-sm font-bold text-zinc-300 mt-2 uppercase tracking-tight">{title}</p>
        <p className="text-xs text-zinc-500 font-medium mt-1">{description}</p>
      </div>
    </Card>
  )
}
