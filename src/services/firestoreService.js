import {
    collection,
    getDocs,
    deleteDoc,
    updateDoc,
    doc,
    onSnapshot,
    Timestamp,
} from "firebase/firestore";
import { db } from "../firebase";

// ─── Collection Names ────────────────────────────────────
const USERS_COL = "users";
const JOBS_COL = "jobs";
const EVENTS_COL = "events";
const REPORTS_COL = "reports";
const MESSAGES_COL = "messages";

// ─── Helpers ─────────────────────────────────────────────
function toDate(raw) {
    if (!raw) return null;
    if (raw.toDate) return raw.toDate();
    const d = new Date(raw);
    return isNaN(d.getTime()) ? null : d;
}

// ─── Users / Alumni ──────────────────────────────────────
export function subscribeToUsers(callback) {
    return onSnapshot(
        collection(db, USERS_COL),
        (snap) => {
            const users = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
            users.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
            callback(users);
        },
        (err) => { console.error("Users error:", err.message); callback([]); }
    );
}

export async function fetchUsers() {
    try {
        const snap = await getDocs(collection(db, USERS_COL));
        const users = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        users.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return users;
    } catch (e) { console.error("fetchUsers:", e.message); return []; }
}

export async function suspendUser(userId) {
    await updateDoc(doc(db, USERS_COL, userId), { status: "suspended" });
}

export async function activateUser(userId) {
    await updateDoc(doc(db, USERS_COL, userId), { status: "active" });
}

export async function updateUserRole(userId, newRole) {
    await updateDoc(doc(db, USERS_COL, userId), { role: newRole });
}

export async function removeStaffRole(userId) {
    await updateDoc(doc(db, USERS_COL, userId), { role: "alumni" });
}

export async function warnUser(userId) {
    await updateDoc(doc(db, USERS_COL, userId), {
        warned: true,
        warnedAt: Timestamp.now(),
    });
}

// ─── Jobs ────────────────────────────────────────────────
export function subscribeToJobs(callback) {
    return onSnapshot(
        collection(db, JOBS_COL),
        (snap) => {
            const jobs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
            callback(jobs);
        },
        (err) => { console.error("Jobs error:", err.message); callback([]); }
    );
}

export async function fetchJobs() {
    try {
        const snap = await getDocs(collection(db, JOBS_COL));
        return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    } catch (e) { console.error("fetchJobs:", e.message); return []; }
}

export async function deleteJob(jobId) {
    await deleteDoc(doc(db, JOBS_COL, jobId));
}

export async function verifyJob(jobId) {
    await updateDoc(doc(db, JOBS_COL, jobId), {
        verified: true,
        verifiedAt: Timestamp.now(),
    });
}

// ─── Events ──────────────────────────────────────────────
export function subscribeToEvents(callback) {
    return onSnapshot(
        collection(db, EVENTS_COL),
        (snap) => {
            const events = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
            callback(events);
        },
        (err) => { console.error("Events error:", err.message); callback([]); }
    );
}

export async function fetchEvents() {
    try {
        const snap = await getDocs(collection(db, EVENTS_COL));
        return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    } catch (e) { console.error("fetchEvents:", e.message); return []; }
}

export async function deleteEvent(eventId) {
    await deleteDoc(doc(db, EVENTS_COL, eventId));
}

// ─── Reports ─────────────────────────────────────────────
export function subscribeToReports(callback) {
    return onSnapshot(
        collection(db, REPORTS_COL),
        (snap) => {
            const reports = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
            callback(reports);
        },
        (err) => { console.error("Reports error:", err.message); callback([]); }
    );
}

export async function fetchReports() {
    try {
        const snap = await getDocs(collection(db, REPORTS_COL));
        return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    } catch (e) { console.error("fetchReports:", e.message); return []; }
}

export async function resolveReport(reportId, action) {
    await updateDoc(doc(db, REPORTS_COL, reportId), {
        status: "resolved",
        action,
        resolvedAt: Timestamp.now(),
    });
}

export async function ignoreReport(reportId) {
    await updateDoc(doc(db, REPORTS_COL, reportId), {
        status: "ignored",
        resolvedAt: Timestamp.now(),
    });
}

// ─── Messages (count only) ──────────────────────────────
export async function getMessageCount() {
    try {
        const snap = await getDocs(collection(db, MESSAGES_COL));
        return snap.size;
    } catch { return 0; }
}

// ─── Dashboard Stats ─────────────────────────────────────
export async function fetchDashboardStats() {
    const [users, jobs, events, reports, messageCount] = await Promise.all([
        fetchUsers(),
        fetchJobs(),
        fetchEvents(),
        fetchReports(),
        getMessageCount(),
    ]);

    const students = users.filter((u) => u.role === "student");
    const alumni = users.filter((u) => u.role === "alumni");
    const staff = users.filter((u) => u.role === "staff");
    const pendingReports = reports.filter((r) => !r.status || r.status === "pending");

    return {
        totalUsers: users.length,
        studentCount: students.length,
        alumniCount: alumni.length,
        staffCount: staff.length,
        totalJobs: jobs.length,
        totalEvents: events.length,
        pendingReports: pendingReports.length,
        messageCount,
        recentUsers: users.slice(0, 5),
        recentJobs: jobs.slice(0, 4),
        upcomingEvents: events.filter((e) => {
            if (e.status === "upcoming") return true;
            const d = toDate(e.date);
            return d && d > new Date();
        }),
        users,
        jobs,
        events,
        reports,
    };
}

