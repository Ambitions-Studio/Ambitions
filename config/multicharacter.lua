-- ===================================================================
-- AMBITIONS FRAMEWORK - SPAWN CONFIGURATION
-- ===================================================================
-- This configuration file controls the spawn system of the Ambitions framework.
-- It determines whether the framework manages player spawning directly or
-- delegates this responsibility to an external identity/multicharacter system.
--
-- HOW IT WORKS:
-- - If useMulticharacter = true: Framework delegates ALL spawning to an
--   external system (identity/multicharacter). Framework no longer handles spawn.
-- 
-- - If useMulticharacter = false: Framework only handles basic player spawning
--   using the parameters configured below. It does NOT manage any identity
--   system or character creation.
-- ===================================================================

return {
  -- ===================================================================
  -- SPAWN MANAGEMENT - DELEGATION OR FRAMEWORK
  -- ===================================================================

  --- Delegate spawning to an external identity/multicharacter system
  --- 
  --- • true: Framework delegates ALL spawning to the external system
  ---         Framework no longer handles player spawning
  ---         Perfect for using a complete identity system
  --- 
  --- • false: Framework handles basic player spawning
  ---          Uses defaultSpawnPosition and defaultModel parameters
  ---          NO identity system or character creation included
  ---
  --- USAGE EXAMPLES:
  --- - GetResourceState('Ambitions-Multicharacter') == 'started'  (auto-detect Ambitions Studio)
  --- - GetResourceState('your-identity') == 'started'             (auto-detect your resource)
  --- - true                                                       (always delegate)
  --- - false                                                      (framework handles spawn)
  useMulticharacter = GetResourceState('Ambitions-Multicharacter') == 'started',

  -- ===================================================================
  -- SPAWN PARAMETERS (useMulticharacter = false only)
  -- ===================================================================
  -- These parameters are ONLY used if useMulticharacter = false
  -- If useMulticharacter = true, these values are ignored
  -- ===================================================================

  --- Default spawn position for players
  --- Format: vector4(x, y, z, heading)
  --- Used only when framework handles spawning (useMulticharacter = false)
  defaultSpawnPosition = vector4(0.0, 0.0, 70.0, 0.0),

  --- Default character model
  --- Common models: 'mp_m_freemode_01' (male), 'mp_f_freemode_01' (female)
  --- Used only when framework handles spawning (useMulticharacter = false)
  defaultModel = 'mp_m_freemode_01',
}