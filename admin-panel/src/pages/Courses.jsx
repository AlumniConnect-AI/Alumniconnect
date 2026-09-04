import { useState, useEffect } from "react";
import { BookOpen, Plus, Edit, Trash2 } from "lucide-react";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import CourseFormModal from "../components/CourseFormModal";
import { fetchCourses, addCourse, updateCourse, deleteCourse } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";
import { useAdminAuth } from "../context/AdminAuthContext";

export default function Courses() {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showFormModal, setShowFormModal] = useState(false);
  const [editingCourse, setEditingCourse] = useState(null);
  const { globalFilters } = useAdminAuth();

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetchCourses(globalFilters);
      setCourses(res);
    } catch (err) {
      console.error("Failed to load courses:", err);
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
  }, [globalFilters]);

  const handleOpenAddModal = () => {
    setEditingCourse(null);
    setShowFormModal(true);
  };

  const handleOpenEditModal = (crs) => {
    setEditingCourse(crs);
    setShowFormModal(true);
  };

  const handleDelete = async (crs) => {
    if (window.confirm(`Are you sure you want to delete course "${crs.name}"?`)) {
      try {
        await deleteCourse(crs.id);
        alert(`Course "${crs.name}" deleted successfully.`);
      } catch (err) {
        alert(err.message || "Failed to delete course.");
      }
    }
  };

  const handleSaveCourse = async (formData) => {
    try {
      if (editingCourse) {
        await updateCourse(editingCourse.id, formData);
        alert(`Course "${formData.name}" updated successfully.`);
      } else {
        await addCourse(formData);
        alert(`Course "${formData.name}" added successfully.`);
      }
      loadData();
    } catch (err) {
      alert(err.message || "Operation failed.");
    }
  };

  const columns = [
    {
      header: "Course Name",
      accessorKey: "name",
      cell: (r) => <div style={{ fontWeight: "700", color: "#f9fafb" }}>{r.name}</div>
    },
    { header: "Stream", accessorKey: "stream" },
    { header: "Enrolled", accessorKey: "students", cell: (r) => (r.students || 0).toLocaleString() },
    { header: "Annual Graduates", accessorKey: "graduates", cell: (r) => (r.graduates || 0).toLocaleString() },
    { header: "Placement %", accessorKey: "placementRate", cell: (r) => <span style={{ color: "#34d399", fontWeight: "700" }}>{r.placementRate}%</span> },
    { header: "Higher Studies %", accessorKey: "higherStudiesRate", cell: (r) => `${r.higherStudiesRate}%` },
    { header: "Industry Demand", accessorKey: "demandLevel", cell: (r) => <StatusBadge status={r.demandLevel} /> },
    { header: "Accountability Index", accessorKey: "accountabilityStatus", cell: (r) => <StatusBadge status={r.accountabilityStatus} /> },
    {
      header: "Actions",
      cell: (r) => (
        <div style={{ display: "flex", gap: "6px" }}>
          <button className="btn btn-secondary btn-sm" onClick={() => handleOpenEditModal(r)} title="Edit Course">
            <Edit size={14} />
          </button>
          <button className="btn btn-secondary btn-sm" style={{ color: "var(--accent-rose)" }} onClick={() => handleDelete(r)} title="Delete Course">
            <Trash2 size={14} />
          </button>
        </div>
      )
    }
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "12px" }}>
        <div>
          <h1 style={{ fontSize: "1.5rem" }}>Curriculum & Provider Accountability Matrix</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Academic program evaluation, skills mapping, and course performance benchmarks
          </p>
        </div>
        <button className="btn btn-primary" onClick={handleOpenAddModal}>
          <Plus size={16} /> Add Course
        </button>
      </div>

      <div className="glass-card">
        {loading ? (
          <div style={{ padding: "30px", textAlign: "center", color: "var(--text-muted)" }}>Loading Academic Courses...</div>
        ) : (
          <DataTable columns={columns} data={courses} searchPlaceholder="Search course name or stream..." />
        )}
      </div>

      <CourseFormModal
        isOpen={showFormModal}
        onClose={() => setShowFormModal(false)}
        onSave={handleSaveCourse}
        initialData={editingCourse}
      />
    </div>
  );
}
