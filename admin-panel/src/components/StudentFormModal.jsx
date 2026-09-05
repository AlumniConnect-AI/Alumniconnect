import { useState, useEffect } from "react";
import { X, UserCheck, Save } from "lucide-react";

export default function StudentFormModal({ isOpen, onClose, onSave, initialData, institutions = [] }) {
  const [formData, setFormData] = useState({
    studentId: "",
    name: "",
    email: "",
    phone: "",
    gender: "Male",
    collegeId: "",
    course: "B.Tech Computer Science & Engineering",
    department: "Computer Engineering",
    academicYear: "3rd Year (2023)",
    graduationYear: "2026",
    placementStatus: "Seeking Opportunities",
    careerOutcome: "Seeking",
    status: "Currently Studying"
  });
  const [error, setError] = useState("");

  useEffect(() => {
    const defaultInstId = institutions.length > 0 ? institutions[0].id : "";
    if (initialData) {
      setFormData({
        studentId: initialData.studentId || initialData.id || "",
        name: initialData.name || "",
        email: initialData.email || "",
        phone: initialData.phone || "",
        gender: initialData.gender || "Male",
        collegeId: initialData.collegeId || defaultInstId,
        course: initialData.course || "B.Tech Computer Science & Engineering",
        department: initialData.department || "Computer Engineering",
        academicYear: initialData.academicYear || "3rd Year (2023)",
        graduationYear: initialData.graduationYear || "2026",
        placementStatus: initialData.placementStatus || "Seeking Opportunities",
        careerOutcome: initialData.careerOutcome || "Seeking",
        status: initialData.status || "Currently Studying"
      });
    } else {
      setFormData({
        studentId: `STU-2025-${Math.floor(1000 + Math.random() * 9000)}`,
        name: "",
        email: "",
        phone: "",
        gender: "Male",
        collegeId: defaultInstId,
        course: "B.Tech Computer Science & Engineering",
        department: "Computer Engineering",
        academicYear: "3rd Year (2023)",
        graduationYear: "2026",
        placementStatus: "Seeking Opportunities",
        careerOutcome: "Seeking",
        status: "Currently Studying"
      });
    }
  }, [initialData, isOpen, institutions]);

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    setError("");

    if (!formData.name || !formData.collegeId) {
      setError("Student Name and Affiliated College are required.");
      return;
    }

    onSave(formData);
    onClose();
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
      <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "660px", background: "#111827", maxHeight: "90vh", overflowY: "auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "14px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <UserCheck size={24} style={{ color: "var(--primary)" }} />
            <h3 style={{ fontSize: "1.25rem", fontWeight: "700" }}>
              {initialData ? "Edit Student Record" : "Manually Add Student"}
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

        <form onSubmit={handleSubmit}>
          <div className="grid-2">
            <div className="form-group">
              <label>Student ID *</label>
              <input
                type="text"
                className="form-control"
                value={formData.studentId}
                onChange={(e) => setFormData({ ...formData, studentId: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label>Student Full Name *</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Rahul Sharma"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>
          </div>

          <div className="grid-3">
            <div className="form-group">
              <label>Email Address</label>
              <input
                type="email"
                className="form-control"
                placeholder="student@edu.in"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>Phone Number</label>
              <input
                type="text"
                className="form-control"
                placeholder="+91 9820012345"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>Gender *</label>
              <select
                className="form-select"
                value={formData.gender}
                onChange={(e) => setFormData({ ...formData, gender: e.target.value })}
              >
                <option value="Male">Male</option>
                <option value="Female">Female</option>
                <option value="Other">Other / Unspecified</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label>Affiliated College / Institution *</label>
            <select
              className="form-select"
              value={formData.collegeId}
              onChange={(e) => setFormData({ ...formData, collegeId: e.target.value })}
              required
            >
              {institutions.map((inst) => (
                <option key={inst.id} value={inst.id}>
                  {inst.name} ({inst.university})
                </option>
              ))}
            </select>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Academic Course</label>
              <select
                className="form-select"
                value={formData.course}
                onChange={(e) => setFormData({ ...formData, course: e.target.value })}
              >
                <option value="B.Tech Computer Science & Engineering">B.Tech Computer Science & Engineering</option>
                <option value="B.Tech Information Technology">B.Tech Information Technology</option>
                <option value="B.Tech Artificial Intelligence & Data Science">B.Tech Artificial Intelligence & Data Science</option>
                <option value="B.Tech Cyber Security">B.Tech Cyber Security</option>
                <option value="B.Tech Electronics & Communication">B.Tech Electronics & Communication</option>
                <option value="B.Tech Mechanical Engineering">B.Tech Mechanical Engineering</option>
                <option value="B.Tech Civil Engineering">B.Tech Civil Engineering</option>
                <option value="Master of Business Administration (MBA)">Master of Business Administration (MBA)</option>
              </select>
            </div>

            <div className="form-group">
              <label>Department</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Computer Engineering"
                value={formData.department}
                onChange={(e) => setFormData({ ...formData, department: e.target.value })}
              />
            </div>
          </div>

          <div className="grid-3">
            <div className="form-group">
              <label>Academic Year</label>
              <select
                className="form-select"
                value={formData.academicYear}
                onChange={(e) => setFormData({ ...formData, academicYear: e.target.value })}
              >
                <option value="1st Year (2025)">1st Year (2025)</option>
                <option value="2nd Year (2024)">2nd Year (2024)</option>
                <option value="3rd Year (2023)">3rd Year (2023)</option>
                <option value="4th Year / Final">4th Year / Final</option>
              </select>
            </div>

            <div className="form-group">
              <label>Graduation Year</label>
              <input
                type="text"
                className="form-control"
                value={formData.graduationYear}
                onChange={(e) => setFormData({ ...formData, graduationYear: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>Enrollment Status</label>
              <select
                className="form-select"
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
              >
                <option value="Currently Studying">Currently Studying</option>
                <option value="Graduated">Graduated</option>
                <option value="Discontinued">Discontinued</option>
              </select>
            </div>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Placement Status</label>
              <select
                className="form-select"
                value={formData.placementStatus}
                onChange={(e) => setFormData({ ...formData, placementStatus: e.target.value })}
              >
                <option value="Placed">Placed</option>
                <option value="Seeking Opportunities">Seeking Opportunities</option>
                <option value="Higher Studies">Higher Studies</option>
                <option value="In Progress">In Progress</option>
                <option value="Not Eligible">Not Eligible</option>
              </select>
            </div>

            <div className="form-group">
              <label>Career Outcome</label>
              <select
                className="form-select"
                value={formData.careerOutcome}
                onChange={(e) => setFormData({ ...formData, careerOutcome: e.target.value })}
              >
                <option value="Corporate Job">Corporate Job</option>
                <option value="Higher Education">Higher Education</option>
                <option value="Entrepreneurship">Entrepreneurship</option>
                <option value="Government Exam">Government Exam</option>
                <option value="Seeking">Seeking Opportunities</option>
              </select>
            </div>
          </div>

          <div style={{ marginTop: "24px", display: "flex", justifyContent: "flex-end", gap: "10px" }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              <Save size={16} /> {initialData ? "Save Changes" : "Create Student Record"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
