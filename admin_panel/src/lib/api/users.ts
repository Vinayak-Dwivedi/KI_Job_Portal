import { collection, query, getDocs, limit, startAfter, doc, updateDoc, orderBy, QueryDocumentSnapshot, addDoc, Timestamp } from "firebase/firestore";
import { db } from "../firebase";

export interface UserData {
  id: string;
  name?: string;
  fullName?: string;
  email: string;
  phone?: string;
  role: string;
  isVerified?: boolean;
  isBlocked?: boolean;
  credits?: number;
  profilePhotoUrl?: string;
  createdAt?: any;
}

const PAGE_SIZE = 20;

export const createPersonalNotification = async (targetUid: string, title: string, message: string, type: string = "info") => {
  try {
    await addDoc(collection(db, "announcements"), {
      title,
      message,
      targetUid,
      type,
      createdAt: Timestamp.now(),
    });
    return true;
  } catch (error) {
    console.error("Error creating personal notification:", error);
    return false;
  }
};

export const fetchUsers = async (lastDoc: QueryDocumentSnapshot | null = null, roleFilter?: string) => {
  try {
    let q = query(collection(db, "users"), orderBy("createdAt", "desc"), limit(PAGE_SIZE));
    
    // We keep it simple since complex filtering + pagination in Firestore requires composite indexes
    if (lastDoc) {
      q = query(collection(db, "users"), orderBy("createdAt", "desc"), startAfter(lastDoc), limit(PAGE_SIZE));
    }

    const snapshot = await getDocs(q);
    const users: UserData[] = [];
    
    snapshot.forEach((docSnap) => {
      const data = docSnap.data();
      
      // Client side filtering for simplicity if roleFilter exists 
      // (Proper way is firestore where('role', '==', roleFilter) but requires indexing with orderBy)
      if (roleFilter && roleFilter !== 'all' && data.role !== roleFilter) {
        return;
      }
      
      users.push({
        id: docSnap.id,
        name: data.name || data.fullName || "Unknown User",
        email: data.email || "No Email",
        phone: data.phone || "No Phone",
        role: data.role || "user",
        isVerified: data.isVerified || false,
        isBlocked: data.isBlocked || false,
        credits: data.credits || 0,
        createdAt: data.createdAt,
      });
    });

    const newLastDoc = snapshot.docs.length === PAGE_SIZE ? snapshot.docs[snapshot.docs.length - 1] : null;

    return { users, lastDoc: newLastDoc };
  } catch (error) {
    console.error("Error fetching users:", error);
    throw error;
  }
};

export const updateUserStatus = async (userId: string, data: Partial<UserData>) => {
  try {
    const userRef = doc(db, "users", userId);
    await updateDoc(userRef, data);

    // If verification status changed to true, notify the user
    if (data.isVerified === true) {
      await createPersonalNotification(
        userId,
        "Profile Verified 🛡️",
        "Congrats! Your profile has been verified by the admin. You now have full access to premium features.",
        "success"
      );
    }

    return true;
  } catch (error) {
    console.error("Error updating user:", error);
    throw error;
  }
};

export const registerAdminAccount = async (data: { name: string, email: string, phone: string }) => {
  try {
    await addDoc(collection(db, "users"), {
      ...data,
      role: "admin",
      isVerified: true,
      isBlocked: false,
      credits: 9999,
      createdAt: Timestamp.now(),
    });
    return true;
  } catch (error) {
    console.error("Error registering admin:", error);
    throw error;
  }
};

export const fetchActiveWorkConnections = async () => {
  try {
    const appsSnap = await getDocs(collection(db, "applications"));
    const usersSnap = await getDocs(collection(db, "users"));
    
    const userMap: Record<string, string> = {};
    usersSnap.forEach(doc => {
      const data = doc.data();
      userMap[doc.id] = data.name || data.fullName || "Unknown";
    });

    const connectionsByUid: Record<string, Set<string>> = {};
    
    appsSnap.forEach(appDoc => {
      const data = appDoc.data();
      const workerId = data.workerId;
      const employerId = data.employerId;

      if (workerId && employerId) {
        if (!connectionsByUid[employerId]) connectionsByUid[employerId] = new Set();
        connectionsByUid[employerId].add(userMap[workerId] || "Unknown Worker");

        if (!connectionsByUid[workerId]) connectionsByUid[workerId] = new Set();
        connectionsByUid[workerId].add(userMap[employerId] || "Unknown Employer");
      }
    });

    const result: Record<string, string[]> = {};
    Object.keys(connectionsByUid).forEach(k => {
       result[k] = Array.from(connectionsByUid[k]);
    });
    
    return result;
  } catch (error) {
    console.error("Error fetching connections:", error);
    return {};
  }
};
