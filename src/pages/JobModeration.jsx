import { useState, useEffect, useMemo } from "react";
import {
    Briefcase, Search, Trash2, Eye, X, MapPin, DollarSign,
    User, Calendar, Building2, CheckCircle2, ShieldCheck, Filter,
} from "lucide-react";
import {
    subscribeToJobs, deleteJob, verifyJob, computeTopCompanies,
} from "../services/firestoreService";
import LoadingSpinner from "../components/LoadingSpinner";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import "./JobModeration.css";

export default function JobModeration() {
    const [jobs, setJobs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [filter, setFilter] = useState("all");
    const [selectedJob, setSelectedJob] = useState(null);
    const [confirmDelete, setConfirmDelete] = useState(null);
    const [deleting, setDeleting] = useState(false);
    const [verifying, setVerifying] = useState(null);

    useEffect(() => {
        const unsub = subscribeToJobs((data) => { setJobs(data); setLoading(false); });
        return unsub;
    }, []);

    const topCompanies = useMemo(() => computeTopCompanies(jobs, 6), [jobs]);
    const verifiedCount = jobs.filter((j) => j.verified).length;
    const unverifiedCount = jobs.length - verifiedCount;

    const filtered = useMemo(() => {
        const q = search.toLowerCase();
        return jobs.filter((j) => {
            const matchQ = !q ||
                (j.title || "").toLowerCase().includes(q) ||
                (j.company || "").toLowerCase().includes(q);
            const matchF = filter === "all" ||
                (filter === "verified" && j.verified) ||
                (filter === "unverified" && !j.verified);
            return matchQ && matchF;
        });
    }, [jobs, search, filter]);

    const handleDelete = async (jobId) => {
        setDeleting(true);
        try { await deleteJob(jobId); } catch (e) { alert("Delete failed: " + e.message); }
        setDeleting(false);
        setConfirmDelete(null);
    };

    const handleVerify = async (jobId) => {
        setVerifying(jobId);
        try { await verifyJob(jobId); } catch (e) { alert("Verify failed: " + e.message); }
        setVerifying(null);
    };

    if (loading) return <LoadingSpinner message="Loading jobs..." />;

    return (
        <div className="jm-page">
            <div className="jm-header animate-fade-in-up">
                <div>
                    <h2 className="jm-title">Job Moderation</h2>
                    <p className="jm-subtitle">{jobs.length} jobs · {verifiedCount} verified · {unverifiedCount} pending</p>
                </div>
            </div>

            {/* Top Companies Card */}
            {topCompanies.length > 0 && (
                <div className="jm-top-companies animate-fade-in-up">
                    <h3 className="jm-top-companies-title"><Building2 size={16} /> Most Hiring Companies</h3>
                    <div className="jm-top-chart">
                        <ResponsiveContainer width="100%" height={140}>
                            <BarChart data={topCompanies} layout="vertical" margin={{ left: 80, right: 20, top: 5, bottom: 5 }}>
                                <XAxis type="number" hide />
                                <YAxis type="category" dataKey="name" tick={{ fontSize: 12, fill: "#6B7280" }} width={75} />
                                <Tooltip contentStyle={{ border: "none", borderRadius: 8, fontSize: 13 }} />
                                <Bar dataKey="jobs" fill="#2BB673" radius={[0, 4, 4, 0]} barSize={16} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            )}

            {/* Controls */}
            <div className="jm-controls animate-fade-in-up">
                <div className="sv-search-wrap">
                    <Search size={16} className="sv-search-icon" />
                    <input placeholder="Search jobs..." value={search} onChange={(e) => setSearch(e.target.value)} className="sv-search-input" />
                </div>
                <div className="sv-tabs">
                    <Filter size={14} style={{ color: "var(--text-muted)" }} />
                    {["all", "verified", "unverified"].map((f) => (
                        <button key={f} className={`sv-tab ${filter === f ? "active" : ""}`} onClick={() => setFilter(f)}>
                            {f.charAt(0).toUpperCase() + f.slice(1)}
                        </button>
                    ))}
                </div>
            </div>

            {/* Job Grid */}
            <div className="jm-grid stagger">
                {filtered.map((j) => {
                    const rawDate = j.postedAt || j.createdAt;
                    const dateObj = rawDate?.toDate ? rawDate.toDate() : new Date(rawDate);
                    const dateStr = dateObj && !isNaN(dateObj) ? dateObj.toLocaleDateString() : "—";
                    const posterRole = j.postedByRole || (j.postedBy?.includes("staff") ? "staff" : "alumni");

                    return (
                        <div className={`jm-card animate-fade-in-up ${j.verified ? "jm-card--verified" : ""}`} key={j.id}>
                            <div className="jm-card-top">
                                <div className="jm-card-icon"><Briefcase size={20} /></div>
                                <div className="jm-card-badges">
                                    {j.verified && <span className="jm-verified-badge"><CheckCircle2 size={12} /> Verified</span>}
                                    <span className={`jm-poster-role jm-poster-${posterRole}`}>{posterRole}</span>
                                </div>
                            </div>
                            <h3 className="jm-card-title">{j.title || "Untitled"}</h3>
                            <p className="jm-card-company"><Building2 size={14} />{j.company || "Unknown"}</p>
                            <div className="jm-card-meta">
                                <span><MapPin size={13} />{j.location || "N/A"}</span>
                                <span><Calendar size={13} />{dateStr}</span>
                            </div>
                            {j.salary && <p className="jm-card-salary"><DollarSign size={13} />{j.salary}</p>}
                            <div className="jm-card-actions">
                                <button className="jm-action-btn jm-action-view" onClick={() => setSelectedJob(j)}><Eye size={15} /> View</button>
                                {!j.verified && (
                                    <button className="jm-action-btn jm-action-verify" onClick={() => handleVerify(j.id)} disabled={verifying === j.id}>
                                        <ShieldCheck size={15} /> {verifying === j.id ? "..." : "Verify"}
                                    </button>
                                )}
                                <button className="jm-action-btn jm-action-delete" onClick={() => setConfirmDelete(j.id)}><Trash2 size={15} /></button>
                            </div>
                        </div>
                    );
                })}
                {filtered.length === 0 && <p className="jm-empty">No jobs found</p>}
            </div>

            {/* Detail Modal */}
            {selectedJob && (
                <div className="jm-modal-overlay" onClick={() => setSelectedJob(null)}>
                    <div className="jm-modal animate-scale-in" onClick={(e) => e.stopPropagation()}>
                        <button className="jm-modal-close" onClick={() => setSelectedJob(null)}><X size={18} /></button>
                        <div className="jm-modal-icon"><Briefcase size={24} /></div>
                        <h3 className="jm-modal-title">{selectedJob.title || "Untitled"}</h3>
                        <p className="jm-modal-company">{selectedJob.company || "Unknown"}</p>
                        <div className="jm-modal-grid">
                            <div className="jm-modal-item"><span className="jm-modal-label">Location</span><span className="jm-modal-value">{selectedJob.location || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Type</span><span className="jm-modal-value">{selectedJob.type || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Salary</span><span className="jm-modal-value">{selectedJob.salary || "Not specified"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Posted By</span><span className="jm-modal-value">{selectedJob.postedBy || "Unknown"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Verified</span><span className="jm-modal-value">{selectedJob.verified ? "✅ Yes" : "❌ No"}</span></div>
                        </div>
                        {selectedJob.description && <p className="jm-modal-desc">{selectedJob.description}</p>}
                    </div>
                </div>
            )}

            {/* Delete Confirm */}
            {confirmDelete && (
                <div className="jm-modal-overlay" onClick={() => !deleting && setConfirmDelete(null)}>
                    <div className="jm-confirm animate-scale-in" onClick={(e) => e.stopPropagation()}>
                        <div className="jm-confirm-icon"><Trash2 size={28} /></div>
                        <h3>Delete this job?</h3>
                        <p>This action cannot be undone.</p>
                        <div className="jm-confirm-actions">
                            <button className="jm-confirm-cancel" onClick={() => setConfirmDelete(null)} disabled={deleting}>Cancel</button>
                            <button className="jm-confirm-delete" onClick={() => handleDelete(confirmDelete)} disabled={deleting}>
                                {deleting ? "Deleting..." : <><Trash2 size={15} /> Delete</>}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
