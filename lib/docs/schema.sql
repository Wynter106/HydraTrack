-- HydraTrack Database Schema
-- Version: 1.0
-- Description: SQLite database structure for hydration tracking app

-- =============================================
-- BEVERAGES TABLE
-- Stores all beverage information with caffeine and hydration data
-- Source: Caffeine Informer (https://www.caffeineinformer.com)
-- =============================================
CREATE TABLE IF NOT EXISTS beverages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    caffeine_per_oz REAL NOT NULL DEFAULT 0,
    hydration_factor REAL NOT NULL DEFAULT 1.0,
    default_volume_oz REAL NOT NULL DEFAULT 8
);

-- =============================================
-- DRINK_LOGS TABLE
-- Stores user's drink consumption history
-- =============================================
CREATE TABLE IF NOT EXISTS drink_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    beverage_id INTEGER NOT NULL,
    volume_oz REAL NOT NULL,
    timestamp TEXT NOT NULL,
    actual_hydration_oz REAL NOT NULL,
    FOREIGN KEY (beverage_id) REFERENCES beverages(id)
);

-- =============================================
-- USER_SETTINGS TABLE
-- Stores user preferences and goals
-- =============================================
CREATE TABLE IF NOT EXISTS user_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    setting_key TEXT NOT NULL UNIQUE,
    setting_value TEXT NOT NULL
);

-- Default user settings
INSERT OR IGNORE INTO user_settings (setting_key, setting_value) VALUES ('hydration_goal_oz', '64');
INSERT OR IGNORE INTO user_settings (setting_key, setting_value) VALUES ('caffeine_limit_mg', '400');

-- =============================================
-- INDEXES
-- For faster queries
-- =============================================
CREATE INDEX IF NOT EXISTS idx_drink_logs_timestamp ON drink_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_drink_logs_beverage_id ON drink_logs(beverage_id);
CREATE INDEX IF NOT EXISTS idx_beverages_name ON beverages(name);