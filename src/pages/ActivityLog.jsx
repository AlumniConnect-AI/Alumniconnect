import { useState, useEffect, useMemo } from "react";
import {
    ScrollText, UserPlus, Briefcase, CalendarDays, AlertTriangle,
    ShieldCheck, Filter, Clock,
} from "lucide-react";
import { fetchActivityLog } from "../services/firestoreService";
import LoadingSpinner from "../components/LoadingSpinner";
import "./ActivityLog.css";

const typeConfig = {
    registration: { icon: UserPlus, color: "#2BB673", bg: "rgba(43,182,115,0.1)", label: "Registration" },
    job: { icon: Briefcase, color: "#3B82F6", bg: "rgba(59,130,246,0.1)", label: "Job Posted" },
    event: { icon: CalendarDays, color: "#8B5CF6", bg: "rgba(139,92,246,0.1)", label: "Event Created" },
    report: { icon: AlertTriangle, color: "#EF4444", bg: "rgba(239,68,68,0.1)", label: "Report" },
    role_change: { icon: ShieldCheck, color: "#F59E0B", bg: "rgba(245,158,11,0.1)", label: "Role Change" },
};

export default function ActivityLog() {
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState("all");

    useEffect(() => {
        (async () => {
            try { setItems(await fetchActivityLog()); }
            catch (e) { console.error("ActivityLog:", e); }
            finally { setLoading(false); }
        })();
    }, []);

    const filtered = useMemo(() => {
        if (filter === "all") return items;
        return items.filter((i) => i.type === filter);
    }, [items, filter]);

    const typeCounts = useMemo(() => {
        const counts = { registration: 0, job: 0, event: 0, report: 0 };
        items.forEach((i) => { if (counts[i.type] !== undefined) counts[i.type]++; });
        return counts;
    }, [items]);

    if (loading) return <LoadingSpinner message="Loading activity log..." />;

    return (
        <div className="activity-page">
            <div className="al-header animate-fade-in-up">
                <div>
                    <h2 className="al-title">Activity Log</h2>
                    <p className="al-subtitle">{items.length} total activities tracked across the platform</p>
                </div>
                <div className="al-badge"><ScrollText size={14} /> Audit Trail</div>
            </div>

            {/* Quick Counts */}
            <div className="al-counts stagger">
                {Object.entries(typeConfig).filter(([k]) => k !== "role_change").map(([key, cfg]) => (
                    <div className="al-count-card animate-fade-in-up" key={key} onClick={() => setFilter(key === filter ? "all" : key)} style={{ cursor: "pointer" }}>
                        <div className="al-count-icon" style={{ background: cfg.bg, color: cfg.color }}><cfg.icon size={18} /></div>
                        <div className="al-count-value">{typeCounts[key] || 0}</div>
                        <div className="al-count-label">{cfg.label}s</div>
                    </div>
                ))}
            </div>

            {/* Filter Tabs */}
            <div className="al-filters animate-fade-in-up">
                <Filter size={16} className="al-filter-icon" />
                {["all", "registration", "job", "event", "report"].map((f) => (
                    <button key={f} className={`sv-tab ${filter === f ? "active" : ""}`} onClick={() => setFilter(f)}>
                        {f === "all" ? "All" : typeConfig[f]?.label || f}
                    </button>
                ))}
            </div>

            {/* Timeline */}
            <div className="al-timeline stagger">
                {filtered.slice(0, 100).map((item, i) => {
                    const cfg = typeConfig[item.type] || typeConfig.registration;
                    const Icon = cfg.icon;
                    const dateStr = item.date.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
                    const timeStr = item.date.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit" });

                    return (
                        <div className="al-item animate-fade-in-up" key={i}>
                            <div className="al-item-line">
                                <div className="al-item-dot" style={{ background: cfg.color }} />
                                {i < filtered.length - 1 && <div className="al-item-connector" />}
                            </div>
                            <div className="al-item-content">
                                <div className="al-item-header">
                                    <div className="al-item-icon" style={{ background: cfg.bg, color: cfg.color }}><Icon size={16} /></div>
                                    <span className="al-item-type-badge" style={{ background: cfg.bg, color: cfg.color }}>{cfg.label}</span>
                                    <span className="al-item-time"><Clock size={12} /> {dateStr} · {timeStr}</span>
                                </div>
                                <h4 className="al-item-title">{item.title}</h4>
                                <p className="al-item-detail">{item.detail}</p>
                            </div>
                        </div>
                    );
                })}
                {filtered.length === 0 && (
                    <div className="rp-empty"><ScrollText size={40} strokeWidth={1} /><p>No activities found</p></div>
                )}
            </div>
        </div>
    );
}
