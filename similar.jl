using DataFrames
using SQLite
using LinearAlgebra

function get_similar_names(db_name)
    db = SQLite.DB(db_name)

    query = """
    SELECT * FROM names;
    """
    data = DBInterface.execute(db, query) |> DataFrame

    Ng = length(unique(groupby(data, "sex")[1][!, "name"]))
    Nb = length(unique(groupby(data, "sex")[2][!, "name"]))
    Ny = length(unique(data[!, "year"]))

    boy_name_to_index = Dict{String, Int32}()
    boy_index_to_name = Dict{Int32, String}()

    index = 1

    for row in eachrow(unique(groupby(data, "sex")[2][!, "name"]))
        boy_name_to_index[row[1]] = index
        boy_index_to_name[index] = row[1]
        index += 1
    end

    girl_name_to_index = Dict{String, Int32}()
    girl_index_to_name = Dict{Int32, String}()

    index = 1

    for row in eachrow(unique(groupby(data, "sex")[1][!, "name"]))
        girl_name_to_index[row[1]] = index
        girl_index_to_name[index] = row[1]
        index += 1
    end

    year_to_index = Dict{Int32, Int32}()
    index_to_year = Dict{Int32, Int32}()

    index = 1

    for row in eachrow(unique(data[!, "year"]))
        year_to_index[row[1]] = index
        index_to_year[index] = row[1]
        index += 1
    end

    Fb = Array{Int32, 2}(zeros(Nb, Ny))
    Fg = Array{Int32, 2}(zeros(Ng, Ny))

    for row in eachrow(data)
        if row[:sex] == "F"
            Fg[girl_name_to_index[row[:name]], year_to_index[row[:year]]] = row[:num]
        else
            Fb[boy_name_to_index[row[:name]], year_to_index[row[:year]]] = row[:num]
        end
    end

    Ty = zeros(Ny)

    for i in eachindex(Ty)
        Ty[i] = sum(Fb[:, i]) + sum(Fg[:, i])
    end

    Pb = Array{Float32, 2}(zeros(Nb, Ny))
    Pg = Array{Float32, 2}(zeros(Ng, Ny))
    
    for i in 1:Nb
        for j in 1:Ny
            Pb[i, j] = Fb[i, j] / Ty[j]
        end
    end
    
    for i in 1:Ng
        for j in 1:Ny
            Pg[i, j] = Fg[i, j] / Ty[j]
        end
    end

    Qb = Array{Float32, 2}(zeros(Nb, Ny))
    Qg = Array{Float32, 2}(zeros(Ng, Ny))
    
    for i in 1:Nb
        row = Pb[i, :]
        n_row = normalize(row)
        Qb[i, :] = n_row
    end
    
    for i in 1:Ng
        row = Pg[i, :]
        n_row = normalize(row)
        Qg[i, :] = n_row
    end
    
    # Partition the matrix

    Qb_part = Array{Array{Float32, 2}, 1}()
    Qg_part = Array{Array{Float32, 2}, 1}()

    i = 1
    j = Int(round(Nb / 10))
    x = 1
    y = Int(round(Ng / 10))

    while j < Nb && y < Ng
        push!(Qb_part, Qb[i:j, :])
        push!(Qg_part, Qg[x:y, :])

        i += Int(round(Nb / 10))
        j += Int(round(Nb / 10))
        x += Int(round(Ng / 10))
        y += Int(round(Ng / 10))
    end

    global max_distance = Float64(0)
    global partition = 0
    global index1 = 0
    global index2 = 0

    Threads.@threads for i in 1:10
        for j in 1:10
            m = findmax(Qb_part[i] * Qg_part[j]')
            if max_distance < m[1]
                global index1 = m[2][1]
                global index2 = m[2][2]
                global max_distance = m[1]
                global partition = i
            end
        end
    end

    return [girl_index_to_name[(partition - 1) * Int(round(Ng / 10)) + index2], boy_index_to_name[(partition - 1) * Int(round(Nb / 10)) + index1], max_distance]
end

names = get_similar_names("names.db")
println("Girl name: $(names[1])\nBoy name: $(names[2])\nMax distance: $(names[3])")