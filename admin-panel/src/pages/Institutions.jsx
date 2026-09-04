import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { GraduationCap, Plus, Eye, Edit, Trash2, MapPin, X, Users } from "lucide-react";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import InstitutionFormModal from "../components/InstitutionFormModal";
import { fetchInstitutions, addInstitution, updateInstitution, deleteInstitution, fetchUniversities } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";
import { useAdminAuth } from "../context/AdminAuthContext";

export default function Institutions() {
  const navigate = useNavigate();
  const [institutions, setInstitutions] = useState([]);
  const [universities, setUniversities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedInst, setSelectedInst] = useState(null);
  const [showViewModal, setShowViewModal] = useState(false);
  const [showFormModal, setShowFormModal] = useState(false);
  const [editingInst, setEditingInst] = useState(null);
  const { globalFilters } = useAdminAuth();

  const loadData = async () => {
    try {
      setLoading(true);
      const [instRes, univRes] = await Promise.all([
        fetchInstitutions(globalFilters),
        fetchUniversities(globalFilters)
      ]);
      setInstitutions(instRes);
      setUniversities(univRes);
    } catch (err) {
      console.error("Failed to load institutions:", err);
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
    setEditingInst(null);
    setShowFormModal(true);
  };

  const handleOpenEditModal = (inst) => {
    setEditingInst(inst);
    setShowFormModal(true);
  };

  const handleOpenStudentReport = (inst) => {
    navigate(`/institutions/${inst.id}/students`);
  };

  const handleDelete = async (inst) => {
    if (window.confirm(`Are you sure you want to delete "${inst.name}"?`)) {
      try {
        await deleteInstitution(inst.id);
        alert(`Institution "${inst.name}" deleted successfully.`);
      } catch (err) {
        alert(err.message || "Failed to delete institution.");
      }
    }
  };

  const handleSaveInstitution = async (formData) => {
    try {
      if (editingInst) {
        await updateInstitution(editingInst.id, formData);
        alert(`Institution "${formData.name}" updated successfully.`);
      } else {
        await addInstitution(formData);
        alert(`Institution "${formData.name}" added successfully.`);
      }
      loadData();
    } catch (err) {
      alert(err.message || "Operation failed.");
    }
  };

  const columns = [
    {
      header: "Institution Name",
      accessorKey: "name",
      cell: (r) => (
        <div>
          <div style={{ fontWeight: "700", color: "#f9fafb" }}>{r.name}</div>
          <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px" }}>
            <MapPin size={12} /> {r.district}, {r.state}
          </div>
        </div>
      )
    },
    { header: "Affiliated University", accessorKey: "university" },
    { header: "Courses", accessorKey: "coursesCount", cell: (r) => r.coursesCount || r.courses || 10 },
    {
      header: "Students (Derived)",
      accessorKey: "students",
      cell: (r) => (
        <span style={{ fontWeight: "700", color: "var(--accent-cyan)" }}>
          {(r.students || 0).toLocaleString()}
        </span>
      )
    },
    { header: "Status", accessorKey: "status", cell: (r) => <StatusBadge status={r.status} /> },
    {
      header: "Actions",
      cell: (r) => (
        <div style={{ display: "flex", gap: "6px" }}>
          <button
            className="btn btn-outline btn-sm"
            onClick={() => handleOpenStudentReport(r)}
            title="View College Student Report (Eye Icon)"
            style={{ borderColor: "var(--accent-cyan)", color: "var(--accent-cyan)" }}
          >
            <Eye size={14} />
          </button>
          <button className="btn btn-secondary btn-sm" onClick={() => handleOpenEditModal(r)} title="Edit Record">
            <Edit size={14} />
          </button>
          <button className="btn btn-secondary btn-sm" style={{ color: "var(--accent-rose)" }} onClick={() => handleDelete(r)} title="Delete Record">
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
          <h1 style={{ fontSize: "1.5rem" }}>Affiliated Institutions & Autonomous Colleges</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Directory of affiliated technical institutes and colleges across {globalFilters.state}. Click the Eye icon to view that college's student report.
          </p>
        </div>
        <button className="btn btn-primary" onClick={handleOpenAddModal}>
          <Plus size={16} /> Add Institution
        </button>
      </div>

      <div className="glass-card">
        {loading ? (
          <div style={{ padding: "30px", textAlign: "center", color: "var(--text-muted)" }}>Loading Institutions...</div>
        ) : (
          <DataTable columns={columns} data={institutions} searchPlaceholder="Search institution name or university..." />
        )}
      </div>

      {/* View Modal */}
      {showViewModal && selectedInst && (
        <div
          style={{
            position: "fixed",
            top: 0, left: 0, right: 0, bottom: 0,
            background: "rgba(0,0,0,0.75)",
            backdropFilter: "blur(4px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 100,
            padding: "20px"
          }}
        >
          <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "540px", background: "#111827" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "12px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <GraduationCap size={24} style={{ color: "var(--accent-emerald)" }} />
                <h3 style={{ fontSize: "1.2rem" }}>{selectedInst.name}</h3>
              </div>
              <button className="btn btn-outline btn-icon" onClick={() => setShowViewModal(false)}>
                <X size={18} />
              </button>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "14px", fontSize: "0.9rem" }}>
              <div><span style={{ color: "var(--text-muted)" }}>Affiliated University:</span> <strong>{selectedInst.university}</strong></div>
              <div className="grid-2">
                <div><span style={{ color: "var(--text-muted)" }}>State:</span> <strong>{selectedInst.state}</strong></div>
                <div><span style={{ color: "var(--text-muted)" }}>District:</span> <strong>{selectedInst.district}</strong></div>
              </div>
              <div className="grid-2">
                <div><span style={{ color: "var(--text-muted)" }}>Status:</span> <StatusBadge status={selectedInst.status} /></div>
                <div><span style={{ color: "var(--text-muted)" }}>Courses:</span> <strong>{selectedInst.coursesCount || selectedInst.courses || 10}</strong></div>
              </div>
              <hr style={{ borderColor: "var(--border-color)" }} />
              <div className="grid-2">
                <div><span style={{ color: "var(--text-muted)" }}>Calculated Student Records:</span> <strong style={{ color: "var(--accent-cyan)" }}>{(selectedInst.students || 0).toLocaleString()}</strong></div>
              </div>
            </div>

            <div style={{ marginTop: "24px", display: "flex", justifyContent: "flex-end", gap: "10px" }}>
              <button className="btn btn-secondary" onClick={() => setShowViewModal(false)}>Close</button>
              <button className="btn btn-primary" onClick={() => { setShowViewModal(false); handleOpenStudentReport(selectedInst); }}>
                <Users size={16} /> Open College Student Report
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Form Modal */}
      <InstitutionFormModal
        isOpen={showFormModal}
        onClose={() => setShowFormModal(false)}
        onSave={handleSaveInstitution}
        initialData={editingInst}
        universities={universities}
      />
    </div>
  );
}
