import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./contexts/AuthContext";
import Login from "./pages/Login";
import Layout from "./components/Layout";
import Dashboard from "./pages/Dashboard";
import UserManagement from "./pages/UserManagement";
import StaffVerification from "./pages/StaffVerification";
import JobModeration from "./pages/JobModeration";
import EventManagement from "./pages/EventManagement";
import ReportsSafety from "./pages/ReportsSafety";
import Analytics from "./pages/Analytics";
import ActivityLog from "./pages/ActivityLog";

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Login />} />
          <Route element={<Layout />}>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/users" element={<UserManagement />} />
            <Route path="/staff" element={<StaffVerification />} />
            <Route path="/jobs" element={<JobModeration />} />
            <Route path="/events" element={<EventManagement />} />
            <Route path="/reports" element={<ReportsSafety />} />
            <Route path="/analytics" element={<Analytics />} />
            <Route path="/activity" element={<ActivityLog />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
