import GRDB

/// A type responsible for initializing the application database.

struct AppDatabase {
    
    /// Creates a fully initialized database at path
    static func openDatabase(atPath path: String) throws -> DatabaseQueue {
        dbQueue = try DatabaseQueue(path: path)
        try migrator.migrate(dbQueue)
        return dbQueue
    }
  
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1") { db in
            // Create all requied tables
            try db.create(table: "ufo") { t in
              t.column("name", .text).notNull()
              t.column("store_id", .text).notNull()
              t.column("brew_id", .text).notNull()
              t.column("brewer", .text)
              t.column("city", .text)
              t.column("is_local", .text)
              t.column("country", .text)
              t.column("containerx", .text)
              t.column("style", .text)
              t.column("descriptionx", .text)
              t.column("abv", .text)
              t.column("stars", .text)
              t.column("reviews", .text)
              t.column("created", .text)
              t.column("active", .text)
              t.column("tasted", .text)
              t.column("highlighted", .text)
              t.column("created_date", .text)
              t.column("new_arrival", .text)
              t.column("is_import", .text)
              t.column("glass_size", .text)
              t.column("glass_price", .text)
            }
        }
        
        migrator.registerMigration("v2") { db in
          try db.execute("ALTER TABLE ufo ADD COLUMN user_review TEXT")
          try db.execute("ALTER TABLE ufo ADD COLUMN user_stars TEXT")
          try db.execute("ALTER TABLE ufo ADD COLUMN review_id TEXT")
          try db.execute("ALTER TABLE ufo ADD COLUMN review_flag TEXT")
          try db.execute("ALTER TABLE ufo ADD COLUMN timestamp TEXT")
        }
      
      migrator.registerMigration("v3") { db in
        try db.create(table: "ufolocal") { t in
          t.column("name", .text).notNull()
          t.column("store_id", .text).notNull()
          t.column("brew_id", .text).notNull()
          t.column("glass_size", .text)
          t.column("glass_price", .text)
          t.column("added_now_flag", .text)
          t.column("last_updated_date", .text)
          t.column("abv", .text)
          t.column("untappd_beer", .text)
          t.column("untappd_brewery", .text)
        }
        try db.execute("ALTER TABLE ufo ADD COLUMN untappd_beer TEXT")
        try db.execute("ALTER TABLE ufo ADD COLUMN untappd_brewery TEXT")
      }

      //DRS 20231121
      migrator.registerMigration("v4") { db in
        try db.execute("ALTER TABLE ufo ADD COLUMN que_stamp TEXT")
        try db.execute("ALTER TABLE ufo ADD COLUMN currently_queued TEXT")
      }
      
      return migrator
    }
}
