CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `license` VARCHAR(60) NOT NULL UNIQUE,
  `discord_id` VARCHAR(60) NOT NULL UNIQUE,
  `ip` VARCHAR(40) NOT NULL,
  `last_seen` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_played_character` VARCHAR(15) DEFAULT NULL,
  `total_playtime` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total playtime in seconds',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_license` (`license`),
  INDEX `idx_discord_id` (`discord_id`),
  INDEX `idx_last_seen` (`last_seen`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `characters`(
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `unique_id` VARCHAR(15) NOT NULL UNIQUE,
  `firstname` VARCHAR(50) NOT NULL,
  `lastname` VARCHAR(50) NOT NULL,
  `dateofbirth` VARCHAR(10) NOT NULL,
  `sex` VARCHAR(1) NOT NULL,
  `nationality` VARCHAR(50) NOT NULL,
  `height` INT UNSIGNED NOT NULL,
  `appearance` LONGTEXT DEFAULT NULL,
  `group` VARCHAR(40) NOT NULL,
  `ped_model` VARCHAR(60) NOT NULL,
  `position_x` FLOAT NOT NULL,
  `position_y` FLOAT NOT NULL,
  `position_z` FLOAT NOT NULL,
  `heading` FLOAT NOT NULL,
  `needs` LONGTEXT NOT NULL COMMENT 'Character needs data stored as JSON',
  `playtime` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Character playtime in seconds',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_played` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_unique_id` (`unique_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Add foreign key constraint after both tables exist
ALTER TABLE `users` ADD CONSTRAINT `fk_last_played_character` 
FOREIGN KEY (`last_played_character`) REFERENCES `characters`(`unique_id`) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS `roles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL UNIQUE,
  `label` VARCHAR(100) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `description` VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `role_permissions` (
  `role_id` INT NOT NULL,
  `permission_id` INT NOT NULL,

  PRIMARY KEY (`role_id`, `permission_id`),

  FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`permission_id`) REFERENCES `permissions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `character_roles` (
  `character_id` INT NOT NULL,
  `role_id` INT NOT NULL,

  PRIMARY KEY (`character_id`, `role_id`),

  FOREIGN KEY (`character_id`) REFERENCES `characters`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;