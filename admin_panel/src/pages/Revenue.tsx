import { useQuery } from "@tanstack/react-query"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { DollarSign, Loader2, TrendingUp, CreditCard } from "lucide-react"
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  AreaChart,
  Area
} from "recharts"
import { collection, getCountFromServer } from "firebase/firestore"
import { db } from "@/lib/firebase"

const fetchRevenueStats = async () => {
    // Basic mock implementation for revenue page
    // In a production system, revenue should accurately reflect transactions.
    const subSnap = await getCountFromServer(collection(db, "subscriptions"));
    const applicationsSnap = await getCountFromServer(collection(db, "applications"));
    
    // Revenue mock based on tokens & subscriptions
    const subCount = subSnap.data().count;
    const appCount = applicationsSnap.data().count;

    // Tokens bought * est cost, etc.
    const currentMonth = new Date().getMonth();
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    
    // Instead of completely fabricated data, use zeros for past, and actual aggregate for current month until a timeseries backend is implemented.
    const realGrowth = Array.from({length: 6}).map((_, i) => {
      const isCurrent = i === 5;
      return {
        name: months[(currentMonth - 5 + i + 12) % 12],
        revenue: isCurrent ? (subCount * 499 + appCount * 15) : 0,
        subRevenue: isCurrent ? (subCount * 499) : 0,
        tokenRevenue: isCurrent ? (appCount * 15) : 0,
      }
    });

    return {
      totalRevenue: subCount * 499 + appCount * 15,
      mrr: subCount * 499,
      revenueGrowth: realGrowth
    };
};

export default function Revenue() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ["revenue_stats"],
    queryFn: fetchRevenueStats,
  });

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
         <h2 className="text-3xl font-bold tracking-tight">Revenue Dashboard</h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className="glass-card border-none shadow-xl bg-gradient-to-br from-green-500/10 to-transparent">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-zinc-500">Total Lifecycle Revenue</CardTitle>
            <div className="bg-green-500/10 p-2 rounded-lg">
               <DollarSign className="h-4 w-4 text-green-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-4xl font-black">₹{stats?.totalRevenue.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
              <TrendingUp className="w-3 h-3 text-green-500" /> Projected platform economy
            </p>
          </CardContent>
        </Card>

        <Card className="glass-card border-none shadow-xl bg-gradient-to-br from-purple-500/10 to-transparent">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-zinc-500">Estimated MRR</CardTitle>
            <div className="bg-purple-500/10 p-2 rounded-lg">
               <CreditCard className="h-4 w-4 text-purple-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-4xl font-black">₹{stats?.mrr.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1 text-purple-400">Monthly recurring revenue from subscriptions</p>
          </CardContent>
        </Card>
      </div>

      {/* Revenue Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="glass-card border-none shadow-lg">
          <CardHeader>
            <CardTitle>Revenue Velocity</CardTitle>
            <CardDescription>Monthly growth in total platform earnings</CardDescription>
          </CardHeader>
          <CardContent className="pl-2">
            <div className="h-[350px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={stats?.revenueGrowth}>
                  <defs>
                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#22c55e" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#22c55e" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" opacity={0.1} vertical={false} />
                  <XAxis dataKey="name" stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="#888888" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `₹${value}`} />
                  <Tooltip contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }} />
                  <Area type="monotone" dataKey="revenue" stroke="#22c55e" fillOpacity={1} fill="url(#colorRevenue)" strokeWidth={3} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card className="glass-card border-none shadow-lg">
          <CardHeader>
            <CardTitle>Revenue Sources</CardTitle>
            <CardDescription>Subscriptions vs Token Purchases</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[350px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={stats?.revenueGrowth}>
                  <CartesianGrid strokeDasharray="3 3" opacity={0.1} vertical={false} />
                  <XAxis dataKey="name" stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }} />
                  <Bar dataKey="subRevenue" fill="#a855f7" radius={[4, 4, 0, 0]} stackId="a" name="Subscriptions" />
                  <Bar dataKey="tokenRevenue" fill="#3b82f6" radius={[4, 4, 0, 0]} stackId="a" name="Tokens" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
