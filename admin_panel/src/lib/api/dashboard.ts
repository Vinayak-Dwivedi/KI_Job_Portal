import { collection, getCountFromServer, query, where, getDocs, orderBy, Timestamp } from "firebase/firestore";
import { db } from "../firebase";

export interface DashboardStats {
  totalUsers: number;
  totalWorkers: number;
  totalEmployers: number;
  totalSubscribers: number;
  userGrowth: { 
    name: string; 
    users: number; 
    workers: number; 
    employers: number; 
    subscribers: number; 
  }[];
}

export const fetchDashboardStats = async (): Promise<DashboardStats> => {
  try {
    const usersSnap = await getCountFromServer(collection(db, "users"));
    const workersSnap = await getCountFromServer(query(collection(db, "users"), where("role", "==", "worker")));
    const employersSnap = await getCountFromServer(query(collection(db, "users"), where("role", "==", "employer")));
    const subscribersSnap = await getCountFromServer(collection(db, "subscriptions"));
    
    // Fetch users from the last 6 months for growth data
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    
    const growthQuery = query(
      collection(db, "users"),
      where("createdAt", ">=", Timestamp.fromDate(sixMonthsAgo)),
      orderBy("createdAt", "asc")
    );
    
    const growthDocs = await getDocs(growthQuery);
    
    // Initialize monthly buckets
    const months = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date();
      d.setMonth(d.getMonth() - i);
      months.push(d.toLocaleString('default', { month: 'short' }));
    }

    const growthMap = months.reduce((acc, month) => {
      acc[month] = { name: month, users: 0, workers: 0, employers: 0, subscribers: 0 };
      return acc;
    }, {} as Record<string, any>);

    // Aggregate monthly data
    growthDocs.forEach(doc => {
      const data = doc.data();
      const createdAt = data.createdAt?.toDate ? data.createdAt.toDate() : null;
      if (createdAt) {
        const monthName = createdAt.toLocaleString('default', { month: 'short' });
        if (growthMap[monthName]) {
          growthMap[monthName].users++;
          if (data.role === "worker") growthMap[monthName].workers++;
          if (data.role === "employer") growthMap[monthName].employers++;
          if (data.subscriptionTier && data.subscriptionTier !== "free") growthMap[monthName].subscribers++;
        }
      }
    });

    const userGrowth = months.map(m => growthMap[m]);

    return {
      totalUsers: usersSnap.data().count,
      totalWorkers: workersSnap.data().count,
      totalEmployers: employersSnap.data().count,
      totalSubscribers: subscribersSnap.data().count,
      userGrowth
    };
  } catch (error) {
    console.error("Error fetching dashboard stats:", error);
    throw error;
  }
};

export interface ComprehensiveUserData {
  id: string;
  name: string;
  email: string;
  role: string;
  credits: number;
  joinDate: string;
  postsCount: number;
  activeWork: string[]; // Names of people hired or hired by
}

export const exportComprehensiveAnalytics = async (): Promise<ComprehensiveUserData[]> => {
  try {
    // Fetch all users
    const usersSnap = await getDocs(query(collection(db, "users"), orderBy("createdAt", "desc")));
    // Fetch all posts
    const postsSnap = await getDocs(collection(db, "posts"));
    // Fetch all applications
    const appsSnap = await getDocs(collection(db, "applications"));

    // Pre-process posts count per user
    const postsCountByUid: Record<string, number> = {};
    postsSnap.forEach(postDoc => {
      const { uid } = postDoc.data();
      if (uid) {
        postsCountByUid[uid] = (postsCountByUid[uid] || 0) + 1;
      }
    });

    // Extract raw users
    const usersData = usersSnap.docs.map(doc => {
      const d = doc.data();
      return {
         id: doc.id,
         name: d.name || d.fullName || "Unknown",
         email: d.email || "No Email",
         role: d.role || "user",
         credits: d.credits || 0,
         createdAt: d.createdAt?.toDate ? d.createdAt.toDate().toLocaleDateString() : 'N/A'
      };
    });

    // Create user name map for resolving connections
    const userMap: Record<string, string> = {};
    usersData.forEach(u => { userMap[u.id] = u.name; });

    // Identify active work relationships: Applications are between Worker and Employer
    // We map Worker => Hired by [EmployerNames]
    // We map Employer => Hired [WorkerNames]
    const connectionsByUid: Record<string, Set<string>> = {};
    
    appsSnap.forEach(appDoc => {
      const data = appDoc.data();
      const workerId = data.workerId;
      const employerId = data.employerId;

      if (workerId && employerId) {
        // Map Employer
        if (!connectionsByUid[employerId]) connectionsByUid[employerId] = new Set();
        connectionsByUid[employerId].add(userMap[workerId] || "Unknown Worker");

        // Map Worker
        if (!connectionsByUid[workerId]) connectionsByUid[workerId] = new Set();
        connectionsByUid[workerId].add(userMap[employerId] || "Unknown Employer");
      }
    });

    // Combine everything
    return usersData.map(u => ({
      id: u.id,
      name: u.name,
      email: u.email,
      role: u.role,
      credits: u.credits,
      joinDate: u.createdAt,
      postsCount: postsCountByUid[u.id] || 0,
      activeWork: connectionsByUid[u.id] ? Array.from(connectionsByUid[u.id]) : []
    }));

  } catch (error) {
    console.error("Error compiling comprehensive export analytics:", error);
    throw error;
  }
};
