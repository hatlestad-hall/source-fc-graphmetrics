% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function [ lambda, node_lambda ] = ch_harmm_lambda ( D )

n = size(D,1);
if any(any(isnan(D)))
    error('The distance matrix must not contain NaN values');
end

D(1:n+1:end) = NaN;             % set diagonal distance to NaN

% Use harmonic mean to compute characteristic path length for the network.
lambda = harmmean ( D, 'all', 'omitnan' );

% Use harmonic mean to compute average shortest path for each node.
node_lambda = harmmean ( D, 2, 'omitnan' );

end