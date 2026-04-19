import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom"
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { ThemeProvider } from "./components/theme-provider"
import { AuthProvider } from "./providers/AuthContext"
import { ProtectedRoute } from "./components/layout/ProtectedRoute"
import { DashboardLayout } from "./components/layout/DashboardLayout"
import Dashboard from "./pages/Dashboard"
import Revenue from "./pages/Revenue"
import Login from "./pages/auth/Login"
import Users from "./pages/Users"
import Verification from "./pages/Verification"
import Jobs from "./pages/Jobs"
import Posts from "./pages/Posts"
import Payments from "./pages/Payments"
import Announcements from "./pages/Announcements"
import Settings from "./pages/Settings"
import Support from "./pages/Support"
import Reports from "./pages/Reports"
import UserProfile from "./pages/UserProfile"
import Plans from "./pages/Plans"

const queryClient = new QueryClient()

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider defaultTheme="dark" storageKey="vite-ui-theme">
        <AuthProvider>
          <BrowserRouter>
            <Routes>
              {/* Public Routes */}
              <Route path="/login" element={<Login />} />

              {/* Protected Admin Routes */}
              <Route path="/" element={<ProtectedRoute><DashboardLayout /></ProtectedRoute>}>
                <Route index element={<Dashboard />} />
                <Route path="revenue" element={<Revenue />} />
                <Route path="users" element={<Users />} />
                <Route path="verification" element={<Verification />} />
                <Route path="jobs" element={<Jobs />} />
                <Route path="posts" element={<Posts />} />
                <Route path="payments" element={<Payments />} />
                <Route path="announcements" element={<Announcements />} />
                <Route path="support" element={<Support />} />
                <Route path="reports" element={<Reports />} />
                <Route path="users/:uid" element={<UserProfile />} />
                <Route path="plans" element={<Plans />} />
                <Route path="settings" element={<Settings />} />
              </Route>
              
              {/* Fallback routing */}
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </BrowserRouter>
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  )
}

export default App
