import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyDZkdVo7SzUsCEuiHaNLz15wLmCsceB7fQ",
  authDomain: "chatapp-654b1.firebaseapp.com",
  projectId: "chatapp-654b1",
  storageBucket: "chatapp-654b1.appspot.com", // ✅ Corrected
  messagingSenderId: "372360592503",
  appId: "1:372360592503:web:a3b976f34872becfb5da72",
};

// Check if Firebase is already initialized
const app = initializeApp(firebaseConfig);

export const auth = getAuth();
export const db = getFirestore();
export const storage = getStorage();
