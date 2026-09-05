import { useState } from "react";
import { Search, Download } from "lucide-react";

export default function DataTable({ columns, data, searchPlaceholder = "Search records...", onExport }) {
  const [searchTerm, setSearchTerm] = useState("");

  const filteredData = data.filter(item => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return Object.values(item).some(val => 
      val && String(val).toLowerCase().includes(term)
    );
  });

  const handleExportCSV = () => {
    if (onExport) {
      onExport(filteredData);
      return;
    }
    // Default CSV exporter
    if (!filteredData.length) return;
    const headers = columns.map(c => c.header).join(",");
    const rows = filteredData.map(row => 
      columns.map(c => {
        const val = c.accessorKey ? row[c.accessorKey] : "";
        return `"${String(val).replace(/"/g, '""')}"`;
      }).join(",")
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `export_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: "12px" }}>
        <div style={{ position: "relative", width: "100%", maxWidth: "320px" }}>
          <Search size={16} style={{ position: "absolute", left: "12px", top: "50%", transform: "translateY(-50%)", color: "var(--text-muted)" }} />
          <input
            type="text"
            className="form-control"
            placeholder={searchPlaceholder}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{ paddingLeft: "36px" }}
          />
        </div>

        <button className="btn btn-secondary btn-sm" onClick={handleExportCSV}>
          <Download size={14} />
          <span>Export CSV</span>
        </button>
      </div>

      <div className="table-responsive" style={{ border: "1px solid var(--border-color)", borderRadius: "var(--radius-md)", background: "rgba(17, 24, 39, 0.4)" }}>
        <table className="data-table">
          <thead>
            <tr>
              {columns.map((col, idx) => (
                <th key={idx} style={col.style}>
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filteredData.length > 0 ? (
              filteredData.map((row, rIdx) => (
                <tr key={rIdx}>
                  {columns.map((col, cIdx) => (
                    <td key={cIdx} style={col.style}>
                      {col.cell ? col.cell(row) : row[col.accessorKey]}
                    </td>
                  ))}
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={columns.length} style={{ textAlign: "center", padding: "32px", color: "var(--text-muted)" }}>
                  No matching records found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      
      <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", textAlign: "right" }}>
        Showing {filteredData.length} of {data.length} total entries
      </div>
    </div>
  );
}
