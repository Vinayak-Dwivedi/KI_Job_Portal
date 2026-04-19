import { Outlet, Link, useLocation, useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
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
  DollarSign,
  Flag,
  Sparkles
} from "lucide-react"

import { ModeToggle } from "../mode-toggle"
import { Button } from "../ui/button"
import { useAuth } from "@/providers/AuthContext"

const sidebarItems = [
  { icon: BarChart3, label: "Overview", href: "/" },
  { icon: DollarSign, label: "Revenue", href: "/revenue" },
  { icon: Users, label: "Users", href: "/users" },
  { icon: Briefcase, label: "Jobs", href: "/jobs" },
  { icon: FileText, label: "Posts", href: "/posts" },
  { icon: ShieldCheck, label: "Verification", href: "/verification" },
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

  return (
    <div className="flex h-screen w-full overflow-hidden bg-background">
      {/* Sidebar */}
      <motion.aside 
        initial={{ x: -300 }}
        animate={{ x: 0 }}
        className="w-64 flex-shrink-0 border-r glass-card flex flex-col z-10"
      >
        <div className="h-16 flex items-center px-6 border-b border-white/10 dark:border-white/5">
          <div className="flex items-center gap-2">
            <div className="h-8 w-8 rounded-lg bg-gradient-to-tr from-primary to-blue-500 flex items-center justify-center text-white font-bold">
              KI
            </div>
            <span className="font-bold text-lg text-gradient">Admin Panel</span>
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto py-6 px-4 space-y-2">
          {sidebarItems.map((item) => {
            const isActive = location.pathname === item.href
            return (
              <Link key={item.href} to={item.href}>
                <motion.div
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                    isActive 
                      ? "bg-primary/10 text-primary font-medium" 
                      : "text-muted-foreground hover:bg-white/10 dark:hover:bg-white/5 hover:text-foreground"
                  }`}
                >
                  <item.icon className={`h-5 w-5 ${isActive ? "text-primary" : ""}`} />
                  {item.label}
                  {isActive && (
                    <motion.div 
                      layoutId="active-nav" 
                      className="absolute right-0 w-1 h-8 bg-primary rounded-l-full" 
                    />
                  )}
                </motion.div>
              </Link>
            )
          })}
        </nav>

        <div className="p-4 border-t border-white/10 dark:border-white/5">
          <Button onClick={logout} variant="ghost" className="w-full justify-start gap-3 text-muted-foreground hover:text-destructive">
            <LogOut className="h-5 w-5" />
            Logout
          </Button>
        </div>
      </motion.aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col relative overflow-hidden z-0">
        {/* Header */}
        <header className="h-16 flex items-center justify-between px-8 border-b glass-card z-10">
          <h1 className="text-xl font-semibold capitalize">
            {location.pathname === "/" ? "Overview" : location.pathname.replace("/", "")}
          </h1>
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="icon" className="relative">
              <Bell className="h-5 w-5" />
              <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-primary animate-pulse" />
            </Button>
            <ModeToggle />
            <div 
              className="h-9 w-9 rounded-xl border border-white/10 overflow-hidden bg-gradient-to-tr from-purple-500/20 to-primary/20 flex items-center justify-center cursor-pointer group hover:border-primary/50 transition-all"
              onClick={() => navigate("/settings")}
            >
              {user?.profilePhotoUrl ? (
                <img src={user.profilePhotoUrl} alt="Admin" className="h-full w-full object-cover group-hover:scale-110 transition-transform" />
              ) : (
                <span className="text-xs font-black text-primary uppercase">
                  {(user?.name || "AD").substring(0, 2)}
                </span>
              )}
            </div>
          </div>
        </header>

        {/* Dynamic Page Content */}
        <div className="flex-1 overflow-auto p-8 relative">
          {/* Subtle animated background blob */}
          <div className="absolute top-[-10%] left-[-10%] w-96 h-96 bg-primary/20 rounded-full blur-[100px] pointer-events-none" />
          <div className="absolute bottom-[-10%] right-[-10%] w-96 h-96 bg-blue-500/20 rounded-full blur-[100px] pointer-events-none" />
          
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
            className="h-full relative z-10"
          >
            <Outlet />
          </motion.div>
        </div>
      </main>
    </div>
  )
}
