module ImageDataIO

using HDF5, MHDIO

include("centroids_io.jl")
include("worm_features_io.jl")
include("activity_io.jl")
include("segmentation_io.jl")
include("registration_io.jl")

export
        load_registration_problems,
        read_head_pos,
        write_centroids,
        read_centroids_transformix,
        read_centroids_roi,
        read_mhd,
        load_training_set,
        load_predictions,
        read_activity,
        write_activity,
        modify_parameter_file
end # module
