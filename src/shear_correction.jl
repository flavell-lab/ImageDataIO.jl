function shear_correction_mhd(path_dir_mhd, n_x, n_y, n_z, t_range, list_ch, f_basename::Function; vmax=1600)    
    size_x, size_y, size_z = n_x, n_y, n_z
    
    img1_g = CuArray{Float32}(undef, size_x, size_y)
    img2_g = CuArray{Float32}(undef, size_x, size_y)
    img1_f_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    img2_f_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    CC_g = CuArray{Complex{Float32}}(undef, size_x, size_y)
    N_g = CuArray{Float32}(undef, size_x, size_y);

    img_stack = zeros(Float32, size_x, size_y, size_z)
    img_stack_reg = zeros(Float32, size_x, size_y, size_z)

    @showprogress for t = t_range, ch = list_ch
        basename = f_basename(t, ch)
        path_mhd = joinpath(path_dir_mhd, basename * ".mhd")
        path_raw = joinpath(path_dir_mhd, basename * ".raw")
        path_MIP = joinpath(path_dir_mhd, basename * ".png")

        img_stack .= Float32.(read_img(MHD(path_mhd)))
        reg_stack_translate!(img_stack, img_stack_reg, img1_g, img2_g, img1_f_g, img2_f_g, CC_g, N_g, z_center=nothing)

        write_raw(path_raw, floor.(UInt16, clamp.(img_stack_reg, typemin(UInt16), typemax(UInt16))))
#         imsave(path_MIP, maxprj(img_stack_reg, dims=3) / vmax, cmap="gray");
    end
end
