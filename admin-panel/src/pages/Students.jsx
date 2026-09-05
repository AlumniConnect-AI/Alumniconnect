import { useState, useEffect } from "react";
import {
  Users, GraduationCap, Briefcase, Award, Plus, Download, UploadCloud,
  Search, Filter, Edit, Trash2, UserCheck, HelpCircle, ArrowRight
} from "lucide-react";
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, PieChart, Pie, Cell } from "recharts";
import KpiCard from "../components/KpiCard";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import StudentFormModal from "../components/StudentFormModal";
import StudentImportModal from "../components/StudentImportModal";
import {
  fetchStudents, fetchInstitutions, fetchUniversities, addStudent,
  updateStudent, deleteStudent, importStudentsBatch, fetchAdminKpis
} from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";
import { useAdminAuth } from "../context/AdminAuthContext";
import { useNavigate } from "react-router-dom";

export default function Students() {
  const navigate = useNavigate();
  const { globalFilters } = useAdminAuth();

  const [studentsResult, setStudentsResult] = useState({ items: [], total: 0, page: 1, pageSize: 10, totalPages: 1 });
  const [institutions, setInstitutions] = useState([]);
  const [universities, setUniversities] = useState([]);
  const [kpis, setKpis] = useState(null);
  const [loading, setLoading] = useState(true);

  // Filters State
  const [filters, setFilters] = useState({
    search: "",
    college: "All Colleges",
    university: "All Universities",
    course: "All Courses",
    academicYear: "All Years",
    placementStatus: "All Statuses",
    status: "All Statuses",
    page: 1,
    pageSize: 10
  });

  // Modal State
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingStudent, setEditingStudent] = useState(null);
  const [isImportModalOpen, setIsImportModalOpen] = useState(false);

  const loadData = async () => {
    try {
      setLoading(true);
      const [kpiRes, instRes, univRes, stuRes] = await Promise.all([
        fetchAdminKpis(globalFilters),
        fetchInstitutions(globalFilters),
        fetchUniversities(globalFilters),
        fetchStudents({
          ...globalFilters,
          search: filters.search,
          college: filters.college,
          university: filters.university,
          course: filters.course,
          academicYear: filters.academicYear,
          placementStatus: filters.placementStatus,
          status: filters.status,
          page: filters.page,
          pageSize: filters.pageSize
        })
      ]);

      setKpis(kpiRes);
      setInstitutions(instRes);
      setUniversities(univRes);
      setStudentsResult(stuRes);
    } catch (err) {
      console.error("Failed to load student management system:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const unsubscribe = dataEngine.subscribe(() => {
      loadData();
    });
    return () => unsubscribe();
  }, [globalFilters, filters]);

  const handleSaveStudent = async (studentData) => {
    if (editingStudent) {
      await updateStudent(editingStudent.id, studentData);
      setEditingStudent(null);
    } else {
      await addStudent(studentData);
    }
    loadData();
  };

  const handleDeleteStudent = async (studentId, studentName) => {
    if (window.confirm(`Are you sure you want to delete student record for ${studentName} (${studentId})?`)) {
      await deleteStudent(studentId);
      loadData();
    }
  };

  const handleImportBatch = (parsedRows) => {
    const res = importStudentsBatch(parsedRows);
    loadData();
    return res;
  };

  const handleExportCsv = () => {
    const allStudents = dataEngine.getStudents(globalFilters).items;
    if (allStudents.length === 0) {
      alert("No student records available to export.");
      return;
    }
    const headers = ["Student ID", "Name", "Email", "Phone", "Gender", "College", "University", "State", "Course", "Department", "Academic Year", "Placement Status", "Career Outcome", "Status"];
    const rows = allStudents.map((s) => [
      s.studentId || s.id,
      `"${s.name}"`,
      s.email,
      s.phone,
      s.gender,
      `"${s.college}"`,
      `"${s.university}"`,
      s.state,
      `"${s.course}"`,
      `"${s.department}"`,
      s.academicYear,
      s.placementStatus,
      s.careerOutcome,
      s.status
    ]);
    const csvContent = [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", `All_Students_Data_Report.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleClearFilters = () => {
    setFilters({
      search: "",
      college: "All Colleges",
      university: "All Universities",
      course: "All Courses",
      academicYear: "All Years",
      placementStatus: "All Statuses",
      status: "All Statuses",
      page: 1,
      pageSize: 10
    });
  };

  if (loading || !kpis) {
    return <div style={{ padding: "40px", textAlign: "center", color: "var(--text-muted)" }}>Loading Student Data System...</div>;
  }

  const columns = [
    { header: "Student ID", accessorKey: "studentId", cell: (r) => <strong>{r.studentId || r.id}</strong> },
    { header: "Student Name", accessorKey: "name", cell: (r) => (
      <div>
        <div style={{ fontWeight: "600", color: "#f9fafb" }}>{r.name}</div>
        <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.email}</div>
      </div>
    )},
    {
      header: "College & University",
      cell: (r) => (
        <div>
          <div style={{ fontWeight: "600", fontSize: "0.85rem", color: "var(--accent-cyan)" }}>{r.college}</div>
          <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.university}</div>
        </div>
      )
    },
    { header: "Course", accessorKey: "course", cell: (r) => <span style={{ fontSize: "0.85rem" }}>{r.course}</span> },
    { header: "Academic Year", accessorKey: "academicYear", cell: (r) => <span className="badge badge-indigo">{r.academicYear}</span> },
    { header: "Placement Status", accessorKey: "placementStatus", cell: (r) => <StatusBadge status={r.placementStatus} /> },
    { header: "Career Outcome", accessorKey: "careerOutcome", cell: (r) => <span style={{ fontWeight: "600", color: "var(--primary)", fontSize: "0.85rem" }}>{r.careerOutcome}</span> },
    { header: "Status", accessorKey: "status", cell: (r) => <StatusBadge status={r.status} /> },
    {
      header: "Actions",
      cell: (r) => (
        <div style={{ display: "flex", gap: "6px" }}>
          <button className="btn btn-outline btn-icon" title="Edit Student" onClick={() => setEditingStudent(r)}>
            <Edit size={14} />
          </button>
          <button className="btn btn-outline btn-icon" title="Delete Student" style={{ color: "#f87171" }} onClick={() => handleDeleteStudent(r.id, r.name)}>
            <Trash2 size={14} />
          </button>
        </div>
      )
    }
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      {/* Header Bar */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h1 style={{ fontSize: "1.5rem" }}>National Student Data Management System</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Centralized single source of truth for student records, enrollment tracking, and outcome diagnostics across {globalFilters.state}
          </p>
        </div>

        <div style={{ display: "flex", gap: "10px" }}>
          <button className="btn btn-secondary" onClick={() => setIsImportModalOpen(true)}>
            <UploadCloud size={16} /> Import File (CSV/XLSX)
          </button>
          <button className="btn btn-secondary" onClick={handleExportCsv}>
            <Download size={16} /> Export All CSV
          </button>
          <button className="btn btn-primary" onClick={() => setIsAddModalOpen(true)}>
            <Plus size={16} /> + Add Student
          </button>
        </div>
      </div>

      {/* Summary KPI Cards */}
      <div className="grid-4">
        <KpiCard title="Total Student Records" value={studentsResult.total.toLocaleString()} growth={kpis.totalStudentsGrowth} icon={Users} color="cyan" subtext="Single Source of Truth Database" />
        <KpiCard title="Degree Graduation Rate" value={`${kpis.graduationRate}%`} growth={kpis.graduationRateGrowth} icon={GraduationCap} color="emerald" subtext="Calculated from Records" />
        <KpiCard title="Placement Eligible" value={`${(kpis.totalGraduates / 1000).toFixed(1)} K`} growth={kpis.totalGraduatesGrowth} icon={Briefcase} color="indigo" subtext="Final Year / Placed" />
        <KpiCard title="Internship Participation" value={`${kpis.internshipRate}%`} growth={kpis.internshipRateGrowth} icon={Award} color="amber" subtext="Industry Verified" />
      </div>

      {/* Main Student Directory Table */}
      <div className="glass-card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px", flexWrap: "wrap", gap: "12px" }}>
          <div>
            <h3 style={{ fontSize: "1.1rem" }}>All Student Directory ({studentsResult.total.toLocaleString()})</h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Search, filter, edit, or delete student records in real time</p>
          </div>
          <button className="btn btn-outline" style={{ fontSize: "0.8rem", padding: "6px 12px" }} onClick={handleClearFilters}>
            Clear Filters / Reset
          </button>
        </div>

        {/* Filter Controls Bar */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))", gap: "12px", marginBottom: "16px" }}>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Search Student</label>
            <input
              type="text"
              className="form-control"
              placeholder="Search ID, Name, Email..."
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value, page: 1 })}
            />
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>College</label>
            <select
              className="form-select"
              value={filters.college}
              onChange={(e) => setFilters({ ...filters, college: e.target.value, page: 1 })}
            >
              <option value="All Colleges">All Colleges</option>
              {institutions.map(i => <option key={i.id} value={i.name}>{i.name}</option>)}
            </select>
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>University</label>
            <select
              className="form-select"
              value={filters.university}
              onChange={(e) => setFilters({ ...filters, university: e.target.value, page: 1 })}
            >
              <option value="All Universities">All Universities</option>
              {universities.map(u => <option key={u.id} value={u.name}>{u.name}</option>)}
            </select>
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Course</label>
            <select
              className="form-select"
              value={filters.course}
              onChange={(e) => setFilters({ ...filters, course: e.target.value, page: 1 })}
            >
              <option value="All Courses">All Courses</option>
              <option value="B.Tech Computer Science & Engineering">B.Tech Computer Science & Engineering</option>
              <option value="B.Tech Information Technology">B.Tech Information Technology</option>
              <option value="B.Tech Artificial Intelligence & Data Science">B.Tech Artificial Intelligence & Data Science</option>
              <option value="B.Tech Electronics & Communication">B.Tech Electronics & Communication</option>
              <option value="B.Tech Mechanical Engineering">B.Tech Mechanical Engineering</option>
              <option value="Master of Business Administration (MBA)">Master of Business Administration (MBA)</option>
            </select>
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Placement Status</label>
            <select
              className="form-select"
              value={filters.placementStatus}
              onChange={(e) => setFilters({ ...filters, placementStatus: e.target.value, page: 1 })}
            >
              <option value="All Statuses">All Statuses</option>
              <option value="Placed">Placed</option>
              <option value="Seeking Opportunities">Seeking Opportunities</option>
              <option value="Higher Studies">Higher Studies</option>
              <option value="In Progress">In Progress</option>
            </select>
          </div>
        </div>

        {/* Data Table */}
        <DataTable columns={columns} data={studentsResult.items} searchPlaceholder="" />

        {/* Pagination Bar */}
        <div style={{ marginTop: "16px", display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "12px", borderTop: "1px solid var(--border-color)", paddingTop: "14px" }}>
          <div style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Showing <strong>{studentsResult.items.length > 0 ? (filters.page - 1) * filters.pageSize + 1 : 0}</strong> – <strong>{Math.min(filters.page * filters.pageSize, studentsResult.total)}</strong> of <strong>{studentsResult.total.toLocaleString()}</strong> students
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <span style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>Rows per page:</span>
            <select
              className="form-select"
              style={{ width: "70px", padding: "4px 8px", fontSize: "0.8rem" }}
              value={filters.pageSize}
              onChange={(e) => setFilters({ ...filters, pageSize: parseInt(e.target.value, 10), page: 1 })}
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>

            <button
              className="btn btn-outline"
              disabled={filters.page <= 1}
              onClick={() => setFilters({ ...filters, page: filters.page - 1 })}
            >
              Previous
            </button>
            <span style={{ fontSize: "0.85rem", padding: "0 6px" }}>Page {filters.page} of {studentsResult.totalPages}</span>
            <button
              className="btn btn-outline"
              disabled={filters.page >= studentsResult.totalPages}
              onClick={() => setFilters({ ...filters, page: filters.page + 1 })}
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Add / Edit Student Modal */}
      <StudentFormModal
        isOpen={isAddModalOpen || !!editingStudent}
        onClose={() => { setIsAddModalOpen(false); setEditingStudent(null); }}
        onSave={handleSaveStudent}
        initialData={editingStudent}
        institutions={institutions}
      />

      {/* Import CSV / XLSX Modal */}
      <StudentImportModal
        isOpen={isImportModalOpen}
        onClose={() => setIsImportModalOpen(false)}
        onImportSuccess={handleImportBatch}
      />
    </div>
  );
}