// ─── Activity Log (merged timeline) ─────────────────────
export async function fetchActivityLog() {
    const [users, jobs, events, reports] = await Promise.all([
        fetchUsers(), fetchJobs(), fetchEvents(), fetchReports(),
    ]);

    const items = [];

    users.forEach((u) => {
        const d = toDate(u.joinedAt || u.createdAt);
        if (d) items.push({
            type: "registration",
            title: `${u.name || u.email || "User"} registered`,
            detail: `Role: ${u.role || "alumni"} · ${u.department || "N/A"}`,
            date: d,
            userId: u.id,
        });
    });

    jobs.forEach((j) => {
        const d = toDate(j.postedAt || j.createdAt);
        if (d) items.push({
            type: "job",
            title: `Job posted: ${j.title || "Untitled"}`,
            detail: `${j.company || "Unknown"} · by ${j.postedBy || "Unknown"}`,
            date: d,
        });
    });

    events.forEach((e) => {
        const d = toDate(e.date || e.createdAt);
        if (d) items.push({
            type: "event",
            title: `Event created: ${e.title || "Untitled"}`,
            detail: `${e.location || "TBD"} · ${e.participants || 0} participants`,
            date: d,
        });
    });

    reports.forEach((r) => {
        const d = toDate(r.createdAt || r.reportedAt);
        if (d) items.push({
            type: "report",
            title: `Report submitted`,
            detail: `Reason: ${r.reason || "N/A"} · Status: ${r.status || "pending"}`,
            date: d,
        });
    });

    items.sort((a, b) => b.date - a.date);
    return items;
}

// ─── Analytics Helpers ───────────────────────────────────

export function computeUserGrowth(users) {
    const monthMap = {};
    users.forEach((u) => {
        const date = toDate(u.joinedAt || u.createdAt);
        if (!date) return;
        const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
        const label = date.toLocaleDateString("en-US", { month: "short", year: "2-digit" });
        if (!monthMap[key]) monthMap[key] = { key, month: label, users: 0 };
        monthMap[key].users += 1;
    });
    return Object.values(monthMap).sort((a, b) => a.key.localeCompare(b.key)).slice(-12);
}

export function computeTopCompanies(jobs, topN = 8) {
    const counts = {};
    jobs.forEach((j) => {
        const company = j.company || "Unknown";
        counts[company] = (counts[company] || 0) + 1;
    });
    return Object.entries(counts)
        .map(([name, jobCount]) => ({ name, jobs: jobCount }))
        .sort((a, b) => b.jobs - a.jobs)
        .slice(0, topN);
}

export function computeDepartmentDistribution(users) {
    const COLORS = ["#2BB673", "#34d68a", "#6ee7a7", "#a7f3d0", "#d1fae5", "#059669", "#10B981", "#bbf7d0"];
    const counts = {};
    users.forEach((u) => { const d = u.department || "Other"; counts[d] = (counts[d] || 0) + 1; });
    return Object.entries(counts)
        .map(([name, value], i) => ({ name, value, color: COLORS[i % COLORS.length] }))
        .sort((a, b) => b.value - a.value);
}

export function computeBatchDistribution(users) {
    const COLORS = ["#2BB673", "#059669", "#34d68a", "#6ee7a7", "#a7f3d0", "#10B981", "#d1fae5", "#bbf7d0"];
    const counts = {};
    users.forEach((u) => { const b = u.batch || "Unknown"; counts[b] = (counts[b] || 0) + 1; });
    return Object.entries(counts)
        .map(([name, value], i) => ({ name, value, color: COLORS[i % COLORS.length] }))
        .sort((a, b) => b.value - a.value);
}

export function computeEventParticipation(events) {
    return events.map((e) => ({
        name: (e.title || "Untitled").length > 18 ? (e.title || "").slice(0, 18) + "…" : e.title || "Untitled",
        value: e.participants || 0,
    }));
}

export function computeMostActiveUsers(users, jobs, events) {
    const activity = {};
    users.forEach((u) => { activity[u.id] = { name: u.name || u.email || "User", score: 0 }; });
    jobs.forEach((j) => {
        if (j.postedById && activity[j.postedById]) activity[j.postedById].score += 3;
        else if (j.postedBy) {
            const match = Object.entries(activity).find(([, v]) => v.name === j.postedBy);
            if (match) match[1].score += 3;
        }
    });
    events.forEach((e) => {
        if (e.organizerId && activity[e.organizerId]) activity[e.organizerId].score += 5;
    });
    return Object.entries(activity)
        .map(([id, { name, score }]) => ({ id, name, score }))
        .filter((u) => u.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, 8);
}

export async function computeEngagementRate() {
    try {
        const snap = await getDocs(collection(db, MESSAGES_COL));
        if (snap.size === 0) return 0;
        const dates = snap.docs.map((d) => toDate(d.data().createdAt || d.data().timestamp)).filter(Boolean);
        if (dates.length < 2) return snap.size;
        const minDate = new Date(Math.min(...dates));
        const maxDate = new Date(Math.max(...dates));
        const days = Math.max(1, Math.ceil((maxDate - minDate) / (1000 * 60 * 60 * 24)));
        return Math.round(snap.size / days);
    } catch { return 0; }
}

export async function fetchEngagementData() {
    try {
        const snap = await getDocs(collection(db, "engagement"));
        if (snap.size > 0) return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    } catch { }
    return [];
}
