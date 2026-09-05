// Centralized Mock Data for National Education & Career Analytics Admin Panel

export const INITIAL_ADMIN_PROFILE = {
  name: "Dr. Rajesh V. Sharma",
  email: "admin@maharashtra.edu.gov.in",
  organization: "Maharashtra State Council",
  designation: "Senior Analytics Director",
  state: "Maharashtra",
  role: "Super Admin",
  status: "Active",
  avatar: "RS"
};

export const MOCK_ADMIN_USERS = [
  { id: "adm-101", name: "Dr. Rajesh V. Sharma", email: "admin@maharashtra.edu.gov.in", organization: "Maharashtra State Council", designation: "Senior Analytics Director", role: "Super Admin", state: "Maharashtra", status: "Active", lastLogin: "Today, 09:42 AM" },
  { id: "adm-102", name: "Priya Nair", email: "p.nair@tn.edu.gov.in", organization: "Tamil Nadu Higher Education Board", designation: "State Data Coordinator", role: "State Admin", state: "Tamil Nadu", status: "Active", lastLogin: "Yesterday, 04:15 PM" },
  { id: "adm-103", name: "Anil Kulkarni", email: "a.kulkarni@mu.ac.in", organization: "University of Mumbai", designation: "Data Administrator", role: "Data Administrator", state: "Maharashtra", status: "Active", lastLogin: "02 Sep 2026, 11:30 AM" },
  { id: "adm-104", name: "Dr. Sunita Deshmukh", email: "s.deshmukh@highered.gov.in", organization: "National Council of Higher Education", designation: "Analytics Director", role: "Analytics Administrator", state: "All India", status: "Active", lastLogin: "01 Sep 2026, 02:20 PM" },
  { id: "adm-105", name: "Kiran Kumar", email: "kiran@telangana.edu.gov.in", organization: "Telangana State Council", designation: "Regional Administrator", role: "Institution Administrator", state: "Telangana", status: "Inactive", lastLogin: "20 Aug 2026, 10:05 AM" }
];

export const MOCK_KPIS = {
  totalUniversities: 1248,
  totalUniversitiesGrowth: "+4.2%",
  totalInstitutions: 45850,
  totalInstitutionsGrowth: "+8.1%",
  totalStudents: 28450000,
  totalStudentsGrowth: "+5.6%",
  totalCourses: 14200,
  totalCoursesGrowth: "+3.8%",
  totalGraduates: 6210000,
  totalGraduatesGrowth: "+4.9%",
  placementRate: 68.2,
  placementRateGrowth: "+3.5%",
  graduationRate: 74.6,
  graduationRateGrowth: "+2.1%",
  higherStudiesRate: 16.4,
  higherStudiesRateGrowth: "+1.2%",
  internshipRate: 81.5,
  internshipRateGrowth: "+6.4%",
  careerOutcomeRate: 84.6,
  careerOutcomeRateGrowth: "+4.0%"
};

export const STATES_LIST = [
  "All India",
  "Maharashtra",
  "Tamil Nadu",
  "Karnataka",
  "Kerala",
  "Telangana",
  "Andhra Pradesh",
  "Gujarat",
  "Rajasthan",
  "Uttar Pradesh",
  "West Bengal",
  "Delhi",
  "Madhya Pradesh"
];

