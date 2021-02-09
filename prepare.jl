using ZipFile
using SQLite
using CSV
using DataFrames

drop_tables = """
DROP TABLE IF EXISTS names;
"""

schema = """
CREATE TABLE IF NOT EXISTS names (
year INTEGER,
name TEXT,
sex TEXT,
num INTEGER
);
"""

prepared_statement = """
INSERT INTO names
(year, name, sex, num)
VALUES
(?, ?, ?, ?);
"""

function load(zip_archive, db_name)
   reader = ZipFile.Reader(zip_archive)
   db = SQLite.DB(db_name)

   DBInterface.execute(db, drop_tables)
   DBInterface.execute(db, schema)

   insertion = DBInterface.prepare(db, prepared_statement)

   for file in reader.files
      if endswith(f.name, ".txt")
         year = split(split(split(f.name, "/")[end], ".")[1], "yob")[end]
         csv_file = CSV.File(f; header=false, footerskip=1)
         println("Loading data from $(year)...")
         for row in csv_file
            DBInterface.execute(insertion, [year, row[1], row[2], row[3]])
         end
      end
   end

   close(reader)
   close(db)
end

load(ARGS[1], ARGS[2])
