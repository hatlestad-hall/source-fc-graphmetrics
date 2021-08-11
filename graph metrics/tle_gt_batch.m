%% About
%
% Batch script for full graph theory analysis of functional connectivity matrices.

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

%% Preparation

% Add support functions to MATLAB path.
AddPath( 'support' );
AddPath( 'stats' );
AddPath( 'bct' );

% Select the frequency bands to compute.
band_files = ch_selectfiles( 'mat', 'on' );

% Select the base output directory.
base_outdir = [ uigetdir( sprintf( '%s/../../', band_files( 1 ).folder ), 'Select output directory' ) '/' ];

% Loop the frequency bands.
for band = 1 : numel( band_files )
	
	% Set the frequency band output directory.
	[ ~, band_name, ~ ] = fileparts( sprintf( '%s/%s', band_files( band ).folder, band_files( band ).name ) );
	band_outdir = sprintf( '%s%s/', base_outdir, band_name );
	if ~exist( band_outdir, 'dir' ), mkdir( band_outdir ); end
	
	%% Compute weighted/binary graph metrics
	ch_verbose( 'Calculating GT metrics...', 2, 2, 0 );
	cfg						= [ ];
	cfg.subjects			= [ ];
	cfg.recompute			= false;
	cfg.graph_type			= 'both';
	cfg.method_threshold	= 'mst_density';
	cfg.density_threshold	= 0.40;
	cfg.random_networks		= 100;
	cfg.file				= band_files( band );
	cfg.output_dir			= band_outdir;
	
	gt_metrics_files = s1_tle_gt_metrics( cfg );
	
	%% Organise the graph metrics
	ch_verbose( 'Organising GT metrics...', 2, 2, 0 );
	gt_organised_bin_files = cell( 1, numel( gt_metrics_files ) );
	gt_organised_wei_files = cell( 1, numel( gt_metrics_files ) );
	for t = 1 : numel( gt_metrics_files )
		
		graph_type			= cfg.graph_type;
		cfg					= [ ];
		cfg.graph_type		= graph_type;
		cfg.files			= gt_metrics_files{ t };
		cfg.hub_node_cutoff	= 0.2;
		cfg.output_dir		= sprintf( '%s/../', gt_metrics_files{ t }( 1 ).folder );
		
		if strcmp( cfg.graph_type, 'binary' ) || strcmp( cfg.graph_type, 'both' )
			cfg.graph					= 'binary';
			gt_organised_bin_files{ t } = s2_tle_gt_organise_metrics( cfg );
		end
		
		if strcmp( cfg.graph_type, 'weighted' ) || strcmp( cfg.graph_type, 'both' )
			cfg.graph					= 'weighted';
			gt_organised_wei_files{ t } = s2_tle_gt_organise_metrics( cfg );
		end
		
		% ZIP the individual subjects' files, and delete unzipped files.
		zip( sprintf( '%s/../subjects.zip', gt_metrics_files{ t }( 1 ).folder ), { sprintf( '%s/*.mat', gt_metrics_files{ t }( 1 ).folder ) } );
		delete( sprintf( '%s/*.mat', gt_metrics_files{ t }( 1 ).folder ) );
		rmdir( sprintf( '%s', gt_metrics_files{ t }( 1 ).folder ) );
	end
	
	%% Analyse the global metrics
% 	ch_verbose( 'Analysing global GT metrics...', 2, 2, 0 );
% 	for t = 1 : numel( gt_metrics_files )
% 		
% 		cfg				= [ ];
% 		cfg.metrics		= { 'degree', 'strength', 'density', 'clust_coeff', 'transitivity', 'components', 'modularity', 'communities', ...
% 			'assortativity', 'lambda', 'lambda_harmonic', 'global_efficiency', 'radius', 'diameter', 'small_world' };
% 		cfg.group		= [ 0,1,0,1,0,1,0,1,0,0,0,1,0,0,1,1,0,1,0,1,0,1,1,0,0,0,1,0,0,1,0,0,1,0,1,1,0 ];
% 		cfg.output_dir	= sprintf( '%s/../', gt_metrics_files{ t }( 1 ).folder );
% 		
% 		cfg.file		= gt_organised_bin_files{ t };
% 		s3a_tle_gt_evaluate_global( cfg );
% 		
% 		cfg.file		= gt_organised_wei_files{ t };
% 		s3a_tle_gt_evaluate_global( cfg );
% 		
% 	end
	
	%% Analyse the local metrics
% 	ch_verbose( 'Analysing local GT metrics...', 2, 2, 0 );
% 	for t = 1 : numel( gt_metrics_files )
% 		
% 		cfg					= [ ];
% 		cfg.metrics			= { 'degree', 'strength', 'clust_coeff', 'components', 'community_affl', 'module_degree_z', 'eccentricity', 'lambda', ...
% 			'lambda_harmonic', 'local_efficiency', 'betweenness_centrality', 'eigenvector_centrality', 'hubness' };
% 		
% 		cfg.group			= [ 0,1,0,1,0,1,0,1,0,0,0,1,0,0,1,1,0,1,0,1,0,1,1,0,0,0,1,0,0,1,0,0,1,0,1,1,0 ];
% 		cfg.output_dir		= sprintf( '%s/../', gt_metrics_files{ t }( 1 ).folder );
% 		
% 		cfg.file		= gt_organised_bin_files{ t };
% 		s3b_tle_gt_evaluate_local( cfg );
% 		
% 		cfg.file		= gt_organised_wei_files{ t };
% 		s3b_tle_gt_evaluate_local( cfg );
% 		
% 	end
	
end
