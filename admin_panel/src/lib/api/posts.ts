import { collection, query, where, getDocs, getDoc, limit, startAfter, doc, updateDoc, deleteDoc, orderBy, QueryDocumentSnapshot } from "firebase/firestore";
import { db } from "../firebase";

export interface PostData {
  id: string;
  uid: string;
  name: string;
  text: string;
  role: string;
  imageUrl?: string;
  media?: { url: string; type: string }[];
  location?: string;
  isVerified?: boolean;
  isJobPost?: boolean;
  isAvailabilityPost?: boolean;
  isHidden?: boolean;
  likes?: number;
  comments?: number;
  createdAt?: any;
  status?: 'pending' | 'approved' | 'rejected';
  jobTitle?: string;
  jobSalary?: string;
  jobExperience?: string;
  jobSkills?: string;
  companyName?: string;
  eventDate?: any;
  eventTime?: string;
  eventLocation?: string;
  eventTitle?: string;
  profilePhotoUrl?: string;
  hasPendingEdit?: boolean;
  pendingEdit?: Partial<PostData> & { submittedAt?: any };
}

const PAGE_SIZE = 20;

export const fetchPosts = async (
  lastDoc: QueryDocumentSnapshot | null = null, 
  filter?: "all" | "jobs" | "social",
  status?: "all" | "pending" | "approved" | "rejected",
  startDate?: Date,
  endDate?: Date
) => {
  try {
    let q = query(collection(db, "posts"), orderBy("createdAt", "desc"), limit(PAGE_SIZE));
    
    if (startDate) {
      q = query(q, where("createdAt", ">=", startDate));
    }
    if (endDate) {
      q = query(q, where("createdAt", "<=", endDate));
    }

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const snapshot = await getDocs(q);
    const posts: PostData[] = [];
    
    snapshot.forEach((docSnap) => {
      const data = docSnap.data();
      
      if (filter === "jobs" && !data.isJobPost) return;
      if (filter === "social" && (data.isJobPost || data.isAvailabilityPost)) return;
      // Don't filter out hasPendingEdit posts when status filter is 'pending' or 'all'
      if (status && status !== "all" && data.status !== status) {
        // Still show hasPendingEdit posts under 'pending' filter
        if (!(status === "pending" && data.hasPendingEdit === true)) return;
      }

      posts.push({
        id: docSnap.id,
        uid: data.uid || "Unknown",
        name: data.name || "Unknown User",
        text: data.text || "",
        role: data.role || "user",
        imageUrl: data.imageUrl,
        media: data.media,
        location: data.location || "",
        isVerified: data.isVerified || false,
        isJobPost: data.isJobPost || false,
        isAvailabilityPost: data.isAvailabilityPost || false,
        isHidden: data.isHidden || false,
        likes: data.likes || 0,
        comments: data.comments || 0,
        createdAt: data.createdAt,
        status: data.status || 'approved',
        jobTitle: data.jobTitle,
        jobSalary: data.jobSalary,
        jobExperience: data.jobExperience,
        jobSkills: data.jobSkills,
        companyName: data.companyName,
        eventDate: data.eventDate,
        eventTime: data.eventTime,
        eventLocation: data.eventLocation,
        eventTitle: data.eventTitle,
        profilePhotoUrl: data.profilePhotoUrl,
        hasPendingEdit: data.hasPendingEdit || false,
        pendingEdit: data.pendingEdit || null,
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
    const postSnap = await getDoc(postRef);
    let postTextSnippet = "your post";
    if (postSnap.exists() && postSnap.data().text) {
      postTextSnippet = `"${postSnap.data().text.substring(0, 30)}..."`;
    }

    await updateDoc(postRef, data);

    if (ownerUid) {
      if (data.status === 'approved') {
        await createPersonalNotification(
          ownerUid,
          "Post Approved ✅",
          `Your community post ${postTextSnippet} has been reviewed and is now live!`,
          "post_approved",
          { postId }
        );
      } else if (data.status === 'rejected') {
        await createPersonalNotification(
          ownerUid,
          "Post Rejected ❌",
          `Your post ${postTextSnippet} was rejected by the moderator. Please ensure it follows guidelines.`,
          "error",
          { postId }
        );
      }

      if (data.isHidden === false) {
        await createPersonalNotification(
          ownerUid,
          "Post Restored 👁️",
          `Your post ${postTextSnippet} is now visible again on the community feed.`,
          "success",
          { postId }
        );
      } else if (data.isHidden === true) {
         await createPersonalNotification(
          ownerUid,
          "Post Hidden 👁️",
          `Your post ${postTextSnippet} has been hidden by the moderator. Please review our guidelines.`,
          "warning",
          { postId }
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
    const postSnap = await getDoc(postRef);
    let postTextSnippet = "Your post";
    if (postSnap.exists() && postSnap.data().text) {
      postTextSnippet = `Your post "${postSnap.data().text.substring(0, 30)}..."`;
    }

    await deleteDoc(postRef);
    
    if (ownerUid) {
      await createPersonalNotification(
        ownerUid,
        "Post Removed 🗑️",
        `${postTextSnippet} was removed by the administrator for violating community guidelines.`,
        "error"
      );
    }
    return true;
  } catch (error) {
    console.error("Error deleting post:", error);
    throw error;
  }
};

export const approvePostEdit = async (postId: string, ownerUid?: string) => {
  try {
    const postRef = doc(db, "posts", postId);
    const postSnap = await getDoc(postRef);
    
    if (!postSnap.exists()) throw new Error("Post not found");
    
    const postData = postSnap.data();
    const pendingEdit = postData.pendingEdit;
    
    if (!pendingEdit) throw new Error("No pending edit found");
    
    // Merge pending edit into the root document
    // Remove metadata fields from pendingEdit if any
    const { submittedAt, ...editData } = pendingEdit;
    
    await updateDoc(postRef, {
      ...editData,
      pendingEdit: null,
      hasPendingEdit: false,
      updatedAt: new Date()
    });
    
    if (ownerUid) {
      const textSnippet = postData.text ? `"${postData.text.substring(0, 30)}..."` : "your post";
      await createPersonalNotification(
        ownerUid,
        "Edit Approved ✅",
        `Your changes to ${textSnippet} have been approved and are now live!`,
        "post_approved",
        { postId }
      );
    }
    return true;
  } catch (error) {
    console.error("Error approving post edit:", error);
    throw error;
  }
};

export const rejectPostEdit = async (postId: string, ownerUid?: string) => {
  try {
    const postRef = doc(db, "posts", postId);
    const postSnap = await getDoc(postRef);
    let postTextSnippet = "your post";
    if (postSnap.exists() && postSnap.data().text) {
      postTextSnippet = `"${postSnap.data().text.substring(0, 30)}..."`;
    }

    await updateDoc(postRef, {
      pendingEdit: null,
      hasPendingEdit: false
    });
    
    if (ownerUid) {
      await createPersonalNotification(
        ownerUid,
        "Edit Rejected ❌",
        `Your proposed changes to ${postTextSnippet} were rejected by the moderator.`,
        "error",
        { postId }
      );
    }
    return true;
  } catch (error) {
    console.error("Error rejecting post edit:", error);
    throw error;
  }
};
