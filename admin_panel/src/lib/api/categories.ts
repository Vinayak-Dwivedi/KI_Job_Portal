import { collection, getDocs, doc, deleteDoc, updateDoc, Timestamp, addDoc } from "firebase/firestore";
import { db } from "../firebase";

export interface Category {
  id: string;
  name: string;
  isActive: boolean;
}

export const fetchCategories = async () => {
  try {
    const snapshot = await getDocs(collection(db, "job_categories"));
    return snapshot.docs.map(docSnap => ({
      id: docSnap.id,
      ...docSnap.data()
    })) as Category[];
  } catch (error) {
    console.error("Error fetching categories:", error);
    throw error;
  }
};

export const addCategory = async (name: string) => {
  try {
    const docRef = await addDoc(collection(db, "job_categories"), {
      name,
      isActive: true,
      createdAt: Timestamp.now()
    });
    return { id: docRef.id, name, isActive: true };
  } catch (error) {
    console.error("Error adding category:", error);
    throw error;
  }
};

export const updateCategory = async (id: string, data: Partial<Category>) => {
  try {
    await updateDoc(doc(db, "job_categories", id), data);
    return true;
  } catch (error) {
    console.error("Error updating category:", error);
    throw error;
  }
};

export const deleteCategory = async (id: string) => {
  try {
    await deleteDoc(doc(db, "job_categories", id));
    return true;
  } catch (error) {
    console.error("Error deleting category:", error);
    throw error;
  }
};
