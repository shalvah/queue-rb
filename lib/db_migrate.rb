require_relative "./db"

DB.create_table :jobs do
  primary_key :id
  String :name, unique: true, null: false
end