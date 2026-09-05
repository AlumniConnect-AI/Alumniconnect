// Unified API Service connected directly to reactive persistent dataEngine & Firestore

import { dataEngine } from "./adminDataEngine";
import {
  MOCK_CAREER_OUTCOMES_BREAKDOWN,
  MOCK_NON_PLACEMENT_REASONS,
  MOCK_LONG_TERM_RETENTION,
  MOCK_CONSENT_COMPLIANCE,
  INITIAL_ADMIN_PROFILE
} from "../data/adminMockData";

export async function fetchAdminKpis(filters = {}) {
  await dataEngine.syncWithFirestore();
  return dataEngine.calculateKpis(filters);
}

export async function fetchStateOverview(filters = {}) {
  return dataEngine.getStateOverview(filters);
}

export async function fetchUniversities(filters = {}) {
  return dataEngine.getUniversities(filters);
}

export async function fetchUniversityById(id) {
  return dataEngine.getUniversityById(id);
}

export async function addUniversity(univData) {
  return dataEngine.addUniversity(univData);
}

export async function updateUniversity(id, fields) {
  return dataEngine.updateUniversity(id, fields);
}

export async function deleteUniversity(id) {
  return dataEngine.deleteUniversity(id);
}

export async function fetchInstitutions(filters = {}) {
  return dataEngine.getInstitutions(filters);
}

export async function fetchInstitutionById(id) {
  return dataEngine.getInstitutionById(id);
}

export async function addInstitution(instData) {
  return dataEngine.addInstitution(instData);
}

export async function updateInstitution(id, fields) {
  return dataEngine.updateInstitution(id, fields);
}

export async function deleteInstitution(id) {
  return dataEngine.deleteInstitution(id);
}

// --- STUDENT API METHODS ---
export async function fetchStudents(filters = {}) {
  return dataEngine.getStudents(filters);
}

export async function fetchCollegeStudentSummary(collegeId, collegeName) {
  return dataEngine.getCollegeStudentSummary(collegeId, collegeName);
}

export async function addStudent(studentData) {
  return dataEngine.addStudent(studentData);
}

export async function updateStudent(id, fields) {
  return dataEngine.updateStudent(id, fields);
}

export async function deleteStudent(id) {
  return dataEngine.deleteStudent(id);
}

export async function importStudentsBatch(parsedRows) {
  return dataEngine.importStudentsBatch(parsedRows);
}

export async function fetchCourses(filters = {}) {
  return dataEngine.getCourses(filters);
}

export async function addCourse(courseData) {
  return dataEngine.addCourse(courseData);
}

export async function updateCourse(id, fields) {
  return dataEngine.updateCourse(id, fields);
}

export async function deleteCourse(id) {
  return dataEngine.deleteCourse(id);
}

export async function fetchCareerOutcomes(filters = {}) {
  return {
    outcomes: MOCK_CAREER_OUTCOMES_BREAKDOWN,
    nonPlacementReasons: MOCK_NON_PLACEMENT_REASONS,
    longTermRetention: MOCK_LONG_TERM_RETENTION
  };
}

export async function fetchConsentCompliance() {
  return MOCK_CONSENT_COMPLIANCE;
}

export async function fetchReports() {
  return dataEngine.getReports();
}

export async function createReport(repData) {
  return dataEngine.addReport(repData);
}

export async function fetchDataSyncLogs() {
  return dataEngine.getSyncLogs();
}

export async function importCsvData(entityType, rows) {
  return dataEngine.importBatchData(entityType, rows);
}

export async function fetchAdminUsers() {
  return dataEngine.getAdminUsers();
}

export async function addAdminUser(userData) {
  return dataEngine.addAdminUser(userData);
}

export async function updateAdminUser(id, fields) {
  return dataEngine.updateAdminUser(id, fields);
}

export async function deleteAdminUser(id) {
  return dataEngine.deleteAdminUser(id);
}

// --- FIREBASE APP USERS (fetched from main project's RTDB) ---
export async function fetchFirebaseUsers(filters = {}) {
  return dataEngine.getFirebaseUsers(filters);
}

export async function loginAdmin(email, password) {
  if (email && password) {
    return { success: true, user: { ...INITIAL_ADMIN_PROFILE, email } };
  }
  throw new Error("Invalid admin credentials");
}

export async function signupAdmin(adminData) {
  return { success: true, user: { ...INITIAL_ADMIN_PROFILE, ...adminData } };
}