export const MOCK_STATE_OVERVIEW = [
  { state: "Maharashtra", universities: 124, institutions: 4820, students: 3450000, graduates: 780000, placementRate: 72.4, graduationRate: 78.1, higherStudies: 15.2, careerOutcome: 87.6 },
  { state: "Tamil Nadu", universities: 108, institutions: 4210, students: 3120000, graduates: 710000, placementRate: 74.8, graduationRate: 80.4, higherStudies: 14.8, careerOutcome: 89.6 },
  { state: "Karnataka", universities: 96, institutions: 3890, students: 2890000, graduates: 640000, placementRate: 71.2, graduationRate: 76.8, higherStudies: 17.1, careerOutcome: 88.3 },
  { state: "Telangana", universities: 64, institutions: 2640, students: 1980000, graduates: 430000, placementRate: 69.5, graduationRate: 75.2, higherStudies: 16.8, careerOutcome: 86.3 },
  { state: "Gujarat", universities: 78, institutions: 3150, students: 2340000, graduates: 510000, placementRate: 67.8, graduationRate: 74.0, higherStudies: 13.9, careerOutcome: 81.7 },
  { state: "Uttar Pradesh", universities: 142, institutions: 6120, students: 4620000, graduates: 990000, placementRate: 61.4, graduationRate: 70.2, higherStudies: 18.4, careerOutcome: 79.8 },
  { state: "Delhi", universities: 45, institutions: 1450, students: 1250000, graduates: 290000, placementRate: 78.6, graduationRate: 82.5, higherStudies: 19.2, careerOutcome: 91.4 },
  { state: "Kerala", universities: 42, institutions: 1850, students: 1140000, graduates: 260000, placementRate: 66.4, graduationRate: 81.2, higherStudies: 21.4, careerOutcome: 87.8 },
  { state: "Rajasthan", universities: 85, institutions: 3240, students: 2150000, graduates: 460000, placementRate: 63.2, graduationRate: 71.8, higherStudies: 15.6, careerOutcome: 78.8 },
  { state: "West Bengal", universities: 68, institutions: 2980, students: 2050000, graduates: 440000, placementRate: 64.8, graduationRate: 73.4, higherStudies: 17.9, careerOutcome: 82.7 },
  { state: "Andhra Pradesh", universities: 62, institutions: 2510, students: 1870000, graduates: 410000, placementRate: 68.1, graduationRate: 74.9, higherStudies: 14.5, careerOutcome: 82.6 },
  { state: "Madhya Pradesh", universities: 74, institutions: 2990, students: 1960000, graduates: 420000, placementRate: 60.8, graduationRate: 69.5, higherStudies: 15.1, careerOutcome: 75.9 }
];

export const MOCK_UNIVERSITIES = [
  { id: "univ-1", name: "University of Mumbai", state: "Maharashtra", district: "Mumbai City", type: "State Public", institutions: 780, students: 540000, courses: 420, graduationRate: 79.2, placementRate: 74.5, status: "Active" },
  { id: "univ-2", name: "Savitribai Phule Pune University", state: "Maharashtra", district: "Pune", type: "State Public", institutions: 650, students: 480000, courses: 380, graduationRate: 81.5, placementRate: 76.8, status: "Active" },
  { id: "univ-3", name: "Anna University", state: "Tamil Nadu", district: "Chennai", type: "State Technical", institutions: 520, students: 410000, courses: 310, graduationRate: 83.0, placementRate: 80.2, status: "Active" },
  { id: "univ-4", name: "Visvesvaraya Technological University", state: "Karnataka", district: "Belagavi", type: "State Technical", institutions: 218, students: 320000, courses: 240, graduationRate: 77.4, placementRate: 73.1, status: "Active" },
  { id: "univ-5", name: "Jawaharlal Nehru Technological University", state: "Telangana", district: "Hyderabad", type: "State Technical", institutions: 290, students: 290000, courses: 210, graduationRate: 76.0, placementRate: 71.8, status: "Active" },
  { id: "univ-6", name: "University of Delhi", state: "Delhi", district: "Central Delhi", type: "Central Public", institutions: 91, students: 220000, courses: 290, graduationRate: 85.6, placementRate: 82.4, status: "Active" },
  { id: "univ-7", name: "Gujarat Technological University", state: "Gujarat", district: "Ahmedabad", type: "State Technical", institutions: 410, students: 350000, courses: 260, graduationRate: 74.8, placementRate: 69.4, status: "Active" },
  { id: "univ-8", name: "Dr. A.P.J. Abdul Kalam Technical University", state: "Uttar Pradesh", district: "Lucknow", type: "State Technical", institutions: 750, students: 590000, courses: 340, graduationRate: 71.2, placementRate: 64.5, status: "Active" }
];

