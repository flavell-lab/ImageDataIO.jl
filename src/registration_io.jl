"""
Modifies an elastix transform parameter file `param_in` by changing every entry of it that is a key in `substitutions`
to the corresponding value. Writes the output to `param_out`.
"""
function modify_parameter_file(param_in::String, param_out::String, substitutions::Dict)
    if length(keys(substitutions)) == 0
        error("Empty substitution dictionary.")
    end
    result_str = ""
    open(param_in, "r") do f
        for line in eachline(f)
            if length(line) == 0
                result_str *= line*"\n"
                continue
            end
            line_key = split(line)[1][2:end]
            for key in keys(substitutions)
                if key == line_key
                    result_str *= "($key $(substitutions[key]))\n"
                else
                    result_str *= line*"\n"
                end
            end
        end
    end
    open(param_out, "w") do f
        write(f, result_str)
    end
end