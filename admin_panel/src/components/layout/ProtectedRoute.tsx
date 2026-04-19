import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "@/providers/AuthContext";
import { Loader2 } from "lucide-react";

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="flex h-screen w-screen items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground animate-pulse">Checking credentials...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    // Save the current location so we can redirect back after login if desired
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
