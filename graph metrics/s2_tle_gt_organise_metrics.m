%% About
%
%
%
%
% Configuration fields:
%	cfg.graph					Graph type to organise. 'binary' or 'weighted'.
%	cfg.files					Input files; one file per subject.
%	cfg.hub_node_cutoff			In the definition of hub nodes, sets the cutoff of how many nodes constitute hubs in each metric.
%								From van den Heuvel (2010): Top/bottom 20 % of nodes.
%	cfg.output_dir				Output directory.
%
%
% Output:
%	out_files					Path to the saved output file.
%
% ----
%
% About "hubness":
%
% "Hubness" - to what degree a node constitutes a hub - may be delineated by the following node metrics:
%
%	- High degree.
%	- High centrality (betweenness centrality?).
%	- Short average distance (to other nodes; path length).
%	- Low clustering coefficient.
%
%
% van den Heuvel et al. (2010) ranked node "hubness" by allocating a "hub point" to the nodes which rank within the top 20% in each
% category. Each node will thus receive a "hub score" of 0-4 points.
%

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function out_file = s2_tle_gt_organise_metrics( cfg )
%% Specify parameters
if nargin < 1
	
	cfg.graph			= 'weighted';
	cfg.files			= ch_selectfiles( 'mat', 'on' );
	cfg.hub_node_cutoff	= 0.2;
	cfg.output_dir		= [ uigetdir( sprintf( '%s/../', cfg.files( 1 ).folder ), 'Select output directory' ) '/' ];
	if numel ( cfg.output_dir ) < 3, return; end
	
end
%% Load all files into a cell structure

% Define the cell structure into which the files are loaded.
all_files = cell( numel( cfg.files ), 1 );

% Loop the files: Load into cells; get the subject names.
subjects = cell( numel( cfg.files ), 1 );
for f = 1 : numel( cfg.files )
	all_files{ f } = load( sprintf( '%s/%s', cfg.files( f ).folder, cfg.files( f ).name ), 'subject', 'freq_band', 'density_threshold', 'atlas', ...
		sprintf( 'gt_%s', cfg.graph ) );
	subjects{ f } = all_files{ f }.subject;
end

% Get the frequency band and density threshold.
output.freq_band			= all_files{ 1 }.freq_band;
output.density_threshold	= all_files{ 1 }.density_threshold;

% Add the node atlas to the output structure.
output.atlas = all_files{ 1 }.atlas;

%% Organise global metrics (network-wide)

% Define the global metrics tables (empirical and normalised-against-random).
var_names = { 'degree', 'strength', 'density', 'clust_coeff', 'transitivity', 'components', 'modularity', 'communities', ...
	'assortativity', 'lambda', 'lambda_harmonic', 'global_efficiency', 'radius', 'diameter', 'small_world' };
var_types = repmat( { 'double' }, [ 1, numel( var_names ) ] );
global_metrics_emp = table( 'Size', [ numel( cfg.files ), numel( var_names ) ], 'VariableTypes', var_types, 'VariableNames', var_names, ...
	'RowNames', subjects );
global_metrics_nrm = table( 'Size', [ numel( cfg.files ), numel( var_names ) ], 'VariableTypes', var_types, 'VariableNames', var_names, ...
	'RowNames', subjects );

