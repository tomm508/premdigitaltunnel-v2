import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "premdigital-vpn",
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "",
  authDomain: (import.meta.env.VITE_FIREBASE_PROJECT_ID || "premdigital-vpn") + ".firebaseapp.com"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
