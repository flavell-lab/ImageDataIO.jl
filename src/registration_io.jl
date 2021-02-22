"""
`function modify_parameter_file(param_in::String, param_out::String, substitutions::Dict; is_universal=false)``
Modifies an elastix transform parameter file `param_in` by changing every entry of it that is a key in `substitutions`
to the corresponding value. Writes the output to `param_out`. If keyword parameter `is_universal` is set to true,
it will simply find/replace all instances of text in `substitutions` regardless of if it is a key.
"""
function modify_parameter_file(param_in::String, param_out::String, substitutions::Dict; is_universal=false)
    result_str = ""
    open(param_in, "r") do f
        for line in eachline(f)
            if length(line) == 0
                result_str *= line*"\n"
                continue
            end

            line_key = split(line)[1][2:end]
            found = false
            for key in keys(substitutions)
                if is_universal
                    result_str *= replace(line, key => substitutions[key]) * "\n"
                elseif key == line_key
                    result_str *= "($key $(substitutions[key]))\n"
                    found = true
                    break
                end
            end
            if !is_universal && !found
                result_str *= line*"\n"
            end
        end
    end
    open(param_out, "w") do f
        write(f, result_str)
    end
end

"""
Reads a value from a paremeter file.

# Arguments

- `parameter_fiile_path::String`: Path to parameter file
- `key::String`: Value to read
- `dtype::Type`: Type of the value or elements of value (if it's an array)
"""
function read_parameter_file(parameter_file_path::String, key::String, dtype::Type)
    val = nothing
    open(parameter_file_path, "r") do f
        for line in eachline(f)
            if length(line) == 0
                continue
            end
            line_key = split(line)[1][2:end]
            if key == line_key
                value = [parse(dtype, replace(x, ")"=>"")) for x in split(line)[2:end]]
                if length(value) == 1
                    val = value[1]
                else
                    val = value
                end
                break
            end
        end
    end
    if isnothing(val)
        error("Key $(key) not found in parameter file $(parameter_file_path)")
    else
        return val
    end
end

"""
Modifies an mhd file `mhd_in` by changing every entry of it that is a key in `substitutions`
to the corresponding value. Writes the output to `mhd_out`.
"""
function modify_mhd(mhd_in::String, mhd_out::String, substitutions::Dict)
    result_str = ""
    open(mhd_in, "r") do f
        for line in eachline(f)
            if length(line) == 0
                result_str *= line*"\n"
                continue
            end
            line_key = split(line)[1]
            found = false
            for key in keys(substitutions)
                if key == line_key
                    result_str *= "$key = $(substitutions[key])\n"
                    found = true
                    break
                end
            end
            if !found
                result_str *= line*"\n"
            end
        end
    end
    open(mhd_out, "w") do f
        write(f, result_str)
    end
end
