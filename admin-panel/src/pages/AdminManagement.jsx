import { useState, useEffect } from "react";
import { UserPlus, Edit, Trash2 } from "lucide-react";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import AdminUserFormModal from "../components/AdminUserFormModal";
import { fetchAdminUsers, addAdminUser, updateAdminUser, deleteAdminUser } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";

export default function AdminManagement() {
  const [admins, setAdmins] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showFormModal, setShowFormModal] = useState(false);
  const [editingAdmin, setEditingAdmin] = useState(null);

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetchAdminUsers();
      setAdmins(res);
    } catch (err) {
      console.error("Failed to fetch admin users:", err);
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
  }, []);

  const handleOpenAddModal = () => {
    setEditingAdmin(null);
    setShowFormModal(true);
  };

  const handleOpenEditModal = (adm) => {
    setEditingAdmin(adm);
    setShowFormModal(true);
  };

  const handleDelete = async (adm) => {
    if (window.confirm(`Are you sure you want to deactivate admin user "${adm.name}"?`)) {
      try {
        await deleteAdminUser(adm.id);
        alert(`Admin user "${adm.name}" deactivated.`);
      } catch (err) {
        alert(err.message || "Failed to delete user.");
      }
    }
  };

  const handleSaveAdmin = async (formData) => {
    try {
      if (editingAdmin) {
        await updateAdminUser(editingAdmin.id, formData);
        alert(`Admin user "${formData.name}" updated successfully.`);
      } else {
        await addAdminUser(formData);
        alert(`Admin user "${formData.name}" created successfully.`);
      }
      loadData();
    } catch (err) {
      alert(err.message || "Operation failed.");
    }
  };

  const columns = [
    {
      header: "Admin Name",
      accessorKey: "name",
      cell: (r) => (
        <div>
          <div style={{ fontWeight: "700", color: "#f9fafb" }}>{r.name}</div>
          <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>{r.email}</div>
        </div>
      )
    },
    { header: "Organization", accessorKey: "organization" },
    { header: "Designation", accessorKey: "designation" },
    { header: "State", accessorKey: "state" },
    { header: "Role", accessorKey: "role", cell: (r) => <StatusBadge status={r.role} /> },
    { header: "Status", accessorKey: "status", cell: (r) => <StatusBadge status={r.status} /> },
    { header: "Last Login", accessorKey: "lastLogin" },
    {
      header: "Actions",
      cell: (r) => (
        <div style={{ display: "flex", gap: "6px" }}>
          <button className="btn btn-outline btn-sm" onClick={() => handleOpenEditModal(r)} title="Edit Admin Role">
            <Edit size={14} />
          </button>
          <button className="btn btn-secondary btn-sm" style={{ color: "var(--accent-rose)" }} onClick={() => handleDelete(r)} title="Deactivate User">
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
          <h1 style={{ fontSize: "1.5rem" }}>Admin User & Role Governance</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Access control management for Super Admins, State Admins, Data Administrators, and Analytics Officers
          </p>
        </div>
        <button className="btn btn-primary" onClick={handleOpenAddModal}>
          <UserPlus size={16} /> Add New Admin
        </button>
      </div>

      <div className="glass-card">
        {loading ? (
          <div style={{ padding: "30px", textAlign: "center", color: "var(--text-muted)" }}>Loading Admin Roster...</div>
        ) : (
          <DataTable columns={columns} data={admins} searchPlaceholder="Search admin name or organization..." />
        )}
      </div>

      <AdminUserFormModal
        isOpen={showFormModal}
        onClose={() => setShowFormModal(false)}
        onSave={handleSaveAdmin}
        initialData={editingAdmin}
      />
    </div>
  );
}
