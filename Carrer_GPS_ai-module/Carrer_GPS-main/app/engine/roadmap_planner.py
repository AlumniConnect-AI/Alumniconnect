from typing import List, Dict, Any, Optional
from app.models.profile import CareerProfile
from app.models.career import CareerDetail
from app.models.skill import SkillGap
from app.models.roadmap import CareerRoadmap, RoadmapPhase, RoadmapTask
from app.knowledge.skill_database import skill_db
from app.knowledge.learning_database import learning_db

class RoadmapPlanner:
    def generate_roadmap(
        self,
        profile: CareerProfile,
        target_career: CareerDetail,
        skill_gaps: List[SkillGap]
    ) -> CareerRoadmap:
        timeline_months = profile.target_duration_months
        total_weeks = timeline_months * 4
        
        # 1. Filter skills that have gaps (gap > 0)
        gap_skills = [gap for gap in skill_gaps if gap.gap > 0]
        
        # 2. Sort skills deterministically by:
        #    a) Dependency Depth ascending (lowest depth first, i.e., prerequisites first)
        #    b) Priority Score descending (highest priority first for equal depth)
        sorted_gaps = sorted(
            gap_skills,
            key=lambda x: (skill_db.get_skill_dependency_depth(x.skill), -x.priority_score)
        )
        
        # Determine number of phases
        if timeline_months <= 3:
            num_phases = 2
            phase_titles = ["Foundational Integration", "Core Competencies & Projects"]
        elif timeline_months <= 6:
            num_phases = 3
            phase_titles = ["Phase 1: Foundational Systems", "Phase 2: Core Engineering", "Phase 3: Production & Architecture"]
        else:
            num_phases = 4
            phase_titles = ["Phase 1: Foundations", "Phase 2: Intermediate Core", "Phase 3: Advanced Architectures", "Phase 4: Production Engineering"]
            
        weeks_per_phase = max(1, total_weeks // num_phases)
        phases: List[RoadmapPhase] = []
        
        # If there are no gaps, assign target core skills for refinement/advanced learning
        if not sorted_gaps:
            # Reconstruct list using target career required skills
            all_target_skills = list(target_career.required_skills.keys())
            for i in range(num_phases):
                title = phase_titles[i] if i < len(phase_titles) else f"Refinement Phase {i+1}"
                skills_allocated = all_target_skills[i*len(all_target_skills)//num_phases : (i+1)*len(all_target_skills)//num_phases]
                if not skills_allocated:
                    skills_allocated = [all_target_skills[0]] if all_target_skills else ["System Design"]
                    
                phases.append(RoadmapPhase(
                    phase=i + 1,
                    title=title,
                    objective=f"Refine and optimize competencies in {', '.join(skills_allocated)}.",
                    duration_weeks=weeks_per_phase,
                    skills=skills_allocated,
                    tasks=[
                        RoadmapTask(title=f"Conduct advanced performance profiling in {s}", estimated_hours=10, priority="MEDIUM")
                        for s in skills_allocated
                    ],
                    project=f"Advanced {target_career.title} Optimization Sandbox",
                    milestone=f"Achieve expert-level optimization in {skills_allocated[0]}",
                    expected_outcome=f"Production-ready codebase optimizations demonstrating depth in {skills_allocated[0]}."
                ))
            return CareerRoadmap(
                title=f"{target_career.title} Career Refinement Roadmap",
                duration_months=timeline_months,
                phases=phases
            )

        # 3. Distribute skills across phases based on sorted sequence
        allocated_skills: List[List[str]] = [[] for _ in range(num_phases)]
        for idx, gap in enumerate(sorted_gaps):
            # Simple round-robin or bucket distribution preserving dependency sort
            # For dependency ordering, bucket 0 gets early index, bucket N gets late index
            bucket = min(num_phases - 1, idx * num_phases // len(sorted_gaps))
            allocated_skills[bucket].append(gap.skill)

        # 4. Generate Phase Details
        for i in range(num_phases):
            phase_num = i + 1
            title = phase_titles[i] if i < len(phase_titles) else f"Advanced Development Phase {phase_num}"
            skills_in_phase = allocated_skills[i]
            
            # If a phase is empty (e.g. only 1 gap overall), distribute from previous or skip
            if not skills_in_phase:
                if i > 0 and allocated_skills[i-1]:
                    # Shift half of previous phase skills to keep it balanced
                    prev_skills = allocated_skills[i-1]
                    half = len(prev_skills) // 2
                    skills_in_phase = prev_skills[half:]
                    allocated_skills[i-1] = prev_skills[:half]
                else:
                    skills_in_phase = ["General Software Engineering Principles"]

            # Formulate Objective
            objective = f"Establish and solidify competencies in: {', '.join(skills_in_phase)}."
            
            # Create Tasks
            tasks: List[RoadmapTask] = []
            for skill in skills_in_phase:
                # Find learning info
                path_info = learning_db.get_skill_path_info(skill)
                hours = path_info.get("hours_per_level", 15)
                
                # Check actual gap size to scale estimated hours
                matching_gap = next((g for g in sorted_gaps if g.skill == skill), None)
                gap_size = matching_gap.gap if matching_gap else 1
                total_est_hours = hours * gap_size
                
                # Create study tasks
                tasks.append(RoadmapTask(
                    title=f"Study {skill} concepts: {', '.join(path_info.get('resources', [])[:1])}",
                    estimated_hours=max(4, total_est_hours // 2),
                    priority="HIGH" if matching_gap and matching_gap.priority == "HIGH" else "MEDIUM"
                ))
                
                # Create milestone task
                milestones_list = path_info.get("milestones", [])
                milestone_txt = milestones_list[0] if milestones_list else f"Complete {skill} exercises"
                # Select milestone appropriate for target level
                target_lvl = matching_gap.required_level if matching_gap else 3
                if target_lvl <= 2 and len(milestones_list) > 0:
                    milestone_txt = milestones_list[0]
                elif target_lvl <= 3 and len(milestones_list) > 1:
                    milestone_txt = milestones_list[1]
                elif len(milestones_list) > 2:
                    milestone_txt = milestones_list[2]
                    
                tasks.append(RoadmapTask(
                    title=f"Implement milestone: {milestone_txt}",
                    estimated_hours=max(4, total_est_hours // 2),
                    priority="MEDIUM"
                ))

            # Select recommended project for this phase
            matched_projects = learning_db.get_projects_for_skills(skills_in_phase)
            project_name = None
            if matched_projects:
                project_name = matched_projects[0]["name"]
            else:
                project_name = f"Practice Sandbox for {skills_in_phase[0]}"
                
            milestone = f"Build and verify a project incorporating {skills_in_phase[0]}"
            expected_outcome = f"Hands-on expertise in {', '.join(skills_in_phase)} demonstrated through completed repository."
            
            phases.append(RoadmapPhase(
                phase=phase_num,
                title=title,
                objective=objective,
                duration_weeks=weeks_per_phase,
                skills=skills_in_phase,
                tasks=tasks,
                project=project_name,
                milestone=milestone,
                expected_outcome=expected_outcome
            ))
            
        return CareerRoadmap(
            title=f"{target_career.title} Career Roadmap",
            duration_months=timeline_months,
            phases=phases
        )

# Singleton instance
roadmap_planner = RoadmapPlanner()
