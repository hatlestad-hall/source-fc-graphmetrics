%% About
%
%
%
%
% Configuration fields:
%	cfg.subjects				Subjects to run. [ ] = all; else, specify numbers in an array.
%	cfg.recompute				Recompute already computed subjects. true or false.
%	cfg.graph_type				Graph type. 'binary', 'weighted', or 'both'.
%	cfg.method_threshold		'mst_density':	Computes first the MST, then adds edges incrementally until density level is reached.
%								'density':		The n % strongest edges are kept.
%								'none':			No threshold is applied.
%	cfg.density_threshold		Density threshold(s). If more than one threshold is specified, the function will compute metrics for all threshold
%								settings separately. The results are saved in separate folders in the output directory.
%	cfg.random_networks			Number of random networks to generate for normalisation.
%	cfg.file					Input file. Multi-subject connectivity matrix: < node x node x subject >
%	cfg.output_dir				Output directory.
%
%
% Output:
%	out_files					Cell array of 'dir' structs; each column is one threshold level.
%
%

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function out_files = s1_tle_gt_metrics( cfg )
%% Set up configuration
if nargin < 1
	
	cfg.subjects			= [ ];
	cfg.recompute			= false;
	cfg.graph_type			= 'weighted';
	cfg.method_threshold	= 'mst_density';
	cfg.density_threshold	= 0.40 : 0.05 : 0.65;
	cfg.random_networks		= 100;
	cfg.file				= ch_selectfiles( 'mat', 'off' );
	cfg.output_dir			= [ uigetdir( sprintf( '%s/../', cfg.file.folder ), 'Select output directory' ) '/' ];
	if numel ( cfg.output_dir ) < 3, return; end
	
end
%% Compute graph metrics for specified subjects across specified density thresholds

% If threshold-imposing is disabled, set threshold level parameter to 1.
if ~endsWith( cfg.method_threshold, 'density' )
	cfg.density_threshold = 1;
end

% Define the cell structure where output files paths are stored.
out_files = cell( 1, length( cfg.density_threshold ) );

% Load the frequency band connectivity matrix (<node x node x subject>) from file.
ch_verbose( sprintf( 'Loading file: %s', cfg.file.name ), 1, 1 );
band = load( sprintf( '%s/%s', cfg.file.folder, cfg.file.name ) );

% Extract the subjects to run.
if ~isempty( cfg.subjects )
	band.conn_matrix	= band.conn_matrix( :, :, cfg.subjects );
	band.avg_conn		= band.avg_conn( cfg.subjects );
	band.subjects		= band.subjects( cfg.subjects );
end

