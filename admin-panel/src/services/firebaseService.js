// Firebase Realtime Database Service for Admin Panel
// Mirrors and syncs the local dataEngine with Firebase RTDB for live data.

import {
  database, ref, set, get, push, update, remove, onValue, off
} from "../firebase";

const DB_PATHS = {
  UNIVERSITIES: "admin/universities",
  INSTITUTIONS: "admin/institutions",
  STUDENTS:     "admin/students",
  COURSES:      "admin/courses",
  REPORTS:      "admin/reports",
  SYNC_LOGS:    "admin/sync_logs",
  ADMIN_USERS:  "admin/admin_users",
  KPI_OVERRIDES:"admin/kpi_overrides"
};

let connectionEstablished = false;

// Check if Firebase is reachable
export async function checkFirebaseConnection() {
  try {
    const testRef = ref(database, ".info/connected");
    const snap = await get(testRef);
    connectionEstablished = true;
    return snap.val();
  } catch (err) {
    console.warn("[Firebase] Connection check failed:", err.message);
    return false;
  }
}

// --- GENERIC HELPERS ---
function toArray(snapshot) {
  if (!snapshot.exists()) return [];
  const val = snapshot.val();
  return Object.entries(val).map(([key, value]) => ({ _fbKey: key, ...value }));
}

// --- UNIVERSITIES ---
export async function fbGetUniversities() {
  try {
    const snap = await get(ref(database, DB_PATHS.UNIVERSITIES));
    return toArray(snap);
  } catch { return []; }
}

