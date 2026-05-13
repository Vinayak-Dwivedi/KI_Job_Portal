import { useState, useEffect } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Lock, Mail, Loader2, AlertCircle } from "lucide-react";
import { auth } from "@/lib/firebase";
import { useAuth } from "@/providers/AuthContext";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (user) {
      navigate("/");
    }
  }, [user, navigate]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Please fill in both fields");
      return;
    }

    setLoading(true);
    setError("");

    try {
      await signInWithEmailAndPassword(auth, email, password);
      // Wait for AuthContext to detect auth change, fetch role, and redirect via useEffect.
    } catch (err: any) {
      setError(err.message || "Failed to sign in. Please check your credentials.");
      // Enhance common Firebase enum errors
      if (err.code === "auth/invalid-credential") {
         setError("Invalid email or password.");
      }
      setLoading(false); // Only set loading to false on error. On success, context loading takes over.
    }
  };

  const handleForgotPassword = async () => {
    if (!email) {
      setError("Please enter your admin email to reset password.");
      return;
    }
    try {
      const { sendPasswordResetEmail } = await import("firebase/auth");
      await sendPasswordResetEmail(auth, email);
      setError("Password reset email sent. Check your inbox.");
    } catch (err: any) {
      setError(err.message || "Failed to send reset email.");
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background relative overflow-hidden">
      {/* Background Orbs */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-primary/20 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] bg-blue-500/20 rounded-full blur-[120px] pointer-events-none" />

      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: "easeOut" }}
        className="w-full max-w-md z-10 px-4"
      >
        <Card className="glass-card border-white/20 dark:border-white/10 shadow-2xl">
          <CardHeader className="space-y-3 text-center pt-8">
            <div className="mx-auto bg-gradient-to-tr from-primary to-blue-500 w-16 h-16 rounded-2xl flex items-center justify-center shadow-lg border border-white/20 mb-2">
              <Lock className="w-8 h-8 text-white" />
            </div>
            <CardTitle className="text-2xl font-bold tracking-tight">Admin Gateway</CardTitle>
            <CardDescription>
              Enter your credentials to access the KI Job Portal system.
            </CardDescription>
          </CardHeader>
          <CardContent className="pb-8">
            <form onSubmit={handleLogin} className="space-y-5">
              
              {error && (
                <motion.div 
                  initial={{ opacity: 0, height: 0 }} 
                  animate={{ opacity: 1, height: "auto" }} 
                  className="bg-destructive/15 text-destructive p-3 rounded-lg flex items-start gap-2 text-sm border border-destructive/20"
                >
                  <AlertCircle className="w-4 h-4 mt-0.5" />
                  <p>{error}</p>
                </motion.div>
              )}

              <div className="space-y-4">
                <div className="relative">
                  <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input 
                    placeholder="Admin Email" 
                    type="email" 
                    className="pl-10 h-11 bg-background/50 border-white/10 dark:border-white/5"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
                <div className="relative">
                  <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input 
                    placeholder="Password" 
                    type="password" 
                    className="pl-10 h-11 bg-background/50 border-white/10 dark:border-white/5"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                  />
                </div>
              </div>

              <div className="flex justify-end">
                <button
                  type="button"
                  onClick={handleForgotPassword}
                  className="text-sm text-primary hover:text-primary/80 font-medium transition-colors"
                >
                  Forgot Password?
                </button>
              </div>

              <Button 
                type="submit" 
                className="w-full h-11 bg-primary hover:bg-primary/90 text-primary-foreground font-semibold tracking-wide transition-all shadow-md"
                disabled={loading}
              >
                {loading ? (
                  <Loader2 className="w-5 h-5 animate-spin" />
                ) : (
                  "Authenticate"
                )}
              </Button>
            </form>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  );
}
