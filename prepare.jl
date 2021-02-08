using ZipFile
using SQLite
using CSV

rdr = ZipFile.Reader(ARGS[1])
db = SQLite.DB(ARGS[2])

drop = """
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
insert = """
INSERT INTO names
(year, name, sex, num)
VALUES
(?, ?, ?, ?);
"""
insert_sql = DBInterface.prepare(db, insert)

DBInterface.execute(db, drop)
DBInterface.execute(db, schema)

for f in rdr.files
   if endswith(f.name, ".txt")
      year = split(split(split(f.name, "/")[end], ".")[1], "yob")[end]
      f_csv = CSV.File(f; header=false, footerskip=1)
      println("Loading year $(year) from $(f.name)...")
      for row in f_csv
         DBInterface.execute(insert_sql, [year, row[1], row[2], row[3]])
      end
      println("Completed :)")
   end
end