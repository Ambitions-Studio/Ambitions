-- ===================================================================
-- AMBITIONS FRAMEWORK - DATABASE MIGRATION CONFIGURATION
-- ===================================================================
-- This configuration file controls the automatic database migration system
-- for the Ambitions framework. The migration system ensures your database
-- schema is always up-to-date with the latest framework version.
--
-- HOW IT WORKS:
-- The migration system automatically detects schema changes and applies
-- them to your database when the resource starts. It tracks applied
-- migrations to prevent duplicate execution and ensures data integrity.
-- ===================================================================

migrationConfig = {
    -- ===================================================================
    -- AUTO-MIGRATION SYSTEM
    -- ===================================================================

    --- Enable or disable the auto-migration system
    --- 
    --- • true: Automatically check and apply database migrations
    ---         Recommended for production and development
    ---         Ensures database is always compatible with framework
    --- 
    --- • false: Disable auto-migration system completely
    ---          Use only if you want to manually manage database schema
    ---          NOT recommended unless you're an advanced user
    ---
    --- WARNING: Disabling auto-migration may cause compatibility issues
    --- if your database schema becomes outdated
    enabled = true,

    --- Run migration automatically when resource starts
    --- 
    --- • true: Check and apply migrations on every resource start
    ---         Recommended for most users
    ---         Ensures immediate compatibility on server restart
    --- 
    --- • false: Migration system is enabled but won't run automatically
    ---          You must manually trigger migrations using console commands
    ---          Useful for controlled migration timing in production
    ---
    --- MANUAL COMMANDS (when runOnStart = false):
    --- - ambitions:migrate         (apply pending migrations)
    --- - ambitions:migration-status (check current status)
    runOnStart = true,

    -- ===================================================================
    -- LOGGING AND DEBUGGING
    -- ===================================================================

    --- Migration system log level
    --- Controls how much information is displayed during migration process
    --- 
    --- • 'debug': Show all details including SQL queries and timing
    ---           Use for development or troubleshooting migration issues
    ---           Most verbose output
    --- 
    --- • 'info': Show general migration progress and results
    ---          Recommended for production use
    ---          Shows applied migrations and timing
    --- 
    --- • 'warning': Only show warnings and important notices
    ---             Minimal output, only potential issues
    --- 
    --- • 'error': Only show errors and failures
    ---           Quietest setting, only shows problems
    logLevel = 'info',
}