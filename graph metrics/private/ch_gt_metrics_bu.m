%% About
%
% This function computes graph theory metrics for undirected, binary connectivity matrices.
%
% Input arguments:
%	- adjc_mat		The binary, undirected adjacency matrix from which to compute graph metrics.
%
% Output:
%	- gt_node		Struct containing node-wise graph metrics.
%	- gt_network	Struct containing network-wide graph metrics.
%
%

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function [ gt_node, gt_network ] = ch_gt_metrics_bu ( adjc_mat )

%% Compute metrics for the empirical network
ch_verbose ( 'Computing graph metrics for binary, undirected network:', 2, 2, 5 );

% Compute the node degree values.
ch_verbose ( 'Node degree...', 0, 1, 10 );
gt_node.degree		= degrees_und ( adjc_mat )';
gt_network.degree	= mean ( gt_node.degree );

% Compute the node strength values.
ch_verbose ( 'Node strength...', 0, 1, 10 );
gt_node.strength	= strengths_und ( adjc_mat )';
gt_network.strength = mean ( gt_node.strength );

% Compute the network density.
ch_verbose ( 'Network density...', 0, 1, 10 );
gt_network.density = density_und ( adjc_mat );

% Compute the node-wise clustering coefficient.
ch_verbose ( 'Node clustering coefficients...', 0, 1, 10 );
gt_node.clustering_coeff	= clustering_coef_bu ( adjc_mat );
gt_network.clustering_coeff	= mean ( gt_node.clustering_coeff );

% Compute the network transitivity. Use the normalised connectivity matrix.
ch_verbose ( 'Network transitivity...', 0, 1, 10 );
gt_network.transitivity = transitivity_bu ( adjc_mat );

% Find the number of connected components.
ch_verbose ( 'Connected components...', 0, 1, 10 );
gt_node.components		= get_components ( adjc_mat )';
gt_network.components	= length ( unique( gt_node.components ) );

% Compute the community structure using the Louvain method (modularity maximisation; non-overlapping modules).
ch_verbose ( 'Louvain community structure and modularity...', 0, 1, 10 );
[ gt_node.community_affiliation, gt_network.modularity ]	= community_louvain ( adjc_mat, 1 );
gt_network.communities										= length ( unique( gt_node.community_affiliation ) );

% Compute module degree z-score, using the community affiliation values computed previously.
ch_verbose ( 'Module degree z-score (from Louvain community affiliation)...', 0, 1, 10 );
gt_node.module_degree_z = module_degree_zscore ( adjc_mat, gt_node.community_affiliation, 0 );

% Compute assortativity.
ch_verbose ( 'Network assortativity...', 0, 1, 10 );
gt_network.assortativity = assortativity_bin ( adjc_mat, 0 );

% Compute the rich-club coefficient.
ch_verbose ( 'Rich-club coefficient...', 0, 1, 10 );
gt_node.rich_club = rich_club_bu ( adjc_mat );

% Compute the characteristic path length. First, generate a distance matrix from the connectivity matrix.
ch_verbose ( 'Characteristic path length, global efficiency, eccentricity, radius and diameter...', 0, 1, 10 );
adjc_mat_dst = distance_bin ( adjc_mat );
[ gt_network.lambda, gt_network.global_efficiency, gt_node.eccentricity, gt_network.radius, gt_network.diameter ] = ...
	charpath ( adjc_mat_dst, 0, 0 );
[ gt_network.lambda_harmm, gt_node.lambda_harmm ] = ch_harmm_lambda ( adjc_mat_dst );
[ gt_node.lambda, ~ ] = ch_node_lambda ( adjc_mat_dst );

% Compute local efficiency.
ch_verbose ( 'Local efficiency...', 0, 1, 10 );
gt_node.local_efficiency = efficiency_bin ( adjc_mat, 1 );

% Compute betweenness centrality.
ch_verbose ( 'Betweenness centrality...', 0, 1, 10 );
[ gt_node.edge_betweenness_centrality, gt_node.betweenness_centrality ] = edge_betweenness_bin ( adjc_mat );

% Compute the eigenvector centrality.
ch_verbose ( 'Eigenvector centrality...', 0, 1, 10 );
gt_node.eigenvector_centrality = eigenvector_centrality_und ( adjc_mat );

end