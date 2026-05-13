import { collection, query, getDocs, orderBy, limit, doc, getDoc } from "firebase/firestore";
import { db } from "../firebase";

export interface ReferralStat {
  id: string;
  referrerUid: string;
  referrerName: string;
  referredUid: string;
  referredName: string;
  bonusAmount: number;
  status: 'pending' | 'paid' | 'expired';
  timestamp: any;
}

export const fetchReferralHistory = async () => {
  const q = query(collection(db, "referrals"), orderBy("timestamp", "desc"), limit(50));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as ReferralStat));
};

export const fetchReferralSettings = async () => {
  const snap = await getDoc(doc(db, "settings", "referrals"));
  if (snap.exists()) return snap.data();
  return { bonusPerReferral: 100, isActive: true };
};