% Loop all the subjects.
for s = 1 : numel( cfg.files )
	
	% Copy the empirical metrics structure (to avoid eval calls).
	metrics = eval( sprintf( 'all_files{ s }.gt_%s.empirical.network', cfg.graph ) );
	
	% Add the subject's empirical global metrics to the table.
	global_metrics_emp{ s, 'degree' }				= metrics.degree;
	global_metrics_emp{ s, 'strength' }				= metrics.strength;
	global_metrics_emp{ s, 'density' }				= metrics.density;
	global_metrics_emp{ s, 'clust_coeff' }			= metrics.clustering_coeff;
	global_metrics_emp{ s, 'transitivity' }			= metrics.transitivity;
	global_metrics_emp{ s, 'components' }			= metrics.components;
	global_metrics_emp{ s, 'modularity' }			= metrics.modularity;
	global_metrics_emp{ s, 'communities' }			= metrics.communities;
	global_metrics_emp{ s, 'assortativity' }		= metrics.assortativity;
	global_metrics_emp{ s, 'lambda' }				= metrics.lambda;
	global_metrics_emp{ s, 'lambda_harmonic' }		= metrics.lambda_harmm;
	global_metrics_emp{ s, 'global_efficiency' }	= metrics.global_efficiency;
	global_metrics_emp{ s, 'radius' }				= metrics.radius;
	global_metrics_emp{ s, 'diameter' }				= metrics.diameter;
	
	% Copy the normalised metrics structure (to avoid eval calls).
	metrics = eval( sprintf( 'all_files{ s }.gt_%s.normalised', cfg.graph ) );
	
	% Add the subject's normalised global metrics to the table.
	global_metrics_nrm{ s, 'degree' }				= metrics.degree;
	global_metrics_nrm{ s, 'strength' }				= metrics.strength;
	global_metrics_nrm{ s, 'density' }				= metrics.density;
	global_metrics_nrm{ s, 'clust_coeff' }			= metrics.clustering_coeff;
	global_metrics_nrm{ s, 'transitivity' }			= metrics.transitivity;
	global_metrics_nrm{ s, 'components' }			= metrics.components;
	global_metrics_nrm{ s, 'modularity' }			= metrics.modularity;
	global_metrics_nrm{ s, 'communities' }			= metrics.communities;
	global_metrics_nrm{ s, 'assortativity' }		= metrics.assortativity;
	global_metrics_nrm{ s, 'lambda' }				= metrics.lambda;
	global_metrics_nrm{ s, 'lambda_harmonic' }		= metrics.lambda_harmm;
	global_metrics_nrm{ s, 'global_efficiency' }	= metrics.global_efficiency;
	global_metrics_nrm{ s, 'radius' }				= metrics.radius;
	global_metrics_nrm{ s, 'diameter' }				= metrics.diameter;
	global_metrics_nrm{ s, 'small_world' }			= metrics.small_world;
	
	% Add the small-world metric to the empirical metrics table.
	global_metrics_emp{ s, 'small_world' }			= metrics.small_world;
	
end

%% Organise local metrics (node-specific)

% Define the local metrics struct.
local_metrics = struct( ...
	'degree',					cell( numel( subjects ), 1 ), ...
	'strength',					cell( numel( subjects ), 1 ), ...
	'clust_coeff',				cell( numel( subjects ), 1 ), ...
	'components',				cell( numel( subjects ), 1 ), ...
	'community_affl',			cell( numel( subjects ), 1 ), ...
	'module_degree_z',			cell( numel( subjects ), 1 ), ...
	'eccentricity',				cell( numel( subjects ), 1 ), ...
	'lambda',					cell( numel( subjects ), 1 ), ...
	'lambda_harmonic',			cell( numel( subjects ), 1 ), ...
	'local_efficiency',			cell( numel( subjects ), 1 ), ...
	'betweenness_centrality',	cell( numel( subjects ), 1 ), ...
	'eigenvector_centrality',	cell( numel( subjects ), 1 ) );

% Define the normalised local metrics struct.
local_metrics_nrm = struct( ...
	'degree',					cell( numel( subjects ), 1 ), ...
	'strength',					cell( numel( subjects ), 1 ), ...
	'clust_coeff',				cell( numel( subjects ), 1 ), ...
	'components',				cell( numel( subjects ), 1 ), ...
	'community_affl',			cell( numel( subjects ), 1 ), ...
	'module_degree_z',			cell( numel( subjects ), 1 ), ...
	'eccentricity',				cell( numel( subjects ), 1 ), ...
	'lambda',					cell( numel( subjects ), 1 ), ...
	'lambda_harmonic',			cell( numel( subjects ), 1 ), ...
	'local_efficiency',			cell( numel( subjects ), 1 ), ...
	'betweenness_centrality',	cell( numel( subjects ), 1 ), ...
	'eigenvector_centrality',	cell( numel( subjects ), 1 ) );

