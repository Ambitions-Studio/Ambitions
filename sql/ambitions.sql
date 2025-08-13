lUSE `ambitions_work`;

CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `license` VARCHAR(60) NOT NULL UNIQUE,
  `discord_id` VARCHAR(60) NOT NULL UNIQUE,
  `ip` VARCHAR(40) NOT NULL,
  `last_seen` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_played_character` VARCHAR(15) NULL,
  `total_playtime` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total playtime in seconds',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_license` (`license`),
  INDEX `idx_discord_id` (`discord_id`),
  INDEX `idx_last_seen` (`last_seen`),
  FOREIGN KEY (`last_played_character`) REFERENCES `characters`(`unique_id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `characters`(
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `unique_id` VARCHAR(15) NOT NULL UNIQUE,
  `group` VARCHAR(40) NOT NULL,
  `ped_model` VARCHAR(60) NOT NULL,
  `position_x` FLOAT NOT NULL,
  `position_y` FLOAT NOT NULL,
  `position_z` FLOAT NOT NULL,
  `heading` FLOAT NOT NULL,
  `playtime` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Character playtime in seconds',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_played` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_unique_id` (`unique_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;