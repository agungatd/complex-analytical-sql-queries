WITH 

-- 1. Filtered_Projects: Select projects that are active and have a specific category.  This reduces the initial dataset.
Filtered_Projects AS (
    SELECT
        project_id,
        project_name,
        start_date,
        end_date,
        category,
        budget
    FROM
        Projects
    WHERE
        status = 'Active'
        AND category IN ('Research', 'Development') -- Limiting to specific, non-trivial categories
),

-- 2. Project_Personnel: Get the personnel assigned to the filtered projects, calculating their time allocation.
Project_Personnel AS (
    SELECT
        fp.project_id,
        pa.personnel_id,
        pe.first_name,
        pe.last_name,
        pe.department,
        pa.allocation_percentage,
        (JULIANDAY(fp.end_date) - JULIANDAY(fp.start_date)) * (pa.allocation_percentage / 100.0) AS allocated_days  -- Calculate allocated days based on project duration and allocation.
    FROM
        Filtered_Projects fp
    JOIN
        Project_Assignments pa ON fp.project_id = pa.project_id
    JOIN
        Personnel pe ON pa.personnel_id = pe.personnel_id
),

-- 3. Department_Aggregates: Calculate total allocated days and average allocation per department.
Department_Aggregates AS (
    SELECT
        department,
        SUM(allocated_days) AS total_allocated_days,
        AVG(allocated_days) AS average_allocated_days,
        COUNT(DISTINCT personnel_id) AS distinct_personnel_count
    FROM
        Project_Personnel
    GROUP BY
        department
),

-- 4. Skill_Expertise: Determine the skills each person possesses and their proficiency level.
Skill_Expertise AS (
    SELECT
        ps.personnel_id,
        s.skill_name,
        ps.proficiency_level,
        CASE 
            WHEN ps.proficiency_level >= 8 THEN 'Expert'
            WHEN ps.proficiency_level >= 5 THEN 'Proficient'
            ELSE 'Beginner'
        END AS proficiency_category -- Categorize proficiency for easier reporting
    FROM
        Personnel_Skills ps
    JOIN
        Skills s ON ps.skill_id = s.skill_id
    WHERE ps.proficiency_level > 2 -- Include only personnel with some level of skill (greater than 2).
),

-- 5. Project_Skills_Required:  Define skills needed for each project and the required proficiency.
Project_Skills_Required AS (
	SELECT 
		psr.project_id,
		s.skill_name,
		psr.required_proficiency_level
	FROM
		Project_Skill_Requirements psr
    JOIN
        Skills s ON psr.skill_id = s.skill_id

),

-- 6. Skills_Gap_Analysis: Identify skill gaps for each project by comparing required skills with available skills.
Skills_Gap_Analysis AS (
    SELECT
        psr.project_id,
        psr.skill_name,
        psr.required_proficiency_level,
		    pp.personnel_id,
        se.proficiency_level,
        se.proficiency_category
    FROM
        Project_Skills_Required psr
	LEFT JOIN
		Project_Personnel pp ON psr.project_id = pp.project_id
    LEFT JOIN
        Skill_Expertise se ON pp.personnel_id = se.personnel_id AND psr.skill_name = se.skill_name
),

--7. Final_Gap_Aggregation
Final_Gap_Aggregation AS (
	SELECT 
		project_id,
		skill_name,
		required_proficiency_level,
		COUNT(DISTINCT personnel_id) as num_personnel_with_skill,
		AVG(proficiency_level) as avg_proficiency,
		CASE 
			WHEN AVG(proficiency_level) >= required_proficiency_level THEN 'No Gap'
			WHEN AVG(proficiency_level) < required_proficiency_level THEN 'Gap Exists'
			WHEN AVG(proficiency_level) IS NULL THEN 'Skill Missing' -- Handle cases where no one has the skill.
			ELSE 'Check Data'
		END AS gap_status
	FROM Skills_Gap_Analysis
	GROUP BY project_id, skill_name, required_proficiency_level
),

-- 8. Project_Risk_Assessment: Combine project details, department allocations, and skill gap analysis for a final risk assessment.
Project_Risk_Assessment AS (
    SELECT
        fp.project_name,
        fp.category,
        fp.budget,
        da.department,
        da.total_allocated_days,
        da.average_allocated_days,
		fga.skill_name,
		fga.required_proficiency_level,
		fga.avg_proficiency,
		fga.gap_status,
        CASE
            WHEN da.total_allocated_days > 180 AND fga.gap_status IN ('Gap Exists', 'Skill Missing')  THEN 'High'  -- Combine time and skill gap for risk.
            WHEN da.total_allocated_days > 90 AND fga.gap_status = 'Gap Exists' THEN 'Medium'
            WHEN fga.gap_status = 'Skill Missing' THEN 'Medium' --even small projects with missing skills are at risk
			ELSE 'Low'
        END AS risk_level
    FROM
        Filtered_Projects fp
    JOIN
        Project_Personnel pp ON fp.project_id = pp.project_id
    JOIN
        Department_Aggregates da ON pp.department = da.department
	LEFT JOIN 
		Final_Gap_Aggregation fga ON fp.project_id = fga.project_id
)

-- Final SELECT statement to retrieve the risk assessment
SELECT *
FROM Project_Risk_Assessment
ORDER BY project_name, risk_level, department;