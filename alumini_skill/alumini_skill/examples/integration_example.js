/**
 * EduBridge AI - Node.js Backend Integration Example
 * Demonstrates how the Node.js / Express backend connects to the Skill Gap Analyzer microservice.
 * Uses native fetch (Node.js 18+) for zero external dependencies.
 */

const SKILL_GAP_API_URL = process.env.SKILL_GAP_API_URL || 'http://localhost:8000';

/**
 * Analyze student skill gaps against a target career benchmark role
 * @param {string} studentName - Student's full name
 * @param {Array<string>} studentSkills - Current skills from student profile/resume
 * @param {string} targetRole - Target benchmark role (e.g. 'Full Stack Web Developer')
 * @returns {Promise<Object>} Detailed skill gap analysis and recommendations
 */
async function analyzeStudentSkillGap(studentName, studentSkills, targetRole) {
  try {
    const response = await fetch(`${SKILL_GAP_API_URL}/api/v1/skill-gap/analyze`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        student_name: studentName,
        student_skills: studentSkills,
        target_role: targetRole,
        experience_level: 'Entry Level'
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`API returned ${response.status}: ${errText}`);
    }

    const result = await response.json();
    console.log(`\n=== Skill Gap Analysis for ${result.student_name} ===`);
    console.log(`Target Role: ${result.target_role}`);
    console.log(`Placement Readiness Score: ${result.placement_readiness_score}% (${result.readiness_level})`);
    console.log(`Matched Skills (${result.matched_skills_count}):`, result.matched_skills.map(s => s.skill_name).join(', '));
    console.log(`Missing Critical Skills:`, result.missing_critical_skills.map(s => s.skill_name).join(', '));
    console.log(`Missing Secondary Skills:`, result.missing_secondary_skills.map(s => s.skill_name).join(', '));
    
    console.log('\n--- Recommended Courses ---');
    result.recommended_courses.forEach(c => {
      console.log(`• [${c.skill}] ${c.title} (${c.provider}) - ${c.url}`);
    });

    console.log('\n--- Recommended Portfolio Projects ---');
    result.recommended_projects.forEach(p => {
      console.log(`• 🛠️ ${p.title} [${p.difficulty}] - Covers: ${p.missing_skills_covered.join(', ')}`);
    });

    return result;
  } catch (error) {
    console.error('Error calling Skill Gap Analyzer API:', error.message);
    throw error;
  }
}

/**
 * Analyze student skills against a live Job Posting description
 */
async function analyzeAgainstJobPosting(studentName, studentSkills, jobDescription) {
  try {
    const response = await fetch(`${SKILL_GAP_API_URL}/api/v1/skill-gap/analyze-jd`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        student_name: studentName,
        student_skills: studentSkills,
        job_description_text: jobDescription,
        target_role: 'Job Posting'
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`API returned ${response.status}: ${errText}`);
    }

    return await response.json();
  } catch (error) {
    console.error('Error in JD analysis:', error.message);
    throw error;
  }
}

// Example Execution
if (require.main === module) {
  const sampleStudentSkills = ['JavaScript', 'HTML5', 'CSS3', 'Python', 'Git'];
  const targetRole = 'Full Stack Web Developer';

  analyzeStudentSkillGap('Aman Gupta', sampleStudentSkills, targetRole)
    .then(() => console.log('\nAnalysis completed successfully.'))
    .catch(err => console.error(err));
}

module.exports = {
  analyzeStudentSkillGap,
  analyzeAgainstJobPosting
};
