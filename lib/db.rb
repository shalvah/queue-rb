require "sequel"

DB = Sequel.sqlite(File.join(__dir__, '../database.db'))