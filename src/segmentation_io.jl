"""
Loads training (or validation dataset) in 3D dataset `h5_file::String`.
Returns `raw`, `label`, and `weight` fields.
"""
function load_training_set(h5_file::String)
    training_set = open(h5_file, "r")
    raw = read(training_set, "raw")[:,:,:]
    label = read(training_set, "label")[:,:,:]
    weight = read(training_set, "weight")[:,:,:]
    close(training_set)
    return (raw, label, weight)
end

"""
Loads UNet predictions in 3D dataset `h5_file::String`.
Assumes binary predictions that are stored in the fourth dimension of the file.
Returns the portion of `predictions` field corresponding to foreground
with probability at least `threshold::Real`
"""
function load_predictions(h5_file::String, threshold::Real)
    prediction_set = open(h5_file, "r")
    predictions = read(prediction_set, "predictions")[:,:,:,2]
    close(prediction_set)
    return predictions .> threshold
end