export const MOCK_INSTITUTIONS = [
  { id: "inst-1", name: "Veermata Jijabai Technological Institute (VJTI)", university: "University of Mumbai", state: "Maharashtra", district: "Mumbai City", courses: 28, students: 4200, graduates: 980, placementRate: 92.4, internshipRate: 96.5, status: "Verified" },
  { id: "inst-2", name: "College of Engineering Pune (COEP)", university: "Savitribai Phule Pune University", state: "Maharashtra", district: "Pune", courses: 32, students: 4800, graduates: 1120, placementRate: 94.1, internshipRate: 98.0, status: "Verified" },
  { id: "inst-3", name: "College of Engineering, Guindy (CEG)", university: "Anna University", state: "Tamil Nadu", district: "Chennai", courses: 35, students: 5100, graduates: 1240, placementRate: 95.2, internshipRate: 97.4, status: "Verified" },
  { id: "inst-4", name: "BMS College of Engineering", university: "Visvesvaraya Technological University", state: "Karnataka", district: "Bengaluru", courses: 26, students: 3900, graduates: 890, placementRate: 88.6, internshipRate: 91.2, status: "Verified" },
  { id: "inst-5", name: "JNTU College of Engineering Hyderabad", university: "Jawaharlal Nehru Technological University", state: "Telangana", district: "Hyderabad", courses: 24, students: 3600, graduates: 840, placementRate: 87.2, internshipRate: 90.5, status: "Verified" },
  { id: "inst-6", name: "L.D. College of Engineering", university: "Gujarat Technological University", state: "Gujarat", district: "Ahmedabad", courses: 22, students: 3400, graduates: 780, placementRate: 82.5, internshipRate: 88.0, status: "Verified" }
];

export const MOCK_COURSES = [
  { id: "crs-1", name: "B.Tech Computer Science & Engineering", stream: "Engineering", students: 1420000, graduates: 320000, placementRate: 86.4, higherStudiesRate: 9.8, demandLevel: "Very High", topSkills: "Java, Python, Cloud, Data Structures", accountabilityStatus: "Excellent" },
  { id: "crs-2", name: "B.Tech Information Technology", stream: "Engineering", students: 980000, graduates: 210000, placementRate: 83.2, higherStudiesRate: 10.4, demandLevel: "Very High", topSkills: "JavaScript, React, SQL, DevOps", accountabilityStatus: "Excellent" },
  { id: "crs-3", name: "B.Tech Artificial Intelligence & Data Science", stream: "Engineering", students: 450000, graduates: 92000, placementRate: 89.1, higherStudiesRate: 8.5, demandLevel: "Very High", topSkills: "Machine Learning, PyTorch, SQL, AI", accountabilityStatus: "Excellent" },
  { id: "crs-4", name: "B.Tech Cyber Security", stream: "Engineering", students: 280000, graduates: 54000, placementRate: 85.0, higherStudiesRate: 9.1, demandLevel: "High", topSkills: "Ethical Hacking, Network Security, SIEM", accountabilityStatus: "Good" },
  { id: "crs-5", name: "B.Tech Electronics & Communication", stream: "Engineering", students: 1120000, graduates: 250000, placementRate: 72.5, higherStudiesRate: 15.2, demandLevel: "High", topSkills: "VLSI, Embedded Systems, IoT, C++", accountabilityStatus: "Good" },
  { id: "crs-6", name: "B.Tech Mechanical Engineering", stream: "Engineering", students: 1350000, graduates: 290000, placementRate: 61.8, higherStudiesRate: 18.5, demandLevel: "Medium", topSkills: "CAD/CAM, Thermodynamics, Robotics", accountabilityStatus: "Average" },
  { id: "crs-7", name: "B.Tech Civil Engineering", stream: "Engineering", students: 890000, graduates: 195000, placementRate: 58.2, higherStudiesRate: 19.1, demandLevel: "Medium", topSkills: "AutoCAD, Structural Analysis, STAAD Pro", accountabilityStatus: "Needs Improvement" },
  { id: "crs-8", name: "Master of Business Administration (MBA)", stream: "Management", students: 1200000, graduates: 410000, placementRate: 78.4, higherStudiesRate: 4.2, demandLevel: "High", topSkills: "Marketing, Financial Modeling, Analytics", accountabilityStatus: "Good" }
];

