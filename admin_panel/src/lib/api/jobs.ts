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
  workerName?: string;
  price?: string;
  acceptedAt?: any;
  type?: "employer" | "worker";
}

const PAGE_SIZE = 20;

export const fetchJobs = async (lastDoc: QueryDocumentSnapshot | null = null, statusFilter?: string) => {
  try {
    const jobs: JobData[] = [];
    let currentLastDoc = lastDoc;
    let hasMore = true;

    while (jobs.length < PAGE_SIZE && hasMore) {
      let q = query(
        collection(db, "posts"),
        orderBy("createdAt", "desc"),
        limit(PAGE_SIZE * 3)
      );

      if (currentLastDoc) {
        q = query(
          collection(db, "posts"),
          orderBy("createdAt", "desc"),
          startAfter(currentLastDoc),
          limit(PAGE_SIZE * 3)
        );
      }

      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        hasMore = false;
        break;
      }

      for (const docSnap of snapshot.docs) {
        const data = docSnap.data();
        currentLastDoc = docSnap;

        const isJobPost = data.isJobPost === true;
        const isAvailabilityPost = data.isAvailabilityPost === true;

        if (!isJobPost && !isAvailabilityPost) continue;

        const status = data.hiringStatus || data.status || "open";
        if (statusFilter && statusFilter !== 'all' && status !== statusFilter) {
          continue;
        }

        let workerName = isAvailabilityPost ? (data.name || "Worker") : "No worker yet";
        let employerName = isAvailabilityPost ? "Looking for Employer" : (data.companyName || data.name || "Unknown Employer");
        let price = data.jobSalary || "Negotiable";
        let acceptedAt = null;

        if (isJobPost) {
          try {
            const appsSnap = await getDocs(collection(db, "posts", docSnap.id, "applications"));
            const acceptedApp = appsSnap.docs.find(d => d.data().status === 'accepted' || d.data().status === 'shortlisted');
            if (acceptedApp) {
              const appData = acceptedApp.data();
              workerName = appData.name || appData.contactName || "Unknown Worker";
              price = appData.proposedPrice || price;
              acceptedAt = appData.appliedAt || appData.acceptedAt;
            }
          } catch (e) {
            console.warn("Error fetching applications for job", docSnap.id);
          }
        }
        
        jobs.push({
          id: docSnap.id,
          title: data.jobTitle || data.title || "Untitled Job",
          description: data.text || data.description || "No description provided",
          location: data.location,
          postedBy: data.uid || "Unknown",
          employerName,
          status,
          isFeatured: data.isFeatured || false,
          createdAt: data.createdAt,
          workerName,
          price,
          acceptedAt,
          type: isAvailabilityPost ? "worker" : "employer"
        });

        if (jobs.length >= PAGE_SIZE) break;
      }

      if (snapshot.docs.length < PAGE_SIZE * 3) {
        hasMore = false;
      }
    }

    return { jobs, lastDoc: hasMore ? currentLastDoc : null };
  } catch (error) {
    console.error("Error fetching jobs:", error);
    throw error;
  }
};

export const updateJobStatus = async (jobId: string, data: Partial<JobData>) => {
  try {
    const jobRef = doc(db, "posts", jobId);
    await updateDoc(jobRef, data);
    return true;
  } catch (error) {
    console.error("Error updating job:", error);
    throw error;
  }
};

export const deleteJobPost = async (jobId: string) => {
  try {
    const jobRef = doc(db, "posts", jobId);
    await deleteDoc(jobRef);
    return true;
  } catch (error) {
    console.error("Error deleting job:", error);
    throw error;
  }
};
