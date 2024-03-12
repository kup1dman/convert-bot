require 'sqlite3'

class Storage
  def initialize
    @db = SQLite3::Database.new 'bot.db'
    setup
  end

  def write_to_files_table(file_id, group_id)
    @db.execute "INSERT INTO files (file_id, group_id) VALUES (?, ?)", file_id, group_id
  end

  def write_to_groups_table(name)
    @db.execute "INSERT INTO groups (name) VALUES (?)", name
  end

  def get_file_ids_by(group)
    @db.query "SELECT file_id FROM files WHERE group=?", group
  end

  def get_group_id_by_name(name)
    query = @db.query "SELECT id FROM groups WHERE name=?", name
    query.first
  end

  def get_group_names
    @db.query "SELECT name FROM groups"
  end

  private

  def setup
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS files(
        id INTEGER PRIMARY KEY NOT NULL,
        file_id INTEGER NOT NULL,
        group_id INTEGER,
        FOREIGN KEY (group_id) REFERENCES groups(id)
      )
    SQL
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS groups(
        id INTEGER PRIMARY KEY NOT NULL,
        name VARCHAR(64) NOT NULL
      )
    SQL
  end
end