% Loop all the subjects.
for s = 1 : numel( cfg.files )
	
	% Empirical:
	% Copy the metrics structure (to avoid eval calls).
	metrics = eval( sprintf( 'all_files{ s }.gt_%s.empirical.node', cfg.graph ) );
	
	% Add the subject's global metrics to the table.
	local_metrics( s ).degree					= metrics.degree;
	local_metrics( s ).strength					= metrics.strength;
	local_metrics( s ).clust_coeff				= metrics.clustering_coeff;
	local_metrics( s ).components				= metrics.components;
	local_metrics( s ).community_affl			= metrics.community_affiliation;
	local_metrics( s ).module_degree_z			= metrics.module_degree_z;
	local_metrics( s ).eccentricity				= metrics.eccentricity;
	local_metrics( s ).lambda					= metrics.lambda;
	local_metrics( s ).lambda_harmonic			= metrics.lambda_harmm;
	local_metrics( s ).local_efficiency			= metrics.local_efficiency;
	local_metrics( s ).betweenness_centrality	= metrics.betweenness_centrality;
	local_metrics( s ).eigenvector_centrality	= metrics.eigenvector_centrality;
	
	% Normalised:
	% Copy the metrics structure (to avoid eval calls).
	metrics = eval( sprintf( 'all_files{ s }.gt_%s.normalised_local', cfg.graph ) );
	
	% Add the subject's global metrics to the table.
	local_metrics_nrm( s ).degree					= metrics.degree;
	local_metrics_nrm( s ).strength					= metrics.strength;
	local_metrics_nrm( s ).clust_coeff				= metrics.clustering_coeff;
	local_metrics_nrm( s ).module_degree_z			= metrics.module_degree_z;
	local_metrics_nrm( s ).eccentricity				= metrics.eccentricity;
	local_metrics_nrm( s ).lambda					= metrics.lambda;
	local_metrics_nrm( s ).lambda_harmonic			= metrics.lambda_harmm;
	local_metrics_nrm( s ).local_efficiency			= metrics.local_efficiency;
	local_metrics_nrm( s ).betweenness_centrality	= metrics.betweenness_centrality;
	local_metrics_nrm( s ).eigenvector_centrality	= metrics.eigenvector_centrality;
	
end

%% Local metric - compute "hubness"

% Get the cut-off number of nodes.
cfg.hub_node_cutoff = round( length( local_metrics( 1 ).degree ) * cfg.hub_node_cutoff );

% Generate matrix for "hub scores"; < nodes x subjects >
hub_scores = zeros( length( local_metrics( 1 ).degree ), length( local_metrics ) );

% Evaluate DEGREE criterion.
degree_data				= [ local_metrics( : ).degree ];
[ ~, degree_scorer ]	= maxk( degree_data, cfg.hub_node_cutoff );
degree_scores			= zeros( size( degree_data ) );
for c = 1 : size( degree_scorer, 2 )
	degree_scores( degree_scorer( :, c ), c ) = 1;
end
hub_scores = hub_scores + degree_scores;

% Evaluate BETWEENNESS CENTRALITY criterion.
betcen_data				= [ local_metrics( : ).betweenness_centrality ];
[ ~, betcen_scorer ]	= maxk( betcen_data, cfg.hub_node_cutoff );
betcen_scores			= zeros( size( betcen_data ) );
for c = 1 : size( betcen_scorer, 2 )
	betcen_scores( betcen_scorer( :, c ), c ) = 1;
end
hub_scores = hub_scores + betcen_scores;

% Evaluate SHORTEST AVERAGE DISTANCE criterion.
avgdst_data				= [ local_metrics( : ).lambda ];
[ ~, avgdst_scorer ]	= mink( avgdst_data, cfg.hub_node_cutoff );
avgdst_scores			= zeros( size( avgdst_data ) );
for c = 1 : size( avgdst_scorer, 2 )
	avgdst_scores( avgdst_scorer( :, c ), c ) = 1;
end
hub_scores = hub_scores + avgdst_scores;

% Evaluate CLUSTERING COEFFICIENT criterion.
clstcoef_data			= [ local_metrics( : ).clust_coeff ];
[ ~, clstcoef_scorer ]	= mink( clstcoef_data, cfg.hub_node_cutoff );
clstcoef_scores			= zeros( size( clstcoef_data ) );
for c = 1 : size( clstcoef_scorer, 2 )
	clstcoef_scores( clstcoef_scorer( :, c ), c ) = 1;
end
hub_scores = hub_scores + clstcoef_scores;

% Add hubness metric to summary structure.
for i = 1 : length( local_metrics )
	local_metrics( i ).hubness = hub_scores( :, i );
end

%% Save the output

% Organise the output structure.
output.subjects				= subjects;
output.global_metrics_emp	= global_metrics_emp;
output.global_metrics_nrm	= global_metrics_nrm;
output.local_metrics		= local_metrics;
output.local_metrics_nrm	= local_metrics_nrm;

% Save the output structure.
save( sprintf( '%sgt_metrics_%s.mat', cfg.output_dir, cfg.graph ), '-struct', 'output' );

% Create the output structure.
out_file = sprintf( '%sgt_metrics_%s.mat', cfg.output_dir, cfg.graph );

end
