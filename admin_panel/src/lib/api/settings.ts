import { doc, getDoc, setDoc, Timestamp } from "firebase/firestore";
import { db } from "../firebase";

export interface SystemSettings {
  maintenanceMode: boolean;
  minAppVersion: string;
  freeCreditsThreshold: number;
  updatedAt?: any;
  proPrice?: string;
  elitePrice?: string;
}

export const fetchSystemSettings = async () => {
  try {
    const docRef = doc(db, "settings", "master_config");
    const docSnap = await getDoc(docRef);
    
    // Also fetch subscriptions
    const subRef = doc(db, "platform_settings", "subscriptions");
    const subSnap = await getDoc(subRef);
    const subData = subSnap.exists() ? subSnap.data() : {};

    if (docSnap.exists()) {
      return { ...(docSnap.data() as SystemSettings), ...subData };
    }
    // Default settings
    return {
      maintenanceMode: false,
      minAppVersion: "1.0.0",
      freeCreditsThreshold: 50,
      ...subData
    };
  } catch (error) {
    console.error("Error fetching settings:", error);
    throw error;
  }
};

export const updateSystemSettings = async (data: Partial<SystemSettings>) => {
  try {
    const { proPrice, elitePrice, ...masterData } = data;
    
    // Update master config
    const docRef = doc(db, "settings", "master_config");
    await setDoc(docRef, {
      ...masterData,
      updatedAt: Timestamp.now()
    }, { merge: true });

    // Update subscriptions if prices are provided
    if (proPrice !== undefined || elitePrice !== undefined) {
      const subRef = doc(db, "platform_settings", "subscriptions");
      await setDoc(subRef, {
        proPrice: proPrice || "₹299",
        elitePrice: elitePrice || "₹799",
        updatedAt: Timestamp.now()
      }, { merge: true });
    }

    return true;
  } catch (error) {
    console.error("Error updating settings:", error);
    throw error;
  }
};