% Loop #1: Subjects.
for subj = 1 : size ( band.conn_matrix, 3 )
	ch_verbose( sprintf( 'Current subject: %s', band.subjects{ subj } ), 1, 1, 2 );
	
	% Extract the subject connectivity matrix; remove main diagonal connectivity weights.
	conn_mat = weight_conversion( band.conn_matrix( :, :, subj ), 'autofix' );
	
	% Generate the specified number of random networks; for normalisation of the empirical network metrics.
	ch_verbose( sprintf( 'Generating %i random networks:', cfg.random_networks ), 1, 2, 5 );
	rand_conn_mat = cell( 1, cfg.random_networks );
	for r = 1 : cfg.random_networks
		%ch_verbose( sprintf( '%i ...', r ), 0, 0, 10 );
		
		% Generate a randomised network from iterative re-wiring where degree, weight and strength distributions are preserved.
		[ rand_conn_mat{ r }, io_corr ] = null_model_und_sign( conn_mat, 100000, 1 );
		%ch_verbose( sprintf( 'I/O strength correlation: %.3f', io_corr( 1 ) ), 0, 2, 4 - length( num2str( r ) ) );
	end
	
	% Loop #2: Density threshold levels.
	for thresh = 1 : numel( cfg.density_threshold )
		ch_verbose( sprintf( 'Computing graph metrics for networks with an imposed density threshold of %.2f:', ...
			cfg.density_threshold( thresh ) ), 2, 2, 0 );
		
		% Set the density threshold parameter and output directories.
		density_threshold	= cfg.density_threshold( thresh );
		output_thresh		= sprintf( '%s%s_%d/subjects/', cfg.output_dir, cfg.method_threshold, round( density_threshold * 100 ) );
		if ~exist( output_thresh, 'dir' ), mkdir( output_thresh ); end
		
		% Check if the subject graph metrics file already exists in the output folder.
		if exist( sprintf( '%s%s_gt_metrics.mat', output_thresh, band.subjects{ subj } ), 'file' )
			switch cfg.recompute
				case true,	compute = true;
					ch_verbose( 'Previously computed file found. Recomputing the file/threshold...', 2, 2, 0 );
				case false, compute = false;
					ch_verbose( 'Previously computed file found. Skipping to the next file/threshold...', 2, 2, 0 );
			end
		else
			compute = true;
		end
		if compute == true
			
			% Create the subject summary struct.
			gt_subj						= [ ];
			gt_subj.subject				= band.subjects{ subj };
			[ ~, gt_subj.freq_band ]	= fileparts( cfg.file.name );
			gt_subj.density_threshold	= density_threshold;
			gt_subj.conn_mat			= conn_mat;
			gt_subj.atlas				= band.atlas;
			
			% Impose a density threshold on the matrix; method-dependent procedure.
			switch cfg.method_threshold
				case 'mst_density'
					
					% Compute the minimum spanning tree; save the MST matrix.
					mst_mat = ch_mst_wu( conn_mat );
					gt_subj.mst_mat = mst_mat;
					
					% Add weights to the MST to get an adjacency matrix with density d; save the adjacency matrix.
					adjc_mat = ch_mst_threshold_wu( mst_mat, conn_mat, density_threshold, 'decreasing' );
					
				case 'density'
					
					% Impose the density threshold on the connectivity matrix; returns the adjacency matrix.
					adjc_mat = threshold_proportional( conn_mat, density_threshold );
					
				otherwise
					
					% Do not apply threshold.
					adjc_mat = conn_mat;
					
			end
			
			% Store the adjacency matrix.
			gt_subj.adjc_mat = adjc_mat;
			
			if strcmpi( cfg.graph_type, 'weighted' ) || strcmpi( cfg.graph_type, 'both' )
				
				% Compute graph metrics for the weighted empirical network.
				ch_verbose( 'Computing weighted graph metrics for the empirical network...', 1, 1, 4 );
				[ gt_subj.gt_weighted.empirical.node, gt_subj.gt_weighted.empirical.network ] = ch_gt_metrics_wu( adjc_mat );
				
				% Compute graph metrics for the weighted random networks.
				ch_verbose ( 'Computing weighted graph metrics for the random networks...', 2, 1, 4 );
				for r = 1 : cfg.random_networks
					
					% Impose a density threshold on the random network matrix; method-dependent procedure.
					switch cfg.method_threshold
						case 'mst_density'
							
							% Compute the MST for the random connectivity matrix.
							rand_mst_mat = ch_mst_wu( rand_conn_mat{ r } );
							
							% Add weights to the random network MST to get an adjacency matrix with density d.
							rand_adjc_mat = ch_mst_threshold_wu( rand_mst_mat, rand_conn_mat{ r }, density_threshold, 'decreasing' );	%#ok<NASGU>
							
						case 'density'
							
							% Impose the density threshold on the connectivity matrix; returns the adjacency matrix.
							rand_adjc_mat = threshold_proportional( rand_conn_mat{ r }, density_threshold );							%#ok<NASGU>
							
						otherwise
							
							% Do not apply threshold.
							rand_adjc_mat = rand_conn_mat{ r };																			%#ok<NASGU>
							
					end
							
					% Compute graph metrics for the weighted random network.
					[ ~, gt_subj.gt_weighted.random.node( r ), gt_subj.gt_weighted.random.network( r ) ] = ...
						evalc( 'ch_gt_metrics_wu ( rand_adjc_mat );' );
				end
				
				% Normalise the weighted network-wide graph metrics for the empirical network.
				ch_verbose( 'Computing normalised weighted graph metrics for the empirical network...', 1, 1, 4 );
				
				gt_subj.gt_weighted.normalised.degree				= gt_subj.gt_weighted.empirical.network.degree				...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.degree ] ) );
				gt_subj.gt_weighted.normalised.strength				= gt_subj.gt_weighted.empirical.network.strength			...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.strength ] ) );
				gt_subj.gt_weighted.normalised.density				= gt_subj.gt_weighted.empirical.network.density				...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.density ] ) );
				gt_subj.gt_weighted.normalised.clustering_coeff		= gt_subj.gt_weighted.empirical.network.clustering_coeff	...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.clustering_coeff ] ) );
				gt_subj.gt_weighted.normalised.transitivity			= gt_subj.gt_weighted.empirical.network.transitivity		...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.transitivity ] ) );
				gt_subj.gt_weighted.normalised.components			= gt_subj.gt_weighted.empirical.network.components			...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.components ] ) );
				gt_subj.gt_weighted.normalised.communities			= gt_subj.gt_weighted.empirical.network.communities			...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.communities ] ) );
				gt_subj.gt_weighted.normalised.modularity			= gt_subj.gt_weighted.empirical.network.modularity			...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.modularity ] ) );
				gt_subj.gt_weighted.normalised.assortativity		= gt_subj.gt_weighted.empirical.network.assortativity		...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.assortativity ] ) );
				gt_subj.gt_weighted.normalised.lambda				= gt_subj.gt_weighted.empirical.network.lambda				...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.lambda ] ) );
				gt_subj.gt_weighted.normalised.lambda_harmm			= gt_subj.gt_weighted.empirical.network.lambda_harmm		...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.lambda_harmm ] ) );
				gt_subj.gt_weighted.normalised.global_efficiency	= gt_subj.gt_weighted.empirical.network.global_efficiency	...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.global_efficiency ] ) );
				gt_subj.gt_weighted.normalised.radius				= gt_subj.gt_weighted.empirical.network.radius				...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.radius ] ) );
				gt_subj.gt_weighted.normalised.diameter				= gt_subj.gt_weighted.empirical.network.diameter			...
					/ abs( mean( [ gt_subj.gt_weighted.random.network.diameter ] ) );
				
				% Compute the Humphries and Gurney small-worldness index for the weighted network.
				% If 'density' thresholding is applied, use lambda calculated with harmonic mean.
				if strcmpi( cfg.method_threshold, 'density' )
					gt_subj.gt_weighted.normalised.small_world = gt_subj.gt_weighted.normalised.clustering_coeff / ...
						gt_subj.gt_weighted.normalised.lambda_harmm;
				else
					gt_subj.gt_weighted.normalised.small_world = gt_subj.gt_weighted.normalised.clustering_coeff / ...
						gt_subj.gt_weighted.normalised.lambda;
				end
				
				% Normalise the weighted node-wise graph metrics for the empirical network.
				% Loop the nodes.
				nb_nodes = size( adjc_mat, 1 );
				gt_subj.gt_weighted.normalised_local = struct( ...
					'degree',					zeros( nb_nodes, 1 ), ...
					'strength',					zeros( nb_nodes, 1 ), ...
					'clustering_coeff',			zeros( nb_nodes, 1 ), ...
					'module_degree_z',			zeros( nb_nodes, 1 ), ...
					'eccentricity',				zeros( nb_nodes, 1 ), ...
					'lambda_harmm',				zeros( nb_nodes, 1 ), ...
					'lambda',					zeros( nb_nodes, 1 ), ...
					'local_efficiency',			zeros( nb_nodes, 1 ), ...
					'betweenness_centrality',	zeros( nb_nodes, 1 ), ...
					'eigenvector_centrality',	zeros( nb_nodes, 1 ) );
				rand_vals = zeros( nb_nodes, numel( fieldnames( gt_subj.gt_weighted.normalised_local ) ) );
				emp_vals = zeros( size( rand_vals ) );
				for n = 1 : nb_nodes
					vals = zeros( cfg.random_networks, numel( fieldnames( gt_subj.gt_weighted.normalised_local ) ) );
					for r = 1 : cfg.random_networks
						vals( r, 1 ) = gt_subj.gt_weighted.random.node( r ).degree( n );
						vals( r, 2 ) = gt_subj.gt_weighted.random.node( r ).strength( n );
						vals( r, 3 ) = gt_subj.gt_weighted.random.node( r ).clustering_coeff( n );
						vals( r, 4 ) = gt_subj.gt_weighted.random.node( r ).module_degree_z( n );
						vals( r, 5 ) = gt_subj.gt_weighted.random.node( r ).eccentricity( n );
						vals( r, 6 ) = gt_subj.gt_weighted.random.node( r ).lambda_harmm( n );
						vals( r, 7 ) = gt_subj.gt_weighted.random.node( r ).lambda( n );
						vals( r, 8 ) = gt_subj.gt_weighted.random.node( r ).local_efficiency( n );
						vals( r, 9 ) = gt_subj.gt_weighted.random.node( r ).betweenness_centrality( n );
						vals( r, 10 ) = gt_subj.gt_weighted.random.node( r ).eigenvector_centrality( n );
					end
					for rm = 1 : size( vals, 2 )
						rand_vals( n, rm ) = mean( vals( :, rm ), 'omitnan' );
					end
					emp_vals( n, 1 ) = gt_subj.gt_weighted.empirical.node.degree( n );
					emp_vals( n, 2 ) = gt_subj.gt_weighted.empirical.node.strength( n );
					emp_vals( n, 3 ) = gt_subj.gt_weighted.empirical.node.clustering_coeff( n );
					emp_vals( n, 4 ) = gt_subj.gt_weighted.empirical.node.module_degree_z( n );
					emp_vals( n, 5 ) = gt_subj.gt_weighted.empirical.node.eccentricity( n );
					emp_vals( n, 6 ) = gt_subj.gt_weighted.empirical.node.lambda_harmm( n );
					emp_vals( n, 7 ) = gt_subj.gt_weighted.empirical.node.lambda( n );
					emp_vals( n, 8 ) = gt_subj.gt_weighted.empirical.node.local_efficiency( n );
					emp_vals( n, 9 ) = gt_subj.gt_weighted.empirical.node.betweenness_centrality( n );
					emp_vals( n, 10 ) = gt_subj.gt_weighted.empirical.node.eigenvector_centrality( n );
					
					% Compute the normalised values.
					gt_subj.gt_weighted.normalised_local.degree( n )					= emp_vals( n, 1 ) / rand_vals( n, 1 );
					gt_subj.gt_weighted.normalised_local.strength( n )					= emp_vals( n, 2 ) / rand_vals( n, 2 );
					gt_subj.gt_weighted.normalised_local.clustering_coeff( n )			= emp_vals( n, 3 ) / rand_vals( n, 3 );
					gt_subj.gt_weighted.normalised_local.module_degree_z( n )			= emp_vals( n, 4 ) / rand_vals( n, 4 );
					gt_subj.gt_weighted.normalised_local.eccentricity( n )				= emp_vals( n, 5 ) / rand_vals( n, 5 );
					gt_subj.gt_weighted.normalised_local.lambda_harmm( n )				= emp_vals( n, 6 ) / rand_vals( n, 6 );
					gt_subj.gt_weighted.normalised_local.lambda( n )					= emp_vals( n, 7 ) / rand_vals( n, 7 );
					gt_subj.gt_weighted.normalised_local.local_efficiency( n )			= emp_vals( n, 8 ) / rand_vals( n, 8 );
					gt_subj.gt_weighted.normalised_local.betweenness_centrality( n )	= emp_vals( n, 9 ) / rand_vals( n, 9 );
					gt_subj.gt_weighted.normalised_local.eigenvector_centrality( n )	= emp_vals( n, 10 ) / rand_vals( n, 10 );
				end
			end
			
			if strcmpi( cfg.graph_type, 'binary' ) || strcmpi( cfg.graph_type, 'both' )
				
				% Compute graph metrics for the binary empirical network.
				ch_verbose( 'Computing binary graph metrics for the empirical network...', 1, 1, 4 );
				adjc_mat_bin = weight_conversion( adjc_mat, 'binarize' );
				[ gt_subj.gt_binary.empirical.node, gt_subj.gt_binary.empirical.network ] = ch_gt_metrics_bu( adjc_mat_bin );
				
				% Compute graph metrics for the binary random networks.
				ch_verbose( 'Computing binary graph metrics for the random networks...', 2, 1, 4 );
				for r = 1 : cfg.random_networks
					
					% Impose a density threshold on the random network matrix; method-dependent procedure.
					switch cfg.method_threshold
						case 'mst_density'
							
							% Compute the MST for the random connectivity matrix.
							rand_mst_mat = ch_mst_wu( rand_conn_mat{ r } );
							
							% Add weights to the random network MST to get an adjacency matrix with density d.
							rand_adjc_mat = ch_mst_threshold_wu( rand_mst_mat, rand_conn_mat{ r }, density_threshold, 'decreasing' );
							
						case 'density'
							
							% Impose the density threshold on the connectivity matrix; returns the adjacency matrix.
							rand_adjc_mat = threshold_proportional( rand_conn_mat{ r }, density_threshold );
							
						otherwise
							
							% Do not apply threshold.
							rand_adjc_mat = rand_conn_mat{ r };
							
					end
					
					% Binarise the random adjacency matrix.
					rand_adjc_mat = weight_conversion( rand_adjc_mat, 'binarize' ); %#ok<NASGU>
							
					% Compute graph metrics for the binary random network.
					[ ~, gt_subj.gt_binary.random.node( r ), gt_subj.gt_binary.random.network( r ) ] = ...
						evalc( 'ch_gt_metrics_bu ( rand_adjc_mat );' );
				end
				
				% Normalise the binary network-wide graph metrics for the empirical network.
				ch_verbose ( 'Computing normalised binary graph metrics for the empirical network...', 2, 1, 4 );
				
				gt_subj.gt_binary.normalised.degree				= gt_subj.gt_binary.empirical.network.degree			...
					/ abs( mean( [ gt_subj.gt_binary.random.network.degree ] ) );
				gt_subj.gt_binary.normalised.strength			= gt_subj.gt_binary.empirical.network.strength			...
					/ abs( mean( [ gt_subj.gt_binary.random.network.strength ] ) );
				gt_subj.gt_binary.normalised.density			= gt_subj.gt_binary.empirical.network.density			...
					/ abs( mean( [ gt_subj.gt_binary.random.network.density ] ) );
				gt_subj.gt_binary.normalised.clustering_coeff	= gt_subj.gt_binary.empirical.network.clustering_coeff	...
					/ abs( mean( [ gt_subj.gt_binary.random.network.clustering_coeff ] ) );
				gt_subj.gt_binary.normalised.transitivity		= gt_subj.gt_binary.empirical.network.transitivity		...
					/ abs( mean( [ gt_subj.gt_binary.random.network.transitivity ] ) );
				gt_subj.gt_binary.normalised.components			= gt_subj.gt_binary.empirical.network.components		...
					/ abs( mean( [ gt_subj.gt_binary.random.network.components ] ) );
				gt_subj.gt_binary.normalised.communities		= gt_subj.gt_binary.empirical.network.communities		...
					/ abs( mean( [ gt_subj.gt_binary.random.network.communities ] ) );
				gt_subj.gt_binary.normalised.modularity			= gt_subj.gt_binary.empirical.network.modularity		...
					/ abs( mean( [ gt_subj.gt_binary.random.network.modularity ] ) );
				gt_subj.gt_binary.normalised.assortativity		= gt_subj.gt_binary.empirical.network.assortativity		...
					/ abs( mean( [ gt_subj.gt_binary.random.network.assortativity ] ) );
				gt_subj.gt_binary.normalised.lambda				= gt_subj.gt_binary.empirical.network.lambda			...
					/ abs( mean( [ gt_subj.gt_binary.random.network.lambda ] ) );
				gt_subj.gt_binary.normalised.lambda_harmm		= gt_subj.gt_binary.empirical.network.lambda_harmm		...
					/ abs( mean( [ gt_subj.gt_binary.random.network.lambda_harmm ] ) );
				gt_subj.gt_binary.normalised.global_efficiency	= gt_subj.gt_binary.empirical.network.global_efficiency	...
					/ abs( mean( [ gt_subj.gt_binary.random.network.global_efficiency ] ) );
				gt_subj.gt_binary.normalised.radius				= gt_subj.gt_binary.empirical.network.radius			...
					/ abs( mean( [ gt_subj.gt_binary.random.network.radius ] ) );
				gt_subj.gt_binary.normalised.diameter			= gt_subj.gt_binary.empirical.network.diameter			...
					/ abs( mean( [ gt_subj.gt_binary.random.network.diameter ] ) );
				
				% Compute the Humphries and Gurney small-worldness index for the binary network.
				% If 'density' thresholding is applied, use lambda calculated with harmonic mean.
				if strcmpi( cfg.method_threshold, 'density' )
					gt_subj.gt_binary.normalised.small_world = gt_subj.gt_binary.normalised.clustering_coeff / ...
						gt_subj.gt_binary.normalised.lambda_harmm;
				else
					gt_subj.gt_binary.normalised.small_world = gt_subj.gt_binary.normalised.clustering_coeff / ...
						gt_subj.gt_binary.normalised.lambda;
				end
				
				% Normalise the binary node-wise graph metrics for the empirical network.
				% Loop the nodes.
				nb_nodes = size( adjc_mat, 1 );
				gt_subj.gt_binary.normalised_local = struct( ...
					'degree',					zeros( nb_nodes, 1 ), ...
					'strength',					zeros( nb_nodes, 1 ), ...
					'clustering_coeff',			zeros( nb_nodes, 1 ), ...
					'module_degree_z',			zeros( nb_nodes, 1 ), ...
					'eccentricity',				zeros( nb_nodes, 1 ), ...
					'lambda_harmm',				zeros( nb_nodes, 1 ), ...
					'lambda',					zeros( nb_nodes, 1 ), ...
					'local_efficiency',			zeros( nb_nodes, 1 ), ...
					'betweenness_centrality',	zeros( nb_nodes, 1 ), ...
					'eigenvector_centrality',	zeros( nb_nodes, 1 ) );
				rand_vals = zeros( nb_nodes, numel( fieldnames( gt_subj.gt_binary.normalised_local ) ) );
				emp_vals = zeros( size( rand_vals ) );
				for n = 1 : nb_nodes
					vals = zeros( cfg.random_networks, numel( fieldnames( gt_subj.gt_binary.normalised_local ) ) );
					for r = 1 : cfg.random_networks
						vals( r, 1 ) = gt_subj.gt_binary.random.node( r ).degree( n );
						vals( r, 2 ) = gt_subj.gt_binary.random.node( r ).strength( n );
						vals( r, 3 ) = gt_subj.gt_binary.random.node( r ).clustering_coeff( n );
						vals( r, 4 ) = gt_subj.gt_binary.random.node( r ).module_degree_z( n );
						vals( r, 5 ) = gt_subj.gt_binary.random.node( r ).eccentricity( n );
						vals( r, 6 ) = gt_subj.gt_binary.random.node( r ).lambda_harmm( n );
						vals( r, 7 ) = gt_subj.gt_binary.random.node( r ).lambda( n );
						vals( r, 8 ) = gt_subj.gt_binary.random.node( r ).local_efficiency( n );
						vals( r, 9 ) = gt_subj.gt_binary.random.node( r ).betweenness_centrality( n );
						vals( r, 10 ) = gt_subj.gt_binary.random.node( r ).eigenvector_centrality( n );
					end
					for rm = 1 : size( vals, 2 )
						rand_vals( n, rm ) = mean( vals( :, rm ), 'omitnan' );
					end
					emp_vals( n, 1 ) = gt_subj.gt_binary.empirical.node.degree( n );
					emp_vals( n, 2 ) = gt_subj.gt_binary.empirical.node.strength( n );
					emp_vals( n, 3 ) = gt_subj.gt_binary.empirical.node.clustering_coeff( n );
					emp_vals( n, 4 ) = gt_subj.gt_binary.empirical.node.module_degree_z( n );
					emp_vals( n, 5 ) = gt_subj.gt_binary.empirical.node.eccentricity( n );
					emp_vals( n, 6 ) = gt_subj.gt_binary.empirical.node.lambda_harmm( n );
					emp_vals( n, 7 ) = gt_subj.gt_binary.empirical.node.lambda( n );
					emp_vals( n, 8 ) = gt_subj.gt_binary.empirical.node.local_efficiency( n );
					emp_vals( n, 9 ) = gt_subj.gt_binary.empirical.node.betweenness_centrality( n );
					emp_vals( n, 10 ) = gt_subj.gt_binary.empirical.node.eigenvector_centrality( n );
					
					% Compute the normalised values.
					gt_subj.gt_binary.normalised_local.degree( n )					= emp_vals( n, 1 ) / rand_vals( n, 1 );
					gt_subj.gt_binary.normalised_local.strength( n )				= emp_vals( n, 2 ) / rand_vals( n, 2 );
					gt_subj.gt_binary.normalised_local.clustering_coeff( n )		= emp_vals( n, 3 ) / rand_vals( n, 3 );
					gt_subj.gt_binary.normalised_local.module_degree_z( n )			= emp_vals( n, 4 ) / rand_vals( n, 4 );
					gt_subj.gt_binary.normalised_local.eccentricity( n )			= emp_vals( n, 5 ) / rand_vals( n, 5 );
					gt_subj.gt_binary.normalised_local.lambda_harmm( n )			= emp_vals( n, 6 ) / rand_vals( n, 6 );
					gt_subj.gt_binary.normalised_local.lambda( n )					= emp_vals( n, 7 ) / rand_vals( n, 7 );
					gt_subj.gt_binary.normalised_local.local_efficiency( n )		= emp_vals( n, 8 ) / rand_vals( n, 8 );
					gt_subj.gt_binary.normalised_local.betweenness_centrality( n )	= emp_vals( n, 9 ) / rand_vals( n, 9 );
					gt_subj.gt_binary.normalised_local.eigenvector_centrality( n )	= emp_vals( n, 10 ) / rand_vals( n, 10 );
				end
			end
			
			% Save the graph metrics to a *.mat file.
			save( sprintf( '%s%s_gt_metrics.mat', output_thresh, gt_subj.subject ), '-struct', 'gt_subj' );
		end
		
		% Update the output files structure.
		out_files{ thresh } = dir( sprintf( '%s*.mat', output_thresh ) );
	end
end
end
