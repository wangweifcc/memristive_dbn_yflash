function [Y] = one_hot(X, n_classes)
    Y = zeros(size(X, 1), n_classes);
    
    % one hot encoding produced is zero-based
    for i = 1:size(X, 1)
        Y(i, X(i)+1) = 1;
    end
end

