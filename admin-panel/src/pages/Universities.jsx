import { useState, useEffect } from "react";
import { Building2, Plus, Eye, Edit, Trash2, MapPin, X, ExternalLink } from "lucide-react";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import UniversityFormModal from "../components/UniversityFormModal";
import { fetchUniversities, addUniversity, updateUniversity, deleteUniversity } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";
import { useAdminAuth } from "../context/AdminAuthContext";

export default function Universities() {
  const [universities, setUniversities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedUniv, setSelectedUniv] = useState(null);
  const [showViewModal, setShowViewModal] = useState(false);
  const [showFormModal, setShowFormModal] = useState(false);
  const [editingUniv, setEditingUniv] = useState(null);
  const { globalFilters } = useAdminAuth();

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetchUniversities(globalFilters);
      setUniversities(res);
    } catch (err) {
      console.error("Failed to fetch universities:", err);
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
    setEditingUniv(null);
    setShowFormModal(true);
  };

  const handleOpenEditModal = (univ) => {
    setEditingUniv(univ);
    setShowFormModal(true);
  };

  const handleOpenViewModal = (univ) => {
    setSelectedUniv(univ);
    setShowViewModal(true);
  };

  const handleDelete = async (univ) => {
    if (window.confirm(`Are you sure you want to delete "${univ.name}"? This action will remove the record from the national database.`)) {
      try {
        await deleteUniversity(univ.id);
        alert(`University "${univ.name}" deleted successfully.`);
      } catch (err) {
        alert(err.message || "Failed to delete university.");
      }
    }
  };

  const handleSaveUniversity = async (formData) => {
    try {
      if (editingUniv) {
        await updateUniversity(editingUniv.id, formData);
        alert(`University "${formData.name}" updated successfully.`);
      } else {
        await addUniversity(formData);
        alert(`University "${formData.name}" added successfully.`);
      }
      loadData();
    } catch (err) {
      alert(err.message || "Operation failed.");
    }
  };

  const columns = [
    {
      header: "University Name",
      accessorKey: "name",
      cell: (row) => (
        <div>
          <div style={{ fontWeight: "700", color: "#f9fafb" }}>{row.name}</div>
          <div style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px" }}>
            <MapPin size={12} /> {row.district}, {row.state}
          </div>
        </div>
      )
    },
    { header: "State", accessorKey: "state" },
    { header: "Type", accessorKey: "type", cell: (r) => <span className="badge badge-indigo">{r.type}</span> },
    { header: "Institutions", accessorKey: "institutions", cell: (r) => (r.institutions || 0).toLocaleString() },
    { header: "Students", accessorKey: "students", cell: (r) => (r.students || 0).toLocaleString() },
    { header: "Graduation %", accessorKey: "graduationRate", cell: (r) => `${r.graduationRate}%` },
    { header: "Placement %", accessorKey: "placementRate", cell: (r) => <span style={{ fontWeight: "700", color: "#34d399" }}>{r.placementRate}%</span> },
    { header: "Status", accessorKey: "status", cell: (r) => <StatusBadge status={r.status} /> },
    {
      header: "Actions",
      cell: (r) => (
        <div style={{ display: "flex", gap: "6px" }}>
          <button className="btn btn-outline btn-sm" onClick={() => handleOpenViewModal(r)} title="View Details">
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
          <h1 style={{ fontSize: "1.5rem" }}>University Management Directory</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Directory and performance analytics for higher education universities across {globalFilters.state}
          </p>
        </div>
        <button className="btn btn-primary" onClick={handleOpenAddModal}>
          <Plus size={16} /> Add University
        </button>
      </div>

      <div className="glass-card">
        {loading ? (
          <div style={{ padding: "30px", textAlign: "center", color: "var(--text-muted)" }}>Loading University Records...</div>
        ) : (
          <DataTable
            columns={columns}
            data={universities}
            searchPlaceholder="Search by university name, district, or type..."
          />
        )}
      </div>

      {/* University Detail View Modal */}
      {showViewModal && selectedUniv && (
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
          <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "560px", background: "#111827" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "12px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <Building2 size={24} style={{ color: "var(--primary)" }} />
                <div>
                  <h3 style={{ fontSize: "1.2rem" }}>{selectedUniv.name}</h3>
                  <span style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Est. {selectedUniv.estYear || "N/A"}</span>
                </div>
              </div>
              <button className="btn btn-outline btn-icon" onClick={() => setShowViewModal(false)}>
                <X size={18} />
              </button>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "14px", fontSize: "0.9rem" }}>
              <div className="grid-2">
                <div><span style={{ color: "var(--text-muted)" }}>State:</span> <strong>{selectedUniv.state}</strong></div>
                <div><span style={{ color: "var(--text-muted)" }}>District:</span> <strong>{selectedUniv.district}</strong></div>
              </div>
              <div className="grid-2">
                <div><span style={{ color: "var(--text-muted)" }}>Type:</span> <strong>{selectedUniv.type}</strong></div>
                <div><span style={{ color: "var(--text-muted)" }}>Status:</span> <StatusBadge status={selectedUniv.status} /></div>
              </div>
              {selectedUniv.website && (
                <div>
                  <span style={{ color: "var(--text-muted)" }}>Website: </span>
                  <a href={selectedUniv.website} target="_blank" rel="noopener noreferrer" style={{ color: "var(--primary)", display: "inline-flex", alignItems: "center", gap: "4px" }}>
                    {selectedUniv.website} <ExternalLink size={12} />
                  </a>
                </div>
              )}
              {selectedUniv.address && (
                <div><span style={{ color: "var(--text-muted)" }}>Address:</span> {selectedUniv.address}</div>
              )}
              <hr style={{ borderColor: "var(--border-color)" }} />
              <div className="grid-2">
                <div><span style={{ color: "var(--text-muted)" }}>Affiliated Institutions:</span> <strong>{selectedUniv.institutions}</strong></div>
                <div><span style={{ color: "var(--text-muted)" }}>Total Students:</span> <strong>{(selectedUniv.students || 0).toLocaleString()}</strong></div>
              </div>
              <div className="grid-2">
                <div><span style={{ color: "var(--text-muted)" }}>Graduation Rate:</span> <strong style={{ color: "#38bdf8" }}>{selectedUniv.graduationRate}%</strong></div>
                <div><span style={{ color: "var(--text-muted)" }}>Placement Rate:</span> <strong style={{ color: "#34d399" }}>{selectedUniv.placementRate}%</strong></div>
              </div>
            </div>

            <div style={{ marginTop: "24px", display: "flex", justifyContent: "flex-end", gap: "10px" }}>
              <button className="btn btn-secondary" onClick={() => setShowViewModal(false)}>Close</button>
              <button
                className="btn btn-primary"
                onClick={() => {
                  setShowViewModal(false);
                  handleOpenEditModal(selectedUniv);
                }}
              >
                Edit University
              </button>
            </div>
          </div>
        </div>
      )}

      {/* University Add/Edit Modal */}
      <UniversityFormModal
        isOpen={showFormModal}
        onClose={() => setShowFormModal(false)}
        onSave={handleSaveUniversity}
        initialData={editingUniv}
      />
    </div>
  );
}
