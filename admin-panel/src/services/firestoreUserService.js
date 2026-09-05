// Centralized Firebase Firestore User Service for National Education Analytics Portal
// Single Source of Truth for Firestore 'users' collection with real-time onSnapshot listeners

import { firestore, collection, onSnapshot } from "../firebase";

class FirestoreUserService {
  constructor() {
    this.users = [];
    this.subscribers = new Set();
    this.unsubscribeListener = null;
    this.loading = true;
    this.error = null;

    // Auto-start real-time Firestore listener on initialization
    this.initRealtimeListener();
  }

  /**
   * Safe user categorization logic based on document fields
   */
  categorizeUser(u) {
    const rawRole = (u.role || u.userType || u.category || u.accountType || u.type || "").toString().toLowerCase().trim();
    const designation = (u.designation || "").toString().toLowerCase();
    const company = (u.company || "").toString().toLowerCase();
    const batch = (u.batch || u.graduationYear || u.passoutYear || "").toString();

    // 1. Explicit Category/Role Matches
    if (rawRole === "student" || rawRole === "students") return "Student";
    if (rawRole === "alumni" || rawRole === "alumnus" || rawRole === "graduate") return "Alumni";
    if (rawRole === "staff" || rawRole === "faculty" || rawRole === "professor" || rawRole === "teacher" || rawRole === "admin") return "Staff";

    // 2. Heuristic Staff Check
    const staffKeywords = ["professor", "hod", "teacher", "lecturer", "faculty", "dean", "principal", "director", "instructor", "staff"];
    if (staffKeywords.some((kw) => designation.includes(kw))) {
      return "Staff";
    }

    // 3. Heuristic Alumni Check
    if (company && company !== "n/a" && company !== "none" && company !== "student" && company !== "seeking") {
      return "Alumni";
    }
    if (designation && !designation.includes("student") && !designation.includes("intern")) {
      return "Alumni";
    }

    // 4. Batch/Graduation Year Check
    const currentYear = new Date().getFullYear();
    if (batch) {
      const match = batch.match(/\b(19\d\d|20\d\d)\b/);
      if (match) {
        const year = parseInt(match[1], 10);
        if (year < currentYear) return "Alumni";
        if (year >= currentYear) return "Student";
      }
    }

    // 5. Default heuristic: if user has any standard profile, classify as Student if unknown, or Uncategorized
    if (u.name || u.email) {
      return "Student";
    }

    return "Uncategorized";
  }

  /**
   * Normalize user document to prevent missing field crashes
   */
  normalizeUserDoc(docSnap) {
    const data = docSnap.data() || {};
    const id = docSnap.id;

    const category = this.categorizeUser(data);

    // Online status determination
    const isOnline =
      data.online === true ||
      data.isOnline === true ||
      data.status === "online" ||
      data.status === "Online";

    return {
      id,
      docId: id,
      uid: data.uid || id,
      name: data.name || data.displayName || data.fullName || "Unnamed User",
      email: data.email || "No Email Provided",
      batch: data.batch || data.graduationYear || data.passoutYear || "—",
      bio: data.bio || "No bio provided",
      company: data.company || data.organization || "—",
      department: data.department || data.course || data.stream || "General Education",
      designation: data.designation || data.title || (category === "Student" ? "Enrolled Student" : "—"),
      location: data.location || data.city || data.state || "—",
      linkedin: data.linkedin || data.linkedinUrl || "",
      online: isOnline,
      lastSeen: data.lastSeen || data.lastActive || "—",
      createdAt: data.createdAt || data.joinedAt || "—",
      role: data.role || data.userType || category,
      category: category,
      photoURL: data.photoURL || data.avatar || null,
      raw: data
    };
  }

  /**
   * Start Firestore onSnapshot Realtime Listener
   */
  initRealtimeListener() {
    try {
      const usersColRef = collection(firestore, "users");
      this.unsubscribeListener = onSnapshot(
        usersColRef,
        (snapshot) => {
          const userList = [];
          snapshot.forEach((docSnap) => {
            userList.push(this.normalizeUserDoc(docSnap));
          });
          this.users = userList;
          this.loading = false;
          this.error = null;
          console.log(`[FirestoreUserService] Real-time snapshot updated: ${userList.length} total users.`);
          this.notifySubscribers();
        },
        (err) => {
          console.error("[FirestoreUserService] Listener error:", err);
          this.error = err.message || "Failed to load Firestore users.";
          this.loading = false;
          this.notifySubscribers();
        }
      );
    } catch (err) {
      console.error("[FirestoreUserService] Init error:", err);
      this.error = err.message || "Firestore initialization error.";
      this.loading = false;
    }
  }

