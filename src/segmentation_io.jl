"""
Loads training (or validation dataset) in 3D dataset `h5_file::String`.
Returns `raw`, `label`, and `weight` fields.
"""
function load_training_set(h5_file::String)
    training_set = h5open(h5_file, "r")
    raw = read(training_set, "raw")[:,:,:]
    label = read(training_set, "label")[:,:,:]
    weight = read(training_set, "weight")[:,:,:]
    close(training_set)
    return (raw, label, weight)
end

"""
Loads UNet predictions in 3D dataset `h5_file::String`.
If the file has a fourth dimension, assumes predictions are stored in its second entry.
Returns the portion of `predictions` field corresponding to foreground.
Can optionally set `threshold` to binarize predictions.
"""
function load_predictions(h5_file::String; threshold=nothing)
    prediction_set = h5open(h5_file, "r")
    predictions = read(prediction_set, "predictions")
    if length(size(predictions)) == 4
        predictions = predictions[:,:,:,2]
    end
    close(prediction_set)
    if threshold == nothing
        return predictions
    else
        return predictions .> threshold
    end
end
