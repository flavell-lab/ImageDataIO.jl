"""
    shear_correction_nrrd!(
        param_path::Dict, param::Dict, ch::Int, shear_params_dict::Dict;
        vmax::Int=1600, nrrd_in_key::String="path_dir_nrrd", nrrd_out_key::String="path_dir_nrrd_shearcorrect",
        MIP_out_key::String="path_dir_MIP_shearcorrect"
    )

Applies shear correction to a dataset.
# Arguments
 - `param_path::Dict`: Dictionary containing locations of input and output directories with NRRD files
 - `param::Dict`: Dictionary containing image dimension parameters `x_range`, `y_range`, `z_range`, and `t_range`
 - `ch`: Channel to apply shear correction to
 - `shear_params_dict::Dict`: Dictionary of shear correction parameters. If nonempty, those parameters will be used.
    If empty, it will be filled with the computed paramers.
 - `vmax::Int` (optional, default 1600): Contrast parameter for png files
 - `nrrd_in_key::String` (optional): Key in `param_path` containing input NRRD directory
 - `NRRD_out_key::String` (optional): Key in `param_path` containing output NRRD directory
 - `MIP_out_key::String` (optional): Key in `param_path` containing output MIP directory
"""
function shear_correction_nrrd!(param_path::Dict, param::Dict, ch::Int, shear_params_dict::Dict;
        vmax::Int=1600, nrrd_in_key::String="path_dir_nrrd", nrrd_out_key::String="path_dir_nrrd_shearcorrect",
        MIP_out_key::String="path_dir_MIP_shearcorrect")
    create_dir(param_path[nrrd_out_key])
    create_dir(param_path[MIP_out_key])
    size_x, size_y, size_z = length(param["x_range"]), length(param["y_range"]), length(param["z_range"])
    
    img1_f_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    img2_f_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    CC2x_g = CuArray{Complex{Float32}}(undef, 2 * size_x, 2 * size_y)
    N_g = CuArray{Float32}(undef, size_x, size_y)
    img_stack_reg = zeros(Float32, size_x, size_y, size_z)
    img_stack_reg_g = CuArray{Float32}(undef, size_x, size_y, size_z)

    for t = param["t_range"]
        # check if parameters exist at the given time point
        if !haskey(shear_params_dict, t)
            shear_params_dict[t] = Dict()
        end
        basename = param_path["get_basename"](t, ch)
        path_nrrd_in = joinpath(param_path[nrrd_in_key], basename * ".nrrd")
        path_nrrd_out = joinpath(param_path[nrrd_out_key], basename * ".nrrd")
        path_MIP_out = joinpath(param_path[MIP_out_key], basename * ".png")
        
        nrrd_in = NRRD(path_nrrd_in)
        copyto!(img_stack_reg_g, Float32.(read_img(nrrd_in)))
        reg_stack_translate!(img_stack_reg_g, img1_f_g, img2_f_g, CC2x_g, N_g,
            reg_param=shear_params_dict[t])
        copyto!(img_stack_reg, img_stack_reg_g)

    # fill unknown data with noise
    # (unknown because shearing brought unimaged pixels into frame,
    #  previously replaced with wrap-around (bad))
    # Note: if shear magnitude is over half the image, this does the wrong thing, but it's a bad frame anyway
	noise_sampler = vec(img_stack_reg)
	noise_cutoff = quantile(noise_sampler, 0.96) # Define "noise" as dimmest 96% of pixels
	noise_sampler = noise_sampler[noise_sampler .<= noise_cutoff]
	#faux_black = minimum(noise_sampler) #remove once correct quantile is identified
	#img_stack_reg = broadcast((x) -> x > noise_cutoff ? faux_black : x, img_stack_reg) # remove once correct quantile is identiified
	for z_slice in sort(collect(keys(shear_params_dict[t])))
		x_shift = round(Int64, shear_params_dict[t][z_slice][2][1], RoundFromZero)
		y_shift = round(Int64, shear_params_dict[t][z_slice][2][2], RoundFromZero)
		for x in x_shift:-1
			img_stack_reg[size(img_stack_reg)[1]+x+1, :, z_slice] = rand(noise_sampler, size(img_stack_reg)[2])
		end
		for x in 1:x_shift
			img_stack_reg[x, :, z_slice] .= rand(noise_sampler, size(img_stack_reg)[2])
		end
		for y in y_shift:-1
			img_stack_reg[:, size(img_stack_reg)[2]+y+1, z_slice] .= rand(noise_sampler, size(img_stack_reg)[1])
		end
		for y in 1:y_shift
			img_stack_reg[:, y, z_slice] .= rand(noise_sampler, size(img_stack_reg)[1])
		end
	end

        write_nrrd(path_nrrd_out, floor.(UInt16, clamp.(img_stack_reg, typemin(UInt16), typemax(UInt16))),
            spacing(nrrd_in))
        imsave(path_MIP_out, maxprj(img_stack_reg, dims=3) / vmax, cmap="gray")
    end
 
    CUDA.unsafe_free!(img_stack_reg_g)
    CUDA.unsafe_free!(img1_f_g)
    CUDA.unsafe_free!(img2_f_g)
    CUDA.unsafe_free!(CC2x_g)
    CUDA.unsafe_free!(N_g)    
    GC.gc(true)
    CUDA.reclaim()
 
    return shear_params_dict
end
