import React, { useState, useEffect } from "react";
import { UserCheck, BookOpen, CheckCircle, XCircle, RefreshCw, Eye } from "lucide-react";
import KpiCard from "../components/KpiCard";
import DataTable from "../components/DataTable";
import UserProfileModal from "../components/UserProfileModal";
import firestoreUserService from "../services/firestoreUserService";

export default function StaffUserPage() {
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

  const staffData = firestoreUserService.getStaff({
    search: filters.search,
    department: filters.department,
    onlineStatus: filters.onlineStatus,
    page: filters.page,
    pageSize: filters.pageSize
  });

  const uniqueDepartments = Array.from(
    new Set(users.filter((u) => u.category === "Staff").map((u) => u.department).filter((d) => d && d !== "—"))
  );

  const columns = [
    {
      header: "Staff Member Name",
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
                background: "linear-gradient(135deg, var(--accent-amber) 0%, #38bdf8 100%)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontWeight: "700",
                fontSize: "0.85rem"
              }}
            >
              {r.name ? r.name.charAt(0).toUpperCase() : "T"}
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
    { header: "Designation", accessorKey: "designation", cell: (r) => <span style={{ fontWeight: "600", color: "var(--accent-amber)" }}>{r.designation}</span> },
    { header: "Location", accessorKey: "location" },
    {
      header: "Status",
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
          title="View Staff Profile"
          style={{ color: "var(--accent-amber)" }}
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
          <h1 style={{ fontSize: "1.5rem" }}>Administration → Staff</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Real-time faculty and administration staff directory from Firestore users collection
          </p>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", background: "rgba(245, 158, 11, 0.1)", padding: "8px 16px", borderRadius: "20px", border: "1px solid rgba(245, 158, 11, 0.2)" }}>
          <RefreshCw size={14} className="animate-spin" style={{ color: "var(--accent-amber)" }} />
          <span style={{ fontSize: "0.8rem", color: "var(--accent-amber)", fontWeight: "600" }}>Live Firestore Listener Active</span>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid-4">
        <KpiCard title="Total Staff" value={stats.totalStaff.toLocaleString()} growth={+1.5} icon={UserCheck} color="amber" subtext="Faculty & Administrative Staff" />
        <KpiCard title="Currently Online" value={stats.staffOnline.toLocaleString()} growth={+0.8} icon={CheckCircle} color="emerald" subtext="Active on Portal" />
        <KpiCard title="Departments" value={uniqueDepartments.length.toLocaleString()} growth={+1.0} icon={BookOpen} color="cyan" subtext="Academic Departments" />
        <KpiCard title="Active Staff" value={stats.totalStaff.toLocaleString()} growth={+1.5} icon={UserCheck} color="indigo" subtext="Verified Faculty Accounts" />
      </div>

      {/* Main Table Glass Card */}
      <div className="glass-card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
          <h3>Staff Directory ({staffData.total.toLocaleString()})</h3>
        </div>

        {/* Filters */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: "12px", marginBottom: "16px" }}>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Search Staff</label>
            <input
              type="text"
              className="form-control"
              placeholder="Name, Email, Designation..."
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
          <div style={{ padding: "30px", textAlign: "center", color: "var(--text-muted)" }}>Loading Staff...</div>
        ) : (
          <DataTable columns={columns} data={staffData.items} searchPlaceholder="" />
        )}

        {/* Pagination */}
        <div style={{ marginTop: "16px", display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid var(--border-color)", paddingTop: "14px" }}>
          <div style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Showing <strong>{staffData.items.length > 0 ? (staffData.page - 1) * staffData.pageSize + 1 : 0}</strong> – <strong>{Math.min(staffData.page * staffData.pageSize, staffData.total)}</strong> of <strong>{staffData.total}</strong> staff members
          </div>
          <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
            <button className="btn btn-outline" disabled={filters.page <= 1} onClick={() => setFilters({ ...filters, page: filters.page - 1 })}>
              Previous
            </button>
            <span style={{ fontSize: "0.85rem" }}>Page {staffData.page} of {staffData.totalPages}</span>
            <button className="btn btn-outline" disabled={filters.page >= staffData.totalPages} onClick={() => setFilters({ ...filters, page: filters.page + 1 })}>
              Next
            </button>
          </div>
        </div>
      </div>

      <UserProfileModal isOpen={isProfileModalOpen} onClose={() => setIsProfileModalOpen(false)} user={selectedUser} />
    </div>
  );
}
