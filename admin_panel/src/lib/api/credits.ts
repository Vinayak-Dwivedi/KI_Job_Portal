import { collection, query, getDocs, doc, setDoc, deleteDoc, orderBy } from "firebase/firestore";
import { db } from "../firebase";

export interface CreditBundle {
  id: string;
  name: string;
  credits: number;
  price: number;
  description?: string;
  isActive: boolean;
}

export const fetchCreditBundles = async () => {
  const q = query(collection(db, "credit_bundles"), orderBy("price", "asc"));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as CreditBundle));
};

export const createOrUpdateBundle = async (bundle: CreditBundle) => {
  const id = bundle.id || `bundle_${Date.now()}`;
  await setDoc(doc(db, "credit_bundles", id), { ...bundle, id }, { merge: true });
  return true;
};

export const deleteBundle = async (id: string) => {
  await deleteDoc(doc(db, "credit_bundles", id));
  return true;
};
