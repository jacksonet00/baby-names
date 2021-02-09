using SQLite
using Gadfly
using DataFrames

# TODO: Add normalized frequency

function plot(db_name, name, sex)
   db = SQLite.DB(db_name)

   query = """
   SELECT year AS Year, num AS Frequency
   FROM names
   WHERE lower(name)=lower("$(name)") and lower(sex)=lower("$(sex)")
   ORDER BY year;
   """

   data = DBInterface.execute(db, query) |> DataFrame

   plt = Gadfly.plot(data, x=:Year, y=:Frequency, Geom.bar)
   normalized_plt = Gadfly.plot(data, x=:Year, y=:Frequency, Geom.bar)
   fig = Gadfly.hstack(plt, normalized_plt)
   img = SVG("plot.svg")
   draw(img, fig)
end

plot(ARGS[1], ARGS[2], ARGS[3])