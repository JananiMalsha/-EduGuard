-- ============================================================
--  EduGuard — Complete Database Schema
--  Version 2.0  |  MVP (14 tables)
--  Import via phpMyAdmin → eduguard database
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
--  1. USERS  (all accounts: admin, teacher, gate, parent, student)
-- ============================================================
CREATE TABLE IF NOT EXISTS `users` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `name`          VARCHAR(100)    NOT NULL,
    `email`         VARCHAR(150)    NOT NULL UNIQUE,
    `password_hash` VARCHAR(255)    NOT NULL,
    `role`          ENUM('admin','teacher','gate','parent','student') NOT NULL,
    `status`        ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_role`   (`role`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  2. CLASSES
-- ============================================================
CREATE TABLE IF NOT EXISTS `classes` (
    `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `grade`            VARCHAR(20)  NOT NULL,
    `section`          VARCHAR(10)  NOT NULL,
    `class_teacher_id` INT UNSIGNED NULL,
    `year`             YEAR         NOT NULL,
    `created_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_class` (`grade`, `section`, `year`),
    INDEX `idx_year` (`year`),
    CONSTRAINT `fk_class_teacher`
        FOREIGN KEY (`class_teacher_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  3. SUBJECTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `subjects` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`       VARCHAR(100) NOT NULL,
    `code`       VARCHAR(20)  NOT NULL UNIQUE,
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  4. CLASS_SUBJECTS  (which teacher teaches which subject in which class)
-- ============================================================
CREATE TABLE IF NOT EXISTS `class_subjects` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `class_id`   INT UNSIGNED NOT NULL,
    `subject_id` INT UNSIGNED NOT NULL,
    `teacher_id` INT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_class_subject` (`class_id`, `subject_id`),
    CONSTRAINT `fk_cs_class`
        FOREIGN KEY (`class_id`)   REFERENCES `classes`(`id`)  ON DELETE CASCADE,
    CONSTRAINT `fk_cs_subject`
        FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cs_teacher`
        FOREIGN KEY (`teacher_id`) REFERENCES `users`(`id`)    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  5. TEACHERS  (extra teacher info linked to users)
-- ============================================================
CREATE TABLE IF NOT EXISTS `teachers` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`    INT UNSIGNED NOT NULL UNIQUE,
    `phone`      VARCHAR(20)  NULL,
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_teacher_user`
        FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  6. STUDENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `students` (
    `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `user_id`      INT UNSIGNED  NOT NULL UNIQUE,
    `student_no`   VARCHAR(30)   NOT NULL UNIQUE,
    `class_id`     INT UNSIGNED  NOT NULL,
    `photo_path`   VARCHAR(255)  NULL,
    `qr_token`     VARCHAR(64)   NOT NULL UNIQUE,
    `token_status` ENUM('active','revoked') NOT NULL DEFAULT 'active',
    `dob`          DATE          NULL,
    `gender`       ENUM('male','female','other') NULL,
    `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_class`      (`class_id`),
    INDEX `idx_qr_token`   (`qr_token`),
    CONSTRAINT `fk_student_user`
        FOREIGN KEY (`user_id`)  REFERENCES `users`(`id`)   ON DELETE CASCADE,
    CONSTRAINT `fk_student_class`
        FOREIGN KEY (`class_id`) REFERENCES `classes`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  7. PARENTS  (extra parent info linked to users)
-- ============================================================
CREATE TABLE IF NOT EXISTS `parents` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`        INT UNSIGNED NOT NULL UNIQUE,
    `phone`          VARCHAR(20)  NULL,
    `consent_given`  TINYINT(1)   NOT NULL DEFAULT 0,
    `consent_date`   DATETIME     NULL,
    `email_alerts`   TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_parent_user`
        FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  8. PARENT_STUDENT  (many-to-many: a parent can have multiple children)
-- ============================================================
CREATE TABLE IF NOT EXISTS `parent_student` (
    `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `parent_id`    INT UNSIGNED  NOT NULL,
    `student_id`   INT UNSIGNED  NOT NULL,
    `relationship` VARCHAR(50)   NOT NULL DEFAULT 'Guardian',
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_link` (`parent_id`, `student_id`),
    CONSTRAINT `fk_ps_parent`
        FOREIGN KEY (`parent_id`)  REFERENCES `parents`(`id`)  ON DELETE CASCADE,
    CONSTRAINT `fk_ps_student`
        FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  9. ATTENDANCE  (one record per student per school day)
-- ============================================================
CREATE TABLE IF NOT EXISTS `attendance` (
    `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`   INT UNSIGNED  NOT NULL,
    `date`         DATE          NOT NULL,
    `status`       ENUM('present','late','absent','not_yet_confirmed') NOT NULL DEFAULT 'not_yet_confirmed',
    `arrival_time` TIME          NULL,
    `scanned_by`   INT UNSIGNED  NULL,          -- user_id of gate/teacher/admin
    `method`       ENUM('qr','manual') NOT NULL DEFAULT 'qr',
    `note`         TEXT          NULL,
    `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `unique_attendance` (`student_id`, `date`),   -- prevents duplicate scans
    INDEX `idx_date`       (`date`),
    INDEX `idx_student`    (`student_id`),
    INDEX `idx_status`     (`status`),
    CONSTRAINT `fk_att_student`
        FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_att_scanner`
        FOREIGN KEY (`scanned_by`) REFERENCES `users`(`id`)    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  10. ATTENDANCE_LOGS  (audit trail for every attendance change)
-- ============================================================
CREATE TABLE IF NOT EXISTS `attendance_logs` (
    `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `attendance_id` INT UNSIGNED  NOT NULL,
    `changed_by`    INT UNSIGNED  NULL,
    `old_status`    VARCHAR(30)   NULL,
    `new_status`    VARCHAR(30)   NOT NULL,
    `reason`        TEXT          NULL,
    `changed_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_att_id` (`attendance_id`),
    CONSTRAINT `fk_al_attendance`
        FOREIGN KEY (`attendance_id`) REFERENCES `attendance`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_al_user`
        FOREIGN KEY (`changed_by`)    REFERENCES `users`(`id`)      ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  11. ASSESSMENTS  (exams, tests, quizzes)
-- ============================================================
CREATE TABLE IF NOT EXISTS `assessments` (
    `id`         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `class_id`   INT UNSIGNED  NOT NULL,
    `subject_id` INT UNSIGNED  NOT NULL,
    `title`      VARCHAR(150)  NOT NULL,
    `type`       ENUM('exam','test','quiz','assignment','other') NOT NULL DEFAULT 'test',
    `max_marks`  DECIMAL(6,2)  NOT NULL,
    `weight`     DECIMAL(5,2)  NOT NULL DEFAULT 1.00,  -- for weighted average
    `date`       DATE          NULL,
    `created_by` INT UNSIGNED  NULL,
    `created_at` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_class_subject` (`class_id`, `subject_id`),
    CONSTRAINT `fk_assess_class`
        FOREIGN KEY (`class_id`)   REFERENCES `classes`(`id`)  ON DELETE CASCADE,
    CONSTRAINT `fk_assess_subject`
        FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_assess_creator`
        FOREIGN KEY (`created_by`) REFERENCES `users`(`id`)    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  12. RESULTS  (student marks per assessment)
-- ============================================================
CREATE TABLE IF NOT EXISTS `results` (
    `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `assessment_id` INT UNSIGNED  NOT NULL,
    `student_id`    INT UNSIGNED  NOT NULL,
    `marks`         DECIMAL(6,2)  NOT NULL,
    `entered_by`    INT UNSIGNED  NULL,
    `entered_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_result` (`assessment_id`, `student_id`),
    INDEX `idx_student_result` (`student_id`),
    CONSTRAINT `fk_result_assessment`
        FOREIGN KEY (`assessment_id`) REFERENCES `assessments`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_result_student`
        FOREIGN KEY (`student_id`)    REFERENCES `students`(`id`)    ON DELETE CASCADE,
    CONSTRAINT `fk_result_teacher`
        FOREIGN KEY (`entered_by`)    REFERENCES `users`(`id`)       ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  13. NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS `notifications` (
    `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `user_id`      INT UNSIGNED  NOT NULL,
    `type`         VARCHAR(50)   NOT NULL,   -- e.g. 'arrival','late','absent','marks','trend'
    `title`        VARCHAR(100)  NOT NULL,
    `message`      TEXT          NOT NULL,
    `is_read`      TINYINT(1)    NOT NULL DEFAULT 0,
    `email_status` ENUM('pending','sent','failed','skipped') NOT NULL DEFAULT 'pending',
    `retry_count`  TINYINT       NOT NULL DEFAULT 0,
    `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user_read`   (`user_id`, `is_read`),
    INDEX `idx_email_status`(`email_status`),
    CONSTRAINT `fk_notif_user`
        FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  14. AUDIT_LOG  (every action: login, data change, etc.)
-- ============================================================
CREATE TABLE IF NOT EXISTS `audit_log` (
    `id`         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `user_id`    INT UNSIGNED  NULL,
    `action`     VARCHAR(100)  NOT NULL,
    `target`     VARCHAR(255)  NULL,
    `ip_address` VARCHAR(45)   NULL,
    `created_at` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_user_id`    (`user_id`),
    INDEX `idx_created_at` (`created_at`),
    CONSTRAINT `fk_audit_user`
        FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
--  PHASE 2 TABLES (placeholders — add when Phase 2 starts)
-- ============================================================
-- performance_records, plan_templates, improvement_plans,
-- assignments, submissions, announcements

-- ============================================================
--  SEED DATA — Default Admin Account
--  Password: Admin@1234  (bcrypt hash)
--  ⚠️  Change this immediately after first login!
-- ============================================================
INSERT INTO `users` (`name`, `email`, `password_hash`, `role`, `status`) VALUES
('Administrator', 'admin@eduguard.lk',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'admin', 'active');

-- ============================================================
--  SEED DATA — Demo Users (for testing)
--  All passwords: Test@1234
-- ============================================================
INSERT INTO `users` (`name`, `email`, `password_hash`, `role`, `status`) VALUES
('Mrs. Kumari Silva',  'teacher1@eduguard.lk', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher', 'active'),
('Mr. Nimal Perera',   'teacher2@eduguard.lk', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher', 'active'),
('Gate Officer',       'gate@eduguard.lk',     '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'gate',    'active'),
('Kamal Fernando',     'parent1@eduguard.lk',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'parent',  'active'),
('Seetha Jayawardena', 'parent2@eduguard.lk',  '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'parent',  'active'),
('Amal Fernando',      'student1@eduguard.lk', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student', 'active'),
('Dilani Jayawardena', 'student2@eduguard.lk', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student', 'active'),
('Ruwan Bandara',      'student3@eduguard.lk', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student', 'active');

-- Teacher profiles
INSERT INTO `teachers` (`user_id`, `phone`) VALUES
((SELECT id FROM users WHERE email='teacher1@eduguard.lk'), '+94 71 111 2222'),
((SELECT id FROM users WHERE email='teacher2@eduguard.lk'), '+94 71 333 4444');

-- Demo classes
INSERT INTO `classes` (`grade`, `section`, `class_teacher_id`, `year`) VALUES
('Grade 6', 'A', (SELECT id FROM users WHERE email='teacher1@eduguard.lk'), YEAR(CURDATE())),
('Grade 7', 'B', (SELECT id FROM users WHERE email='teacher2@eduguard.lk'), YEAR(CURDATE()));

-- Demo subjects
INSERT INTO `subjects` (`name`, `code`) VALUES
('Mathematics',  'MATH'),
('Science',      'SCI'),
('English',      'ENG'),
('History',      'HIST');

-- Assign subjects to Grade 6A
INSERT INTO `class_subjects` (`class_id`, `subject_id`, `teacher_id`) VALUES
(1, 1, (SELECT id FROM users WHERE email='teacher1@eduguard.lk')),
(1, 2, (SELECT id FROM users WHERE email='teacher1@eduguard.lk')),
(1, 3, (SELECT id FROM users WHERE email='teacher2@eduguard.lk')),
(1, 4, (SELECT id FROM users WHERE email='teacher2@eduguard.lk'));

-- Student profiles  (qr_token = random hex, never the student name/ID)
INSERT INTO `students` (`user_id`, `student_no`, `class_id`, `qr_token`, `gender`) VALUES
((SELECT id FROM users WHERE email='student1@eduguard.lk'), 'STU-001', 1, SHA2(CONCAT('STU-001', UUID()), 256), 'male'),
((SELECT id FROM users WHERE email='student2@eduguard.lk'), 'STU-002', 1, SHA2(CONCAT('STU-002', UUID()), 256), 'female'),
((SELECT id FROM users WHERE email='student3@eduguard.lk'), 'STU-003', 1, SHA2(CONCAT('STU-003', UUID()), 256), 'male');

-- Parent profiles
INSERT INTO `parents` (`user_id`, `phone`, `consent_given`, `consent_date`, `email_alerts`) VALUES
((SELECT id FROM users WHERE email='parent1@eduguard.lk'), '+94 77 555 6666', 1, NOW(), 1),
((SELECT id FROM users WHERE email='parent2@eduguard.lk'), '+94 77 777 8888', 1, NOW(), 1);

-- Link parents to students
INSERT INTO `parent_student` (`parent_id`, `student_id`, `relationship`) VALUES
((SELECT p.id FROM parents p JOIN users u ON p.user_id=u.id WHERE u.email='parent1@eduguard.lk'),
 (SELECT s.id FROM students s JOIN users u ON s.user_id=u.id WHERE u.email='student1@eduguard.lk'),
 'Father'),
((SELECT p.id FROM parents p JOIN users u ON p.user_id=u.id WHERE u.email='parent2@eduguard.lk'),
 (SELECT s.id FROM students s JOIN users u ON s.user_id=u.id WHERE u.email='student2@eduguard.lk'),
 'Mother');

-- Demo assessments for Grade 6A — Mathematics
INSERT INTO `assessments` (`class_id`, `subject_id`, `title`, `type`, `max_marks`, `weight`, `date`) VALUES
(1, 1, 'Term 1 Test',   'test',  100, 1.0, DATE_SUB(CURDATE(), INTERVAL 60 DAY)),
(1, 1, 'Mid Term Exam', 'exam',  100, 2.0, DATE_SUB(CURDATE(), INTERVAL 30 DAY)),
(1, 1, 'Quiz 1',        'quiz',   50, 0.5, DATE_SUB(CURDATE(), INTERVAL 14 DAY)),
(1, 1, 'Term 2 Test',   'test',  100, 1.0, DATE_SUB(CURDATE(), INTERVAL 7  DAY));

-- Demo results for student1 (Amal) — Declining trend in Maths
-- Term1=72, MidTerm=60, Quiz1=28/50(56%), Term2=45 → Declining
INSERT INTO `results` (`assessment_id`, `student_id`, `marks`) VALUES
(1, 1, 72),
(2, 1, 60),
(3, 1, 28),
(4, 1, 45);

-- Demo results for student2 (Dilani) — Improving trend
INSERT INTO `results` (`assessment_id`, `student_id`, `marks`) VALUES
(1, 2, 50),
(2, 2, 62),
(3, 2, 38),
(4, 2, 75);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  DONE! 14 tables created + demo data inserted.
--  Login credentials (all use same password "password"):
--    admin@eduguard.lk    → Admin
--    teacher1@eduguard.lk → Teacher
--    gate@eduguard.lk     → Gate Staff
--    parent1@eduguard.lk  → Parent
--    student1@eduguard.lk → Student
--  ⚠️  Use fake data only — never real student info in demos.
-- ============================================================
