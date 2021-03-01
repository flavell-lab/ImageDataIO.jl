"""
Applies shear correction to a dataset.

# Arguments
 - `param_path::Dict`: Dictionary containing locations of input and output directories with MHD files
 - `param::Dict`: Dictionary containing image dimension parameters `x_range`, `y_range`, `z_range`, and `t_range`
 - `ch_list`: List of channels to apply shear correction to; all channels will have the same shear correction applied.
 - `shear_params_dict::Dict`: Dictionary of shear correction parameters. If nonempty, those parameters will be used.
    If empty, it will be filled with the computed paramers.
 - `vmax::Int`: Contrast parameter for png files
 - `mhd_key::String` (optional): Key in `param_path` containing input MHD directory
 - `mhd_out_key::String` (optional): Key in `param_path` containing output MHD directory
 - `MIP_out_key::String` (optional): Key in `param_path` containing output MIP directory
"""
function shear_correction_mhd!(param_path::Dict, param::Dict, ch_list, shear_params_dict::Dict;
        vmax::Int=1600, mhd_key::String="path_dir_mhd", mhd_out_key::String="path_dir_mhd_shearcorrect", MIP_out_key::String="path_dir_MIP_shearcorrect")

    create_dir(param_path[mhd_out_key])
    create_dir(param_path[MIP_out_key])
    size_x, size_y, size_z = length(param["x_range"]), length(param["y_range"]), length(param["z_range"])
    
    img1_g = CuArray{Float32}(undef, size_x, size_y)
    img2_g = CuArray{Float32}(undef, size_x, size_y)
    img1_f_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    img2_f_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    CC_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    N_g = CuArray{Float32}(undef, size_x, size_y);

    img_stack = zeros(Float32, size_x, size_y, size_z)
    img_stack_reg = zeros(Float32, size_x, size_y, size_z)


    @showprogress for t = param["t_range"]
        # check if parameters exist at the given time point
        if !haskey(shear_params_dict, t)
            shear_params_dict[t] = Dict()
        end
        # first channel in list does the registration; the other channels use the same one
        for ch = ch_list
            basename = param_path["get_basename"](t, ch)
            path_mhd_in = joinpath(param_path[mhd_key], basename * ".mhd")
            path_mhd_out = joinpath(param_path[mhd_out_key], basename * ".mhd")
            path_raw_out = joinpath(param_path[mhd_out_key], basename * ".raw")
            path_MIP_out = joinpath(param_path[MIP_out_key], basename * ".png")

            img_stack .= Float32.(read_img(MHD(path_mhd_in)))
            reg_stack_translate!(img_stack, img_stack_reg, img1_g, img2_g, img1_f_g, img2_f_g, CC_g, N_g, z_center=nothing, reg_params=shear_params_dict[t])

            cp(path_mhd_in, path_mhd_out, force=true)
            write_raw(path_raw_out, floor.(UInt16, clamp.(img_stack_reg, typemin(UInt16), typemax(UInt16))))
            imsave(path_MIP_out, maxprj(img_stack_reg, dims=3) / vmax, cmap="gray")
        end
    end
    return shear_params_dict
end
