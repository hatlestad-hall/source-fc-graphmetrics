%% About
%
% This function computes graph theory metrics for undirected, weighted connectivity matrices.
%
% Input arguments:
%	- adjc_mat		The weighted, undirected adjacency matrix from which to compute graph metrics.
%	- null_itr		The number of random networks to compute in order to normalise the empirical metrics.
%
% Output:
%	- gt_emp		A struct containing the computed graph metrics for the empirical networks; details below.
%	- gt_nrm		A struct containing metrics for the empirical networks, normalised to random networks; details below.
%	- gt_rand		A struct containing the mean graph metrics from x random networks; details below.
%
% Empirical network metrics (gt_emp):
%
%

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function [ gt_emp, gt_emp_nrm, gt_rand ] = ch_gt_metrics_nrm_wu ( adjc_mat, null_itr )

%% Compute metrics for the empirical network
ch_verbose ( 'Computing graph metrics for the empirical network:', 2, 2, 5 );

% Compute the node degree values.
ch_verbose ( 'Node degree...', 0, 1, 10 );
gt_emp.node.degree		= degrees_und ( adjc_mat );
gt_emp.network.degree	= mean ( gt_emp.node.degree );

% Compute the node strength values.
ch_verbose ( 'Node strength...', 0, 1, 10 );
gt_emp.node.strength	= strengths_und ( adjc_mat );
gt_emp.network.strength = mean ( gt_emp.node.strength );

% Compute the network density.
ch_verbose ( 'Network density...', 0, 1, 10 );
gt_emp.network.density = density_und ( adjc_mat );

% Compute the node-wise clustering coefficient. First, normalise the connectivity weights.
ch_verbose ( 'Node clustering coefficients...', 0, 1, 10 );
adjc_mat_nrm							= weight_conversion ( adjc_mat, 'normalize' );
gt_emp.node.clustering_coeff			= clustering_coef_wu ( adjc_mat_nrm );
gt_emp.network.clustering_coeff			= mean ( gt_emp.node.clustering_coeff );

% Compute the network transitivity. Use the normalised connectivity matrix.
ch_verbose ( 'Network transitivity...', 0, 1, 10 );
gt_emp.network.transitivity = transitivity_wu ( adjc_mat_nrm );

% Find the number of connected components. First, binarize the connectivity matrix.
ch_verbose ( 'Connected components...', 0, 1, 10 );
adjc_mat_bin				= weight_conversion ( adjc_mat, 'binarize' );
gt_emp.node.components		= get_components ( adjc_mat_bin );
gt_emp.network.components	= length ( unique( gt_emp.node.components ) );

% Compute the community structure using the Louvain method (modularity maximisation; non-overlapping modules).
ch_verbose ( 'Louvain community structure and modularity...', 0, 1, 10 );
[ gt_emp.node.community_affiliation, gt_emp.network.modularity ]	= community_louvain ( adjc_mat );
gt_emp.network.communities											= length ( unique( gt_emp.node.community_affiliation ) );

% Compute module degree z-score, using the community affiliation values computed previously.
ch_verbose ( 'Module degree z-score (from Louvain community affiliation)...', 0, 1, 10 );
gt_emp.node.module_degree_z = module_degree_zscore ( adjc_mat, gt_emp.node.community_affiliation, 0 );

% Compute assortativity.
ch_verbose ( 'Network assortativity...', 0, 1, 10 );
gt_emp.network.assortativity = assortativity_wei ( adjc_mat, 0 );

% Compute the rich-club coefficient.
ch_verbose ( 'Rich-club coefficient...', 0, 1, 10 );
gt_emp.node.rich_club = rich_club_wu ( adjc_mat );

% Compute the characteristic path length. First, generate a distance matrix from the inverted connectivity matrix.
ch_verbose ( 'Characteristic path length, global efficiency, eccentricity, radius and diameter...', 0, 1, 10 );
adjc_mat_lth = weight_conversion ( adjc_mat, 'lengths' );
adjc_mat_dst = distance_wei ( adjc_mat_lth );
[ gt_emp.network.lambda, gt_emp.network.global_efficiency, gt_emp.node.eccentricity, gt_emp.network.radius, gt_emp.network.diameter ] = ...
	charpath ( adjc_mat_dst, 0, 0 );