export const MOCK_CAREER_OUTCOMES_BREAKDOWN = [
  { category: "Placed (Corporate/Industry)", count: 4235220, percentage: 68.2, trend: "+3.5%" },
  { category: "Higher Studies (Masters/Ph.D)", count: 1018440, percentage: 16.4, trend: "+1.2%" },
  { category: "Government & Public Sector Jobs", count: 322920, percentage: 5.2, trend: "+0.8%" },
  { category: "Entrepreneurship / Startup Founders", count: 186300, percentage: 3.0, trend: "+1.1%" },
  { category: "Internships & Apprenticeships", count: 248400, percentage: 4.0, trend: "+0.5%" },
  { category: "Seeking Employment", count: 124200, percentage: 2.0, trend: "-1.8%" },
  { category: "Other Career Paths", count: 74520, percentage: 1.2, trend: "-0.3%" }
];

export const MOCK_NON_PLACEMENT_REASONS = [
  { reason: "Pursuing Higher Studies", count: 1018440, percentage: 51.5 },
  { reason: "Relocated / Family Commitments", count: 237400, percentage: 12.0 },
  { reason: "Further Professional Skills Training", count: 217600, percentage: 11.0 },
  { reason: "Entrepreneurship / Family Business", count: 186300, percentage: 9.4 },
  { reason: "Preparing for Competitive/Govt Exams", count: 197800, percentage: 10.0 },
  { reason: "Still Seeking Opportunity", count: 120000, percentage: 6.1 }
];

export const MOCK_LONG_TERM_RETENTION = [
  { period: "6 Month Outcome", employmentRetention: 91.2, higherStudiesRetention: 96.4, progressionIndex: 78.5 },
  { period: "12 Month Outcome", employmentRetention: 87.5, higherStudiesRetention: 94.2, progressionIndex: 83.0 },
  { period: "24 Month Outcome", employmentRetention: 84.1, higherStudiesRetention: 91.8, progressionIndex: 89.2 }
];

export const MOCK_CONSENT_COMPLIANCE = {
  totalRecords: 28450000,
  consentGiven: 26174000,
  consentPending: 1850000,
  consentRevoked: 426000,
  verifiedRecords: 25800000,
  consentRate: 92.0
};

export const MOCK_REPORTS = [
  { id: "rep-101", title: "National Education & Placement Performance Summary 2025-26", state: "All India", district: "All Districts", type: "Annual Performance", date: "2026-08-30", status: "Generated", size: "4.2 MB" },
  { id: "rep-102", title: "Maharashtra State Higher Education Outcome Report", state: "Maharashtra", district: "Mumbai & Pune", type: "State Analytics", date: "2026-08-28", status: "Generated", size: "2.8 MB" },
  { id: "rep-103", title: "Technical Education Placement & Salary Index", state: "Tamil Nadu", district: "Chennai", type: "Placement Analytics", date: "2026-08-25", status: "Generated", size: "1.9 MB" },
  { id: "rep-104", title: "Non-Placed Graduate Diagnostic & Intervention Analysis", state: "All India", district: "All Districts", type: "Diagnostic", date: "2026-08-20", status: "Generated", size: "3.5 MB" }
];

export const MOCK_DATA_SYNC_LOGS = [
  { id: "sync-1", entity: "University Accreditation & Enrollment Data", source: "UGC / AISHE API", recordsProcessed: 1248, status: "Validated & Synced", timestamp: "Today, 04:30 AM" },
  { id: "sync-2", entity: "College Level Student Placement Registers", source: "State Higher Ed Portals", recordsProcessed: 45850, status: "Validated & Synced", timestamp: "Yesterday, 11:45 PM" },
  { id: "sync-3", entity: "Graduate Career Outcome Survey 2026", source: "Alumni Direct Outcome Engine", recordsProcessed: 6210000, status: "Syncing (94%)", timestamp: "In Progress..." }
];
