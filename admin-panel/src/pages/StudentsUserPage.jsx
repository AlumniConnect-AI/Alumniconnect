import React, { useState, useEffect } from "react";
import { GraduationCap, Users, UserCheck, BookOpen, Search, Eye, CheckCircle, XCircle, RefreshCw } from "lucide-react";
import KpiCard from "../components/KpiCard";
import DataTable from "../components/DataTable";
import UserProfileModal from "../components/UserProfileModal";
import firestoreUserService from "../services/firestoreUserService";

export default function StudentsUserPage() {
  const [storeState, setStoreState] = useState(firestoreUserService.getStoreState());
  const [filters, setFilters] = useState({
    search: "",
    department: "All",
    onlineStatus: "All",
    page: 1,
    pageSize: 10
  });

  const [selectedUser, setSelectedUser] = useState(null);
  const [isProfileModalOpen, setIsProfileModalOpen] = useState(false);

  useEffect(() => {
    const unsubscribe = firestoreUserService.subscribe((newState) => {
      setStoreState(newState);
    });
    return () => unsubscribe();
  }, []);

  const { users, loading, stats } = storeState;

  const studentsData = firestoreUserService.getStudents({
    search: filters.search,
    department: filters.department,
    onlineStatus: filters.onlineStatus,
    page: filters.page,
    pageSize: filters.pageSize
  });

  const uniqueDepartments = Array.from(
    new Set(users.filter((u) => u.category === "Student").map((u) => u.department).filter((d) => d && d !== "—"))
  );

  const columns = [
    {
      header: "Student Name",
      accessorKey: "name",
      cell: (r) => (
        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
          {r.photoURL ? (
            <img src={r.photoURL} alt={r.name} style={{ width: "32px", height: "32px", borderRadius: "50%" }} />
          ) : (
            <div
              style={{
                width: "32px",
                height: "32px",
                borderRadius: "50%",
                background: "linear-gradient(135deg, var(--accent-emerald) 0%, #38bdf8 100%)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontWeight: "700",
                fontSize: "0.85rem"
              }}
            >
              {r.name ? r.name.charAt(0).toUpperCase() : "S"}
            </div>
          )}
          <div>
            <div style={{ fontWeight: "700", color: "#f9fafb" }}>{r.name}</div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.email}</div>
          </div>
        </div>
      )
    },
    { header: "Department", accessorKey: "department" },
    { header: "Batch", accessorKey: "batch", cell: (r) => <span className="badge badge-emerald">{r.batch}</span> },
    { header: "Location", accessorKey: "location" },
    {
      header: "Online Status",
      cell: (r) =>
        r.online ? (
          <span style={{ color: "var(--accent-emerald)", fontWeight: "600", fontSize: "0.8rem", display: "flex", alignItems: "center", gap: "4px" }}>
            <CheckCircle size={12} /> Online
          </span>
        ) : (
          <span style={{ color: "var(--text-dim)", fontSize: "0.78rem", display: "flex", alignItems: "center", gap: "4px" }}>
            <XCircle size={12} /> Offline
          </span>
        )
    },
    { header: "Last Seen", accessorKey: "lastSeen" },
    {
      header: "Profile",
      cell: (r) => (
        <button
          className="btn btn-outline btn-icon"
          onClick={() => {
            setSelectedUser(r);
            setIsProfileModalOpen(true);
          }}
          title="View Student Profile"
          style={{ color: "var(--accent-emerald)" }}
        >
          <Eye size={16} />
        </button>
      )
    }
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      {/* Title */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h1 style={{ fontSize: "1.5rem" }}>Administration → Students</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Real-time student directory automatically calculated from Firestore users collection
          </p>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", background: "rgba(16, 185, 129, 0.1)", padding: "8px 16px", borderRadius: "20px", border: "1px solid rgba(16, 185, 129, 0.2)" }}>
          <RefreshCw size={14} className="animate-spin" style={{ color: "var(--accent-emerald)" }} />
          <span style={{ fontSize: "0.8rem", color: "var(--accent-emerald)", fontWeight: "600" }}>Live Firestore Listener Active</span>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid-4">
        <KpiCard title="Total Students" value={stats.totalStudents.toLocaleString()} growth={+5.2} icon={GraduationCap} color="emerald" subtext="Enrolled Firestore Students" />
        <KpiCard title="Active Students" value={stats.studentOnline.toLocaleString()} growth={+3.4} icon={UserCheck} color="cyan" subtext="Currently Online" />
        <KpiCard title="Offline Students" value={stats.studentOffline.toLocaleString()} growth={+1.1} icon={Users} color="indigo" subtext="Registered offline" />
        <KpiCard title="Departments Represented" value={uniqueDepartments.length.toLocaleString()} growth={+2.0} icon={BookOpen} color="amber" subtext="Academic Units" />
      </div>

      {/* Main Table Glass Card */}
      <div className="glass-card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px", flexWrap: "wrap", gap: "12px" }}>
          <h3>Student User Records ({studentsData.total.toLocaleString()})</h3>
        </div>

        {/* Filters */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: "12px", marginBottom: "16px" }}>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Search Student</label>
            <input
              type="text"
              className="form-control"
              placeholder="Search Name, Email..."
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value, page: 1 })}
            />
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Department</label>
            <select
              className="form-select"
              value={filters.department}
              onChange={(e) => setFilters({ ...filters, department: e.target.value, page: 1 })}
            >
              <option value="All">All Departments</option>
              {uniqueDepartments.map((d) => (
                <option key={d} value={d}>
                  {d}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Online Status</label>
            <select
              className="form-select"
              value={filters.onlineStatus}
              onChange={(e) => setFilters({ ...filters, onlineStatus: e.target.value, page: 1 })}
            >
              <option value="All">All Statuses</option>
              <option value="Online">Online Only</option>
              <option value="Offline">Offline Only</option>
            </select>
          </div>
        </div>

        {loading ? (
          <div style={{ padding: "30px", textAlign: "center", color: "var(--text-muted)" }}>Loading Students...</div>
        ) : (
          <DataTable columns={columns} data={studentsData.items} searchPlaceholder="" />
        )}

        {/* Pagination */}
        <div style={{ marginTop: "16px", display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid var(--border-color)", paddingTop: "14px" }}>
          <div style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Showing <strong>{studentsData.items.length > 0 ? (studentsData.page - 1) * studentsData.pageSize + 1 : 0}</strong> – <strong>{Math.min(studentsData.page * studentsData.pageSize, studentsData.total)}</strong> of <strong>{studentsData.total}</strong> students
          </div>
          <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
            <button className="btn btn-outline" disabled={filters.page <= 1} onClick={() => setFilters({ ...filters, page: filters.page - 1 })}>
              Previous
            </button>
            <span style={{ fontSize: "0.85rem" }}>Page {studentsData.page} of {studentsData.totalPages}</span>
            <button className="btn btn-outline" disabled={filters.page >= studentsData.totalPages} onClick={() => setFilters({ ...filters, page: filters.page + 1 })}>
              Next
            </button>
          </div>
        </div>
      </div>

      <UserProfileModal isOpen={isProfileModalOpen} onClose={() => setIsProfileModalOpen(false)} user={selectedUser} />
    </div>
  );
}
