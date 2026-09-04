import { useState, useEffect, useRef } from "react";
import { Database, UploadCloud, RefreshCw, FileText, CheckCircle2, AlertTriangle, X } from "lucide-react";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import { fetchDataSyncLogs, importCsvData } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";

export default function DataManagement() {
  const [syncLogs, setSyncLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeImportType, setActiveImportType] = useState(null);
  const [importStatus, setImportStatus] = useState(null);
  const fileInputRef = useRef(null);

  const loadLogs = async () => {
    try {
      setLoading(true);
      const res = await fetchDataSyncLogs();
      setSyncLogs(res);
    } catch (err) {
      console.error("Failed to fetch data sync logs:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLogs();
    const unsubscribe = dataEngine.subscribe(() => {
      loadLogs();
    });
    return () => unsubscribe();
  }, []);

  const importTypes = [
    { type: "University", title: "Import University Data", desc: "Upload CSV schema of UGC accredited universities", icon: Database },
    { type: "Institution", title: "Import Institution Data", desc: "Batch import college profiles & district affiliations", icon: Database },
    { type: "Student", title: "Import Student Data", desc: "Upload aggregated enrollment & degree completion records", icon: Database },
    { type: "Course", title: "Import Course Data", desc: "Curriculum & skill domain mapping tables", icon: Database },
    { type: "Placement", title: "Import Placement Data", desc: "Corporate campus placement registers & package distributions", icon: Database }
  ];

  const handleOpenUpload = (imp) => {
    setActiveImportType(imp.type);
    setImportStatus(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
      fileInputRef.current.click();
    }
  };

  const handleFileSelected = (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (event) => {
      try {
        const text = event.target.result;
        const lines = text.split("\n").map(l => l.trim()).filter(Boolean);
        if (lines.length < 2) {
          setImportStatus({ success: false, message: "Invalid CSV file. Must contain header row and data rows." });
          return;
        }

        const headers = lines[0].split(",").map(h => h.trim().replace(/^"|"$/g, ""));
        const rows = lines.slice(1).map(line => {
          const vals = line.split(",").map(v => v.trim().replace(/^"|"$/g, ""));
          const obj = {};
          headers.forEach((h, i) => {
            obj[h] = vals[i] || "";
          });
          return obj;
        });

        // Validate records
        const count = await importCsvData(activeImportType, rows);
        setImportStatus({
          success: true,
          message: `Successfully validated and imported ${count > 0 ? count : rows.length} records into the live ${activeImportType} database!`,
          count: count > 0 ? count : rows.length
        });
        loadLogs();
      } catch (err) {
        setImportStatus({ success: false, message: `Import error: ${err.message}` });
      }
    };
    reader.readAsText(file);
  };

  const columns = [
    { header: "Entity / Data Stream", accessorKey: "entity", cell: (r) => <strong>{r.entity}</strong> },
    { header: "Data Source", accessorKey: "source" },
    { header: "Records Processed", accessorKey: "recordsProcessed", cell: (r) => (r.recordsProcessed || 0).toLocaleString() },
    { header: "Sync Status", accessorKey: "status", cell: (r) => <StatusBadge status={r.status} /> },
    { header: "Timestamp", accessorKey: "timestamp" }
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      {/* Hidden File Input */}
      <input
        type="file"
        ref={fileInputRef}
        accept=".csv, .txt"
        style={{ display: "none" }}
        onChange={handleFileSelected}
      />

      <div>
        <h1 style={{ fontSize: "1.5rem" }}>Data Management & Import Pipeline</h1>
        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
          CSV / API Data integration dropzones, schema validation status, and automated synchronization logs
        </p>
      </div>

      {importStatus && (
        <div
          className="animate-fade-in"
          style={{
            background: importStatus.success ? "rgba(16, 185, 129, 0.15)" : "rgba(244, 63, 94, 0.15)",
            border: `1px solid ${importStatus.success ? "rgba(16, 185, 129, 0.3)" : "rgba(244, 63, 94, 0.3)"}`,
            color: importStatus.success ? "#34d399" : "#f87171",
            padding: "16px",
            borderRadius: "var(--radius-md)",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between"
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            {importStatus.success ? <CheckCircle2 size={20} /> : <AlertTriangle size={20} />}
            <span style={{ fontSize: "0.9rem" }}>{importStatus.message}</span>
          </div>
          <button className="btn btn-outline btn-sm" onClick={() => setImportStatus(null)}>
            <X size={14} />
          </button>
        </div>
      )}

      {/* Import Dropzones */}
      <div className="grid-3">
        {importTypes.map((imp, idx) => (
          <div key={idx} className="glass-card" style={{ display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
            <div>
              <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "10px" }}>
                <UploadCloud size={20} style={{ color: "var(--primary)" }} />
                <h3 style={{ fontSize: "1.05rem" }}>{imp.title}</h3>
              </div>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "16px" }}>{imp.desc}</p>
            </div>
            <button
              className="btn btn-outline btn-sm"
              onClick={() => handleOpenUpload(imp)}
              style={{ width: "100%" }}
            >
              Upload Data File (CSV)
            </button>
          </div>
        ))}
      </div>

      {/* Data Sync Logs */}
      <div className="glass-card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
          <div>
            <h3 style={{ fontSize: "1.1rem" }}>Data Sync & Validation Activity</h3>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Live records sync status across state portals</p>
          </div>
          <button className="btn btn-secondary btn-sm" onClick={() => { dataEngine.syncWithFirestore(); alert("Manual API re-sync triggered."); }}>
            <RefreshCw size={14} /> Trigger Re-Sync
          </button>
        </div>
        {loading ? (
          <div style={{ padding: "20px", textAlign: "center", color: "var(--text-muted)" }}>Loading logs...</div>
        ) : (
          <DataTable columns={columns} data={syncLogs} searchPlaceholder="Search data logs..." />
        )}
      </div>
    </div>
  );
}
