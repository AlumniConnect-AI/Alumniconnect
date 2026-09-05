import React, { useState, useEffect } from "react";
import { Briefcase, Building, Linkedin, BookOpen, CheckCircle, XCircle, RefreshCw, Eye } from "lucide-react";
import KpiCard from "../components/KpiCard";
import DataTable from "../components/DataTable";
import UserProfileModal from "../components/UserProfileModal";
import firestoreUserService from "../services/firestoreUserService";

export default function AlumniUserPage() {
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

  const alumniData = firestoreUserService.getAlumni({
    search: filters.search,
    department: filters.department,
    onlineStatus: filters.onlineStatus,
    page: filters.page,
    pageSize: filters.pageSize
  });

  const uniqueDepartments = Array.from(
    new Set(users.filter((u) => u.category === "Alumni").map((u) => u.department).filter((d) => d && d !== "—"))
  );

  const columns = [
    {
      header: "Alumni Name",
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
                background: "linear-gradient(135deg, var(--accent-indigo) 0%, #38bdf8 100%)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontWeight: "700",
                fontSize: "0.85rem"
              }}
            >
              {r.name ? r.name.charAt(0).toUpperCase() : "A"}
            </div>
          )}
          <div>
            <div style={{ fontWeight: "700", color: "#f9fafb" }}>{r.name}</div>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.email}</div>
          </div>
        </div>
      )
    },
    { header: "Graduation Batch", accessorKey: "batch", cell: (r) => <span className="badge badge-indigo">{r.batch}</span> },
    { header: "Department", accessorKey: "department" },
    { header: "Designation", accessorKey: "designation", cell: (r) => <span style={{ fontWeight: "600", color: "var(--accent-cyan)" }}>{r.designation}</span> },
    { header: "Company", accessorKey: "company" },
    { header: "Location", accessorKey: "location" },
    {
      header: "LinkedIn",
      cell: (r) =>
        r.linkedin ? (
          <a
            href={r.linkedin.startsWith("http") ? r.linkedin : `https://${r.linkedin}`}
            target="_blank"
            rel="noreferrer"
            style={{ color: "#38bdf8", display: "inline-flex", alignItems: "center", gap: "4px", fontSize: "0.8rem", textDecoration: "underline" }}
          >
            <Linkedin size={14} /> Profile
          </a>
        ) : (
          <span style={{ fontSize: "0.8rem", color: "var(--text-dim)" }}>—</span>
        )
    },
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
    {
      header: "Profile",
      cell: (r) => (
        <button
          className="btn btn-outline btn-icon"
          onClick={() => {
            setSelectedUser(r);
            setIsProfileModalOpen(true);
          }}
          title="View Alumni Profile"
          style={{ color: "var(--accent-indigo)" }}
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
          <h1 style={{ fontSize: "1.5rem" }}>Administration → Alumni</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Real-time alumni network and working graduate outcomes from Firestore users collection
          </p>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", background: "rgba(99, 102, 241, 0.1)", padding: "8px 16px", borderRadius: "20px", border: "1px solid rgba(99, 102, 241, 0.2)" }}>
          <RefreshCw size={14} className="animate-spin" style={{ color: "var(--accent-indigo)" }} />
          <span style={{ fontSize: "0.8rem", color: "var(--accent-indigo)", fontWeight: "600" }}>Live Firestore Listener Active</span>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid-4">
        <KpiCard title="Total Alumni" value={stats.totalAlumni.toLocaleString()} growth={+4.8} icon={Briefcase} color="indigo" subtext="Graduated Network" />
        <KpiCard title="Currently Online" value={stats.alumniOnline.toLocaleString()} growth={+2.1} icon={CheckCircle} color="emerald" subtext="Active Alumni" />
        <KpiCard title="Companies Represented" value={stats.alumniCompaniesCount.toLocaleString()} growth={+3.5} icon={Building} color="cyan" subtext="Employing Organizations" />
        <KpiCard title="Departments Represented" value={uniqueDepartments.length.toLocaleString()} growth={+1.8} icon={BookOpen} color="amber" subtext="Fields of Study" />
      </div>

      {/* Main Table Glass Card */}
      <div className="glass-card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
          <h3>Alumni Records ({alumniData.total.toLocaleString()})</h3>
        </div>

        {/* Filters */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: "12px", marginBottom: "16px" }}>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Search Alumni</label>
            <input
              type="text"
              className="form-control"
              placeholder="Name, Company, Designation..."
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
          <div style={{ padding: "30px", textAlign: "center", color: "var(--text-muted)" }}>Loading Alumni...</div>
        ) : (
          <DataTable columns={columns} data={alumniData.items} searchPlaceholder="" />
        )}

        {/* Pagination */}
        <div style={{ marginTop: "16px", display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid var(--border-color)", paddingTop: "14px" }}>
          <div style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Showing <strong>{alumniData.items.length > 0 ? (alumniData.page - 1) * alumniData.pageSize + 1 : 0}</strong> – <strong>{Math.min(alumniData.page * alumniData.pageSize, alumniData.total)}</strong> of <strong>{alumniData.total}</strong> alumni
          </div>
          <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
            <button className="btn btn-outline" disabled={filters.page <= 1} onClick={() => setFilters({ ...filters, page: filters.page - 1 })}>
              Previous
            </button>
            <span style={{ fontSize: "0.85rem" }}>Page {alumniData.page} of {alumniData.totalPages}</span>
            <button className="btn btn-outline" disabled={filters.page >= alumniData.totalPages} onClick={() => setFilters({ ...filters, page: filters.page + 1 })}>
              Next
            </button>
          </div>
        </div>
      </div>

      <UserProfileModal isOpen={isProfileModalOpen} onClose={() => setIsProfileModalOpen(false)} user={selectedUser} />
    </div>
  );
}
