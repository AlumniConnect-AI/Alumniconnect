import React, { useState, useEffect } from "react";
import { Users, GraduationCap, Briefcase, UserCheck, Search, Filter, Eye, CheckCircle, XCircle, RefreshCw, AlertCircle } from "lucide-react";
import KpiCard from "../components/KpiCard";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import UserProfileModal from "../components/UserProfileModal";
import firestoreUserService from "../services/firestoreUserService";

export default function UserManagement({ initialCategory = "All" }) {
  const [storeState, setStoreState] = useState(firestoreUserService.getStoreState());
  const [selectedCategory, setSelectedCategory] = useState(initialCategory);

  const [filters, setFilters] = useState({
    search: "",
    department: "All",
    batch: "All",
    onlineStatus: "All",
    sortBy: "name",
    page: 1,
    pageSize: 10
  });

  const [selectedUser, setSelectedUser] = useState(null);
  const [isProfileModalOpen, setIsProfileModalOpen] = useState(false);

  useEffect(() => {
    // Subscribe to real-time Firestore updates
    const unsubscribe = firestoreUserService.subscribe((newState) => {
      setStoreState(newState);
    });
    return () => unsubscribe();
  }, []);

  const { users, loading, error, stats } = storeState;

  // Filtered dataset
  const filteredData = firestoreUserService.getFilteredUsers({
    category: selectedCategory,
    search: filters.search,
    department: filters.department,
    batch: filters.batch,
    onlineStatus: filters.onlineStatus,
    sortBy: filters.sortBy,
    page: filters.page,
    pageSize: filters.pageSize
  });

  // Extract unique departments for filter dropdown
  const uniqueDepartments = Array.from(new Set(users.map((u) => u.department).filter((d) => d && d !== "—")));

  const handleRowClick = (user) => {
    setSelectedUser(user);
    setIsProfileModalOpen(true);
  };

  const columns = [
    {
      header: "User Name & Email",
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
                background: "linear-gradient(135deg, var(--primary) 0%, #38bdf8 100%)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontWeight: "700",
                fontSize: "0.85rem"
              }}
            >
              {r.name ? r.name.charAt(0).toUpperCase() : "U"}
            </div>
          )}
          <div>
            <div style={{ fontWeight: "700", color: "#f9fafb" }}>{r.name}</div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.email}</div>
          </div>
        </div>
      )
    },
    {
      header: "Category",
      accessorKey: "category",
      cell: (r) => <StatusBadge status={r.category} />
    },
    {
      header: "Department",
      accessorKey: "department",
      cell: (r) => <span style={{ fontSize: "0.85rem", color: "#e2e8f0" }}>{r.department}</span>
    },
    {
      header: "Batch / Year",
      accessorKey: "batch",
      cell: (r) => <span className="badge badge-indigo">{r.batch}</span>
    },
    {
      header: "Designation & Company",
      cell: (r) => (
        <div>
          <div style={{ fontWeight: "600", fontSize: "0.85rem", color: "var(--accent-cyan)" }}>{r.designation}</div>
          <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.company}</div>
        </div>
      )
    },
    {
      header: "Location",
      accessorKey: "location",
      cell: (r) => <span style={{ fontSize: "0.82rem", color: "var(--text-muted)" }}>{r.location}</span>
    },
    {
      header: "Status / Last Seen",
      cell: (r) => (
        <div>
          {r.online ? (
            <span style={{ color: "var(--accent-emerald)", fontWeight: "600", fontSize: "0.8rem", display: "flex", alignItems: "center", gap: "4px" }}>
              <CheckCircle size={12} /> Online
            </span>
          ) : (
            <span style={{ color: "var(--text-dim)", fontSize: "0.78rem", display: "flex", alignItems: "center", gap: "4px" }}>
              <XCircle size={12} /> {r.lastSeen || "Offline"}
            </span>
          )}
        </div>
      )
    },
    {
      header: "Profile View",
      cell: (r) => (
        <button
          className="btn btn-outline btn-icon"
          onClick={() => handleRowClick(r)}
          title="View Complete User Profile"
          style={{ color: "var(--primary)" }}
        >
          <Eye size={16} />
        </button>
      )
    }
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      {/* Header Bar */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h1 style={{ fontSize: "1.5rem" }}>Administration → User Data</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Live real-time administration portal synchronized directly with Firestore <code style={{ color: "var(--accent-cyan)" }}>users</code> collection
          </p>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", background: "rgba(16, 185, 129, 0.1)", padding: "8px 16px", borderRadius: "20px", border: "1px solid rgba(16, 185, 129, 0.2)" }}>
          <RefreshCw size={14} className="animate-spin" style={{ color: "var(--accent-emerald)" }} />
          <span style={{ fontSize: "0.8rem", color: "var(--accent-emerald)", fontWeight: "600" }}>Live Firestore Real-Time Sync</span>
        </div>
      </div>

      {/* Error Alert */}
      {error && (
        <div style={{ padding: "14px", background: "rgba(239, 68, 68, 0.15)", border: "1px solid rgba(239, 68, 68, 0.3)", borderRadius: "10px", color: "#f87171", display: "flex", alignItems: "center", gap: "10px" }}>
          <AlertCircle size={20} />
          <div>
            <strong>Firestore Error:</strong> {error}
          </div>
        </div>
      )}

      {/* Summary KPI Cards */}
      <div className="grid-4">
        <KpiCard title="Total Users" value={stats.totalUsers.toLocaleString()} growth={+4.8} icon={Users} color="cyan" subtext="Live Firestore Records" />
        <KpiCard title="Total Students" value={stats.totalStudents.toLocaleString()} growth={+5.2} icon={GraduationCap} color="emerald" subtext="Enrolled & Active" />
        <KpiCard title="Total Alumni" value={stats.totalAlumni.toLocaleString()} growth={+3.6} icon={Briefcase} color="indigo" subtext="Graduates & Working" />
        <KpiCard title="Total Staff" value={stats.totalStaff.toLocaleString()} growth={+1.5} icon={UserCheck} color="amber" subtext="Faculty & Admins" />
      </div>

      {/* Category Tabs */}
      <div style={{ display: "flex", gap: "8px", borderBottom: "1px solid var(--border-color)", paddingBottom: "12px" }}>
        {[
          { key: "All", label: `All Users (${stats.totalUsers})` },
          { key: "Student", label: `Students (${stats.totalStudents})` },
          { key: "Alumni", label: `Alumni (${stats.totalAlumni})` },
          { key: "Staff", label: `Staff (${stats.totalStaff})` },
          ...(stats.totalUncategorized > 0 ? [{ key: "Uncategorized", label: `Uncategorized (${stats.totalUncategorized})` }] : [])
        ].map((tab) => (
          <button
            key={tab.key}
            onClick={() => {
              setSelectedCategory(tab.key);
              setFilters({ ...filters, page: 1 });
            }}
            className="btn"
            style={{
              padding: "8px 18px",
              borderRadius: "20px",
              fontSize: "0.85rem",
              fontWeight: selectedCategory === tab.key ? "700" : "500",
              background: selectedCategory === tab.key ? "var(--primary)" : "rgba(255,255,255,0.04)",
              color: selectedCategory === tab.key ? "#ffffff" : "var(--text-muted)",
              border: selectedCategory === tab.key ? "none" : "1px solid var(--border-color)"
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Main Users Table Glass Card */}
      <div className="glass-card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px", flexWrap: "wrap", gap: "12px" }}>
          <div>
            <h3 style={{ fontSize: "1.1rem" }}>
              {selectedCategory === "All" ? "All Firestore Users" : `${selectedCategory} Directory`} ({filteredData.total.toLocaleString()})
            </h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
              Real-time directory. Click any row icon to view complete profile details.
            </p>
          </div>
        </div>

        {/* Filter Controls Bar */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))", gap: "12px", marginBottom: "16px" }}>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Search User</label>
            <input
              type="text"
              className="form-control"
              placeholder="Name, Email, Company, Dept..."
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
              {uniqueDepartments.map((dept) => (
                <option key={dept} value={dept}>
                  {dept}
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

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Sort By</label>
            <select
              className="form-select"
              value={filters.sortBy}
              onChange={(e) => setFilters({ ...filters, sortBy: e.target.value, page: 1 })}
            >
              <option value="name">Name (A-Z)</option>
              <option value="email">Email</option>
              <option value="department">Department</option>
              <option value="category">Category</option>
            </select>
          </div>
        </div>

        {/* Data Table */}
        {loading ? (
          <div style={{ padding: "40px", textAlign: "center", color: "var(--text-muted)" }}>
            Loading live Firestore users...
          </div>
        ) : filteredData.items.length === 0 ? (
          <div style={{ padding: "40px", textAlign: "center", color: "var(--text-muted)" }}>
            No users match the selected filters or collection is empty.
          </div>
        ) : (
          <DataTable columns={columns} data={filteredData.items} searchPlaceholder="" />
        )}

        {/* Pagination Bar */}
        <div
          style={{
            marginTop: "16px",
            display: "flex",
            justify: "space-between",
            alignItems: "center",
            flexWrap: "wrap",
            gap: "12px",
            borderTop: "1px solid var(--border-color)",
            paddingTop: "14px"
          }}
        >
          <div style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Showing <strong>{filteredData.items.length > 0 ? (filteredData.page - 1) * filteredData.pageSize + 1 : 0}</strong> –{" "}
            <strong>{Math.min(filteredData.page * filteredData.pageSize, filteredData.total)}</strong> of <strong>{filteredData.total.toLocaleString()}</strong> users
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <span style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>Rows:</span>
            <select
              className="form-select"
              style={{ width: "70px", padding: "4px 8px", fontSize: "0.8rem" }}
              value={filters.pageSize}
              onChange={(e) => setFilters({ ...filters, pageSize: parseInt(e.target.value, 10), page: 1 })}
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
            </select>

            <button
              className="btn btn-outline"
              disabled={filters.page <= 1}
              onClick={() => setFilters({ ...filters, page: filters.page - 1 })}
            >
              Previous
            </button>
            <span style={{ fontSize: "0.85rem", padding: "0 6px" }}>
              Page {filteredData.page} of {filteredData.totalPages}
            </span>
            <button
              className="btn btn-outline"
              disabled={filters.page >= filteredData.totalPages}
              onClick={() => setFilters({ ...filters, page: filters.page + 1 })}
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* User Profile View Modal */}
      <UserProfileModal
        isOpen={isProfileModalOpen}
        onClose={() => setIsProfileModalOpen(false)}
        user={selectedUser}
      />
    </div>
  );
}
