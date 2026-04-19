import { collection, query, getDocs, limit, startAfter, doc, updateDoc, QueryDocumentSnapshot, Timestamp } from "firebase/firestore";
import { db } from "../firebase";

export interface SubscriptionData {
  id: string; // userId
  name?: string;
  email?: string;
  currentTier: string;
  validUntil: any;
  maxApplicationsPerDay: number;
  usedApplicationsToday: number;
}

const PAGE_SIZE = 20;

export const fetchAllSubscriptions = async (lastDoc: QueryDocumentSnapshot | null = null) => {
  try {
    let q = query(collection(db, "subscriptions"), limit(PAGE_SIZE));
    
    if (lastDoc) {
      q = query(collection(db, "subscriptions"), startAfter(lastDoc), limit(PAGE_SIZE));
    }

    const snapshot = await getDocs(q);
    const subscriptions: any[] = [];
    
    // We need to join with users to get names/emails for the admin view
    for (const docSnap of snapshot.docs) {
      subscriptions.push({
        id: docSnap.id,
        ...docSnap.data()
      });
    }

    const newLastDoc = snapshot.docs.length === PAGE_SIZE ? snapshot.docs[snapshot.docs.length - 1] : null;

    return { subscriptions, lastDoc: newLastDoc };
  } catch (error) {
    console.error("Error fetching subscriptions:", error);
    throw error;
  }
};

export const updateUserSubscriptionTier = async (uid: string, tier: string, days: number = 30) => {
  try {
    const expiry = new Date();
    expiry.setDate(expiry.getDate() + days);
    
    const subRef = doc(db, "subscriptions", uid);
    await updateDoc(subRef, {
      currentTier: tier,
      validUntil: Timestamp.fromDate(expiry),
      usedApplicationsToday: 0
    });

    // Also sync to users collection
    const userRef = doc(db, "users", uid);
    await updateDoc(userRef, {
      subscriptionTier: tier,
      subscriptionValidUntil: Timestamp.fromDate(expiry)
    });

    return true;
  } catch (error) {
    console.error("Error updating user subscription:", error);
    throw error;
  }
};
