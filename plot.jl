using SQLite
using Gadfly
using DataFrames

function plot(db_name, name, sex)
   db = SQLite.DB(db_name)

   query = """
   SELECT name, n.year as Year, num as Count, (num * 1.0 / pop) * 100 as Normalized
   FROM (
      SELECT year, sum(num) as pop
      FROM names
      GROUP BY year
   ) t1, names n
   WHERE t1.year = n.year AND LOWER(name)=LOWER("$(name)") AND LOWER(sex)=LOWER("$(sex)");
   """

   data = DBInterface.execute(db, query) |> DataFrame

   Gadfly.push_theme(:dark)

   plt = Gadfly.plot(
      data,
      x=:Year,
      y=:Count,
      Geom.bar,
      Scale.y_continuous(format=:plain)
   )
   Gadfly.push!(plt, Guide.title("Population"))
   Gadfly.push!(plt, Guide.xlabel(nothing))
   Gadfly.push!(plt, Guide.ylabel("# of citizens"))

   normalized_plt = Gadfly.plot(
      data,
      x=:Year,
      y=:Normalized,
      Geom.bar,
   )
   Gadfly.push!(normalized_plt, Guide.title("Normalized"))
   Gadfly.push!(normalized_plt, Guide.xlabel(nothing))
   Gadfly.push!(normalized_plt, Guide.ylabel("% of citizens"))

   fig = Gadfly.hstack(plt, normalized_plt)

   img = SVG("plot.svg", 10inch, 6inch)
   draw(img, fig)

   close(db)
end

plot(ARGS[1], ARGS[2], ARGS[3])
