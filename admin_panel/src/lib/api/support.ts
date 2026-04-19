import { collection, query, getDocs, limit, startAfter, doc, updateDoc, orderBy, QueryDocumentSnapshot, Timestamp, where } from "firebase/firestore";
import { db } from "../firebase";

export interface SupportTicket {
  id: string;
  uid: string;
  subject: string;
  message: string;
  status: "open" | "resolved" | "pending";
  response?: string;
  createdAt: any;
}

const PAGE_SIZE = 20;

export const fetchSupportTickets = async (lastDoc: QueryDocumentSnapshot | null = null, status?: string) => {
  try {
    let q = query(collection(db, "support"), orderBy("createdAt", "desc"), limit(PAGE_SIZE));
    
    if (status && status !== "all") {
      q = query(collection(db, "support"), where("status", "==", status), orderBy("createdAt", "desc"), limit(PAGE_SIZE));
    }

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const snapshot = await getDocs(q);
    const tickets: SupportTicket[] = [];
    
    snapshot.forEach((docSnap) => {
      tickets.push({ id: docSnap.id, ...docSnap.data() } as SupportTicket);
    });

    const newLastDoc = snapshot.docs.length === PAGE_SIZE ? snapshot.docs[snapshot.docs.length - 1] : null;
    return { tickets, lastDoc: newLastDoc };
  } catch (error) {
    console.error("Error fetching tickets:", error);
    throw error;
  }
};

export const resolveTicket = async (ticketId: string, response: string) => {
  try {
    await updateDoc(doc(db, "support", ticketId), {
      status: "resolved",
      response,
      resolvedAt: Timestamp.now()
    });
    return true;
  } catch (error) {
    console.error("Error resolving ticket:", error);
    throw error;
  }
};
