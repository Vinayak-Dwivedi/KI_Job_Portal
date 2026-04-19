import { collection, query, getDocs, getDoc, limit, startAfter, doc, updateDoc, deleteDoc, orderBy, QueryDocumentSnapshot } from "firebase/firestore";
import { db } from "../firebase";

export interface PostData {
  id: string;
  uid: string;
  name: string;
  text: string;
  role: string;
  imageUrl?: string;
  location?: string;
  isVerified?: boolean;
  isJobPost?: boolean;
  isAvailabilityPost?: boolean;
  isHidden?: boolean;
  likes?: number;
  comments?: number;
  createdAt?: any;
}

const PAGE_SIZE = 20;

export const fetchPosts = async (lastDoc: QueryDocumentSnapshot | null = null, filter?: "all" | "jobs" | "social") => {
  try {
    let q = query(collection(db, "posts"), orderBy("createdAt", "desc"), limit(PAGE_SIZE));
    
    if (lastDoc) {
      q = query(collection(db, "posts"), orderBy("createdAt", "desc"), startAfter(lastDoc), limit(PAGE_SIZE));
    }

    const snapshot = await getDocs(q);
    const posts: PostData[] = [];
    
    snapshot.forEach((docSnap) => {
      const data = docSnap.data();
      
      // Filter logic
      if (filter === "jobs" && !data.isJobPost) return;
      if (filter === "social" && (data.isJobPost || data.isAvailabilityPost)) return;

      posts.push({
        id: docSnap.id,
        uid: data.uid || "Unknown",
        name: data.name || "Unknown User",
        text: data.text || "",
        role: data.role || "user",
        imageUrl: data.imageUrl,
        location: data.location || "",
        isVerified: data.isVerified || false,
        isJobPost: data.isJobPost || false,
        isAvailabilityPost: data.isAvailabilityPost || false,
        isHidden: data.isHidden || false,
        likes: data.likes || 0,
        comments: data.comments || 0,
        createdAt: data.createdAt,
      });
    });

    const newLastDoc = snapshot.docs.length === PAGE_SIZE ? snapshot.docs[snapshot.docs.length - 1] : null;

    return { posts, lastDoc: newLastDoc };
  } catch (error) {
    console.error("Error fetching posts:", error);
    throw error;
  }
};

export const fetchPostById = async (postId: string): Promise<PostData | null> => {
  try {
    const docSnap = await getDoc(doc(db, "posts", postId));
    if (docSnap.exists()) {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        uid: data.uid || "Unknown",
        name: data.name || "Unknown User",
        text: data.text || "",
        role: data.role || "user",
        imageUrl: data.imageUrl,
        location: data.location || "",
        isVerified: data.isVerified || false,
        isJobPost: data.isJobPost || false,
        isAvailabilityPost: data.isAvailabilityPost || false,
        isHidden: data.isHidden || false,
        likes: data.likes || 0,
        comments: data.comments || 0,
        createdAt: data.createdAt,
      };
    }
    return null;
  } catch(e) {
    console.error("Error fetching single post:", e);
    return null;
  }
}


import { createPersonalNotification } from "./users";

export const updatePostStatus = async (postId: string, data: Partial<PostData>, ownerUid?: string) => {
  try {
    const postRef = doc(db, "posts", postId);
    await updateDoc(postRef, data);

    if (ownerUid) {
      if (data.isHidden === false) {
        await createPersonalNotification(
          ownerUid,
          "Post Approved ✅",
          "Your community post has been reviewed and is now live for everyone to see!",
          "success"
        );
      } else if (data.isHidden === true) {
         await createPersonalNotification(
          ownerUid,
          "Post Hidden 👁️",
          "One of your posts has been hidden by the moderator. Please review our community guidelines.",
          "warning"
        );
      }
    }
    return true;
  } catch (error) {
    console.error("Error updating post:", error);
    throw error;
  }
};

export const deletePostPermanently = async (postId: string, ownerUid?: string) => {
  try {
    const postRef = doc(db, "posts", postId);
    await deleteDoc(postRef);
    
    if (ownerUid) {
      await createPersonalNotification(
        ownerUid,
        "Post Removed 🗑️",
        "Your post was removed by the administrator for violating community guidelines.",
        "error"
      );
    }
    return true;
  } catch (error) {
    console.error("Error deleting post:", error);
    throw error;
  }
};
