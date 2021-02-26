function shear_correction_mhd(path_dir_mhd, path_dir_MIP, n_x, n_y, n_z, t_range, ch_list, f_basename::Function; vmax=1600)    
    size_x, size_y, size_z = n_x, n_y, n_z
    
    img1_g = CuArray{Float32}(undef, size_x, size_y)
    img2_g = CuArray{Float32}(undef, size_x, size_y)
    img1_f_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    img2_f_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    CC_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    N_g = CuArray{Float32}(undef, size_x, size_y);

    img_stack = zeros(Float32, size_x, size_y, size_z)
    img_stack_reg = zeros(Float32, size_x, size_y, size_z)

    reg_params_dict = Dict()

    @showprogress for t = t_range
        # reset parameters for each time point
        reg_params_dict[t] = Dict()
        # first channel in list does the registration; the other channels use the same one
        for ch = ch_list
            basename = f_basename(t, ch)
            path_mhd = joinpath(path_dir_mhd, basename * ".mhd")
            path_raw = joinpath(path_dir_mhd, basename * ".raw")
            path_MIP = joinpath(path_dir_MIP, basename * ".png")

            img_stack .= Float32.(read_img(MHD(path_mhd)))
            reg_stack_translate!(img_stack, img_stack_reg, img1_g, img2_g, img1_f_g, img2_f_g, CC_g, N_g, z_center=nothing, reg_params=reg_params_dict[t])

            write_raw(path_raw, floor.(UInt16, clamp.(img_stack_reg, typemin(UInt16), typemax(UInt16))))
            imsave(path_MIP, maxprj(img_stack_reg, dims=3) / vmax, cmap="gray")
        end
    end
    return reg_params_dict
end
