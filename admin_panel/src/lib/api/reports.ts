import { collection, query, getDocs, limit, startAfter, doc, updateDoc, orderBy, QueryDocumentSnapshot } from "firebase/firestore";
import { db } from "../firebase";

export interface ReportData {
  id: string;
  postId: string;
  reporterId: string;
  reason: string;
  status: "pending" | "resolved" | "ignored";
  postContent?: string;
  postUid?: string;
  createdAt: any;
}

const PAGE_SIZE = 20;

export const fetchReports = async (lastDoc: QueryDocumentSnapshot | null = null) => {
  try {
    let q = query(collection(db, "reports"), orderBy("createdAt", "desc"), limit(PAGE_SIZE));

    if (lastDoc) {
      q = query(collection(db, "reports"), orderBy("createdAt", "desc"), startAfter(lastDoc), limit(PAGE_SIZE));
    }

    const snapshot = await getDocs(q);
    const reports: ReportData[] = [];

    snapshot.forEach((docSnap) => {
      reports.push({ id: docSnap.id, ...docSnap.data() } as ReportData);
    });

    const newLastDoc = snapshot.docs.length === PAGE_SIZE ? snapshot.docs[snapshot.docs.length - 1] : null;
    return { reports, lastDoc: newLastDoc };
  } catch (error) {
    console.error("Error fetching reports:", error);
    throw error;
  }
};

export const updateReportStatus = async (reportId: string, status: "resolved" | "ignored") => {
  try {
    await updateDoc(doc(db, "reports", reportId), { status });
    return true;
  } catch (error) {
    console.error("Error updating report:", error);
    throw error;
  }
};
