import { useEffect, useState } from "react";
import {
    TrendingUp, Building2, Users, CalendarDays, MessageSquare, Zap, Award,
} from "lucide-react";
import {
    AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell, RadarChart,
    PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar,
    XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from "recharts";
import {
    fetchUsers, fetchJobs, fetchEvents, fetchEngagementData,
    computeUserGrowth, computeTopCompanies, computeDepartmentDistribution,
    computeBatchDistribution, computeEventParticipation, computeMostActiveUsers,
    computeEngagementRate,
} from "../services/firestoreService";
import LoadingSpinner from "../components/LoadingSpinner";
import "./Analytics.css";

export default function Analytics() {
    const [loading, setLoading] = useState(true);
    const [data, setData] = useState({});

    useEffect(() => {
        (async () => {
            try {
                const [users, jobs, events, engagement, engRate] = await Promise.all([
                    fetchUsers(), fetchJobs(), fetchEvents(), fetchEngagementData(), computeEngagementRate(),
                ]);
                setData({
                    growthData: computeUserGrowth(users),
                    topCompanies: computeTopCompanies(jobs),
                    deptDist: computeDepartmentDistribution(users),
                    batchDist: computeBatchDistribution(users),
                    eventPart: computeEventParticipation(events),
                    activeUsers: computeMostActiveUsers(users, jobs, events),
                    engagementRate: engRate,
                    engagement,
                    radarData: [
                        { metric: "Users", value: users.length },
                        { metric: "Jobs", value: jobs.length },
                        { metric: "Events", value: events.length },
                        { metric: "Messages", value: engRate * 30 },
                        { metric: "Engagement", value: Math.min((jobs.length + events.length) * 10, 100) },
                    ],
                });
            } catch (e) { console.error("Analytics:", e); }
            finally { setLoading(false); }
        })();
    }, []);

    if (loading) return <LoadingSpinner message="Loading analytics..." />;

    const {
        growthData, topCompanies, deptDist, batchDist, eventPart,
        activeUsers, engagementRate, engagement, radarData,
    } = data;

    return (
        <div className="analytics">
            <div className="an-header animate-fade-in-up">
                <div>
                    <h2 className="an-title">Analytics & Insights</h2>
                    <p className="an-subtitle">Platform performance and engagement metrics</p>
                </div>
                <div className="an-badge"><TrendingUp size={14} /> Live Data</div>
            </div>

            {/* Row 1: Growth + Top Companies */}
            <div className="an-row an-row-2">
                <div className="an-card animate-fade-in-up">
                    <div className="an-card-header">
                        <div><h3 className="an-card-title"><TrendingUp size={16} /> User Growth</h3><p className="an-card-subtitle">Monthly registration trend</p></div>
                    </div>
                    {growthData?.length > 0 ? (
                        <ResponsiveContainer width="100%" height={250}>
                            <AreaChart data={growthData}><defs><linearGradient id="g1" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#2BB673" stopOpacity={0.25} /><stop offset="95%" stopColor="#2BB673" stopOpacity={0} /></linearGradient></defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" /><XAxis dataKey="month" tick={{ fontSize: 12, fill: "#9CA3AF" }} axisLine={false} tickLine={false} /><YAxis tick={{ fontSize: 12, fill: "#9CA3AF" }} axisLine={false} tickLine={false} />
                                <Tooltip contentStyle={{ border: "none", borderRadius: 10, boxShadow: "0 4px 14px rgba(0,0,0,0.08)", fontSize: 13 }} /><Area type="monotone" dataKey="users" stroke="#2BB673" strokeWidth={2.5} fill="url(#g1)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    ) : <p className="an-empty">No registration data</p>}
                </div>

                <div className="an-card animate-fade-in-up">
                    <div className="an-card-header">
                        <div><h3 className="an-card-title"><Building2 size={16} /> Top Companies</h3><p className="an-card-subtitle">Most hiring companies</p></div>
                    </div>
                    {topCompanies?.length > 0 ? (
                        <ResponsiveContainer width="100%" height={250}>
                            <BarChart data={topCompanies} layout="vertical" margin={{ left: 80 }}>
                                <XAxis type="number" hide /><YAxis type="category" dataKey="name" tick={{ fontSize: 12, fill: "#6B7280" }} width={75} />
                                <Tooltip contentStyle={{ border: "none", borderRadius: 8, fontSize: 13 }} /><Bar dataKey="jobs" fill="#2BB673" radius={[0, 4, 4, 0]} barSize={16} />
                            </BarChart>
                        </ResponsiveContainer>
                    ) : <p className="an-empty">No job data</p>}
                </div>
            </div>

            {/* Row 2: Batch Distribution + Department Distribution */}
            <div className="an-row an-row-2">
                <div className="an-card animate-fade-in-up">
                    <div className="an-card-header">
                        <div><h3 className="an-card-title"><Award size={16} /> Batch Distribution</h3><p className="an-card-subtitle">Alumni by graduation year</p></div>
                    </div>
                    {batchDist?.length > 0 ? (
                        <div className="an-pie-wrap">
                            <ResponsiveContainer width="50%" height={200}>
                                <PieChart><Pie data={batchDist} cx="50%" cy="50%" outerRadius={80} dataKey="value" stroke="none">
                                    {batchDist.map((d, i) => <Cell key={i} fill={d.color} />)}
                                </Pie><Tooltip /></PieChart>
                            </ResponsiveContainer>
                            <div className="an-pie-legend">
                                {batchDist.slice(0, 6).map((d, i) => (
                                    <div className="an-pie-legend-item" key={i}><div className="an-pie-dot" style={{ background: d.color }} /><span className="an-pie-label">{d.name}</span><span className="an-pie-value">{d.value}</span></div>
                                ))}
                            </div>
                        </div>
                    ) : <p className="an-empty">No batch data</p>}
                </div>

                <div className="an-card animate-fade-in-up">
                    <div className="an-card-header">
                        <div><h3 className="an-card-title"><Users size={16} /> Department Distribution</h3><p className="an-card-subtitle">Alumni by department</p></div>
                    </div>
                    {deptDist?.length > 0 ? (
                        <div className="an-pie-wrap">
                            <ResponsiveContainer width="50%" height={200}>
                                <PieChart><Pie data={deptDist} cx="50%" cy="50%" outerRadius={80} dataKey="value" stroke="none">
                                    {deptDist.map((d, i) => <Cell key={i} fill={d.color} />)}
                                </Pie><Tooltip /></PieChart>
                            </ResponsiveContainer>
                            <div className="an-pie-legend">
                                {deptDist.slice(0, 6).map((d, i) => (
                                    <div className="an-pie-legend-item" key={i}><div className="an-pie-dot" style={{ background: d.color }} /><span className="an-pie-label">{d.name}</span><span className="an-pie-value">{d.value}</span></div>
                                ))}
                            </div>
                        </div>
                    ) : <p className="an-empty">No department data</p>}
                </div>
            </div>

            {/* Row 3: Event Participation + Radar */}
            <div className="an-row an-row-2">
                <div className="an-card animate-fade-in-up">
                    <div className="an-card-header">
                        <div><h3 className="an-card-title"><CalendarDays size={16} /> Event Participation</h3><p className="an-card-subtitle">Attendance per event</p></div>
                    </div>
                    {eventPart?.length > 0 ? (
                        <ResponsiveContainer width="100%" height={220}>
                            <BarChart data={eventPart}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" /><XAxis dataKey="name" tick={{ fontSize: 11, fill: "#9CA3AF" }} axisLine={false} tickLine={false} />
                                <YAxis tick={{ fontSize: 12, fill: "#9CA3AF" }} axisLine={false} tickLine={false} /><Tooltip contentStyle={{ border: "none", borderRadius: 8, fontSize: 13 }} />
                                <Bar dataKey="value" fill="#8B5CF6" radius={[4, 4, 0, 0]} barSize={20} name="Participants" />
                            </BarChart>
                        </ResponsiveContainer>
                    ) : <p className="an-empty">No event data</p>}
                </div>

                <div className="an-card animate-fade-in-up">
                    <div className="an-card-header">
                        <div><h3 className="an-card-title"><Zap size={16} /> Platform Overview</h3><p className="an-card-subtitle">Multi-metric radar</p></div>
                    </div>
                    {radarData ? (
                        <ResponsiveContainer width="100%" height={220}>
                            <RadarChart data={radarData}>
                                <PolarGrid stroke="#e5e7eb" /><PolarAngleAxis dataKey="metric" tick={{ fontSize: 11, fill: "#6B7280" }} />
                                <PolarRadiusAxis tick={{ fontSize: 10, fill: "#9CA3AF" }} /><Radar dataKey="value" stroke="#2BB673" fill="#2BB673" fillOpacity={0.2} strokeWidth={2} />
                            </RadarChart>
                        </ResponsiveContainer>
                    ) : <p className="an-empty">No data</p>}
                </div>
            </div>

            {/* Row 4: Insight Cards */}
            <div className="an-row an-row-3">
                <div className="an-card an-insight animate-fade-in-up">
                    <MessageSquare size={22} className="an-insight-icon" style={{ color: "#06B6D4" }} />
                    <div className="an-insight-value">{engagementRate || 0}</div>
                    <div className="an-insight-label">Messages / Day</div>
                </div>

                <div className="an-card an-insight animate-fade-in-up">
                    <div className="an-insight-header"><Award size={22} className="an-insight-icon" style={{ color: "#F59E0B" }} /></div>
                    <div className="an-insight-label" style={{ marginBottom: 8 }}>Most Active Users</div>
                    <div className="an-active-list">
                        {activeUsers?.slice(0, 5).map((u, i) => (
                            <div className="an-active-item" key={i}>
                                <span className="an-active-rank">#{i + 1}</span>
                                <span className="an-active-name">{u.name}</span>
                                <span className="an-active-score">{u.score} pts</span>
                            </div>
                        ))}
                        {(!activeUsers || activeUsers.length === 0) && <p className="an-empty" style={{ padding: 10 }}>No activity data</p>}
                    </div>
                </div>

                <div className="an-card an-insight animate-fade-in-up">
                    <Zap size={22} className="an-insight-icon" style={{ color: "#2BB673" }} />
                    <div className="an-insight-value">{engagement?.length || 0}</div>
                    <div className="an-insight-label">Engagement Records</div>
                </div>
            </div>
        </div>
    );
}
