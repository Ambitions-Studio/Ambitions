-- ===================================================================
-- AMBITIONS - SETTINGS CONFIGURATION
-- ===================================================================
-- This configuration file defines integration settings and optional
-- features for the Ambitions framework. It controls which external
-- resources are integrated and how the system interacts with other
-- Ambitions ecosystem components.
--
-- SYSTEM FEATURES:
-- • Toggle integrations with other Ambitions resources
-- • Enable/disable optional features per resource
-- • Automatic resource detection (only integrates if resource is running)
-- ===================================================================

settingsConfig = {

  -- ===================================================================
  -- RESOURCE INTEGRATIONS
  -- ===================================================================

  --- Enable Ambitions Inventory integration
  ---
  --- Automatically detects if the ambitions-inventory resource is available.
  --- When the resource is present, the framework will integrate with the
  --- inventory system for item management, player inventories, and related
  --- features.
  ---
  --- REQUIREMENTS:
  --- • ambitions-inventory resource must be running on the server
  --- • Database tables (inventories, inventory_items) must exist
  ---
  --- BEHAVIOR:
  --- • Resource detected: Full inventory integration enabled
  --- • Resource missing: No inventory features available
  ---
  --- USAGE:
  --- • Check this value before calling inventory exports
  --- • if settingsConfig.useAmbitionsInventory then ... end
  useAmbitionsInventory = GetResourceState('Ambitions-Inventory') ~= 'missing',

}
