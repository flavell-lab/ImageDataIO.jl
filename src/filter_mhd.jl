function get_λ(img_list::Array; verbose=true)
    # img_array dim: x, y, z, t
    n_t = length(img_list)

    θ_list = []
    for t = 1:n_t
        img_MIP = Float32.(maxprj(img_list[t], dims=3))
        push!(θ_list, compute_λ_filt(img_MIP))
    end
    
    λ_μ = mean(θ_list)
    λ_σ = std(θ_list)
    verbose && println("mean(λ): $(λ_μ) std(λ): $(λ_σ)")
    
    λ_μ
end

function filter_mhd_gpu(param_path::Dict, path_dir_mhd, t_range, list_ch, f_basename::Function; mhd_filt_dir_key::String="path_dir_mhd_filt", 
        mip_filt_dir_key::String="path_dir_MIP_filt", vmax=1600)
    path_dir_mhd_filt = param_path[mhd_filt_dir_key]
    path_dir_MIP_filt = param_path[mip_filt_dir_key]
    create_dir.([path_dir_mhd_filt, path_dir_MIP_filt])
    
    # getting image size
    path_mhd = joinpath(path_dir_mhd, f_basename(t_range[1], list_ch[1]) * ".mhd")
    img = read_img(MHD(path_mhd))
    type_img = eltype(img)
    n_t = length(t_range)
    
    # getting the filter parameter
    list_λ = []
    for ch = list_ch
        list_img_λ = []
        for t = [round(Int, n_t * i / 10) for i = 1:10]
            path_mhd = joinpath(path_dir_mhd, f_basename(t, ch) * ".mhd")
            push!(list_img_λ, read_img(MHD(path_mhd)))
        end
        println("ch$ch parameter:")
        push!(list_λ, get_λ(list_img_λ))
    end

    # filtering
    @showprogress for t = t_range
        for (i_ch, ch) = enumerate(list_ch)
            λ_ch = list_λ[i_ch]
            basename = f_basename(t, ch)
            path_mhd = joinpath(path_dir_mhd, basename * ".mhd")
            path_mhd_filt = joinpath(path_dir_mhd_filt, basename * ".mhd")
            path_raw_filt = joinpath(path_dir_mhd_filt, basename * ".raw")
            path_MIP = joinpath(path_dir_MIP_filt, basename * ".png")
            
            img = Float32.(read_img(MHD(path_mhd)))
            n_x, n_y, n_z = size(img)
            img_filt = zeros(type_img, n_x, n_y, n_z)
            for z = 1:n_z
                img_filt[:,:,z] .= round.(type_img, gpu_imROF(img[:,:,z], λ_ch, 100))
            end

            cp(path_mhd, path_mhd_filt, force=true)
            write_raw(path_raw_filt, img_filt)
            imsave(path_MIP, maxprj(img_filt, dims=3) / vmax, cmap="gray");
        end
    end
end