export async function fbSetUniversities(universities) {
  try {
    const obj = {};
    universities.forEach(u => { obj[u.id.replace(/[.#$/[\]]/g, "_")] = u; });
    await set(ref(database, DB_PATHS.UNIVERSITIES), obj);
  } catch (err) { console.warn("[Firebase] fbSetUniversities:", err.message); }
}

export async function fbAddUniversity(univ) {
  try {
    await set(ref(database, `${DB_PATHS.UNIVERSITIES}/${univ.id.replace(/[.#$/[\]]/g, "_")}`), univ);
    return univ;
  } catch (err) { console.warn("[Firebase] fbAddUniversity:", err.message); return univ; }
}

export async function fbUpdateUniversity(id, fields) {
  try {
    await update(ref(database, `${DB_PATHS.UNIVERSITIES}/${id.replace(/[.#$/[\]]/g, "_")}`), fields);
  } catch (err) { console.warn("[Firebase] fbUpdateUniversity:", err.message); }
}

export async function fbDeleteUniversity(id) {
  try {
    await remove(ref(database, `${DB_PATHS.UNIVERSITIES}/${id.replace(/[.#$/[\]]/g, "_")}`));
  } catch (err) { console.warn("[Firebase] fbDeleteUniversity:", err.message); }
}

// --- INSTITUTIONS ---
export async function fbGetInstitutions() {
  try {
    const snap = await get(ref(database, DB_PATHS.INSTITUTIONS));
    return toArray(snap);
  } catch { return []; }
}

export async function fbSetInstitutions(institutions) {
  try {
    const obj = {};
    institutions.forEach(i => { obj[i.id.replace(/[.#$/[\]]/g, "_")] = i; });
    await set(ref(database, DB_PATHS.INSTITUTIONS), obj);
  } catch (err) { console.warn("[Firebase] fbSetInstitutions:", err.message); }
}

export async function fbAddInstitution(inst) {
  try {
    await set(ref(database, `${DB_PATHS.INSTITUTIONS}/${inst.id.replace(/[.#$/[\]]/g, "_")}`), inst);
    return inst;
  } catch (err) { console.warn("[Firebase] fbAddInstitution:", err.message); return inst; }
}

export async function fbUpdateInstitution(id, fields) {
  try {
    await update(ref(database, `${DB_PATHS.INSTITUTIONS}/${id.replace(/[.#$/[\]]/g, "_")}`), fields);
  } catch (err) { console.warn("[Firebase] fbUpdateInstitution:", err.message); }
}

export async function fbDeleteInstitution(id) {
  try {
    await remove(ref(database, `${DB_PATHS.INSTITUTIONS}/${id.replace(/[.#$/[\]]/g, "_")}`));
  } catch (err) { console.warn("[Firebase] fbDeleteInstitution:", err.message); }
}

// --- STUDENTS ---
export async function fbGetStudents() {
  try {
    const snap = await get(ref(database, DB_PATHS.STUDENTS));
    return toArray(snap);
  } catch { return []; }
}

export async function fbSetStudents(students) {
  try {
    const obj = {};
    students.forEach(s => { obj[s.id.replace(/[.#$/[\]]/g, "_")] = s; });
    await set(ref(database, DB_PATHS.STUDENTS), obj);
  } catch (err) { console.warn("[Firebase] fbSetStudents:", err.message); }
}

export async function fbAddStudent(student) {
  try {
    await set(ref(database, `${DB_PATHS.STUDENTS}/${student.id.replace(/[.#$/[\]]/g, "_")}`), student);
    return student;
  } catch (err) { console.warn("[Firebase] fbAddStudent:", err.message); return student; }
}

export async function fbUpdateStudent(id, fields) {
  try {
    await update(ref(database, `${DB_PATHS.STUDENTS}/${id.replace(/[.#$/[\]]/g, "_")}`), fields);
  } catch (err) { console.warn("[Firebase] fbUpdateStudent:", err.message); }
}

export async function fbDeleteStudent(id) {
  try {
    await remove(ref(database, `${DB_PATHS.STUDENTS}/${id.replace(/[.#$/[\]]/g, "_")}`));
  } catch (err) { console.warn("[Firebase] fbDeleteStudent:", err.message); }
}

// --- COURSES ---
export async function fbGetCourses() {
  try {
    const snap = await get(ref(database, DB_PATHS.COURSES));
    return toArray(snap);
  } catch { return []; }
}

export async function fbSetCourses(courses) {
  try {
    const obj = {};
    courses.forEach(c => { obj[c.id.replace(/[.#$/[\]]/g, "_")] = c; });
    await set(ref(database, DB_PATHS.COURSES), obj);
  } catch (err) { console.warn("[Firebase] fbSetCourses:", err.message); }
}

// --- REPORTS ---
export async function fbGetReports() {
  try {
    const snap = await get(ref(database, DB_PATHS.REPORTS));
    return toArray(snap);
  } catch { return []; }
}

export async function fbAddReport(rep) {
  try {
    await set(ref(database, `${DB_PATHS.REPORTS}/${rep.id.replace(/[.#$/[\]]/g, "_")}`), rep);
    return rep;
  } catch (err) { console.warn("[Firebase] fbAddReport:", err.message); return rep; }
}

// --- SYNC LOGS ---
export async function fbGetSyncLogs() {
  try {
    const snap = await get(ref(database, DB_PATHS.SYNC_LOGS));
    return toArray(snap);
  } catch { return []; }
}

export async function fbAddSyncLog(log) {
  try {
    await set(ref(database, `${DB_PATHS.SYNC_LOGS}/${log.id.replace(/[.#$/[\]]/g, "_")}`), log);
    return log;
  } catch (err) { console.warn("[Firebase] fbAddSyncLog:", err.message); return log; }
}

// --- ADMIN USERS ---
export async function fbGetAdminUsers() {
  try {
    const snap = await get(ref(database, DB_PATHS.ADMIN_USERS));
    return toArray(snap);
  } catch { return []; }
}

export async function fbAddAdminUser(user) {
  try {
    await set(ref(database, `${DB_PATHS.ADMIN_USERS}/${user.id.replace(/[.#$/[\]]/g, "_")}`), user);
    return user;
  } catch (err) { console.warn("[Firebase] fbAddAdminUser:", err.message); return user; }
}

export async function fbUpdateAdminUser(id, fields) {
  try {
    await update(ref(database, `${DB_PATHS.ADMIN_USERS}/${id.replace(/[.#$/[\]]/g, "_")}`), fields);
  } catch (err) { console.warn("[Firebase] fbUpdateAdminUser:", err.message); }
}

export async function fbDeleteAdminUser(id) {
  try {
    await remove(ref(database, `${DB_PATHS.ADMIN_USERS}/${id.replace(/[.#$/[\]]/g, "_")}`));
  } catch (err) { console.warn("[Firebase] fbDeleteAdminUser:", err.message); }
}

// --- REAL-TIME LISTENERS ---
// Subscribe to live Firebase updates for a given collection path
export function fbSubscribeToCollection(path, callback) {
  const dbRef = ref(database, DB_PATHS[path] || path);
  onValue(dbRef, (snapshot) => {
    const data = toArray(snapshot);
    callback(data);
  }, (error) => {
    console.warn(`[Firebase] Live listener error on ${path}:`, error.message);
  });
  // Return unsubscribe function
  return () => off(dbRef);
}

// Full bi-directional initial seed: push local data to Firebase if FB is empty
export async function seedFirebaseIfEmpty(localData) {
  const results = {};
  for (const [key, items] of Object.entries(localData)) {
    const path = DB_PATHS[key];
    if (!path || !items || !items.length) continue;
    try {
      const snap = await get(ref(database, path));
      if (!snap.exists()) {
        const obj = {};
        items.forEach(item => {
          const safeId = (item.id || `item_${Date.now()}`).replace(/[.#$/[\]]/g, "_");
          obj[safeId] = item;
        });
        await set(ref(database, path), obj);
        results[key] = `Seeded ${items.length} records`;
      } else {
        results[key] = `Already has data (${Object.keys(snap.val()).length} records)`;
      }
    } catch (err) {
      results[key] = `Error: ${err.message}`;
    }
  }
  return results;
}

export { DB_PATHS };
