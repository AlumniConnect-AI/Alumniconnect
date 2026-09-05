import { useState, useEffect } from "react";
import { Building2, GraduationCap, Users, BookOpen, Award, TrendingUp, CheckCircle, Target, Briefcase, ChevronRight, RefreshCw } from "lucide-react";
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, PieChart, Pie, Cell, Legend } from "recharts";
import KpiCard from "../components/KpiCard";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import { fetchAdminKpis, fetchStateOverview } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";
import { useAdminAuth } from "../context/AdminAuthContext";
import { useNavigate } from "react-router-dom";

export default function Dashboard() {
  const [kpis, setKpis] = useState(null);
  const [stateOverview, setStateOverview] = useState([]);
  const [loading, setLoading] = useState(true);
  const { globalFilters } = useAdminAuth();
  const navigate = useNavigate();

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [kpiRes, overviewRes] = await Promise.all([
        fetchAdminKpis(globalFilters),
        fetchStateOverview(globalFilters)
      ]);
      setKpis(kpiRes);
      setStateOverview(overviewRes);
    } catch (err) {
      console.error("Dashboard data load error:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDashboardData();
    const unsubscribe = dataEngine.subscribe(() => {
      loadDashboardData();
    });
    return () => unsubscribe();
  }, [globalFilters]);

  // Chart dataset derived dynamically from current stateOverview
  const chartBarData = stateOverview.slice(0, 7).map((s) => ({
    name: s.state,
    placement: s.placementRate,
    graduation: s.graduationRate
  }));

  const chartPieData = [
    { name: "Corporate Jobs", value: 68.2, color: "#06b6d4" },
    { name: "Higher Education", value: 16.4, color: "#6366f1" },
    { name: "Govt & Enterprise", value: 5.2, color: "#10b981" },
    { name: "Founders & Startups", value: 4.8, color: "#f59e0b" },
    { name: "Unemployed / Seeking", value: 5.4, color: "#f43f5e" }
  ];

  const tableColumns = [
    {
      header: "State / Region",
      accessorKey: "state",
      cell: (row) => (
        <div style={{ display: "flex", alignItems: "center", gap: "8px", fontWeight: "700" }}>
          <span style={{ color: "var(--primary)" }}>🌐</span> {row.state}
        </div>
      )
    },
    { header: "Universities", accessorKey: "universities", cell: (r) => (r.universities || 0).toLocaleString() },
    { header: "Institutions", accessorKey: "institutions", cell: (r) => (r.institutions || 0).toLocaleString() },
    { header: "Total Students", accessorKey: "students", cell: (r) => (r.students || 0).toLocaleString() },
    { header: "Graduates", accessorKey: "graduates", cell: (r) => (r.graduates || 0).toLocaleString() },
    { header: "Placement %", accessorKey: "placementRate", cell: (r) => <span style={{ color: "#34d399", fontWeight: "700" }}>{r.placementRate}%</span> },
    { header: "Graduation %", accessorKey: "graduationRate", cell: (r) => <span style={{ color: "#38bdf8", fontWeight: "700" }}>{r.graduationRate}%</span> },
    { header: "Higher Studies %", accessorKey: "higherStudies", cell: (r) => `${r.higherStudies}%` }
  ];

  if (loading || !kpis) {
    return <div style={{ padding: "40px", textAlign: "center", color: "var(--text-muted)" }}>Loading National Analytics Dashboard...</div>;
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "28px" }}>
      {/* Scope Banner */}
      <div
        className="glass-card"
        style={{
          background: "linear-gradient(135deg, rgba(99, 102, 241, 0.15), rgba(6, 182, 212, 0.15))",
          border: "1px solid rgba(99, 102, 241, 0.3)",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: "16px"
        }}
      >
        <div>
          <div style={{ fontSize: "0.75rem", textTransform: "uppercase", letterSpacing: "1px", color: "var(--primary)", fontWeight: "700" }}>
            Council Administration Command Center
          </div>
          <h2 style={{ fontSize: "1.4rem", marginTop: "4px" }}>
            National Education & Career Outcome Analytics
          </h2>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)", marginTop: "4px" }}>
            Centralized monitoring for Universities, Institutions, Graduates, and Career Outcomes across {globalFilters.state}
          </p>
        </div>
        <div style={{ display: "flex", gap: "10px" }}>
          <span className="badge badge-indigo" style={{ padding: "8px 14px", fontSize: "0.85rem" }}>
            Scope: {globalFilters.state} ({globalFilters.district})
          </span>
          <button className="btn btn-secondary btn-sm" onClick={() => loadDashboardData()} title="Refresh live data">
            <RefreshCw size={14} /> Re-Calculate Live Stats
          </button>
        </div>
      </div>

      {/* Row 1: Primary KPI Cards (5 Grid) */}
      <div className="grid-5">
        <div onClick={() => navigate("/universities")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Total Universities"
            value={kpis.totalUniversities.toLocaleString()}
            subtext="UG / PG / Autonomous"
            growth={kpis.totalUniversitiesGrowth}
            icon={Building2}
            color="primary"
          />
        </div>
        <div onClick={() => navigate("/institutions")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Total Institutions"
            value={kpis.totalInstitutions.toLocaleString()}
            subtext="Colleges & Institutes"
            growth={kpis.totalInstitutionsGrowth}
            icon={GraduationCap}
            color="cyan"
          />
        </div>
        <div onClick={() => navigate("/students")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Total Students"
            value={`${(kpis.totalStudents / 10000000).toFixed(2)} Cr`}
            subtext="Active Enrolled"
            growth={kpis.totalStudentsGrowth}
            icon={Users}
            color="emerald"
          />
        </div>
        <div onClick={() => navigate("/courses")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Total Courses"
            value={kpis.totalCourses.toLocaleString()}
            subtext="Accredited Programs"
            growth={kpis.totalCoursesGrowth}
            icon={BookOpen}
            color="amber"
          />
        </div>
        <div onClick={() => navigate("/placements")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Total Graduates"
            value={`${(kpis.totalGraduates / 100000).toFixed(2)} L`}
            subtext="Annual Batch"
            growth={kpis.totalGraduatesGrowth}
            icon={Award}
            color="rose"
          />
        </div>
      </div>

      {/* Row 2: Secondary Outcome KPIs (5 Grid) */}
      <div className="grid-5">
        <div onClick={() => navigate("/placements")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Placement Rate"
            value={`${kpis.placementRate}%`}
            subtext="Campus & Off-Campus"
            growth={kpis.placementRateGrowth}
            icon={Briefcase}
            color="emerald"
          />
        </div>
        <div onClick={() => navigate("/state-analytics")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Graduation Rate"
            value={`${kpis.graduationRate}%`}
            subtext="Degree Awarded"
            growth={kpis.graduationRateGrowth}
            icon={CheckCircle}
            color="cyan"
          />
        </div>
        <div onClick={() => navigate("/career-outcomes")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Higher Studies Rate"
            value={`${kpis.higherStudiesRate}%`}
            subtext="Masters & Doctorate"
            growth={kpis.higherStudiesRateGrowth}
            icon={BookOpen}
            color="primary"
          />
        </div>
        <div onClick={() => navigate("/placements")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Internship Rate"
            value={`${kpis.internshipRate}%`}
            subtext="Industry Training"
            growth={kpis.internshipRateGrowth}
            icon={TrendingUp}
            color="amber"
          />
        </div>
        <div onClick={() => navigate("/career-outcomes")} style={{ cursor: "pointer" }}>
          <KpiCard
            title="Career Outcome Rate"
            value={`${kpis.careerOutcomeRate}%`}
            subtext="Skill & Job Index"
            growth="+4.0%"
            icon={Target}
            color="rose"
          />
        </div>
      </div>

      {/* Row 3: Recharts Charts */}
      <div style={{ display: "grid", gridTemplateColumns: "1.6fr 1fr", gap: "20px" }}>
        {/* Bar Chart: State Placement vs Graduation */}
        <div className="glass-card">
          <h3 style={{ fontSize: "1.1rem", marginBottom: "4px" }}>State-Wise Placement vs Graduation Trends</h3>
          <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "16px" }}>Comparative performance across top states</p>
          <div style={{ width: "100%", height: "260px" }}>
            <ResponsiveContainer>
              <BarChart data={chartBarData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey="name" stroke="#9ca3af" fontSize={11} tickLine={false} />
                <YAxis stroke="#9ca3af" fontSize={11} domain={[0, 100]} />
                <Tooltip
                  contentStyle={{ background: "#1f2937", borderColor: "rgba(255,255,255,0.1)", borderRadius: "8px", color: "#fff", fontSize: "12px" }}
                />
                <Bar dataKey="placement" fill="#10b981" radius={[4, 4, 0, 0]} name="Placement Rate (%)" />
                <Bar dataKey="graduation" fill="#6366f1" radius={[4, 4, 0, 0]} name="Graduation Rate (%)" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Pie Chart: National Career Outcome Breakdown */}
        <div className="glass-card">
          <h3 style={{ fontSize: "1.1rem", marginBottom: "4px" }}>National Career Path Breakdown</h3>
          <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "16px" }}>Aggregate student post-graduation outcomes</p>
          <div style={{ width: "100%", height: "260px" }}>
            <ResponsiveContainer>
              <PieChart>
                <Pie
                  data={chartPieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={80}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {chartPieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ background: "#1f2937", borderColor: "rgba(255,255,255,0.1)", borderRadius: "8px", color: "#fff", fontSize: "12px" }}
                />
                <Legend verticalAlign="bottom" height={36} iconSize={8} formatter={(val) => <span style={{ color: "#9ca3af", fontSize: "11px" }}>{val}</span>} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Row 4: India State Overview Data Table */}
      <div className="glass-card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
          <div>
            <h3 style={{ fontSize: "1.15rem" }}>India Education Overview</h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>State-level aggregated statistics and career outcome metrics across higher education institutions</p>
          </div>
          <button className="btn btn-outline btn-sm" onClick={() => navigate("/state-analytics")}>
            Detailed State Drill-Down <ChevronRight size={14} />
          </button>
        </div>
        <DataTable
          columns={tableColumns}
          data={stateOverview}
          searchPlaceholder="Search states or regions..."
        />
      </div>
    </div>
  );
}
