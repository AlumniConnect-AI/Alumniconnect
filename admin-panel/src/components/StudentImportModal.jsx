import { useState, useRef } from "react";
import { X, UploadCloud, CheckCircle2, AlertTriangle, FileSpreadsheet, Layers } from "lucide-react";
import * as XLSX from "xlsx";

export default function StudentImportModal({ isOpen, onClose, onImportSuccess }) {
  const [fileData, setFileData] = useState(null);
  const [fileName, setFileName] = useState("");
  const [previewStats, setPreviewStats] = useState(null);
  const [parsedRows, setParsedRows] = useState([]);
  const [error, setError] = useState("");
  const fileInputRef = useRef(null);

  if (!isOpen) return null;

  const handleFileChange = (e) => {
    setError("");
    setPreviewStats(null);
    setParsedRows([]);

    const file = e.target.files[0];
    if (!file) return;

    setFileName(file.name);
    const reader = new FileReader();

    reader.onload = (evt) => {
      try {
        const bstr = evt.target.result;
        const workbook = XLSX.read(bstr, { type: "binary" });
        const firstSheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[firstSheetName];
        const jsonRows = XLSX.utils.sheet_to_json(worksheet, { defval: "" });

        if (!jsonRows || jsonRows.length === 0) {
          setError("Uploaded file is empty or contains no data rows.");
          return;
        }

        // Validate preview
        let valid = 0;
        let invalid = 0;
        let duplicate = 0;
        const seenIds = new Set();

        jsonRows.forEach((r, idx) => {
          const sId = r["Student ID"] || r.studentId || r.id;
          const sName = r["Student Name"] || r.name;
          const sCollege = r["College"] || r.college;

          if (!sName || !sCollege) {
            invalid++;
          } else if (sId && seenIds.has(sId)) {
            duplicate++;
          } else {
            if (sId) seenIds.add(sId);
            valid++;
          }
        });

        setParsedRows(jsonRows);
        setPreviewStats({
          totalRows: jsonRows.length,
          validRows: valid,
          invalidRows: invalid,
          duplicateRows: duplicate
        });
      } catch (err) {
        setError(`Failed to read file: ${err.message}`);
      }
    };

    reader.readAsBinaryString(file);
  };

  const handleExecuteImport = () => {
    if (!parsedRows || parsedRows.length === 0) return;
    try {
      const res = onImportSuccess(parsedRows);
      alert(`Import completed successfully!\nImported Records: ${res.importedCount}\nDuplicates Skipped: ${res.duplicateCount}\nInvalid Skipped: ${res.invalidCount}`);
      onClose();
    } catch (err) {
      setError(err.message || "Failed to import student dataset.");
    }
  };

  return (
    <div
      style={{
        position: "fixed",
        top: 0, left: 0, right: 0, bottom: 0,
        background: "rgba(0,0,0,0.75)",
        backdropFilter: "blur(4px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 120,
        padding: "20px"
      }}
    >
      <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "580px", background: "#111827", maxHeight: "90vh", overflowY: "auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "14px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <FileSpreadsheet size={24} style={{ color: "var(--accent-emerald)" }} />
            <h3 style={{ fontSize: "1.25rem", fontWeight: "700" }}>
              Batch Student Data Import (CSV / XLSX)
            </h3>
          </div>
          <button className="btn btn-outline btn-icon" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {error && (
          <div style={{ background: "rgba(244, 63, 94, 0.15)", border: "1px solid rgba(244, 63, 94, 0.3)", color: "#f87171", padding: "10px 14px", borderRadius: "var(--radius-md)", fontSize: "0.85rem", marginBottom: "16px" }}>
            {error}
          </div>
        )}

        <input
          type="file"
          ref={fileInputRef}
          accept=".csv, .xlsx, .xls"
          style={{ display: "none" }}
          onChange={handleFileChange}
        />

        <div
          onClick={() => fileInputRef.current && fileInputRef.current.click()}
          style={{
            border: "2px dashed var(--border-color)",
            borderRadius: "var(--radius-md)",
            padding: "30px",
            textAlign: "center",
            cursor: "pointer",
            background: "rgba(255,255,255,0.02)",
            marginBottom: "20px",
            transition: "all 0.2s ease"
          }}
        >
          <UploadCloud size={36} style={{ color: "var(--primary)", marginBottom: "10px" }} />
          <div style={{ fontWeight: "700", color: "#f9fafb", fontSize: "1rem" }}>
            {fileName ? fileName : "Click or Drag & Drop Student File (CSV / XLSX)"}
          </div>
          <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "4px" }}>
            Required Columns: Student ID, Student Name, College, University, Course, Department, Academic Year, Placement Status
          </div>
        </div>

        {previewStats && (
          <div className="glass-card" style={{ marginBottom: "20px", background: "rgba(255,255,255,0.03)" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "12px", fontWeight: "700", color: "var(--primary)" }}>
              <Layers size={18} /> Import Validation Preview
            </div>
            <div className="grid-2" style={{ gap: "10px", fontSize: "0.85rem" }}>
              <div style={{ padding: "10px", background: "rgba(255,255,255,0.03)", borderRadius: "6px" }}>
                Total Rows Processed: <strong>{previewStats.totalRows.toLocaleString()}</strong>
              </div>
              <div style={{ padding: "10px", background: "rgba(16, 185, 129, 0.1)", borderRadius: "6px", color: "#34d399" }}>
                Valid Rows: <strong>{previewStats.validRows.toLocaleString()}</strong>
              </div>
              <div style={{ padding: "10px", background: "rgba(245, 158, 11, 0.1)", borderRadius: "6px", color: "#fbbf24" }}>
                Duplicate Rows: <strong>{previewStats.duplicateRows.toLocaleString()}</strong>
              </div>
              <div style={{ padding: "10px", background: "rgba(244, 63, 94, 0.1)", borderRadius: "6px", color: "#f87171" }}>
                Invalid Rows: <strong>{previewStats.invalidRows.toLocaleString()}</strong>
              </div>
            </div>
          </div>
        )}

        <div style={{ display: "flex", justifyContent: "flex-end", gap: "10px" }}>
          <button type="button" className="btn btn-secondary" onClick={onClose}>
            Cancel
          </button>
          <button
            type="button"
            className="btn btn-primary"
            disabled={!previewStats || previewStats.validRows === 0}
            onClick={handleExecuteImport}
          >
            <CheckCircle2 size={16} /> Import Valid Records ({previewStats ? previewStats.validRows : 0})
          </button>
        </div>
      </div>
    </div>
  );
}
