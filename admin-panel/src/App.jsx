import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AdminAuthProvider, useAdminAuth } from "./context/AdminAuthContext";
import AdminLayout from "./components/AdminLayout";
import Login from "./pages/Login";
import Signup from "./pages/Signup";
import Dashboard from "./pages/Dashboard";
import Universities from "./pages/Universities";
import Institutions from "./pages/Institutions";
import CollegeStudentReport from "./pages/CollegeStudentReport";
import Students from "./pages/Students";
import Courses from "./pages/Courses";
import Placements from "./pages/Placements";
import CareerOutcomes from "./pages/CareerOutcomes";
import StateAnalytics from "./pages/StateAnalytics";
import Reports from "./pages/Reports";
import DataManagement from "./pages/DataManagement";
import AdminManagement from "./pages/AdminManagement";
import Settings from "./pages/Settings";

import UserManagement from "./pages/UserManagement";
import StudentsUserPage from "./pages/StudentsUserPage";
import AlumniUserPage from "./pages/AlumniUserPage";
import StaffUserPage from "./pages/StaffUserPage";

function ProtectedAdminRoute({ children }) {
  const { adminUser } = useAdminAuth();
  if (!adminUser) {
    return <Navigate to="/login" replace />;
  }
  return children;
}

export default function App() {
  return (
    <AdminAuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public Auth Routes */}
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />

          {/* Protected Admin Routes */}
          <Route
            path="/"
            element={
              <ProtectedAdminRoute>
                <AdminLayout />
              </ProtectedAdminRoute>
            }
          >
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            
            {/* Administration User Data Routes (Firestore) */}
            <Route path="users-data" element={<UserManagement initialCategory="All" />} />
            <Route path="users-data/students" element={<StudentsUserPage />} />
            <Route path="users-data/alumni" element={<AlumniUserPage />} />
            <Route path="users-data/staff" element={<StaffUserPage />} />

            <Route path="universities" element={<Universities />} />
            <Route path="institutions" element={<Institutions />} />
            <Route path="institutions/:institutionId/students" element={<CollegeStudentReport />} />
            <Route path="students" element={<Students />} />
            <Route path="courses" element={<Courses />} />
            <Route path="placements" element={<Placements />} />
            <Route path="career-outcomes" element={<CareerOutcomes />} />
            <Route path="state-analytics" element={<StateAnalytics />} />
            <Route path="reports" element={<Reports />} />
            <Route path="data-management" element={<DataManagement />} />
            <Route path="admin-management" element={<AdminManagement />} />
            <Route path="settings" element={<Settings />} />
          </Route>


          {/* Fallback */}
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </AdminAuthProvider>
  );
}
