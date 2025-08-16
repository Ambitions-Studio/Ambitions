--- Database schema configuration for auto-migration system
--- This file defines all tables and their structure in a declarative way
---@return table schema The complete database schema configuration
return {
  version = "1.0.0",
  charset = "utf8mb4",
  collation = "utf8mb4_unicode_ci",
  engine = "InnoDB",

  tables = {
    users = {
      columns = {
        {
          name = "id",
          type = "INT",
          autoIncrement = true,
          primaryKey = true
        },
        {
          name = "license",
          type = "VARCHAR",
          length = 60,
          notNull = true,
          unique = true
        },
        {
          name = "discord_id",
          type = "VARCHAR", 
          length = 60,
          notNull = true,
          unique = true
        },
        {
          name = "ip",
          type = "VARCHAR",
          length = 40,
          notNull = true
        },
        {
          name = "last_seen",
          type = "TIMESTAMP",
          notNull = true,
          default = "CURRENT_TIMESTAMP",
          onUpdate = "CURRENT_TIMESTAMP"
        },
        {
          name = "last_played_character",
          type = "VARCHAR",
          length = 15,
          null = true
        },
        {
          name = "total_playtime",
          type = "INT",
          unsigned = true,
          notNull = true,
          default = 0,
          comment = "Total playtime in seconds"
        },
        {
          name = "created_at",
          type = "TIMESTAMP",
          notNull = true,
          default = "CURRENT_TIMESTAMP"
        }
      },
      indexes = {
        {
          name = "idx_license",
          columns = {"license"}
        },
        {
          name = "idx_discord_id", 
          columns = {"discord_id"}
        },
        {
          name = "idx_last_seen",
          columns = {"last_seen"}
        }
      },
      foreignKeys = {
        {
          name = "fk_last_played_character",
          column = "last_played_character",
          references = {
            table = "characters",
            column = "unique_id"
          },
          onDelete = "SET NULL"
        }
      }
    },

    characters = {
      columns = {
        {
          name = "id",
          type = "INT",
          autoIncrement = true,
          primaryKey = true
        },
        {
          name = "user_id",
          type = "INT",
          notNull = true
        },
        {
          name = "unique_id",
          type = "VARCHAR",
          length = 15,
          notNull = true,
          unique = true
        },
        {
          name = "group",
          type = "VARCHAR",
          length = 40,
          notNull = true
        },
        {
          name = "ped_model",
          type = "VARCHAR",
          length = 60,
          notNull = true
        },
        {
          name = "position_x",
          type = "FLOAT",
          notNull = true
        },
        {
          name = "position_y",
          type = "FLOAT",
          notNull = true
        },
        {
          name = "position_z",
          type = "FLOAT",
          notNull = true
        },
        {
          name = "heading",
          type = "FLOAT",
          notNull = true
        },
        {
          name = "playtime",
          type = "INT",
          unsigned = true,
          notNull = true,
          default = 0,
          comment = "Character playtime in seconds"
        },
        {
          name = "created_at",
          type = "TIMESTAMP",
          notNull = true,
          default = "CURRENT_TIMESTAMP"
        },
        {
          name = "last_played",
          type = "TIMESTAMP",
          notNull = true,
          default = "CURRENT_TIMESTAMP",
          onUpdate = "CURRENT_TIMESTAMP"
        }
      },
      indexes = {
        {
          name = "idx_user_id",
          columns = {"user_id"}
        },
        {
          name = "idx_unique_id",
          columns = {"unique_id"}
        }
      },
      foreignKeys = {
        {
          name = "fk_characters_user_id",
          column = "user_id",
          references = {
            table = "users",
            column = "id"
          },
          onDelete = "CASCADE"
        }
      }
    },

    -- Table for migration tracking
    schema_migrations = {
      columns = {
        {
          name = "id",
          type = "INT",
          autoIncrement = true,
          primaryKey = true
        },
        {
          name = "version",
          type = "VARCHAR",
          length = 50,
          notNull = true,
          unique = true
        },
        {
          name = "applied_at",
          type = "TIMESTAMP",
          notNull = true,
          default = "CURRENT_TIMESTAMP"
        }
      },
      indexes = {
        {
          name = "idx_version",
          columns = {"version"}
        }
      }
    }
  }
}