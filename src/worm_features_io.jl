"""
Loads a set of registration problems into an array.
# Arguments:
- `rootpath::String`: working directory of registration quality data
- `edge_files::Array{String, 1}`: files containing registration problems
"""
function load_registration_problems(rootpath::String, edge_files::Array{String,1})
    reg_problems = []
    for edge_file in edge_files
        open(joinpath(rootpath, edge_file)) do f
            for line in eachline(f)
                push!(reg_problems, Tuple(map(x->parse(Int64, x), split(line))))
            end
        end
    end
    return reg_problems
end

"""
Reads the worm head position from the file `head_path::String`.
Returns a dictionary mapping frame => head position of the worm at that frame.
"""
function read_head_pos(head_path::String)
    head_pos = Dict()
    open(head_path) do f
        for line in eachline(f)
            l = split(line)
            head_pos[parse(Int64, l[1])] = Tuple(map(x->parse(Int64, x), l[2:end]))
        end
    end
    return head_pos
end
