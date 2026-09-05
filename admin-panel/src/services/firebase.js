import { initializeApp } from "firebase/app";
import { getDatabase, ref, onValue, push, set, remove, update } from "firebase/database";
import { getFirestore, collection, onSnapshot } from "firebase/firestore";

// Firebase Configuration from GoogleService-Info.plist
const firebaseConfig = {
  apiKey: "AIzaSyAf8RZeUu1kwFA0jQXSxVpV-ZM3KOr6-6c",
  authDomain: "alumniconnect-722b6.firebaseapp.com",
  databaseURL: "https://alumniconnect-722b6-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "alumniconnect-722b6",
  storageBucket: "alumniconnect-722b6.firebasestorage.app",
  messagingSenderId: "169272546770",
  appId: "1:169272546770:ios:f8155b113e9ad5cdf3a40b"
};

// Initialize Firebase App
const app = initializeApp(firebaseConfig);

// Initialize Realtime Database & Cloud Firestore instances
export const rtdb = getDatabase(app);
export const db = getFirestore(app);

/**
 * Subscribe to Realtime Database path for live data updates
 * @param {string} path - Database node path (e.g. 'students', 'universities')
 * @param {function} callback - Receives array or object of real-time data
 */
export function subscribeToRealtimeData(path, callback) {
  const dbRef = ref(rtdb, path);
  return onValue(dbRef, (snapshot) => {
    if (snapshot.exists()) {
      const data = snapshot.val();
      const formattedList = Array.isArray(data) 
        ? data 
        : Object.keys(data).map(key => ({ id: key, ...data[key] }));
      callback(formattedList, true);
    } else {
      callback([], false);
    }
  }, (err) => {
    console.warn(`Realtime Database listener standby for path [${path}]:`, err.message);
    callback(null, false);
  });
}

/**
 * Subscribe to Firestore Collection for live real-time updates
 * @param {string} collectionName - Firestore collection name
 * @param {function} callback - Receives list of documents in real-time
 */
export function subscribeToFirestoreCollection(collectionName, callback) {
  try {
    const colRef = collection(db, collectionName);
    return onSnapshot(colRef, (snapshot) => {
      const docs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      callback(docs, true);
    }, (err) => {
      console.warn(`Firestore collection listener standby for [${collectionName}]:`, err.message);
      callback(null, false);
    });
  } catch (err) {
    console.warn(`Firestore initialization error for [${collectionName}]:`, err.message);
    callback(null, false);
  }
}

export default app;