% Compute local efficiency.
ch_verbose ( 'Local efficiency...', 0, 1, 10 );
gt_emp.node.local_efficiency = efficiency_wei ( adjc_mat, 2 );

% Compute betweenness centrality, using the inverted connectivity matrix.
ch_verbose ( 'Betweenness centrality...', 0, 1, 10 );
[ gt_emp.node.edge_betweenness_centrality, gt_emp.node.betweenness_centrality ] = edge_betweenness_wei ( adjc_mat_lth );

% Compute the eigenvector centrality.
ch_verbose ( 'Eigenvector centrality...', 0, 1, 10 );
gt_emp.node.eigenvector_centrality = eigenvector_centrality_und ( adjc_mat );

%% Compute metrics for n random networks
ch_verbose ( sprintf( 'Computing graph metrics for %i random (connected) networks:', null_itr ), 5, 2, 5 );

% Create the structures in which to store the random networks metrics.
gt_rand.node = struct ( ...
	'degree',						cell( 1, null_itr ), ...
	'strength',						cell( 1, null_itr ), ...
	'clustering_coeff',				cell( 1, null_itr ), ...
	'components',					cell( 1, null_itr ), ...
	'community_affiliation',		cell( 1, null_itr ), ...
	'module_degree_z',				cell( 1, null_itr ), ...
	'rich_club',					cell( 1, null_itr ), ...
	'eccentricity',					cell( 1, null_itr ), ...
	'local_efficiency',				cell( 1, null_itr ), ...
	'edge_betweenness_centrality',	cell( 1, null_itr ), ...
	'betweenness_centrality',		cell( 1, null_itr ), ...
	'eigenvector_centrality',		cell( 1, null_itr ) );

gt_rand.network = struct ( ...
	'degree',						cell( 1, null_itr ), ...
	'strength',						cell( 1, null_itr ), ...
	'density',						cell( 1, null_itr ), ...
	'clustering_coeff',				cell( 1, null_itr ), ...
	'transitivity',					cell( 1, null_itr ), ...
	'components',					cell( 1, null_itr ), ...
	'communities',					cell( 1, null_itr ), ...
	'modularity',					cell( 1, null_itr ), ...
	'assortativity',				cell( 1, null_itr ), ...
	'lambda',						cell( 1, null_itr ), ...
	'global_efficiency',			cell( 1, null_itr ), ...
	'radius',						cell( 1, null_itr ), ...
	'diameter',						cell( 1, null_itr ) );

% Run for the specified number of iterations.
for r = 1 : null_itr
	ch_verbose ( sprintf( '%i ...', r ), 0, 0, 10 );
	
	% Generate a connected randomised network from iterative re-wiring where degree, weight and strength distributions are preserved.
	[ rand_mat, rewires ] = randmio_und_connected ( adjc_mat, size( adjc_mat, 1 ) * 100 );
	ch_verbose ( sprintf( 'Network was re-wired %i times.', rewires ), 0, 2, 4 - length( num2str( r ) ) );
	
	% Compute the random network metrics.
	gt_rand.node( r ).degree = degrees_und ( rand_mat );
	gt_rand.network( r ).degree = mean ( gt_rand.node( r ).degree );
	gt_rand.node( r ).strength = strengths_und ( rand_mat );
	gt_rand.network( r ).strength = mean ( gt_rand.node( r ).strength );
	gt_rand.network( r ).density = density_und ( rand_mat );
	rand_mat_nrm = weight_conversion ( rand_mat, 'normalize' );
	gt_rand.node( r ).clustering_coeff = clustering_coef_wu ( rand_mat_nrm );
	gt_rand.network( r ).clustering_coeff = mean ( gt_rand.node( r ).clustering_coeff );
	gt_rand.network( r ).transitivity = transitivity_wu ( rand_mat_nrm );
	rand_mat_bin = weight_conversion ( rand_mat, 'binarize' );
	gt_rand.node( r ).components = get_components ( rand_mat_bin );
	gt_rand.network( r ).components = length ( unique( gt_rand.node( r ).components ) );
	[ gt_rand.node( r ).community_affiliation, gt_rand.network( r ).modularity ] = community_louvain ( rand_mat );
	gt_rand.network( r ).communities = length ( unique( gt_rand.node( r ).community_affiliation ) );
	gt_rand.node( r ).module_degree_z = module_degree_zscore ( rand_mat, gt_rand.node( r ).community_affiliation, 0 );
	gt_rand.network( r ).assortativity = assortativity_wei ( rand_mat, 0 );
	gt_rand.node( r ).rich_club = rich_club_wu ( rand_mat );
	rand_mat_lth = weight_conversion ( rand_mat, 'lengths' );
	rand_mat_dst = distance_wei ( rand_mat_lth );
	[ gt_rand.network( r ).lambda, gt_rand.network( r ).global_efficiency, gt_rand.node( r ).eccentricity, gt_rand.network( r ).radius, ...
		gt_rand.network( r ).diameter ] = charpath ( rand_mat_dst, 0, 0 );
	gt_rand.node( r ).local_efficiency = efficiency_wei ( rand_mat, 2 );
	[ gt_rand.node( r ).edge_betweenness_centrality, gt_rand.node( r ).betweenness_centrality ] = edge_betweenness_wei ( rand_mat_lth );
	gt_rand.node( r ).eigenvector_centrality = eigenvector_centrality_und ( rand_mat );