  /**
   * Subscribe to real-time updates
   */
  subscribe(callback) {
    this.subscribers.add(callback);
    // Trigger immediate callback with current data
    callback(this.getStoreState());
    return () => {
      this.subscribers.delete(callback);
    };
  }

  notifySubscribers() {
    const state = this.getStoreState();
    this.subscribers.forEach((cb) => cb(state));
  }

  getStoreState() {
    return {
      users: this.users,
      loading: this.loading,
      error: this.error,
      stats: this.getUserStatistics()
    };
  }

  /**
   * User Statistics Calculation (Single Source of Truth)
   */
  getUserStatistics() {
    const totalUsers = this.users.length;
    const students = this.users.filter((u) => u.category === "Student");
    const alumni = this.users.filter((u) => u.category === "Alumni");
    const staff = this.users.filter((u) => u.category === "Staff");
    const uncategorized = this.users.filter((u) => u.category === "Uncategorized");

    const onlineUsers = this.users.filter((u) => u.online).length;
    const offlineUsers = totalUsers - onlineUsers;

    const studentOnline = students.filter((s) => s.online).length;
    const studentOffline = students.length - studentOnline;

    const alumniOnline = alumni.filter((a) => a.online).length;
    const staffOnline = staff.filter((st) => st.online).length;

    // Unique departments
    const departments = new Set(this.users.map((u) => u.department).filter((d) => d && d !== "—"));

    // Unique companies (for Alumni)
    const alumniCompanies = new Set(alumni.map((a) => a.company).filter((c) => c && c !== "—"));

    return {
      totalUsers,
      totalStudents: students.length,
      totalAlumni: alumni.length,
      totalStaff: staff.length,
      totalUncategorized: uncategorized.length,
      onlineUsers,
      offlineUsers,
      studentOnline,
      studentOffline,
      alumniOnline,
      staffOnline,
      departmentsCount: departments.size,
      alumniCompaniesCount: alumniCompanies.size
    };
  }

  /**
   * Query / Filter methods for UI pages
   */
  getFilteredUsers({ category, search = "", department = "All", batch = "All", onlineStatus = "All", sortBy = "name", page = 1, pageSize = 10 } = {}) {
    let list = [...this.users];

    // Filter by Category if provided
    if (category && category !== "All") {
      list = list.filter((u) => u.category === category);
    }

    // Filter by Department
    if (department && department !== "All") {
      list = list.filter((u) => u.department === department);
    }

    // Filter by Batch
    if (batch && batch !== "All") {
      list = list.filter((u) => u.batch === batch);
    }

    // Filter by Online status
    if (onlineStatus === "Online") {
      list = list.filter((u) => u.online);
    } else if (onlineStatus === "Offline") {
      list = list.filter((u) => !u.online);
    }

    // Search query across fields
    if (search && search.trim()) {
      const q = search.toLowerCase().trim();
      list = list.filter(
        (u) =>
          u.name.toLowerCase().includes(q) ||
          u.email.toLowerCase().includes(q) ||
          u.department.toLowerCase().includes(q) ||
          u.company.toLowerCase().includes(q) ||
          u.designation.toLowerCase().includes(q) ||
          u.location.toLowerCase().includes(q)
      );
    }

    // Sorting
    list.sort((a, b) => {
      if (sortBy === "name") return a.name.localeCompare(b.name);
      if (sortBy === "email") return a.email.localeCompare(b.email);
      if (sortBy === "department") return a.department.localeCompare(b.department);
      if (sortBy === "category") return a.category.localeCompare(b.category);
      if (sortBy === "batch") return a.batch.localeCompare(b.batch);
      return 0;
    });

    const total = list.length;
    const totalPages = Math.ceil(total / pageSize) || 1;
    const currentPage = Math.min(Math.max(1, page), totalPages);
    const startIndex = (currentPage - 1) * pageSize;
    const paginatedItems = list.slice(startIndex, startIndex + pageSize);

    return {
      items: paginatedItems,
      total,
      page: currentPage,
      pageSize,
      totalPages
    };
  }

  getStudents(filters = {}) {
    return this.getFilteredUsers({ ...filters, category: "Student" });
  }

  getAlumni(filters = {}) {
    return this.getFilteredUsers({ ...filters, category: "Alumni" });
  }

  getStaff(filters = {}) {
    return this.getFilteredUsers({ ...filters, category: "Staff" });
  }
}

export const firestoreUserService = new FirestoreUserService();
export default firestoreUserService;
