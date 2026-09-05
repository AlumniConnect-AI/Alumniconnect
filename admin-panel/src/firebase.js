// Firebase Configuration for Admin Panel
// Project: alumniconnect-722b6

import { initializeApp } from "firebase/app";
import { getDatabase, ref, set, get, push, update, remove, onValue, off } from "firebase/database";
import { getAuth } from "firebase/auth";
import {
  getFirestore,
  collection,
  onSnapshot,
  query,
  where,
  doc,
  getDocs,
  getDoc,
  orderBy
} from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyAf8RZeUu1kwFA0jQXSxVpV-ZM3KOr6-6c",
  authDomain: "alumniconnect-722b6.firebaseapp.com",
  databaseURL: "https://alumniconnect-722b6-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "alumniconnect-722b6",
  storageBucket: "alumniconnect-722b6.firebasestorage.app",
  messagingSenderId: "169272546770",
  appId: "1:169272546770:ios:f8155b113e9ad5cdf3a40b"
};

const app = initializeApp(firebaseConfig);
const database = getDatabase(app);
const auth = getAuth(app);
const firestore = getFirestore(app);


export {
  database,
  auth,
  firestore,
  collection,
  onSnapshot,
  query,
  where,
  doc,
  getDocs,
  getDoc,
  orderBy,
  ref,
  set,
  get,
  push,
  update,
  remove,
  onValue,
  off
};
export default app;

