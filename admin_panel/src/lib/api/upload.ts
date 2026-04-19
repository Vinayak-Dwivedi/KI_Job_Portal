import { ref, uploadBytesResumable, getDownloadURL } from "firebase/storage";
import { storage } from "../firebase";

export const uploadMediaFile = async (
  file: File,
  folder: "admin_posts" | "banners" | "profile_photos"
): Promise<{ url: string; type: "image" | "video" }> => {
  return new Promise((resolve, reject) => {
    try {
      const type = file.type.startsWith("video") ? "video" : "image";
      const extension = file.name.split('.').pop() || "png";
      const filePath = `${folder}/${Date.now()}_${Math.random().toString(36).substring(7)}.${extension}`;
      
      const storageRef = ref(storage, filePath);
      const uploadTask = uploadBytesResumable(storageRef, file);

      uploadTask.on(
        "state_changed",
        (_snapshot) => {
           // Optionally track progress here if needed
        },
        (error) => {
          console.error("Upload error:", error);
          reject(error);
        },
        async () => {
          const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);
          resolve({ url: downloadURL, type });
        }
      );
    } catch (error) {
      reject(error);
    }
  });
};
