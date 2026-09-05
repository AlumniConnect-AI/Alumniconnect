import { createContext, useContext, useState, useEffect } from "react";
import { INITIAL_ADMIN_PROFILE } from "../data/adminMockData";
import { loginAdmin, signupAdmin } from "../services/adminApiService";

const AdminAuthContext = createContext(null);

export function AdminAuthProvider({ children }) {
  const [adminUser, setAdminUser] = useState(() => {
    const saved = localStorage.getItem("alumni_admin_session");
    return saved ? JSON.parse(saved) : INITIAL_ADMIN_PROFILE;
  });

  const [globalFilters, setGlobalFilters] = useState({
    country: "India",
    state: "All India",
    district: "All Districts",
    university: "All Universities",
    institution: "All Institutions",
    course: "All Courses",
    academicYear: "2025-2026"
  });

  useEffect(() => {
    if (adminUser) {
      localStorage.setItem("alumni_admin_session", JSON.stringify(adminUser));
    } else {
      localStorage.removeItem("alumni_admin_session");
    }
  }, [adminUser]);

  const handleLogin = async (email, password) => {
    const res = await loginAdmin(email, password);
    setAdminUser(res.user);
    return res;
  };

  const handleSignup = async (formData) => {
    const res = await signupAdmin(formData);
    setAdminUser(res.user);
    return res;
  };

  const handleLogout = () => {
    setAdminUser(null);
    localStorage.removeItem("alumni_admin_session");
  };

  const updateFilters = (newFilters) => {
    setGlobalFilters(prev => ({ ...prev, ...newFilters }));
  };

  return (
    <AdminAuthContext.Provider
      value={{
        adminUser,
        login: handleLogin,
        signup: handleSignup,
        logout: handleLogout,
        globalFilters,
        updateFilters
      }}
    >
      {children}
    </AdminAuthContext.Provider>
  );
}

export function useAdminAuth() {
  const ctx = useContext(AdminAuthContext);
  if (!ctx) {
    throw new Error("useAdminAuth must be used within an AdminAuthProvider");
  }
  return ctx;
}
