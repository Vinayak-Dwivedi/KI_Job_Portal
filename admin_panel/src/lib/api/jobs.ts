import { collection, query, getDocs, limit, startAfter, doc, updateDoc, deleteDoc, orderBy, QueryDocumentSnapshot } from "firebase/firestore";
import { db } from "../firebase";

export interface JobData {
  id: string;
  title: string;
  description: string;
  location?: string;
  postedBy: string;
  employerName?: string;
  status: "open" | "closed" | "filled";
  isFeatured?: boolean;
  createdAt?: any;
}

const PAGE_SIZE = 20;

export const fetchJobs = async (lastDoc: QueryDocumentSnapshot | null = null, statusFilter?: string) => {
  try {
    let q = query(collection(db, "jobs"), orderBy("createdAt", "desc"), limit(PAGE_SIZE));
    
    if (lastDoc) {
      q = query(collection(db, "jobs"), orderBy("createdAt", "desc"), startAfter(lastDoc), limit(PAGE_SIZE));
    }

    const snapshot = await getDocs(q);
    const jobs: JobData[] = [];
    
    snapshot.forEach((docSnap) => {
      const data = docSnap.data();
      
      if (statusFilter && statusFilter !== 'all' && data.status !== statusFilter) {
        return;
      }
      
      jobs.push({
        id: docSnap.id,
        title: data.title || "Untitled Job",
        description: data.description || "No description provided",
        location: data.location,
        postedBy: data.postedBy || "Unknown",
        employerName: data.employerName || "Unknown Employer",
        status: data.status || "open",
        isFeatured: data.isFeatured || false,
        createdAt: data.createdAt,
      });
    });

    const newLastDoc = snapshot.docs.length === PAGE_SIZE ? snapshot.docs[snapshot.docs.length - 1] : null;

    return { jobs, lastDoc: newLastDoc };
  } catch (error) {
    console.error("Error fetching jobs:", error);
    throw error;
  }
};

export const updateJobStatus = async (jobId: string, data: Partial<JobData>) => {
  try {
    const jobRef = doc(db, "jobs", jobId);
    await updateDoc(jobRef, data);
    return true;
  } catch (error) {
    console.error("Error updating job:", error);
    throw error;
  }
};

export const deleteJobPost = async (jobId: string) => {
  try {
    const jobRef = doc(db, "jobs", jobId);
    await deleteDoc(jobRef);
    return true;
  } catch (error) {
    console.error("Error deleting job:", error);
    throw error;
  }
};
