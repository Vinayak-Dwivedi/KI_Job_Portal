import { collection, addDoc, query, getDocs, orderBy, limit, Timestamp, where, doc, getDoc, setDoc } from "firebase/firestore";
import { db } from "../firebase";

export interface AnnouncementData {
  id?: string;
  title: string;
  message: string;
  target?: "all" | "workers" | "employers";
  createdAt?: any;
}

export interface BannerData {
  id?: string;
  imageUrl: string;
  headline?: string;
  subhead?: string;
  isActive: boolean;
  updatedAt?: any;
}

export const broadcastAnnouncement = async (data: AnnouncementData) => {
  try {
    const announcement = {
      ...data,
      createdAt: Timestamp.now()
    };
    await addDoc(collection(db, "announcements"), announcement);
    return true;
  } catch (error) {
    console.error("Error broadcasting announcement:", error);
    throw error;
  }
};

export const createAdminFeedPost = async (text: string, mediaData?: { url: string; type: "image" | "video" }) => {
  try {
    // 1. Create the Feed Post
    const postData: any = {
      text,
      uid: "admin_system",
      name: "KI GLOBAL ADMIN",
      role: "admin",
      isAdmin: true,
      isJobPost: false,
      likes: 0,
      comments: 0,
      createdAt: Timestamp.now(),
      profilePhotoUrl: "" // System default
    };

    if (mediaData) {
      if (mediaData.type === 'image') {
        postData.imageUrl = mediaData.url;
        postData.media = [mediaData];
      } else {
        postData.media = [mediaData];
      }
    }

    const postRef = await addDoc(collection(db, "posts"), postData);

    // 2. Trigger a System Announcement (this will show up as a notification in the mobile app)
    await addDoc(collection(db, "announcements"), {
      title: "New Official Update",
      message: text.length > 100 ? text.substring(0, 100) + "..." : text,
      target: "all",
      postId: postRef.id,
      type: "admin_post",
      createdAt: Timestamp.now()
    });

    return true;
  } catch (error) {
    console.error("Error creating admin feed post:", error);
    throw error;
  }
};

export const fetchRecentAnnouncements = async () => {
  try {
    const q = query(collection(db, "announcements"), orderBy("createdAt", "desc"), limit(20));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error("Error fetching announcements:", error);
    throw error;
  }
};

export const fetchAdminFeedPosts = async () => {
  try {
    const q = query(
      collection(db, "posts"), 
      where("isAdmin", "==", true),
      orderBy("createdAt", "desc"),
      limit(20)
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error("Error fetching admin posts:", error);
    // If indexing fails, we fallback to client side filtering
    const q = query(collection(db, "posts"), orderBy("createdAt", "desc"), limit(50));
    const snapshot = await getDocs(q);
    return snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter((p: any) => p.isAdmin === true);
  }
};

export const fetchActiveBanner = async (): Promise<BannerData | null> => {
  try {
    const docRef = doc(db, "system_config", "active_banner");
    const docSnap = await getDoc(docRef);
    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as BannerData;
    }
    return null;
  } catch (error) {
    console.error("Error fetching active banner:", error);
    return null;
  }
};

export const updateActiveBanner = async (data: Partial<BannerData>) => {
  try {
    await setDoc(doc(db, "system_config", "active_banner"), {
      ...data,
      isActive: true,
      updatedAt: Timestamp.now()
    }, { merge: true });
    return true;
  } catch (error) {
    console.error("Error updating banner:", error);
    throw error;
  }
};

