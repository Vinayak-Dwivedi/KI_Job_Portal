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
    // Fetch everything from 'posts' for this user
    const postsQuery = query(
      collection(db, "posts"),
      where("uid", "==", uid)
    );
    const postsSnap = await getDocs(postsQuery);
    
    const allActivity = postsSnap.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        // Map 'text' to 'content' for the UI component if needed, 
        // but we'll handle it in the TSX for better clarity.
        displayContent: data.text || data.jobTitle || data.description || "No text content",
        type: data.isJobPost ? "Job Posting" : (data.isAvailabilityPost ? "Work Profile" : "Social Post")
      };
    }) as any[];
    
    allActivity.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));

    // Separate them for the tabs
    const posts = allActivity.filter(p => !p.isJobPost);
    const jobs = allActivity.filter(p => p.isJobPost);

    return { posts, jobs };
  } catch (error) {
    console.error("Error fetching user activity:", error);
    return { posts: [], jobs: [] };
  }
};
