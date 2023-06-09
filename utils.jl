function nll_loss(y_hat::GraphNode, y::GraphNode)
    dy = y .* log.(y_hat)
    return sum(dy) * Constant(-1.0)
end

function softmax(x::GraphNode)
    e = Constant(ℯ) .^ x
    return e ./ sum(e)
end

function train_step!(graph::Vector)
    step_loss = forward!(graph)
    backward!(graph)
    return step_loss
end

function test_step(graph::Vector)
    step_loss = forward!(graph)
    return step_loss
end

function encode_one_hot(x, num_classes = 10)
    temp = zeros(length(x), num_classes)
    for i in eachindex(x)
        temp[i, x[i]+1] = 1.0
    end
    return temp
end

function MLP(x, wh, wh1, wo, y)
    x = dense(wh, x, sigmoid)
    x = dense(wh1, x, sigmoid)
    y_hat = dense(wo, x, sigmoid)
    loss = nll_loss(y_hat, y)
    return topological_sort(loss)
end

function train_epoch(train_x, train_y; batch_size = 1, lr = 4e-3)
    epoch_loss = 0.0
    for i in ProgressBar(1:size(train_x, 3), printing_delay = 0.1)
        x = Constant(reshape(train_x[:, :, i], 28 * 28))
        y = Constant(train_y[i])

        graph = MLP(x, Wh, Wh1, Wo, y)
        epoch_loss += train_step!(graph)
        if i % batch_size == 0
            step!(graph, lr)
            zero_grad!(graph)
        end
    end
    return epoch_loss / size(train_x, 3)
end

function test_epoch(test_x, test_y)
    epoch_loss = 0.0
    for i in ProgressBar(1:size(test_x, 3), printing_delay = 0.1)
        x = Constant(reshape(test_x[:, :, i], 28 * 28))
        y = Constant(test_y[i])

        graph = MLP(x, Wh, Wh1, Wo, y)
        epoch_loss += test_step(graph)
    end
    return epoch_loss / size(test_x, 3)
end

function kaiming_normal_weights(n_input::Int, n_output::Int)
    stddev = sqrt(1 / n_input)
    weight = stddev .- rand(n_output, n_input) * 2 * stddev
    return permutedims(weight, (2, 1))
end

function create_kernel(n_input::Int64, n_output::Int64; kernel_size = 3)
    stddev = sqrt(1 / (n_input * 9))
    return stddev .- rand(kernel_size, kernel_size, n_input, n_output) * stddev * 2
end

function initialize_uniform_bias(in_features::Int64, out_features::Int64)
    k = sqrt(1 / in_features)
    return k .- 2 * rand(out_features) * k
end
