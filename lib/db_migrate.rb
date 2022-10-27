DB.drop_table? :jobs
DB.create_table :jobs do
  String :id, primary_key: true, size: 12
  String :name, null: false
  JSON :args, null: false
  String :queue, default: "default"
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP, index: true
  DateTime :next_execution_at, null: true, index: true # for scheduled jobs and retries
  DateTime :last_executed_at, null: true
  Integer :attempts, default: 0
  String :state, default: "waiting", index: true
  String :error_details, null: true
  String :reserved_by, null: true
end