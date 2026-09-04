import { useState, useMemo, useEffect } from "react";
import {
    Users, Search, ChevronDown, ChevronUp, Download, Eye, X,
    UserX, UserCheck, ShieldCheck, Heart, ArrowUpDown,
} from "lucide-react";
import {
    subscribeToUsers, suspendUser, activateUser, updateUserRole,
} from "../services/firestoreService";
import LoadingSpinner from "../components/LoadingSpinner";
import "./UserManagement.css";

const PAGE_SIZE = 12;
const ROLES = ["all", "student", "alumni", "staff"];

export default function UserManagement() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [roleFilter, setRoleFilter] = useState("all");
    const [deptFilter, setDeptFilter] = useState("");
    const [batchFilter, setBatchFilter] = useState("");
    const [sortField, setSortField] = useState("name");
    const [sortDir, setSortDir] = useState("asc");
    const [page, setPage] = useState(1);
    const [selectedUser, setSelectedUser] = useState(null);
    const [acting, setActing] = useState(false);

    useEffect(() => {
        const unsub = subscribeToUsers((data) => { setUsers(data); setLoading(false); });
        return unsub;
    }, []);

    const departments = useMemo(() => [...new Set(users.map((u) => u.department).filter(Boolean))].sort(), [users]);
    const batches = useMemo(() => [...new Set(users.map((u) => u.batch).filter(Boolean))].sort(), [users]);

    const roleCounts = useMemo(() => {
        const c = { all: users.length, student: 0, alumni: 0, staff: 0 };
        users.forEach((u) => { if (c[u.role] !== undefined) c[u.role]++; });
        return c;
    }, [users]);

    const filtered = useMemo(() => {
        const q = search.toLowerCase();
        return users
            .filter((u) => {
                if (roleFilter !== "all" && u.role !== roleFilter) return false;
                if (deptFilter && u.department !== deptFilter) return false;
                if (batchFilter && u.batch !== batchFilter) return false;
                if (q && !(u.name || "").toLowerCase().includes(q) && !(u.email || "").toLowerCase().includes(q)) return false;
                return true;
            })
            .sort((a, b) => {
                const va = (a[sortField] || "").toString().toLowerCase();
                const vb = (b[sortField] || "").toString().toLowerCase();
                return sortDir === "asc" ? va.localeCompare(vb) : vb.localeCompare(va);
            });
    }, [users, search, roleFilter, deptFilter, batchFilter, sortField, sortDir]);

    const totalPages = Math.ceil(filtered.length / PAGE_SIZE);
    const pageData = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

    const toggleSort = (field) => {
        if (sortField === field) setSortDir(sortDir === "asc" ? "desc" : "asc");
        else { setSortField(field); setSortDir("asc"); }
    };

    const handleSuspend = async (u) => {
        setActing(true);
        try {
            if (u.status === "suspended") await activateUser(u.id);
            else await suspendUser(u.id);
        } catch (e) { alert("Failed: " + e.message); }
        setActing(false);
    };

    const handleResetRole = async (u) => {
        if (u.role === "staff") { alert("Cannot reset locked Staff role from here. Use Staff Verification page."); return; }
        setActing(true);
        try { await updateUserRole(u.id, "alumni"); } catch (e) { alert("Failed: " + e.message); }
        setActing(false);
    };

    const exportCSV = () => {
        const header = ["Name", "Email", "Role", "Department", "Batch", "Status", "Mentor"];
        const rows = filtered.map((u) => [
            u.name || "", u.email || "", u.role || "", u.department || "", u.batch || "",
            u.status || "active", u.availableForMentoring ? "Yes" : "No",
        ]);
        const csv = [header, ...rows].map((r) => r.map((c) => `"${c}"`).join(",")).join("\n");
        const blob = new Blob([csv], { type: "text/csv" });
        const a = document.createElement("a"); a.href = URL.createObjectURL(blob);
        a.download = `alumni_${new Date().toISOString().slice(0, 10)}.csv`; a.click();
    };

    if (loading) return <LoadingSpinner message="Loading users..." />;

    return (
        <div className="um-page">
            <div className="um-header animate-fade-in-up">
                <div>
                    <h2 className="um-title">User Management</h2>
                    <p className="um-subtitle">{users.length} total users · {roleCounts.student} students · {roleCounts.alumni} alumni · {roleCounts.staff} staff</p>
                </div>
                <button className="um-export-btn" onClick={exportCSV}><Download size={15} /> Export CSV</button>
            </div>

            {/* Role Tabs */}
            <div className="um-role-tabs animate-fade-in-up">
                {ROLES.map((r) => (
                    <button key={r} className={`um-role-tab ${roleFilter === r ? "active" : ""}`} onClick={() => { setRoleFilter(r); setPage(1); }}>
                        {r === "all" ? "All" : r.charAt(0).toUpperCase() + r.slice(1)}
                        <span className="um-role-count">{roleCounts[r]}</span>
                    </button>
                ))}
            </div>

            {/* Filters */}
            <div className="um-filters animate-fade-in-up">
                <div className="um-search-wrap">
                    <Search size={16} className="um-search-icon" />
                    <input placeholder="Search by name or email..." value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} className="um-search" />
                </div>
                <select className="um-select" value={deptFilter} onChange={(e) => { setDeptFilter(e.target.value); setPage(1); }}>
                    <option value="">All Departments</option>{departments.map((d) => <option key={d}>{d}</option>)}
                </select>
                <select className="um-select" value={batchFilter} onChange={(e) => { setBatchFilter(e.target.value); setPage(1); }}>
                    <option value="">All Batches</option>{batches.map((b) => <option key={b}>{b}</option>)}
                </select>
            </div>

            {/* Table */}
            <div className="um-table-wrap animate-fade-in-up">
                <table className="um-table">
                    <thead>
                        <tr>
                            <th onClick={() => toggleSort("name")} className="um-sortable">Name <ArrowUpDown size={12} /></th>
                            <th>Email</th>
                            <th onClick={() => toggleSort("role")} className="um-sortable">Role <ArrowUpDown size={12} /></th>
                            <th>Department</th>
                            <th>Status</th>
                            <th>Mentor</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {pageData.map((u) => (
                            <tr key={u.id}>
                                <td>
                                    <div className="um-user-cell">
                                        <div className="um-avatar">{(u.name || "?").charAt(0).toUpperCase()}</div>
                                        <span className="um-user-name">{u.name || "Unknown"}</span>
                                    </div>
                                </td>
                                <td className="um-email">{u.email || "—"}</td>
                                <td><span className={`um-role-badge um-role-${u.role || "alumni"}`}>{u.role || "alumni"}</span></td>
                                <td>{u.department || "N/A"}</td>
                                <td><span className={`um-status-badge ${u.status === "suspended" ? "suspended" : "active"}`}>{u.status || "active"}</span></td>
                                <td>{u.availableForMentoring ? <Heart size={14} className="um-mentor-icon" /> : "—"}</td>
                                <td>
                                    <div className="um-actions">
                                        <button className="sv-action-btn sv-view" onClick={() => setSelectedUser(u)} title="View"><Eye size={15} /></button>
                                        <button className="sv-action-btn um-suspend" onClick={() => handleSuspend(u)} disabled={acting} title={u.status === "suspended" ? "Activate" : "Suspend"}>
                                            {u.status === "suspended" ? <UserCheck size={15} /> : <UserX size={15} />}
                                        </button>
                                        {u.role !== "staff" && (
                                            <button className="sv-action-btn rp-ignore" onClick={() => handleResetRole(u)} disabled={acting} title="Reset role to alumni"><ShieldCheck size={15} /></button>
                                        )}
                                    </div>
                                </td>
                            </tr>
                        ))}
                        {pageData.length === 0 && <tr><td colSpan={7} className="sv-empty">No users found</td></tr>}
                    </tbody>
                </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
                <div className="um-pagination animate-fade-in">
                    <span className="um-page-info">Page {page} of {totalPages} · {filtered.length} results</span>
                    <div className="um-page-btns">
                        <button disabled={page <= 1} onClick={() => setPage(page - 1)}>← Prev</button>
                        <button disabled={page >= totalPages} onClick={() => setPage(page + 1)}>Next →</button>
                    </div>
                </div>
            )}

            {/* Modal */}
            {selectedUser && (
                <div className="jm-modal-overlay" onClick={() => setSelectedUser(null)}>
                    <div className="jm-modal animate-scale-in" onClick={(e) => e.stopPropagation()}>
                        <button className="jm-modal-close" onClick={() => setSelectedUser(null)}><X size={18} /></button>
                        <div className="jm-modal-icon" style={{ background: "var(--primary-bg)", color: "var(--primary)" }}><Users size={24} /></div>
                        <h3 className="jm-modal-title">{selectedUser.name || "Unknown"}</h3>
                        <p className="jm-modal-company">{selectedUser.role || "alumni"}</p>
                        <div className="jm-modal-grid">
                            <div className="jm-modal-item"><span className="jm-modal-label">Email</span><span className="jm-modal-value">{selectedUser.email || "—"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Department</span><span className="jm-modal-value">{selectedUser.department || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Batch</span><span className="jm-modal-value">{selectedUser.batch || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Company</span><span className="jm-modal-value">{selectedUser.company || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Designation</span><span className="jm-modal-value">{selectedUser.designation || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Status</span><span className="jm-modal-value" style={{ textTransform: "capitalize" }}>{selectedUser.status || "active"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Mentor Available</span><span className="jm-modal-value">{selectedUser.availableForMentoring ? "Yes ❤️" : "No"}</span></div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
