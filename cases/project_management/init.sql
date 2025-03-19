-- DDL Statements

-- Table: Projects
CREATE TABLE Projects (
    project_id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT NOT NULL,  -- e.g., 'Active', 'Completed', 'On Hold'
    category TEXT NOT NULL, -- e.g., 'Research', 'Development', 'Marketing'
    budget REAL NOT NULL
);

-- Table: Personnel
CREATE TABLE Personnel (
    personnel_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    department TEXT NOT NULL,
    hire_date DATE NOT NULL
);

-- Table: Project_Assignments
CREATE TABLE Project_Assignments (
    assignment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    personnel_id INTEGER NOT NULL,
    allocation_percentage REAL NOT NULL, -- e.g., 50.0 for 50%
    FOREIGN KEY (project_id) REFERENCES Projects(project_id),
    FOREIGN KEY (personnel_id) REFERENCES Personnel(personnel_id)
);

-- Table: Skills
CREATE TABLE Skills (
    skill_id INTEGER PRIMARY KEY AUTOINCREMENT,
    skill_name TEXT NOT NULL UNIQUE  -- Ensure skill names are unique
);

-- Table: Personnel_Skills
CREATE TABLE Personnel_Skills (
    personnel_skill_id INTEGER PRIMARY KEY AUTOINCREMENT,
    personnel_id INTEGER NOT NULL,
    skill_id INTEGER NOT NULL,
    proficiency_level INTEGER NOT NULL, -- e.g., 1-10 (Beginner to Expert)
    FOREIGN KEY (personnel_id) REFERENCES Personnel(personnel_id),
    FOREIGN KEY (skill_id) REFERENCES Skills(skill_id)
);

-- Table Project_Skill_Requirements
CREATE TABLE Project_Skill_Requirements (
    project_skill_req_id INTEGER PRIMARY KEY AUTOINCREMENT,
	project_id INTEGER NOT NULL,
	skill_id INTEGER NOT NULL,
	required_proficiency_level INTEGER NOT NULL,
	FOREIGN KEY (project_id) REFERENCES Projects(project_id),
	FOREIGN KEY (skill_id) REFERENCES Skills(skill_id)
);


-- Insert Seed Data

-- Skills
INSERT INTO Skills (skill_name) VALUES
('Data Analysis'),
('Machine Learning'),
('Project Management'),
('Software Development'),
('Experimental Design'),
('Statistical Modeling'),
('Communication'),
('Leadership'),
('Problem Solving'),
('Genomics');

-- Personnel
INSERT INTO Personnel (first_name, last_name, department, hire_date) VALUES
('Alice', 'Smith', 'Research', '2022-01-15'),
('Bob', 'Johnson', 'Development', '2021-08-20'),
('Charlie', 'Brown', 'Research', '2023-03-10'),
('Diana', 'Davis', 'Development', '2022-05-01'),
('Eve', 'Williams', 'Marketing', '2023-09-01'),  --Not assigned to the projects, but have skills.
('Frank', 'Miller', 'Research', '2022-11-15'),
('Grace', 'Taylor', 'Development', '2023-01-20'),
('Harry', 'Anderson', 'Research', '2021-06-01'),
('Ivy', 'Thomas', 'Development', '2023-04-15'),
('Jack', 'Moore', 'Marketing', '2022-07-01');

-- Projects
INSERT INTO Projects (project_name, start_date, end_date, status, category, budget) VALUES
('Project Alpha', '2023-06-01', '2024-05-31', 'Active', 'Research', 150000.00),
('Project Beta', '2023-07-15', '2024-01-15', 'Active', 'Development', 200000.00),
('Project Gamma', '2023-09-01', '2024-08-31', 'Active', 'Research', 180000.00),
('Project Delta', '2024-01-01', '2024-06-30', 'Active', 'Development', 250000.00),
('Project Epsilon', '2024-03-01', '2024-09-30', 'Active', 'Research', 120000.00); --shorter project

-- Project_Assignments
INSERT INTO Project_Assignments (project_id, personnel_id, allocation_percentage) VALUES
(1, 1, 100.0),  -- Alice 100% on Alpha
(1, 3, 50.0),   -- Charlie 50% on Alpha
(1, 6, 50.0), -- Frank 50% on Alpha
(2, 2, 75.0),   -- Bob 75% on Beta
(2, 4, 100.0),  -- Diana 100% on Beta
(3, 1, 50.0),   -- Alice 50% on Gamma
(3, 8, 100.0),  -- Harry 100% on Gamma
(4, 7, 80.0),   --Grace 80% on Delta
(4, 9, 50.0), --Ivy 50% on Delta
(5, 3, 100.0);  --Charlie 100% on Epsilon

-- Personnel_Skills
INSERT INTO Personnel_Skills (personnel_id, skill_id, proficiency_level) VALUES
(1, 1, 9),  -- Alice: Data Analysis (Expert)
(1, 2, 7),  -- Alice: Machine Learning (Proficient)
(1, 6, 8),  -- Alice: Statistical Modeling (Expert)
(2, 4, 9),  -- Bob: Software Development (Expert)
(2, 9, 8),  -- Bob: Problem Solving (Expert)
(3, 3, 7),  -- Charlie: Project Management (Proficient)
(3, 7, 9),  -- Charlie: Communication (Expert)
(4, 4, 8),  -- Diana: Software Development (Expert)
(4, 2, 5), -- Diana: Machine Learning (Proficient)
(5, 7, 8),  -- Eve: Communication (Expert)
(5, 8, 9),  -- Eve: Leadership (Expert)
(6, 5, 7),  -- Frank: Experimental Design (Proficient)
(6, 6, 9), -- Frank: Statistical Modeling (Expert)
(7, 4, 8), -- Grace: Software Development (Expert)
(7, 9, 7),  -- Grace: Problem Solving (Proficient)
(8, 10, 9), -- Harry: Genomics(Expert)
(8, 6, 7), -- Harry: Statistical Modeling (Proficient)
(9, 4, 9),  -- Ivy: Software Development (Expert)
(9, 1, 6),   -- Ivy: Data Analysis (Proficient)
(10,7, 8), -- Jack: Communication (Expert)
(10,8, 7); -- Jack: Leadership (Proficient)

-- Project_Skill_Requirements
INSERT INTO Project_Skill_Requirements (project_id, skill_id, required_proficiency_level) VALUES
(1, 1, 8), -- Project Alpha requires Data Analysis (Expert)
(1, 6, 7),  -- Project Alpha requires Statistical Modeling (Proficient)
(2, 4, 8), -- Project Beta requires Software Development (Expert)
(2, 9, 7),  -- Project Beta requires Problem Solving (Proficient)
(3, 6, 8),  -- Project Gamma requires Statistical Modeling (Expert)
(3, 10, 7), --Project Gamma require Genomics (Proficient)
(4, 4, 9), -- Project Delta requires Software Development (Expert)
(4, 1, 5),  -- Project Delta requires Data Analysis (Proficient)
(5, 3, 9), -- Project Epsilon requires Project Management (Expert)
(5, 7, 7); -- Project Epsilon requires Communication (Proficient)