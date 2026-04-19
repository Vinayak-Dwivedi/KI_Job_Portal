import { createContext, useContext, useEffect, useState } from "react";
import { onAuthStateChanged, signOut, type User } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";

interface AdminUser {
  uid: string;
  email: string | null;
  role: string;
  name?: string;
  profilePhotoUrl?: string;
}

interface AuthContextType {
  user: AdminUser | null;
  loading: boolean;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  logout: async () => {},
  refreshUser: async () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchUserData = async (uid: string, email: string | null) => {
    try {
      const userDocRef = doc(db, "users", uid);
      const userDocSnap = await getDoc(userDocRef);

      if (userDocSnap.exists()) {
        const userData = userDocSnap.data();

        if (userData.role === "admin") {
          setUser({
            uid: uid,
            email: email,
            role: userData.role,
            name: userData.name || userData.fullName,
            profilePhotoUrl: userData.profilePhotoUrl,
          });
          return true;
        } else {
          console.warn("Access denied. User is not an admin.");
          await signOut(auth);
          setUser(null);
          return false;
        }
      } else {
        console.warn("User document does not exist.");
        await signOut(auth);
        setUser(null);
        return false;
      }
    } catch (error) {
      console.error("Error fetching user data:", error);
      await signOut(auth);
      setUser(null);
      return false;
    }
  };

  const refreshUser = async () => {
    if (auth.currentUser) {
      await fetchUserData(auth.currentUser.uid, auth.currentUser.email);
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser: User | null) => {
      if (firebaseUser) {
        setLoading(true);
        await fetchUserData(firebaseUser.uid, firebaseUser.email);
      } else {
        setUser(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const logout = async () => {
    await signOut(auth);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
