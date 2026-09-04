import { useState, useEffect } from "react";
import {
    ShieldCheck, ShieldAlert, Search, X, UserX, Eye, Users as UsersIcon,
    CheckCircle2, AlertTriangle, Mail,
} from "lucide-react";
import { subscribeToUsers, removeStaffRole } from "../services/firestoreService";
import LoadingSpinner from "../components/LoadingSpinner";
import "./StaffVerification.css";

export default function StaffVerification() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [filter, setFilter] = useState("all");
    const [selectedUser, setSelectedUser] = useState(null);
    const [confirmRemove, setConfirmRemove] = useState(null);
    const [removing, setRemoving] = useState(false);

    useEffect(() => {
        const unsub = subscribeToUsers((data) => {
            setUsers(data);
            setLoading(false);
        });
        return unsub;
    }, []);

    const staffUsers = users.filter((u) => u.role === "staff");
    const verified = staffUsers.filter((u) => u.isVerified || u.verified);
    const unverified = staffUsers.filter((u) => !u.isVerified && !u.verified);

    const filtered = staffUsers.filter((u) => {
        const q = search.toLowerCase();
        const matchSearch = !q || (u.name || "").toLowerCase().includes(q) || (u.email || "").toLowerCase().includes(q);
        const isVer = u.isVerified || u.verified;
        const matchFilter = filter === "all" || (filter === "verified" && isVer) || (filter === "unverified" && !isVer);
        return matchSearch && matchFilter;
    });

    const handleRemoveRole = async (userId) => {
        setRemoving(true);
        try { await removeStaffRole(userId); } catch (e) { alert("Failed: " + e.message); }
        setRemoving(false);
        setConfirmRemove(null);
    };

    if (loading) return <LoadingSpinner message="Loading staff data..." />;

    return (
        <div className="staff-page">
            <div className="sv-header animate-fade-in-up">
                <div>
                    <h2 className="sv-title">Staff Verification Control</h2>
                    <p className="sv-subtitle">Manage staff accounts and verification status</p>
                </div>
            </div>

            {/* Quick Stats */}
            <div className="sv-stats stagger">
                <div className="sv-stat animate-fade-in-up">
                    <UsersIcon size={20} className="sv-stat-icon" />
                    <div><div className="sv-stat-value">{staffUsers.length}</div><div className="sv-stat-label">Total Staff</div></div>
                </div>
                <div className="sv-stat animate-fade-in-up">
                    <CheckCircle2 size={20} className="sv-stat-icon" style={{ color: "var(--primary)" }} />
                    <div><div className="sv-stat-value">{verified.length}</div><div className="sv-stat-label">Verified</div></div>
                </div>
                <div className="sv-stat animate-fade-in-up">
                    <AlertTriangle size={20} className="sv-stat-icon" style={{ color: "#F59E0B" }} />
                    <div><div className="sv-stat-value">{unverified.length}</div><div className="sv-stat-label">Unverified</div></div>
                </div>
            </div>

            {/* Controls */}
            <div className="sv-controls animate-fade-in-up">
                <div className="sv-search-wrap">
                    <Search size={16} className="sv-search-icon" />
                    <input placeholder="Search staff members..." value={search} onChange={(e) => setSearch(e.target.value)} className="sv-search-input" />
                </div>
                <div className="sv-tabs">
                    {["all", "verified", "unverified"].map((f) => (
                        <button key={f} className={`sv-tab ${filter === f ? "active" : ""}`} onClick={() => setFilter(f)}>
                            {f.charAt(0).toUpperCase() + f.slice(1)}
                        </button>
                    ))}
                </div>
            </div>

            {/* Staff Table */}
            <div className="sv-table-wrap animate-fade-in-up">
                <table className="sv-table">
                    <thead>
                        <tr><th>Staff Member</th><th>Email</th><th>Department</th><th>Status</th><th>Verification Code</th><th>Actions</th></tr>
                    </thead>
                    <tbody>
                        {filtered.map((u) => {
                            const isVer = u.isVerified || u.verified;
                            return (
                                <tr key={u.id}>
                                    <td>
                                        <div className="sv-user-cell">
                                            <div className="sv-avatar">{(u.name || "?").charAt(0).toUpperCase()}</div>
                                            <span className="sv-user-name">{u.name || "Unknown"}</span>
                                        </div>
                                    </td>
                                    <td className="sv-email">{u.email || "—"}</td>
                                    <td>{u.department || "N/A"}</td>
                                    <td>
                                        <span className={`sv-status-badge ${isVer ? "verified" : "unverified"}`}>
                                            {isVer ? <><CheckCircle2 size={12} /> Verified</> : <><AlertTriangle size={12} /> Unverified</>}
                                        </span>
                                    </td>
                                    <td className="sv-code">{u.verificationCode || u.empCode || "—"}</td>
                                    <td>
                                        <div className="sv-actions">
                                            <button className="sv-action-btn sv-view" onClick={() => setSelectedUser(u)} title="View"><Eye size={15} /></button>
                                            <button className="sv-action-btn sv-remove" onClick={() => setConfirmRemove(u)} title="Remove staff role"><UserX size={15} /></button>
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                        {filtered.length === 0 && (
                            <tr><td colSpan={6} className="sv-empty">No staff members found</td></tr>
                        )}
                    </tbody>
                </table>
            </div>

            {/* Detail Modal */}
            {selectedUser && (
                <div className="jm-modal-overlay" onClick={() => setSelectedUser(null)}>
                    <div className="jm-modal animate-scale-in" onClick={(e) => e.stopPropagation()}>
                        <button className="jm-modal-close" onClick={() => setSelectedUser(null)}><X size={18} /></button>
                        <div className="jm-modal-icon" style={{ background: "rgba(139,92,246,0.1)", color: "#8B5CF6" }}><ShieldCheck size={24} /></div>
                        <h3 className="jm-modal-title">{selectedUser.name || "Unknown"}</h3>
                        <p className="jm-modal-company">Staff Member</p>
                        <div className="jm-modal-grid">
                            <div className="jm-modal-item"><span className="jm-modal-label">Email</span><span className="jm-modal-value">{selectedUser.email || "—"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Department</span><span className="jm-modal-value">{selectedUser.department || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Status</span><span className="jm-modal-value">{(selectedUser.isVerified || selectedUser.verified) ? "Verified" : "Unverified"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Verification Code</span><span className="jm-modal-value">{selectedUser.verificationCode || selectedUser.empCode || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Account Status</span><span className="jm-modal-value">{selectedUser.status || "active"}</span></div>
                        </div>
                    </div>
                </div>
            )}

            {/* Remove Confirmation */}
            {confirmRemove && (
                <div className="jm-modal-overlay" onClick={() => !removing && setConfirmRemove(null)}>
                    <div className="jm-confirm animate-scale-in" onClick={(e) => e.stopPropagation()}>
                        <div className="jm-confirm-icon"><ShieldAlert size={28} /></div>
                        <h3>Remove Staff Role?</h3>
                        <p>This will change <strong>{confirmRemove.name || "this user"}</strong>'s role from Staff to Alumni. They will lose staff privileges.</p>
                        <div className="jm-confirm-actions">
                            <button className="jm-confirm-cancel" onClick={() => setConfirmRemove(null)} disabled={removing}>Cancel</button>
                            <button className="jm-confirm-delete" onClick={() => handleRemoveRole(confirmRemove.id)} disabled={removing}>
                                {removing ? <span className="login-spinner" style={{ width: 16, height: 16 }} /> : <><UserX size={15} /> Remove Role</>}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
