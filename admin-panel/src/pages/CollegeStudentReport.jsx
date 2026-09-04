import { useState, useEffect } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import {
  Users, GraduationCap, Briefcase, Award, ArrowLeft, Plus, Download, UploadCloud,
  Search, Filter, Edit, Trash2, ShieldCheck, CheckCircle2, UserCheck, HelpCircle
} from "lucide-react";
import KpiCard from "../components/KpiCard";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import StudentFormModal from "../components/StudentFormModal";
import StudentImportModal from "../components/StudentImportModal";
import {
  fetchInstitutionById, fetchStudents, fetchCollegeStudentSummary,
  addStudent, updateStudent, deleteStudent, importStudentsBatch, fetchInstitutions
} from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";

export default function CollegeStudentReport() {
  const { institutionId } = useParams();
  const navigate = useNavigate();

  const [college, setCollege] = useState(null);
  const [summary, setSummary] = useState(null);
  const [studentsResult, setStudentsResult] = useState({ items: [], total: 0, page: 1, pageSize: 10, totalPages: 1 });
  const [allInstitutions, setAllInstitutions] = useState([]);
  const [loading, setLoading] = useState(true);

  // Filters State
  const [filters, setFilters] = useState({
    search: "",
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
      const col = await fetchInstitutionById(institutionId);
      setCollege(col);

      const insts = await fetchInstitutions();
      setAllInstitutions(insts);

      if (col) {
        const sum = await fetchCollegeStudentSummary(col.id, col.name);
        setSummary(sum);

        const res = await fetchStudents({
          collegeId: col.id,
          search: filters.search,
          course: filters.course,
          academicYear: filters.academicYear,
          placementStatus: filters.placementStatus,
          status: filters.status,
          page: filters.page,
          pageSize: filters.pageSize
        });
        setStudentsResult(res);
      }
    } catch (err) {
      console.error("College student report load error:", err);
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
  }, [institutionId, filters]);

  const handleSaveStudent = async (studentData) => {
    if (editingStudent) {
      await updateStudent(editingStudent.id, studentData);
      setEditingStudent(null);
    } else {
      await addStudent({ ...studentData, collegeId: college.id });
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
    const allColStudents = dataEngine.getStudents({ collegeId: college.id }).items;
    if (allColStudents.length === 0) {
      alert("No student records available to export.");
      return;
    }
    const headers = ["Student ID", "Name", "Email", "Phone", "Gender", "Course", "Department", "Academic Year", "Graduation Year", "Placement Status", "Career Outcome", "Status"];
    const rows = allColStudents.map((s) => [
      s.studentId || s.id,
      `"${s.name}"`,
      s.email,
      s.phone,
      s.gender,
      `"${s.course}"`,
      `"${s.department}"`,
      s.academicYear,
      s.graduationYear,
      s.placementStatus,
      s.careerOutcome,
      s.status
    ]);
    const csvContent = [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", `${college.name.replace(/[^a-z0-9]/gi, '_')}_Students_Report.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleClearFilters = () => {
    setFilters({
      search: "",
      course: "All Courses",
      academicYear: "All Years",
      placementStatus: "All Statuses",
      status: "All Statuses",
      page: 1,
      pageSize: 10
    });
  };

  if (loading || !college || !summary) {
    return <div style={{ padding: "40px", textAlign: "center", color: "var(--text-muted)" }}>Loading College Student Report...</div>;
  }

  const columns = [
    { header: "Student ID", accessorKey: "studentId", cell: (r) => <strong>{r.studentId || r.id}</strong> },
    { header: "Student Name", accessorKey: "name", cell: (r) => (
      <div>
        <div style={{ fontWeight: "600", color: "#f9fafb" }}>{r.name}</div>
        <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.email}</div>
      </div>
    )},
    { header: "Course & Dept", accessorKey: "course", cell: (r) => (
      <div>
        <div style={{ fontWeight: "500", fontSize: "0.85rem" }}>{r.course}</div>
        <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.department}</div>
      </div>
    )},
    { header: "Academic Year", accessorKey: "academicYear", cell: (r) => <span className="badge badge-indigo">{r.academicYear}</span> },
    { header: "Grad Year", accessorKey: "graduationYear" },
    { header: "Placement Status", accessorKey: "placementStatus", cell: (r) => <StatusBadge status={r.placementStatus} /> },
    { header: "Career Outcome", accessorKey: "careerOutcome", cell: (r) => <span style={{ fontWeight: "600", color: "var(--accent-cyan)", fontSize: "0.85rem" }}>{r.careerOutcome}</span> },
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
      {/* Back & Title Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <button className="btn btn-outline" style={{ marginBottom: "12px", display: "inline-flex", alignItems: "center", gap: "6px" }} onClick={() => navigate("/institutions")}>
            <ArrowLeft size={16} /> Back to Institutions Directory
          </button>
          <h1 style={{ fontSize: "1.6rem", display: "flex", alignItems: "center", gap: "10px" }}>
            {college.name}
            <span className="badge badge-emerald" style={{ fontSize: "0.75rem" }}>{college.status}</span>
          </h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            University: <strong>{college.university}</strong> | State: <strong>{college.state}</strong> | District: <strong>{college.district}</strong>
          </p>
        </div>

        <div style={{ display: "flex", gap: "10px" }}>
          <button className="btn btn-secondary" onClick={() => setIsImportModalOpen(true)}>
            <UploadCloud size={16} /> Import Students
          </button>
          <button className="btn btn-secondary" onClick={handleExportCsv}>
            <Download size={16} /> Export CSV
          </button>
          <button className="btn btn-primary" onClick={() => setIsAddModalOpen(true)}>
            <Plus size={16} /> + Add Student
          </button>
        </div>
      </div>

      {/* College Student Summary Cards - Section 2 */}
      <div>
        <h3 style={{ fontSize: "1.05rem", marginBottom: "12px", color: "var(--text-muted)" }}>College Student Demographics & Outcome Analytics</h3>
        <div className="grid-5" style={{ marginBottom: "16px" }}>
          <KpiCard title="Total Students" value={summary.totalStudents.toLocaleString()} icon={Users} color="cyan" subtext="Single Source of Truth Count" />
          <KpiCard title="Male Students" value={summary.maleStudents.toLocaleString()} icon={UserCheck} color="indigo" subtext={`${((summary.maleStudents / (summary.totalStudents || 1)) * 100).toFixed(1)}% Ratio`} />
          <KpiCard title="Female Students" value={summary.femaleStudents.toLocaleString()} icon={UserCheck} color="cyan" subtext={`${((summary.femaleStudents / (summary.totalStudents || 1)) * 100).toFixed(1)}% Ratio`} />
          <KpiCard title="Graduated" value={summary.graduatedStudents.toLocaleString()} icon={GraduationCap} color="emerald" subtext="Degree Completed" />
          <KpiCard title="Currently Studying" value={summary.studyingStudents.toLocaleString()} icon={Award} color="amber" subtext="Enrolled Batches" />
        </div>

        <div className="grid-4">
          <KpiCard title="Corporate Placed" value={summary.placedStudents.toLocaleString()} icon={Briefcase} color="emerald" subtext="Industry Employed" />
          <KpiCard title="Higher Studies" value={summary.higherStudiesStudents.toLocaleString()} icon={GraduationCap} color="indigo" subtext="PG & Master Degrees" />
          <KpiCard title="Seeking Opportunities" value={summary.seekingStudents.toLocaleString()} icon={HelpCircle} color="amber" subtext="Job Search Active" />
          <KpiCard title="Other / Unspecified" value={summary.otherStudents.toLocaleString()} icon={Users} color="cyan" subtext="Demographic Buffer" />
        </div>
      </div>

      {/* Student Records Table & Search/Filter Section */}
      <div className="glass-card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px", flexWrap: "wrap", gap: "12px" }}>
          <div>
            <h3 style={{ fontSize: "1.1rem" }}>Associated Student Records ({studentsResult.total.toLocaleString()})</h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Filtered list of verified students enrolled at {college.name}</p>
          </div>
          <button className="btn btn-outline" style={{ fontSize: "0.8rem", padding: "6px 12px" }} onClick={handleClearFilters}>
            Clear Filters / Reset
          </button>
        </div>

        {/* Filter Controls Bar */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: "12px", marginBottom: "16px" }}>
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
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Academic Year</label>
            <select
              className="form-select"
              value={filters.academicYear}
              onChange={(e) => setFilters({ ...filters, academicYear: e.target.value, page: 1 })}
            >
              <option value="All Years">All Years</option>
              <option value="1st Year (2025)">1st Year (2025)</option>
              <option value="2nd Year (2024)">2nd Year (2024)</option>
              <option value="3rd Year (2023)">3rd Year (2023)</option>
              <option value="4th Year / Final">4th Year / Final</option>
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

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: "0.75rem", marginBottom: "4px" }}>Student Status</label>
            <select
              className="form-select"
              value={filters.status}
              onChange={(e) => setFilters({ ...filters, status: e.target.value, page: 1 })}
            >
              <option value="All Statuses">All Statuses</option>
              <option value="Currently Studying">Currently Studying</option>
              <option value="Graduated">Graduated</option>
            </select>
          </div>
        </div>

        {/* Data Table */}
        <DataTable columns={columns} data={studentsResult.items} searchPlaceholder="" />

        {/* Pagination Bar - Section 14 */}
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
        institutions={allInstitutions}
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
