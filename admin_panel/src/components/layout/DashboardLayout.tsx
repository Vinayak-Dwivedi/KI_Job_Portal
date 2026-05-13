import { useState, useEffect } from "react"
import { Outlet, Link, useLocation, useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { collection, query, where, onSnapshot, orderBy, limit } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { toast } from "sonner"
import AdminCopilot from "@/components/copilot/AdminCopilot"
import { 
  BarChart3, 
  Users, 
  Briefcase,
  FileText,
  ShieldCheck, 
  CreditCard,
  Settings, 
  LogOut,
  Bell,
  MessageSquare,
  MessageCircle,
  DollarSign,
  Flag,
  Sparkles,
  Tag,
  UserPlus,
  Coins
} from "lucide-react"

import { Button } from "../ui/button"
import { useAuth } from "@/providers/AuthContext"

const sidebarItems = [
  { icon: BarChart3, label: "Overview", href: "/" },
  { icon: DollarSign, label: "Revenue", href: "/revenue" },
  { icon: Users, label: "Users", href: "/users" },
  { icon: Briefcase, label: "Jobs", href: "/jobs" },
  { icon: MessageCircle, label: "User Chats", href: "/chats" },
  { icon: FileText, label: "Posts", href: "/posts" },
  { icon: ShieldCheck, label: "Verification", href: "/verification" },
  { icon: Tag, label: "Coupons", href: "/coupons" },
  { icon: UserPlus, label: "Referrals", href: "/referrals" },
  { icon: Coins, label: "Credit Bundles", href: "/credits" },
  { icon: CreditCard, label: "Payments", href: "/payments" },
  { icon: Sparkles, label: "Subscription Plans", href: "/plans" },
  { icon: MessageSquare, label: "Announcements", href: "/announcements" },
  { icon: Flag, label: "Reports", href: "/reports" },
  { icon: Settings, label: "Settings", href: "/settings" },
]

export function DashboardLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { logout, user } = useAuth()
  const [unverifiedCount, setUnverifiedCount] = useState(0)

  useEffect(() => {
    // Listen for unverified users count
    const qCount = query(collection(db, "users"), where("isVerified", "==", false))
    const unsubscribeCount = onSnapshot(qCount, (snapshot) => {
      setUnverifiedCount(snapshot.size)
    })

    // Listen for NEW users specifically to show toast
    const qNew = query(
      collection(db, "users"), 
      where("isVerified", "==", false),
      orderBy("createdAt", "desc"),
      limit(1)
    )
    
    let isFirstLoad = true
    const unsubscribeNew = onSnapshot(qNew, (snapshot) => {
      if (isFirstLoad) {
        isFirstLoad = false
        return
      }
      
      if (!snapshot.empty) {
        const newUser = snapshot.docs[0].data()
        toast.info("New User Profile", {
          description: `${newUser.name || 'A new user'} just joined and needs verification.`,
          action: {
            label: "Verify",
            onClick: () => navigate("/users?filter=unverified")
          },
        })
      }
    })

    return () => {
      unsubscribeCount()
      unsubscribeNew()
    }
  }, [navigate])

  return (
    <div className="flex h-screen w-full overflow-hidden bg-[#0A0D12]">
      {/* Sidebar omitted for brevity, keeping existing sidebar logic */}
      <motion.aside 
        initial={{ x: -300 }}
        animate={{ x: 0 }}
        className="w-64 flex-shrink-0 border-r border-white/5 bg-[#0F131A] flex flex-col z-10"
      >
        <div className="h-16 flex items-center px-6 border-b border-white/5">
          <div className="flex items-center gap-2">
            <div className="h-9 w-9 rounded-xl bg-primary flex items-center justify-center text-white font-bold shadow-[0_0_20px_rgba(var(--primary),0.3)]">
              KI
            </div>
            <span className="font-bold text-lg text-white tracking-tighter">KARIGAR <span className="text-primary font-black">AI</span></span>
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto py-6 px-4 space-y-1.5 custom-scrollbar">
          {sidebarItems.map((item) => {
            const isActive = location.pathname === item.href
            return (
              <Link key={item.href} to={item.href}>
                <motion.div
                  whileHover={{ x: 4 }}
                  whileTap={{ scale: 0.98 }}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 group ${
                    isActive 
                      ? "bg-primary/10 text-primary border border-primary/20 shadow-[0_0_20px_rgba(var(--primary),0.05)]" 
                      : "text-zinc-500 hover:text-zinc-200 hover:bg-white/5 border border-transparent"
                  }`}
                >
                  <item.icon className={`h-5 w-5 transition-transform group-hover:scale-110 ${isActive ? "text-primary" : ""}`} />
                  <span className="font-semibold text-sm">{item.label}</span>
                </motion.div>
              </Link>
            )
          })}
        </nav>

        <div className="p-4 border-t border-white/5">
          <Button onClick={logout} variant="ghost" className="w-full justify-start gap-3 text-zinc-500 hover:text-red-400 hover:bg-red-500/10">
            <LogOut className="h-5 w-5" />
            Logout
          </Button>
        </div>
      </motion.aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col relative overflow-hidden z-0">
        {/* Header */}
        <header className="h-16 flex items-center justify-between px-8 border-b border-white/5 bg-[#0F131A]/80 backdrop-blur-xl z-10">
          <h1 className="text-lg font-black tracking-tight text-white uppercase">
            {location.pathname === "/" ? "Overview" : location.pathname.replace("/", "").replace("-", " ")}
          </h1>
          <div className="flex items-center gap-5">
            <div className="hidden md:flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary/10 border border-primary/20">
               <div className="h-2 w-2 rounded-full bg-primary animate-pulse" />
               <span className="text-[10px] font-black text-primary uppercase tracking-widest">System Active</span>
            </div>
            <div className="hidden lg:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-violet-500/10 border border-violet-500/20 cursor-default">
              <img src="/copilot-bot.jpg" alt="Copilot" className="h-4 w-4 rounded-full object-cover" />
              <span className="text-[10px] font-black text-violet-400 uppercase tracking-widest">Copilot Active</span>
            </div>
            
            <div className="flex items-center gap-2">
              <Button 
                variant="ghost" 
                size="icon" 
                className="text-zinc-400 hover:text-white"
                onClick={() => navigate("/chats")}
              >
                <MessageCircle className="h-5 w-5" />
              </Button>

              <Button 
                variant="ghost" 
                size="icon" 
                className="relative text-zinc-400 hover:text-white"
                onClick={() => navigate("/users?filter=unverified")}
              >
                <Bell className="h-5 w-5" />
                {unverifiedCount > 0 && (
                  <span className="absolute top-2 right-2 h-4 w-4 rounded-full bg-primary text-[10px] font-bold text-white flex items-center justify-center shadow-[0_0_10px_rgba(var(--primary),0.8)]">
                    {unverifiedCount}
                  </span>
                )}
              </Button>
            </div>
            
            <div className="h-6 w-px bg-white/10" />
            
            <div 
              className="h-10 w-10 rounded-2xl border border-white/10 overflow-hidden bg-zinc-800 flex items-center justify-center cursor-pointer group hover:border-primary transition-all p-0.5"
              onClick={() => navigate("/settings")}
            >
              {user?.profilePhotoUrl ? (
                <img src={user.profilePhotoUrl} alt="Admin" className="h-full w-full rounded-xl object-cover" />
              ) : (
                <div className="h-full w-full rounded-xl bg-primary/20 flex items-center justify-center">
                  <span className="text-xs font-black text-primary uppercase">
                    {(user?.name || "AD").substring(0, 2)}
                  </span>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Dynamic Page Content */}
        <div className="flex-1 overflow-auto p-8 relative">
          {/* Subtle Background Effects */}
          <div className="absolute top-[-10%] left-[20%] w-[500px] h-[500px] bg-primary/5 rounded-full blur-[120px] pointer-events-none" />
          <div className="absolute bottom-[10%] right-[-10%] w-[400px] h-[400px] bg-blue-500/5 rounded-full blur-[100px] pointer-events-none" />
          
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4, ease: "easeOut" }}
            className="h-full relative z-10"
          >
            <Outlet />
          </motion.div>
        </div>
      </main>

      {/* AI Admin Copilot — Fixed overlay, always available */}
      <AdminCopilot />
    </div>
  )
}
