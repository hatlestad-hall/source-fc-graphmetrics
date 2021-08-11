%% About
%
% This function make use of the minimum spanning tree (MST) of a weighted, undirected connectivity matrix
% to create a node-connected adjacency matrix with a set network density.
%
% Input arguments:
%	- mst_mat		The minimum spanning tree (MST) of the connectivity matrix (<conn_mat>).
%	- conn_mat		The weighted, undirected connectivity matrix which to impose a threshold upon.
%	- density		The target network density. The function will continue to add edges to the adjacency
%					matrix until this density is achieved.
%	- order			The order in which edges are added to the adjacency matrix; 'decreasing' for
%					high-to-low weights, and 'increasing' for low-to-high.
%
% Created:		29 Apr 2020
% Last edited:	29 Apr 2020
%

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall
% ----
function adjc_mat = ch_mst_threshold_wu ( mst_mat, conn_mat, density, order )

% Set the adjacency matrix equal to the input MST matrix.
adjc_mat = mst_mat;

% Use BCT standards for setting the density threshold.
thr_mat = threshold_proportional ( conn_mat, density );
nb_edges = length ( find( triu( thr_mat, 1 ) ) ) - length ( find( triu( mst_mat, 1 ) ) );

% Create a function handle based on the input 'order' argument.
if strcmpi ( order, 'decreasing' )
	order_fun = @max;
else
	order_fun = @min;
end

% Make sure the target density is larger than the density of the MST.
mst_density = density_und ( mst_mat );
if mst_density > density, error ( 'The target density is lower than the MST density.' ); end

% Set all the edges present in the MST matrix to NaN in the adjacency matrix.
conn_mat( mst_mat > 0 ) = NaN;

% Loop until target density has been reached.
for i = 1 : nb_edges
	
	% Find the next maximum/minimum edge weight to add to the adjacency matrix.
	[ x, y ] = find ( conn_mat == order_fun( conn_mat, [ ], 'all', 'omitnan' ) );
	
	% Add the edge to the MST matrix, and remove it from the adjacency matrix.
	adjc_mat( x( 1 ), y( 1 ) )	= conn_mat( x( 1 ), y( 1 ) );
	adjc_mat( x( 2 ), y( 2 ) )	= conn_mat( x( 2 ), y( 2 ) );
	conn_mat( x( 1 ), y( 1 ) )	= NaN;
	conn_mat( x( 2 ), y( 2 ) )	= NaN;
end
end
