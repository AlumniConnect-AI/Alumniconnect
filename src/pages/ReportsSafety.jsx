import { useState, useEffect } from "react";
import {
    AlertTriangle, Shield, Search, X, Eye, UserX, Ban,
    CheckCircle2, Clock, AlertOctagon, MessageSquare,
} from "lucide-react";
import {
    subscribeToReports, resolveReport, ignoreReport,
    suspendUser, warnUser,
} from "../services/firestoreService";
import LoadingSpinner from "../components/LoadingSpinner";
import "./ReportsSafety.css";

export default function ReportsSafety() {
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [filter, setFilter] = useState("all");
    const [selectedReport, setSelectedReport] = useState(null);
    const [acting, setActing] = useState(false);

    useEffect(() => {
        const unsub = subscribeToReports((data) => {
            setReports(data);
            setLoading(false);
        });
        return unsub;
    }, []);

    const pending = reports.filter((r) => !r.status || r.status === "pending");
    const resolved = reports.filter((r) => r.status === "resolved");
    const warned = reports.filter((r) => r.action === "warn");

    const filtered = reports.filter((r) => {
        const q = search.toLowerCase();
        const matchSearch = !q ||
            (r.reason || "").toLowerCase().includes(q) ||
            (r.reportedUser || r.reportedUserId || "").toLowerCase().includes(q) ||
            (r.reporterName || r.reporterId || "").toLowerCase().includes(q);
        const status = r.status || "pending";
        const matchFilter = filter === "all" || status === filter;
        return matchSearch && matchFilter;
    });

    const handleAction = async (report, action) => {
        setActing(true);
        try {
            if (action === "warn") {
                if (report.reportedUserId) await warnUser(report.reportedUserId);
                await resolveReport(report.id, "warn");
            } else if (action === "suspend") {
                if (report.reportedUserId) await suspendUser(report.reportedUserId);
                await resolveReport(report.id, "suspend");
            } else if (action === "ignore") {
                await ignoreReport(report.id);
            }
        } catch (e) { alert("Action failed: " + e.message); }
        setActing(false);
        setSelectedReport(null);
    };

    if (loading) return <LoadingSpinner message="Loading reports..." />;

    return (
        <div className="reports-page">
            <div className="rp-header animate-fade-in-up">
                <div>
                    <h2 className="rp-title">Reports & Safety Center</h2>
                    <p className="rp-subtitle">Manage user reports and enforce platform safety</p>
                </div>
            </div>

            {/* Quick Stats */}
            <div className="rp-stats stagger">
                <div className="rp-stat animate-fade-in-up">
                    <AlertTriangle size={20} className="rp-stat-icon" style={{ color: "#EF4444" }} />
                    <div><div className="rp-stat-value">{reports.length}</div><div className="rp-stat-label">Total Reports</div></div>
                </div>
                <div className="rp-stat animate-fade-in-up">
                    <Clock size={20} className="rp-stat-icon" style={{ color: "#F59E0B" }} />
                    <div><div className="rp-stat-value">{pending.length}</div><div className="rp-stat-label">Pending</div></div>
                </div>
                <div className="rp-stat animate-fade-in-up">
                    <CheckCircle2 size={20} className="rp-stat-icon" style={{ color: "var(--primary)" }} />
                    <div><div className="rp-stat-value">{resolved.length}</div><div className="rp-stat-label">Resolved</div></div>
                </div>
                <div className="rp-stat animate-fade-in-up">
                    <AlertOctagon size={20} className="rp-stat-icon" style={{ color: "#F97316" }} />
                    <div><div className="rp-stat-value">{warned.length}</div><div className="rp-stat-label">Warns Issued</div></div>
                </div>
            </div>

            {/* Controls */}
            <div className="rp-controls animate-fade-in-up">
                <div className="sv-search-wrap">
                    <Search size={16} className="sv-search-icon" />
                    <input placeholder="Search reports..." value={search} onChange={(e) => setSearch(e.target.value)} className="sv-search-input" />
                </div>
                <div className="sv-tabs">
                    {["all", "pending", "resolved", "ignored"].map((f) => (
                        <button key={f} className={`sv-tab ${filter === f ? "active" : ""}`} onClick={() => setFilter(f)}>
                            {f.charAt(0).toUpperCase() + f.slice(1)}
                        </button>
                    ))}
                </div>
            </div>

            {/* Report Cards */}
            <div className="rp-list stagger">
                {filtered.map((r) => {
                    const status = r.status || "pending";
                    const rawDate = r.createdAt || r.reportedAt;
                    const dateObj = rawDate?.toDate ? rawDate.toDate() : new Date(rawDate);
                    const dateStr = dateObj && !isNaN(dateObj) ? dateObj.toLocaleDateString() : "—";

                    return (
                        <div className={`rp-card animate-fade-in-up rp-card--${status}`} key={r.id}>
                            <div className="rp-card-left">
                                <div className={`rp-card-status-icon ${status}`}>
                                    {status === "pending" ? <Clock size={18} /> : status === "resolved" ? <CheckCircle2 size={18} /> : <Ban size={18} />}
                                </div>
                            </div>
                            <div className="rp-card-body">
                                <div className="rp-card-top-row">
                                    <h3 className="rp-card-title">
                                        Report: {r.reportedUser || r.reportedUserName || r.reportedUserId || "Unknown User"}
                                    </h3>
                                    <span className={`rp-status-badge ${status}`}>{status}</span>
                                </div>
                                <p className="rp-card-reason"><MessageSquare size={13} /> Reason: {r.reason || "No reason provided"}</p>
                                <div className="rp-card-meta">
                                    <span>Reported by: {r.reporterName || r.reporterId || "Anonymous"}</span>
                                    <span>Date: {dateStr}</span>
                                    {r.action && <span>Action: {r.action}</span>}
                                </div>
                            </div>
                            <div className="rp-card-actions">
                                <button className="sv-action-btn sv-view" onClick={() => setSelectedReport(r)} title="View details"><Eye size={15} /></button>
                                {status === "pending" && (
                                    <>
                                        <button className="sv-action-btn rp-warn" onClick={() => handleAction(r, "warn")} disabled={acting} title="Warn user"><AlertOctagon size={15} /></button>
                                        <button className="sv-action-btn sv-remove" onClick={() => handleAction(r, "suspend")} disabled={acting} title="Suspend user"><UserX size={15} /></button>
                                        <button className="sv-action-btn rp-ignore" onClick={() => handleAction(r, "ignore")} disabled={acting} title="Ignore report"><Ban size={15} /></button>
                                    </>
                                )}
                            </div>
                        </div>
                    );
                })}
                {filtered.length === 0 && (
                    <div className="rp-empty"><Shield size={40} strokeWidth={1} /><p>No reports found</p></div>
                )}
            </div>

            {/* Detail Modal */}
            {selectedReport && (
                <div className="jm-modal-overlay" onClick={() => setSelectedReport(null)}>
                    <div className="jm-modal animate-scale-in" onClick={(e) => e.stopPropagation()}>
                        <button className="jm-modal-close" onClick={() => setSelectedReport(null)}><X size={18} /></button>
                        <div className="jm-modal-icon" style={{ background: "rgba(239,68,68,0.1)", color: "#EF4444" }}><AlertTriangle size={24} /></div>
                        <h3 className="jm-modal-title">Report Details</h3>
                        <div className="jm-modal-grid">
                            <div className="jm-modal-item"><span className="jm-modal-label">Reported User</span><span className="jm-modal-value">{selectedReport.reportedUser || selectedReport.reportedUserName || selectedReport.reportedUserId || "Unknown"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Reporter</span><span className="jm-modal-value">{selectedReport.reporterName || selectedReport.reporterId || "Anonymous"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Reason</span><span className="jm-modal-value">{selectedReport.reason || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Status</span><span className="jm-modal-value" style={{ textTransform: "capitalize" }}>{selectedReport.status || "pending"}</span></div>
                            {selectedReport.action && <div className="jm-modal-item"><span className="jm-modal-label">Action Taken</span><span className="jm-modal-value" style={{ textTransform: "capitalize" }}>{selectedReport.action}</span></div>}
                        </div>
                        {(selectedReport.status || "pending") === "pending" && (
                            <div className="rp-modal-actions">
                                <button className="rp-modal-btn rp-modal-warn" onClick={() => handleAction(selectedReport, "warn")} disabled={acting}><AlertOctagon size={15} /> Warn User</button>
                                <button className="rp-modal-btn rp-modal-suspend" onClick={() => handleAction(selectedReport, "suspend")} disabled={acting}><UserX size={15} /> Suspend</button>
                                <button className="rp-modal-btn rp-modal-ignore" onClick={() => handleAction(selectedReport, "ignore")} disabled={acting}><Ban size={15} /> Ignore</button>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
}
