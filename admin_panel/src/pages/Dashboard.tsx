import { useState } from "react"
import { useQuery } from "@tanstack/react-query"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Users, Briefcase, Activity, HardHat, Loader2, Download, ChevronDown, FileText, TableProperties, CreditCard } from "lucide-react"
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
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex items-center justify-between">
         <h2 className="text-3xl font-bold tracking-tight">Platform Overview</h2>
         
         <div className="relative">
            <Button 
               variant="outline" 
               className="gap-2 h-11 border-zinc-200 dark:border-zinc-800"
               onClick={() => setShowExportMenu(!showExportMenu)}
               disabled={isExporting}
            >
               {isExporting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
               Export Statistics
               <ChevronDown className="w-4 h-4 opacity-50" />
            </Button>

            {showExportMenu && (
              <div className="absolute right-0 top-full mt-2 w-48 rounded-xl border border-white/10 glass-card bg-background shadow-2xl z-50 overflow-hidden animate-in slide-in-from-top-2">
                <button onClick={() => handleExport('pdf')} className="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium hover:bg-zinc-100 dark:hover:bg-zinc-900 transition-colors">
                  <FileText className="w-4 h-4 text-red-500" /> Export as PDF
                </button>
                <div className="h-px bg-white/5 w-full" />
                <button onClick={() => handleExport('csv')} className="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium hover:bg-zinc-100 dark:hover:bg-zinc-900 transition-colors">
                  <TableProperties className="w-4 h-4 text-green-500" /> Export as CSV
                </button>
              </div>
            )}
         </div>
      </div>

      {/* Top Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="glass-card border-none shadow-xl">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-zinc-500">Total Users</CardTitle>
            <div className="bg-blue-500/10 p-2 rounded-lg">
               <Users className="h-4 w-4 text-blue-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-black">{stats?.totalUsers.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">Platform-wide registrations</p>
          </CardContent>
        </Card>

        <Card className="glass-card border-none shadow-xl">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-zinc-500">Total Workers</CardTitle>
            <div className="bg-emerald-500/10 p-2 rounded-lg">
               <HardHat className="h-4 w-4 text-emerald-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-black">{stats?.totalWorkers.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">Verified taskers</p>
          </CardContent>
        </Card>

        <Card className="glass-card border-none shadow-xl">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-zinc-500">Total Employers</CardTitle>
            <div className="bg-purple-500/10 p-2 rounded-lg">
               <Briefcase className="h-4 w-4 text-purple-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-black">{stats?.totalEmployers.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">Registered employers</p>
          </CardContent>
        </Card>

        <Card className="glass-card border-none shadow-xl">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-zinc-500">Total Subscribers</CardTitle>
            <div className="bg-orange-500/10 p-2 rounded-lg">
               <CreditCard className="h-4 w-4 text-orange-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-black">{stats?.totalSubscribers.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">Active paid plans</p>
          </CardContent>
        </Card>
      </div>

      {/* Chart Section */}
      <Card className="glass-card border-none shadow-lg">
        <CardHeader>
          <CardTitle>Growth Trends</CardTitle>
          <CardDescription>Monthly registration and subscription trajectory</CardDescription>
        </CardHeader>
        <CardContent className="pl-2">
          <div className="h-[400px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={stats?.userGrowth}>
                <defs>
                  <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" opacity={0.1} vertical={false} />
                <XAxis 
                  dataKey="name" 
                  stroke="#888888" 
                  fontSize={12} 
                  tickLine={false} 
                  axisLine={false} 
                />
                <YAxis 
                  stroke="#888888" 
                  fontSize={12} 
                  tickLine={false} 
                  axisLine={false} 
                  tickFormatter={(value) => `${value}`} 
                />
                <Tooltip 
                  contentStyle={{ borderRadius: '12px', background: 'rgba(255,255,255,0.9)', backdropFilter: 'blur(8px)', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                />
                <Area type="monotone" name="Total Users" dataKey="users" stroke="hsl(var(--primary))" fillOpacity={1} fill="url(#colorUsers)" strokeWidth={3} />
                <Area type="monotone" name="Workers" dataKey="workers" stroke="#10b981" fill="transparent" strokeWidth={2} />
                <Area type="monotone" name="Employers" dataKey="employers" stroke="#a855f7" fill="transparent" strokeWidth={2} />
                <Area type="monotone" name="Subscribers" dataKey="subscribers" stroke="#f59e0b" fill="transparent" strokeDasharray="5 5" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
