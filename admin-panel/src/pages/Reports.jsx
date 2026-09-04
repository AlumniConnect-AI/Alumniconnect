import { useState, useEffect } from "react";
import { FileText, Download, Plus, Filter, CheckCircle2 } from "lucide-react";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import ReportGeneratorModal from "../components/ReportGeneratorModal";
import { fetchReports, createReport } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";

export default function Reports() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showGeneratorModal, setShowGeneratorModal] = useState(false);

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetchReports();
      setReports(res);
    } catch (err) {
      console.error("Failed to fetch reports:", err);
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

  const handleDownloadReport = (rep) => {
    const csvContent = "data:text/csv;charset=utf-8," +
      `Report Title,${rep.title}\nState,${rep.state}\nType,${rep.type}\nGenerated Date,${rep.date}\nStatus,${rep.status}\n`;
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `${rep.title.toLowerCase().replace(/\s+/g, "_")}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleSaveReport = async (formData) => {
    try {
      await createReport(formData);
      alert(`Report "${formData.title}" generated successfully.`);
      loadData();
    } catch (err) {
      alert(err.message || "Failed to generate report.");
    }
  };

  const columns = [
    {
      header: "Report Title",
      accessorKey: "title",
      cell: (r) => (
        <div>
          <div style={{ fontWeight: "700", color: "#f9fafb" }}>{r.title}</div>
          <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Scope: {r.state} • {r.district}</div>
        </div>
      )
    },
    { header: "Report Type", accessorKey: "type" },
    { header: "Generated Date", accessorKey: "date" },
    { header: "File Size", accessorKey: "size" },
    { header: "Status", accessorKey: "status", cell: (r) => <StatusBadge status={r.status} /> },
    {
      header: "Export Actions",
      cell: (r) => (
        <button className="btn btn-outline btn-sm" onClick={() => handleDownloadReport(r)}>
          <Download size={14} /> Download Report (CSV)
        </button>
      )
    }
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "12px" }}>
        <div>
          <h1 style={{ fontSize: "1.5rem" }}>Executive Reports & Audit Repository</h1>
          <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
            Downloadable state-wide higher education outcome audits, compliance filings, and placement catalogs
          </p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowGeneratorModal(true)}>
          <Plus size={16} /> Generate New Report
        </button>
      </div>

      <div className="glass-card">
        {loading ? (
          <div style={{ padding: "30px", textAlign: "center", color: "var(--text-muted)" }}>Loading Reports Catalog...</div>
        ) : (
          <DataTable columns={columns} data={reports} searchPlaceholder="Search reports by title or type..." />
        )}
      </div>

      <ReportGeneratorModal
        isOpen={showGeneratorModal}
        onClose={() => setShowGeneratorModal(false)}
        onSave={handleSaveReport}
      />
    </div>
  );
}
