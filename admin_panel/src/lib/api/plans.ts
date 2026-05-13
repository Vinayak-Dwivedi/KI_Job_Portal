import { collection, getDocs, doc, setDoc, deleteDoc, query, orderBy } from "firebase/firestore";
import { db } from "../firebase";

export interface SubscriptionPlan {
  id: string;
  name: string;
  price: number;
  durationDays: number;
  credits: number;
  maxApplicationsPerDay: number;
  features: string[];
  color: string;
  isPopular: boolean;
  description: string;
}

const PLANS_COLLECTION = "subscription_plans";

export const fetchAllPlans = async (): Promise<SubscriptionPlan[]> => {
  try {
    const q = query(collection(db, PLANS_COLLECTION), orderBy("price", "asc"));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as SubscriptionPlan));
  } catch (error) {
    console.error("Error fetching plans:", error);
    throw error;
  }
};

export const createOrUpdatePlan = async (plan: Partial<SubscriptionPlan> & { id: string }) => {
  try {
    const { id, ...data } = plan;
    await setDoc(doc(db, PLANS_COLLECTION, id), data, { merge: true });
    return true;
  } catch (error) {
    console.error("Error saving plan:", error);
    throw error;
  }
};

export const deletePlan = async (id: string) => {
  try {
    await deleteDoc(doc(db, PLANS_COLLECTION, id));
    return true;
  } catch (error) {
    console.error("Error deleting plan:", error);
    throw error;
  }
};

export const seedDefaultPlans = async () => {
  const defaults: SubscriptionPlan[] = [
    {
      id: "pro",
      name: "Pro Plan",
      price: 299,
      durationDays: 30,
      credits: 150,
      maxApplicationsPerDay: 10,
      features: [
        "Unlimited Job Applications",
        "Priority Profile Listing",
        "Contact Employers Directly",
        "No Ads"
      ],
      color: "#1D4ED8",
      isPopular: true,
      description: "Ideal for active job seekers looking for consistent opportunities."
    },
    {
      id: "elite",
      name: "Elite Plan",
      price: 799,
      durationDays: 90,
      credits: 500,
      maxApplicationsPerDay: 999,
      features: [
        "Everything in Pro",
        "Dedicated Account Manager",
        "Featured Badge on Profile",
        "Resume Feedback"
      ],
      color: "#0F172A",
      isPopular: false,
      description: "The ultimate package for professionals who want the best exposure."
    }
  ];

  for (const plan of defaults) {
    await createOrUpdatePlan(plan);
  }
};
