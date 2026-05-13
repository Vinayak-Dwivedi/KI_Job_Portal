import { collection, query, getDocs, doc, setDoc, deleteDoc, orderBy, Timestamp } from "firebase/firestore";
import { db } from "../firebase";

export interface Coupon {
  id: string;
  code: string;
  discountPercent: number;
  expiryDate: any;
  maxUses: number;
  usedCount: number;
  isActive: boolean;
  description?: string;
}

export const fetchAllCoupons = async () => {
  const q = query(collection(db, "coupons"), orderBy("code", "asc"));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as Coupon));
};

export const createOrUpdateCoupon = async (coupon: Coupon) => {
  const couponRef = doc(db, "coupons", coupon.id || coupon.code.toUpperCase());
  const data = {
    ...coupon,
    code: coupon.code.toUpperCase(),
    expiryDate: coupon.expiryDate instanceof Date ? Timestamp.fromDate(coupon.expiryDate) : coupon.expiryDate
  };
  await setDoc(couponRef, data, { merge: true });
  return true;
};

export const deleteCoupon = async (id: string) => {
  await deleteDoc(doc(db, "coupons", id));
  return true;
};