end

%% Compute normalised metrics for the empirical network
ch_verbose ( 'Computing normalised graph metrics for the empirical network:', 5, 2, 5 );

% Compute normalised network-wide metrics.
gt_emp_nrm.network.degree				= gt_emp.network.degree				/ abs ( mean( [ gt_rand.network.degree ] ) );
gt_emp_nrm.network.strength				= gt_emp.network.strength			/ abs ( mean( [ gt_rand.network.strength ] ) );
gt_emp_nrm.network.density				= gt_emp.network.density			/ abs ( mean( [ gt_rand.network.density ] ) );
gt_emp_nrm.network.clustering_coeff		= gt_emp.network.clustering_coeff	/ abs ( mean( [ gt_rand.network.clustering_coeff ] ) );
gt_emp_nrm.network.transitivity			= gt_emp.network.transitivity		/ abs ( mean( [ gt_rand.network.transitivity ] ) );
gt_emp_nrm.network.components			= gt_emp.network.components			/ abs ( mean( [ gt_rand.network.components ] ) );
gt_emp_nrm.network.communities			= gt_emp.network.communities		/ abs ( mean( [ gt_rand.network.communities ] ) );
gt_emp_nrm.network.modularity			= gt_emp.network.modularity			/ abs ( mean( [ gt_rand.network.modularity ] ) );
gt_emp_nrm.network.assortativity		= gt_emp.network.assortativity		/ abs ( mean( [ gt_rand.network.assortativity ] ) );
gt_emp_nrm.network.lambda				= gt_emp.network.lambda				/ abs ( mean( [ gt_rand.network.lambda ] ) );
gt_emp_nrm.network.global_efficiency	= gt_emp.network.global_efficiency	/ abs ( mean( [ gt_rand.network.global_efficiency ] ) );
gt_emp_nrm.network.radius				= gt_emp.network.radius				/ abs ( mean( [ gt_rand.network.radius ] ) );
gt_emp_nrm.network.diameter				= gt_emp.network.diameter			/ abs ( mean( [ gt_rand.network.diameter ] ) );

% Compute the Humphries and Gurney small-worldness index.
% Rationale: A small-world network is characterised by a higher-than-random clustering coefficient, and a similar-to-random
%			 characteristic path length. Hence, the small-worldness is given by the ratio between the clustering coefficient
%			 and the characteristic path length.
ch_verbose ( 'Small-worldness...', 0, 1, 10 );
rand_lambda								= mean ( [ gt_rand.network.lambda ] );
rand_clustc								= mean ( [ gt_rand.network.clustering_coeff ] );
gt_emp_nrm.composite.small_worldness	= ( gt_emp.network.clustering_coeff / rand_clustc ) / ( gt_emp.network.lambda / rand_lambda );

% Write completion statement.
ch_verbose ( 'Done.', 3, 1, 0 );
end