import { useEffect, useState } from "react";
import {
    Users,
    Briefcase,
    CalendarDays,
    TrendingUp,
    ArrowUpRight,
    Activity,
    UserPlus,
    Clock,
    AlertTriangle,
    MessageSquare,
    GraduationCap,
    ShieldCheck,
    UserCheck,
} from "lucide-react";
import {
    AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
    ResponsiveContainer, BarChart, Bar,
} from "recharts";
import { fetchDashboardStats, computeUserGrowth } from "../services/firestoreService";
import LoadingSpinner from "../components/LoadingSpinner";
import AiHubPanel from "../components/AiHubPanel";
import "./Dashboard.css";

const colorMap = {
    green: { bg: "rgba(43,182,115,0.1)", fg: "#2BB673" },
    blue: { bg: "rgba(59,130,246,0.1)", fg: "#3B82F6" },
    purple: { bg: "rgba(139,92,246,0.1)", fg: "#8B5CF6" },
    orange: { bg: "rgba(245,158,11,0.1)", fg: "#F59E0B" },
    red: { bg: "rgba(239,68,68,0.1)", fg: "#EF4444" },
    cyan: { bg: "rgba(6,182,212,0.1)", fg: "#06B6D4" },
};

export default function Dashboard() {
    const [loading, setLoading] = useState(true);
    const [data, setData] = useState(null);

    useEffect(() => {
        let cancelled = false;
        (async () => {
            try {
                const result = await fetchDashboardStats();
                if (!cancelled) setData(result);
            } catch (err) { console.error("Dashboard:", err); }
            finally { if (!cancelled) setLoading(false); }
        })();
        return () => { cancelled = true; };
    }, []);

    if (loading) return <LoadingSpinner message="Loading dashboard..." />;
    if (!data) return <p style={{ padding: 40, textAlign: "center", color: "var(--text-muted)" }}>Failed to load data.</p>;

    const {
        totalUsers, studentCount, alumniCount, staffCount,
        totalJobs, totalEvents, pendingReports, messageCount,
        recentUsers, recentJobs, upcomingEvents, users, jobs, events,
    } = data;

    const growthData = computeUserGrowth(users);

    const engagementByMonth = {};
    jobs.forEach((j) => {
        const raw = j.postedAt || j.createdAt;
        if (!raw) return;
        const date = raw.toDate ? raw.toDate() : new Date(raw);
        if (isNaN(date.getTime())) return;
        const m = date.toLocaleDateString("en-US", { month: "short" });
        if (!engagementByMonth[m]) engagementByMonth[m] = { month: m, jobs: 0, events: 0 };
        engagementByMonth[m].jobs += 1;
    });
    events.forEach((e) => {
        const raw = e.date || e.createdAt;
        if (!raw) return;
        const date = raw.toDate ? raw.toDate() : new Date(raw);
        if (isNaN(date.getTime())) return;
        const m = date.toLocaleDateString("en-US", { month: "short" });
        if (!engagementByMonth[m]) engagementByMonth[m] = { month: m, jobs: 0, events: 0 };
        engagementByMonth[m].events += 1;
    });
    const engagementData = Object.values(engagementByMonth).slice(-6);

    const stats = [
        { label: "Total Users", value: totalUsers.toLocaleString(), sub: `${studentCount} students · ${alumniCount} alumni · ${staffCount} staff`, icon: Users, color: "green" },
        { label: "Job Postings", value: totalJobs.toLocaleString(), icon: Briefcase, color: "blue" },
        { label: "Events Created", value: totalEvents.toLocaleString(), icon: CalendarDays, color: "purple" },
        { label: "Reports Pending", value: pendingReports.toLocaleString(), icon: AlertTriangle, color: "red" },
        { label: "Messages Sent", value: messageCount.toLocaleString(), icon: MessageSquare, color: "cyan" },
        { label: "Engagement Rate", value: totalUsers > 0 ? `${Math.min(Math.round(((totalJobs + totalEvents) / totalUsers) * 100), 100)}%` : "0%", icon: TrendingUp, color: "orange" },
    ];

    return (
        <div className="dashboard">
            {/* Stat Cards */}
            <div className="dash-stats stagger">
                {stats.map((s, i) => {
                    const c = colorMap[s.color];
                    return (
                        <div className="dash-stat-card animate-fade-in-up" key={i}>
                            <div className="dash-stat-top">
                                <div className="dash-stat-icon" style={{ background: c.bg, color: c.fg }}>
                                    <s.icon size={20} strokeWidth={1.8} />
                                </div>
                                <span className="dash-stat-change up"><ArrowUpRight size={14} />Live</span>
                            </div>
                            <div className="dash-stat-value">{s.value}</div>
                            <div className="dash-stat-label">{s.label}</div>
                            {s.sub && <div className="dash-stat-sub">{s.sub}</div>}
                        </div>
                    );
                })}
            </div>

            {/* Role Breakdown Bar */}
            <div className="dash-role-bar animate-fade-in-up">
                <div className="dash-role-segment" style={{ flex: studentCount || 1, background: "#3B82F6" }} title={`Students: ${studentCount}`} />
                <div className="dash-role-segment" style={{ flex: alumniCount || 1, background: "#2BB673" }} title={`Alumni: ${alumniCount}`} />
                <div className="dash-role-segment" style={{ flex: staffCount || 1, background: "#8B5CF6" }} title={`Staff: ${staffCount}`} />
            </div>
            <div className="dash-role-legend animate-fade-in">
                <span><span className="dash-legend-dot" style={{ background: "#3B82F6" }} /> Students ({studentCount})</span>
                <span><span className="dash-legend-dot" style={{ background: "#2BB673" }} /> Alumni ({alumniCount})</span>
                <span><span className="dash-legend-dot" style={{ background: "#8B5CF6" }} /> Staff ({staffCount})</span>
            </div>

            {/* AI Intelligence Hub Panel */}
            <AiHubPanel />

            {/* Charts Row */}
            <div className="dash-charts stagger">
                <div className="dash-card dash-card--wide animate-fade-in-up">
                    <div className="dash-card-header">
                        <div>
                            <h3 className="dash-card-title">User Growth</h3>
                            <p className="dash-card-subtitle">Registration trend over time</p>
                        </div>
                        <div className="dash-badge"><Activity size={14} />Live</div>
                    </div>
                    <div className="dash-chart-wrap">
                        {growthData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={260}>
                                <AreaChart data={growthData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                                    <defs>
                                        <linearGradient id="growthGrad" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#2BB673" stopOpacity={0.25} />
                                            <stop offset="95%" stopColor="#2BB673" stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                                    <XAxis dataKey="month" tick={{ fontSize: 12, fill: "#9CA3AF" }} axisLine={false} tickLine={false} />
                                    <YAxis tick={{ fontSize: 12, fill: "#9CA3AF" }} axisLine={false} tickLine={false} />
                                    <Tooltip contentStyle={{ border: "none", borderRadius: 10, boxShadow: "0 4px 14px rgba(0,0,0,0.08)", fontSize: 13 }} />
                                    <Area type="monotone" dataKey="users" stroke="#2BB673" strokeWidth={2.5} fill="url(#growthGrad)" />
                                </AreaChart>
                            </ResponsiveContainer>
                        ) : <p className="dash-empty-chart">No registration data available yet</p>}
                    </div>
                </div>

                <div className="dash-card animate-fade-in-up">
                    <div className="dash-card-header">
                        <div>
                            <h3 className="dash-card-title">Platform Activity</h3>
                            <p className="dash-card-subtitle">Jobs & events per month</p>
                        </div>
                    </div>
                    <div className="dash-chart-wrap">
                        {engagementData.length > 0 ? (
                            <ResponsiveContainer width="100%" height={260}>
                                <BarChart data={engagementData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                                    <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                                    <XAxis dataKey="month" tick={{ fontSize: 12, fill: "#9CA3AF" }} axisLine={false} tickLine={false} />
                                    <YAxis tick={{ fontSize: 12, fill: "#9CA3AF" }} axisLine={false} tickLine={false} />
                                    <Tooltip contentStyle={{ border: "none", borderRadius: 10, boxShadow: "0 4px 14px rgba(0,0,0,0.08)", fontSize: 13 }} />
                                    <Bar dataKey="jobs" fill="#2BB673" radius={[4, 4, 0, 0]} barSize={14} name="Jobs" />
                                    <Bar dataKey="events" fill="#6ee7a7" radius={[4, 4, 0, 0]} barSize={14} name="Events" />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : <p className="dash-empty-chart">No activity data yet</p>}
                    </div>
                </div>
            </div>

            {/* Bottom Row */}
            <div className="dash-bottom stagger">
                <div className="dash-card animate-fade-in-up">
                    <div className="dash-card-header">
                        <div><h3 className="dash-card-title">Recent Registrations</h3><p className="dash-card-subtitle">Newest members</p></div>
                        <UserPlus size={18} className="dash-card-header-icon" />
                    </div>
                    <div className="dash-user-list">
                        {recentUsers.length > 0 ? recentUsers.map((u) => (
                            <div className="dash-user-item" key={u.id}>
                                <div className="dash-user-avatar">{(u.name || u.email || "?").charAt(0).toUpperCase()}</div>
                                <div className="dash-user-info">
                                    <span className="dash-user-name">{u.name || "Unknown"}</span>
                                    <span className="dash-user-meta">{u.role || "alumni"} · {u.department || "N/A"}</span>
                                </div>
                                <span className={`dash-role-tag dash-role-${u.role || "alumni"}`}>{u.role || "alumni"}</span>
                            </div>
                        )) : <p className="dash-empty-chart">No users yet</p>}
                    </div>
                </div>

                <div className="dash-card animate-fade-in-up">
                    <div className="dash-card-header">
                        <div><h3 className="dash-card-title">Latest Job Postings</h3><p className="dash-card-subtitle">Recently posted</p></div>
                        <Briefcase size={18} className="dash-card-header-icon" />
                    </div>
                    <div className="dash-job-list">
                        {recentJobs.length > 0 ? recentJobs.map((j) => (
                            <div className="dash-job-item" key={j.id}>
                                <div className="dash-job-icon"><Briefcase size={16} /></div>
                                <div className="dash-job-info">
                                    <span className="dash-job-title">{j.title || "Untitled"}</span>
                                    <span className="dash-job-company">{j.company || "Unknown"} · {j.location || "N/A"}</span>
                                </div>
                                <span className="dash-job-type">{j.type || "Job"}</span>
                            </div>
                        )) : <p className="dash-empty-chart">No jobs yet</p>}
                    </div>
                </div>

                <div className="dash-card animate-fade-in-up">
                    <div className="dash-card-header">
                        <div><h3 className="dash-card-title">Upcoming Events</h3><p className="dash-card-subtitle">Scheduled activities</p></div>
                        <CalendarDays size={18} className="dash-card-header-icon" />
                    </div>
                    <div className="dash-event-list">
                        {upcomingEvents.length > 0 ? upcomingEvents.slice(0, 4).map((ev) => {
                            const rawDate = ev.date?.toDate ? ev.date.toDate() : new Date(ev.date);
                            return (
                                <div className="dash-event-item" key={ev.id}>
                                    <div className="dash-event-date"><Clock size={14} /><span>{rawDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })}</span></div>
                                    <div className="dash-event-info">
                                        <span className="dash-event-title">{ev.title || "Untitled"}</span>
                                        <span className="dash-event-meta">{ev.location || "TBD"} · {ev.participants || 0} participants</span>
                                    </div>
                                </div>
                            );
                        }) : <p className="dash-empty-chart">No upcoming events</p>}
                    </div>
                </div>
            </div>
        </div>
    );
}
