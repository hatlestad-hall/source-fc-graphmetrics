%% About
%
% This function creates the minimum spanning tree (MST) for a weighted, undirected connectivity network.
%
% The operation is based on the assumption that a higher connectivity value corresponds to a stronger connection.
% Thus, the output from the function is formally the maximum spanning tree of the connectivity matrix, which is
% equivalent to the minimum spanning tree of the length matrix of the connectivity matrix (again, this assumes that
% higher connectivity values correponds to shorter path lengths).
%
% The input matrix <conn_mat> is a non-sparse, weighted, symmetrical (undirected) connectivity matrix where the
% main diagonal is set to zero.
%
% Created:		29 Apr 2020
% Last edited:	29 Apr 2020
%

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall
% ----
function mst_mat = ch_mst_wu ( conn_mat )

% Convert the connectivity matrix to a length matrix.
lth_mat = weight_conversion ( conn_mat, 'lengths' );

% Compute the minimum span tree (MST) of the length matrix.
lth_mst = minspantree ( graph( lth_mat ), 'Method', 'sparse' );

% Convert the length MST to a logical matrix ("edge is present in MST").
mst_log = logical ( full( adjacency( lth_mst ) ) );

% Create the connectivity MST matrix.
mst_mat = zeros ( size( conn_mat ) );

% Populate the connectivity MST matrix with the edges from the length MST matrix.
mst_mat( mst_log ) = conn_mat( mst_log );

end