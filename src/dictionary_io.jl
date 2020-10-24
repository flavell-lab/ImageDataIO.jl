"""
Writes dictionary `dict` to file `out::AbstractString`
"""
function write_dict(dict, out::AbstractString)
    open(out, "w") do f
        for k in keys(dict)
            write(f, "$(k) $(dict[k])\n")
        end
    end
end


"""
Reads 2D dictionary (dictionary of dictionaries) from a file.

# Arguments
- `input::AbstractString`: input file
- `outer_key_dtype::Type`: data type of outer keys
- `inner_key_dtype::Type`: data type of inner keys
- `val_dtype::Type`: data type of values of inner dict
"""
function read_2d_dict(input::AbstractString, outer_key_dtype::Type, inner_key_dtype::Type, val_dtype::Type)
    dict = Dict()
    open(input) do f
        for line in eachline(f)
            k = Tuple(parse_1d_tuple(split(line, "Dict")[1], outer_key_dtype))
            if length(k) == 1
                k = k[1]
            end
            v = parse_1d_dict(split(line, "}(")[2], inner_key_dtype, val_dtype)
            dict[k] = v
        end
    end
    return dict
end


"""
Parses one-dimensional string tuple `tuple_str::AbstractString` into a tuple of the specified `dtype::Type`
"""
function parse_1d_tuple(tuple_str::AbstractString, dtype::Type)
    return Tuple(map(x->parse(dtype, x), split(replace(tuple_str, r"\(|\)|\[|\]"=>""), ",")))
end


"""
Parses a 1D dictionary; the keys and values must be at most 1D arrays. Arguments:

- `dict_str::AbstractString`: string representation of dictionary to parse
- `key_dtype::Type`: element data type of dictionary keys
- `val_dtype::Type`: element data type of dictionary values
"""
function parse_1d_dict(dict_str::AbstractString, key_dtype::Type, val_dtype::Type)
    dict = Dict()
    kv_pairs = split(dict_str, "=>")
    for i=1:length(kv_pairs) - 1
        key = split_arrays(kv_pairs[i])[2 - (i == 1)]
        if key isa String
            key = parse(key_dtype, key)
        else
            key = Tuple(map(x->parse(key_dtype, x), key))
        end
        val = split_arrays(kv_pairs[i+1])[1]
        if val isa String
            val = parse(val_dtype, val)
        else
            val = Tuple(map(x->parse(val_dtype, x), val))
        end
        dict[key] = val
    end
    return dict
end



"""
Parses a string multi-dimensional array or list of arrays `arrays::AbstractString` into its component arrays.

# Arguments
- `arrays::AbstractString`: string of arrays to parse

# Optional keyword arguments
- `fwd_delimiters`: list of characters to delineate when an array starts
- `back_delimiters`: list of characters to delineate when an array ends
- `val_delimiters`: list of characters to delineate separating values of the array
- `ignore_chars`: list of characters to ignore and not put in the final array
"""
function split_arrays(arrays::AbstractString; fwd_delimiters=['[', '('], back_delimiters=[')', ']'], val_delimiters=[','], ignore_chars=[' ', '\n'])
    arrs = []
    index = [1]
    curr_str = ""
    for c in arrays
        if (c in fwd_delimiters) || (c in back_delimiters) || (c in val_delimiters)
            if curr_str != ""
                push!(multi_index_array(arrs, index[1:end-1]), string(curr_str))
                curr_str = ""
            end
        end
        if c in fwd_delimiters
            push!(multi_index_array(arrs, index[1:end-1]), [])
            push!(index, 1)
        elseif c in back_delimiters
            index = index[1:end-1]
        elseif c in val_delimiters
            index[end] += 1
        elseif !(c in ignore_chars)
            curr_str *= c
        end
    end
    push!(multi_index_array(arrs, index[1:end-1]), string(curr_str))
    return arrs
end


"""
Indexes a nested `array` at `index` as though the array was a mulit-dimensional array.
"""
function multi_index_array(array, index)
    sub_array = array
    for v in index
        sub_array = sub_array[v]
    end
    return sub_array
end


