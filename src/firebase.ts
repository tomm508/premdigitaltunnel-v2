import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  projectId: "premdigital-vpn",
  apiKey: "AIzaSyCBKAcHs0TldS7_Ia78Mig3TR8tJMbt0jw",
  authDomain: "premdigital-vpn.firebaseapp.com"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
