import { doc, getDoc, collection, query, where, getDocs } from "firebase/firestore";
import { db } from "../firebase";
import type { UserData } from "./users";

export interface UserActivity {
  posts: any[];
  jobs: any[];
}

export const fetchUserDetail = async (uid: string): Promise<UserData | null> => {
  try {
    const userDoc = await getDoc(doc(db, "users", uid));
    if (!userDoc.exists()) return null;
    
    const data = userDoc.data();
    return {
      id: userDoc.id,
      name: data.name || data.fullName || "Unknown User",
      email: data.email || "No Email",
      phone: data.phone || "No Phone",
      role: data.role || "user",
      isVerified: data.isVerified || false,
      isBlocked: data.isBlocked || false,
      credits: data.credits || 0,
      createdAt: data.createdAt,
      ...data // preserve extra fields like bio, company, etc.
    } as UserData;
  } catch (error) {
    console.error("Error fetching user detail:", error);
    throw error;
  }
};

export const fetchUserActivity = async (uid: string): Promise<UserActivity> => {
  try {
    // Fetch Posts - removed orderBy to avoid index requirement
    const postsQuery = query(
      collection(db, "posts"),
      where("uid", "==", uid)
    );
    const postsSnap = await getDocs(postsQuery);
    const posts = postsSnap.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .sort((a: any, b: any) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));

    // Fetch Jobs (if Employer) - removed orderBy to avoid index requirement
    const jobsQuery = query(
      collection(db, "jobs"),
      where("uid", "==", uid)
    );
    const jobsSnap = await getDocs(jobsQuery);
    const jobs = jobsSnap.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .sort((a: any, b: any) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));

    return { posts, jobs };
  } catch (error) {
    console.error("Error fetching user activity:", error);
    return { posts: [], jobs: [] };
  }
};
