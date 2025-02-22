CREATE TABLE IF NOT EXISTS `users` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(60) NOT NULL UNIQUE,
    `discord_id` VARCHAR(60) NOT NULL UNIQUE,
    `ip` VARCHAR(50) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_license (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `characters` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT(11) NOT NULL,
    `unique_id` VARCHAR(15) NOT NULL UNIQUE,
    `group` VARCHAR(50) NOT NULL,
    `needs` JSON NOT NULL DEFAULT '{}',	
    `ped_model` VARCHAR(64) NOT NULL,
    `position_x` FLOAT NOT NULL,
    `position_y` FLOAT NOT NULL,
    `position_z` FLOAT NOT NULL,
    `heading` FLOAT NOT NULL,
    `status` JSON NOT NULL DEFAULT '{}',
    `isDead` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_played` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_characters_user_id (`user_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `characters_accounts` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `character_id` INT(11) NOT NULL,
    `account_type` VARCHAR(32) NOT NULL,
    `account_amount` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `account_metadata` JSON NOT NULL DEFAULT '{}',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_characters_accounts_character_id (`character_id`),
    INDEX idx_characters_accounts_composite (`character_id`, `account_type`),
    FOREIGN KEY (`character_id`) REFERENCES `characters`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `society` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `owner_identifier` VARCHAR(60) DEFAULT NULL,
    `society_name` VARCHAR(60) NOT NULL UNIQUE,
    `society_label` VARCHAR(60) NOT NULL,
    `society_iban` VARCHAR(20) DEFAULT NULL UNIQUE,
    `society_money` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `is_society_whitelisted` BOOLEAN NOT NULL DEFAULT FALSE,
    INDEX idx_society_owner_identifier (`owner_identifier`),
    INDEX idx_society_society_name (`society_name`),
    FOREIGN KEY (`owner_identifier`) REFERENCES `users`(`license`) ON DELETE SET DEFAULT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `society_grades` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `society_name` VARCHAR(60) NOT NULL,
    `society_grade` INT(11) NOT NULL,
    `society_grade_name` VARCHAR(60) NOT NULL,
    `society_grade_label` VARCHAR(60) NOT NULL,
    `society_grade_salary` DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK(society_grade_salary >= 0),
    `society_grade_permissions` JSON NOT NULL DEFAULT '{}',
    `is_society_grade_whitelisted` BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (`society_name`, `society_grade`),
    INDEX idx_society_grades_society_name (`society_name`),
    INDEX idx_society_grades_societ_grade_name (`society_grade_name`),
    FOREIGN KEY (`society_name`) REFERENCES `society`(`society_name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crews` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `owner_identifier` VARCHAR(60) DEFAULT NULL,
    `crew_name` VARCHAR(60) NOT NULL UNIQUE,
    `crew_label` VARCHAR(60) NOT NULL,
    `crew_money` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `is_crew_whitelisted` BOOLEAN NOT NULL DEFAULT TRUE,
    INDEX idx_crew_owner_identifier (`owner_identifier`),
    INDEX idx_crew_crew_name (`crew_name`),
    FOREIGN KEY (`owner_identifier`) REFERENCES `users`(`license`) ON DELETE SET DEFAULT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crew_grades` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `crew_name` VARCHAR(60) NOT NULL,
    `crew_grade` INT(11) NOT NULL,
    `crew_grade_name` VARCHAR(60) NOT NULL,
    `crew_grade_label` VARCHAR(60) NOT NULL,
    `crew_grade_salary` DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK(crew_grade_salary >= 0),
    `crew_grade_permissions` JSON NOT NULL DEFAULT '{}',
    `is_crew_grade_whitelisted` BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (`crew_name`, `crew_grade`),
    INDEX idx_crew_grades_crew_name (`crew_name`),
    INDEX idx_crew_grades_crew_grade_name (`crew_grade_name`),
    FOREIGN KEY (`crew_name`) REFERENCES `crews`(`crew_name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_affiliations` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `character_id` INT(11) NOT NULL,
    `job` VARCHAR(60) NOT NULL,
    `job_grade` VARCHAR(60) NOT NULL,
    `on_duty_job` BOOLEAN NOT NULL DEFAULT FALSE,
    `crew` VARCHAR(60) NOT NULL,
    `crew_grade` VARCHAR(60) NOT NULL,
    `on_duty_crew` BOOLEAN NOT NULL DEFAULT FALSE,
    INDEX `idx_character_id` (`character_id`),
    INDEX `idx_job_grade` (`job`, `job_grade`),
    INDEX `idx_crew_grade` (`crew`, `crew_grade`),
    UNIQUE INDEX `unique_character_affiliation` (`character_id`, `job`, `crew`),
    FOREIGN KEY (`character_id`) REFERENCES `characters`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`job`) REFERENCES `society`(`society_name`) ON DELETE CASCADE,
    FOREIGN KEY (`job_grade`) REFERENCES `society_grades`(`society_grade_name`) ON DELETE CASCADE,
    FOREIGN KEY (`crew`) REFERENCES `crews`(`crew_name`) ON DELETE CASCADE,
    FOREIGN KEY (`crew_grade`) REFERENCES `crew_grades`(`crew_grade_name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `licenses` (
    `license_type` VARCHAR(60) NOT NULL PRIMARY KEY,
    `license_label` VARCHAR(60) NOT NULL,
    INDEX `idx_license_label` (`license_label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_licenses` (
    `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `character_unique_id` VARCHAR(10) NOT NULL,
    `license_type` VARCHAR(60) NOT NULL,
    `license_status` BOOLEAN NOT NULL DEFAULT FALSE,
    `license_metadata` JSON NOT NULL DEFAULT '{}',
    `granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `revoked_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_character_unique_id` (`character_unique_id`),
    INDEX `idx_license_type` (`license_type`),
    UNIQUE INDEX `unique_character_license` (`character_unique_id`, `license_type`),
    FOREIGN KEY (`character_unique_id`) REFERENCES `characters`(`unique_id`) ON DELETE CASCADE,
    FOREIGN KEY (`license_type`) REFERENCES `licenses`(`license_type`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `society` (`society_name`, `society_label`, `society_iban`, `society_money`, `is_society_whitelisted`) VALUES
('unemployed', 'Unemployed', NULL, 0.00, FALSE),
('ambulance', 'EMS', '111111', 0.00, TRUE);

INSERT INTO `society_grades` (`society_name`, `society_grade`, `society_grade_name`, `society_grade_label`, `society_grade_salary`, `society_grade_permissions`, `is_society_grade_whitelisted`) VALUES
('unemployed', 0, 'unemployed', 'Unemployed', 0.00, '{}', FALSE),
('ambulance', 1, 'intern', 'Intern', 1500.00, '{}', FALSE),
('ambulance', 2, 'nurse', 'Nurse', 2500.00, '{}', TRUE),
('ambulance', 3, 'doctor', 'Doctor', 4000.00, '{}', TRUE),
('ambulance', 4, 'chief', 'Chief of EMS', 6000.00, '{}', TRUE);

INSERT INTO `crews` (`crew_name`, `crew_label`, `crew_money`, `is_crew_whitelisted`) VALUES
('none', 'N/A', 0.00, FALSE),
('ballas', 'Ballas', 0.00, TRUE);

INSERT INTO `crew_grades` (`crew_name`, `crew_grade`, `crew_grade_name`, `crew_grade_label`, `crew_grade_salary`, `crew_grade_permissions`, `is_crew_grade_whitelisted`) VALUES
('none', 0, 'none', 'N/A', 0.00, '{}', FALSE),
('ballas', 1, 'recruit', 'Recruit', 1000.00, '{}', FALSE),
('ballas', 2, 'soldier', 'Soldier', 2000.00, '{}', TRUE),
('ballas', 3, 'lieutenant', 'Lieutenant', 3500.00, '{}', TRUE),
('ballas', 4, 'boss', 'Boss', 5000.00, '{}', TRUE);

INSERT INTO `licenses` (`license_type`, `license_label`) VALUES
('car', 'Car License'),
('motorcycle', 'Motorcycle License'),
('ppa', 'Firearm License');