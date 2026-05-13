import { collection, addDoc, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";

export interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  type: "general" | "job" | "application" | "chat" | "credit" | "subscription" | "verification";
}

/**
 * Sends a notification to a specific user by writing to their
 * Firestore notifications subcollection.
 */
export const sendNotification = async (payload: NotificationPayload) => {
  try {
    await addDoc(collection(db, "users", payload.userId, "notifications"), {
      title: payload.title,
      body: payload.body,
      type: payload.type,
      isRead: false,
      createdAt: serverTimestamp(),
    });
  } catch (error) {
    console.error("Error sending notification:", error);
  }
};

/**
 * Sends a notification to multiple users at once (e.g., broadcast).
 */
export const sendBulkNotifications = async (
  userIds: string[],
  title: string,
  body: string,
  type: NotificationPayload["type"] = "general"
) => {
  const promises = userIds.map((userId) =>
    sendNotification({ userId, title, body, type })
  );
  await Promise.all(promises);
};
