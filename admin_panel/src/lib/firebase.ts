import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyDzUSIslG1abco6dPwVbBqG12tSi-jWWWs",
  authDomain: "ki-job-portal.firebaseapp.com",
  projectId: "ki-job-portal",
  storageBucket: "ki-job-portal.firebasestorage.app",
  messagingSenderId: "197250239805",
  appId: "1:197250239805:web:cd8fddcfb664391944c954" // Derived from android app id
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const db = getFirestore(app);
export const auth = getAuth(app);
export const storage = getStorage(app);
