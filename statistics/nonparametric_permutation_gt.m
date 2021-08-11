%% About
% Nonparametric permutation testing of graph metrics
% Difference between two independent samples

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function stats = nonparametric_permutation_gt( cfg )
%% Add required tools to path
AddPath( 'stats' );

%% Configuration
if nargin < 1
	
	% Input directory (<this directory>/<band>/<threshold>/...) (full path to directory, or '' to open UI for selection).
	cfg.gt_dir		= '';
	
	% Output directory (full path to directory, or '' to open UI for selection).
	cfg.out_dir		= '';
	
	% Networks to analyse (type1: 'weighted' or 'binary') (type2: 'emp' or 'nrm').
	cfg.netw_type1	= 'weighted';
	cfg.netw_type2	= 'nrm';
	
	% Frequency bands to analyse (must correspond to directory names; labels must be usable as variable names).
	cfg.bands		= { 'Theta', 'Alpha', 'Low-beta', 'High-beta', 'Gamma' };
	cfg.bands_label = { 'theta', 'alpha', 'low_beta', 'high_beta', 'gamma' };
	
	% Threshold levels to analyse.
	cfg.thresh_type = 'mst_density';										% Threshold type: 'mst_density' or 'density'
	cfg.thresh_lvls = { '25', '30', '35', '40', '45', '50', '55', '60', '65', '70', '75' };
	
	% Metrics to analyse.
	cfg.global_met	= { 'clust_coeff', 'lambda' };
	cfg.local_met	= { 'strength', 'clust_coeff', 'lambda', 'eigenvector_centrality' };
	
	% Permutation statistic ('mean' or 't').
	cfg.perm_stat	= 't';
	
	% Number of permutations.
	cfg.perm_n		= 5000;
	
	% Measure of effect size ('hedgesg', 'glassdelta'; see 'mes.m' for more options; or 'off' to disable).
	cfg.eff_size	= 'hedgesg';
	
	% FDR correction for multiple comparisons ('on' or 'off'), and correction procedure ('by' or 'storey').
	cfg.fdr			= 'on';
	cfg.fdr_type	= 'by';
	
	% FDR correction dimension (only applicable if FDR is enabled) 'bands', 'metrics', 'nodes').
	cfg.fdr_dim_g	= 'bands';		% Global level of analysis.
	cfg.fdr_dim_l	= 'bands';		% Local level of analysis.
	
	% If FDR type is 'by', set test dependency assumption ('ind', 'corr+', 'corr-' or 'unknown').
	cfg.fdr_dep_g	= 'corr+';
	cfg.fdr_dep_l	= 'corr+';
	
	% Significance threshold (alpha).
	cfg.alpha		= 0.10;
	
	% Recomputation of multiple comparison correction (full path to previously computed *.mat, or '' to disable).
	cfg.recompute	= '';
	
	% Subject information file (full path to *.txt, or '' to open UI for selection).
	cfg.info_file	= 'C:/Users/chrhh/Google Drive/MATLAB/Connectivity/TLE/Subjects info/tle_subjects_info.txt';
	
	% Grouping variable (table column name) (first occurring name is group 1, rest is group 2; max two groups).
	cfg.group_var	= 'group';
	
	% Display progress bar.
	cfg.prog_bar	= 'on';
	
end

% Recompute conditional.
if isempty( cfg.recompute )
	
	%% Load the input file and prepare the output struct
	
	% Check the input directory.
	if isempty( cfg.gt_dir )
		cfg.gt_dir = uigetdir( pwd, 'Select input graph metrics directory' );
	end
	
	% Check the output directory.
	if isempty( cfg.out_dir )
		cfg.out_dir = uigetdir( pwd, 'Select output directory' );
	end
	
	% Load the subject info file.
	if isempty( cfg.info_file )
		[ file, path ] = uigetfile( '*.txt', 'Select subject info file', 'MultiSelect', 'off' );
		cfg.info_file = sprintf( '%s/%s', path, file );
	end
	sub_info = readtable( cfg.info_file, 'ReadVariableNames', true, 'Delimiter', 'tab' );
	
	% Get grouping filter.
	sub_groups	= unique( sub_info{ :, cfg.group_var }, 'stable' );
	group		= zeros( height( sub_info ), 1 );
	group( strcmp( sub_groups{ 2 }, sub_info{ :, cfg.group_var } ) ) = 1;
	group		= logical( group );
	
	% Define output structures.
	stats.config	= cfg;
	stats.sub_info	= sub_info;
	
	% If enabled, create progress bar.
	if strcmpi( cfg.prog_bar, 'on' )
		progr = 0;
		wb = waitbar( 0, '', 'Name', 'Nonparametric permutation testing' );
	end
	
	%% Main loop 1: Frequency bands
	for b = 1 : numel( cfg.bands )
		
		% Set frequency band directory.
		band_dir = sprintf( '%s/%s', cfg.gt_dir, cfg.bands{ b } );
		
		%% Main loop 2: Threshold levels
		for t = 1 : numel( cfg.thresh_lvls )
			
			% If enabled, update progress bar.
			if strcmpi( cfg.prog_bar, 'on' )
				progr = progr + 1;
				curr_prog = progr / ( numel( cfg.bands ) * numel( cfg.thresh_lvls ) );
				waitbar( curr_prog, wb, sprintf( 'Current band/threshold: %s / %s', cfg.bands{ b }, cfg.thresh_lvls{ t } ) );
			end
			
			% Load threshold level graph metrics.
			gt = load( sprintf( '%s/%s_%s/gt_metrics_%s.mat', band_dir, cfg.thresh_type, cfg.thresh_lvls{ t }, cfg.netw_type1 ) );
			
			% On first iteration, add the atlas info to the output.
			if b == 1 && t == 1
				stats.atlas = gt.atlas;
			end
			
			%% Analyse global metrics
			d = eval( sprintf( 'gt.global_metrics_%s', cfg.netw_type2 ) );
			
			% Write the threshold level to the output.
			eval( sprintf( 'stats.global_stats.%s( t ).threshold = gt.density_threshold;', cfg.bands_label{ b } ) );
			
			% Loop: Global metrics.
			for m = 1 : numel( cfg.global_met )
				
				% Extract grouped metric values.
				v1 = d{ ~group, cfg.global_met{ m } };
				v2 = d{ group,  cfg.global_met{ m } };
				
				% Analyse group differences with nonparametric permutation testing.
				if strcmpi( cfg.perm_stat, 'mean' )
					[ p, obs_stat, eff_size ] = permutationTest( v1, v2, cfg.perm_n );													%#ok<*ASGLU>
				elseif strcmpi( cfg.perm_stat, 't' )
					[ p, obs_stat, eff_size ] = permutationTest( v1, v2, cfg.perm_n, 'tstat', 1 );
				end
				
				% Compute the specified effect size (observed).
				es = mes( v1, v2, cfg.eff_size );
				eff_size = eval( sprintf( 'es.%s;', cfg.eff_size ) );
				
				% Organise the output.
				eval( sprintf( 'stats.global_stats.%s( t ).%s.%s = v1;',				...
					cfg.bands_label{ b }, cfg.global_met{ m }, sub_groups{ 1 } ) );
				eval( sprintf( 'stats.global_stats.%s( t ).%s.%s = v2;',				...
					cfg.bands_label{ b }, cfg.global_met{ m }, sub_groups{ 2 } ) );
				eval( sprintf( 'stats.global_stats.%s( t ).%s.p_uncorr = p;',			cfg.bands_label{ b }, cfg.global_met{ m } ) );
				eval( sprintf( 'stats.global_stats.%s( t ).%s.obs_stat = obs_stat;',	cfg.bands_label{ b }, cfg.global_met{ m } ) );
				eval( sprintf( 'stats.global_stats.%s( t ).%s.eff_size = eff_size;',	cfg.bands_label{ b }, cfg.global_met{ m } ) );
				
			end		% Loop: Global metrics.
			
			%% Analyse local metrics
			switch cfg.netw_type2
				case 'emp', d = get_node_values( gt.local_metrics );
				case 'nrm', d = get_node_values( gt.local_metrics_nrm );
			end
			
			% Write the threshold level to the output.
			eval( sprintf( 'stats.local_stats.%s( t ).threshold = gt.density_threshold;', cfg.bands_label{ b } ) );
			
			% Loop: Local metrics.
			for m = 1 : numel( cfg.local_met )
				
				% Loop: Nodes.
				for n = 1 : length( d )
					
					% Extract grouped node metric values.
					v1 = eval( sprintf( 'd( n ).%s( ~group );', cfg.local_met{ m } ) )';
					v2 = eval( sprintf( 'd( n ).%s( group );',  cfg.local_met{ m } ) )';
					
					% Analyse group differences with nonparametric permutation testing.
					if strcmpi( cfg.perm_stat, 'mean' )
						[ p, obs_stat, eff_size ] = permutationTest( v1, v2, cfg.perm_n );
					elseif strcmpi( cfg.perm_stat, 't' )
						[ p, obs_stat, eff_size ] = permutationTest( v1, v2, cfg.perm_n, 'tstat', 1 );
					end
					
					% Compute the specified effect size (observed).
					es = mes( v1, v2, cfg.eff_size );
					eff_size = eval( sprintf( 'es.%s;', cfg.eff_size ) );
					
					% Organise the output.
					eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).%s = v1;',				...
						cfg.bands_label{ b }, cfg.local_met{ m }, sub_groups{ 1 } ) );
					eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).%s = v2;',				...
						cfg.bands_label{ b }, cfg.local_met{ m }, sub_groups{ 2 } ) );
					eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).p_uncorr = p;',			cfg.bands_label{ b }, cfg.local_met{ m } ) );
					eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).obs_stat = obs_stat;',	cfg.bands_label{ b }, cfg.local_met{ m } ) );
					eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).eff_size = eff_size;',	cfg.bands_label{ b }, cfg.local_met{ m } ) );
					
				end		% Loop: Nodes.
				
			end		% Loop: Local metrics.
			
		end		% Main loop 2: Threshold levels.
		
	end		% Main loop 1: Frequency bands.

else
	
	% Check the output directory.
	if isempty( cfg.out_dir )
		cfg.out_dir = uigetdir( pwd, 'Select output directory' );
	end
	
	% Load the previously computed file.
	stats			= load( cfg.recompute );
	stats.config	= cfg;
	
end		% End recompute conditional.

%% False discovery rate (FDR) correction for multiple comparisons
if strcmpi( cfg.fdr, 'on' )
	
	% If enabled, update the progress bar.
	if strcmpi( cfg.prog_bar, 'on' ) && isempty( cfg.recompute )
		waitbar( 1, wb, 'Applying FDR correction' );
	end
	
	%% Correct p values for global metrics
	d = stats.global_stats;
	
	switch lower( cfg.fdr_dim_g )
		case 'bands'
			
			% Loop 1: Threshold levels.
			for t = 1 : numel( cfg.thresh_lvls )
				
				% Loop 2: Metrics.
				for m = 1 : numel( cfg.global_met )
					
					% Loop 3a: Frequency bands.
					p_uncorr = zeros( numel( cfg.bands ), 1 );
					for b = 1 : numel( cfg.bands )
						
						% Extract p values for the frequency bands.
						p_uncorr( b ) = eval( sprintf( 'd.%s( t ).%s.p_uncorr;', cfg.bands_label{ b }, cfg.global_met{ m } ) );
						
					end		% Loop 3a: Frequency bands.
					
					% Correct the p values with FDR.
					switch lower( cfg.fdr_type )
						case 'storey'
							[ p_corr, fdr_alpha ] = fdr_storey( p_uncorr, cfg.alpha, false );
							
						case 'by'
							[ p_corr, fdr_alpha ] = fdr_BY( p_uncorr, cfg.alpha, cfg.fdr_dep_g, false );							%#ok<*NASGU>
							
					end
					
					% Loop 3b: Frequency bands.
					for b = 1 : numel( cfg.bands )
						
						% Insert corrected p values for the frequency bands.
						eval( sprintf( 'stats.global_stats.%s( t ).%s.fdr_q = p_corr( b );',		  cfg.bands_label{ b }, cfg.global_met{ m } ) );
						eval( sprintf( 'stats.global_stats.%s( t ).%s.fdr_alpha = fdr_alpha( b );',	  cfg.bands_label{ b }, cfg.global_met{ m } ) );
						eval( sprintf( 'stats.global_stats.%s( t ).%s.fdr_dim = cfg.fdr_dim_g;',	  cfg.bands_label{ b }, cfg.global_met{ m } ) );
						eval( sprintf( 'stats.global_stats.%s( t ).%s.fdr_num = numel( cfg.bands );', cfg.bands_label{ b }, cfg.global_met{ m } ) );
						
					end		% Loop 3b: Frequency bands.
					
				end		% Loop 2: Metrics.
				
			end		% Loop 1: Threshold levels.
			
		case 'metrics'
			
			% Loop 1: Threshold levels.
			for t = 1 : numel( cfg.thresh_lvls )
				
				% Loop 2: Frequency bands.
				for b = 1 : numel( cfg.bands )
					
					% Loop 3a: Metrics.
					p_uncorr = zeros( numel( cfg.global_met ), 1 );
					for m = 1 : numel( cfg.global_met )
						
						% Extract p values for the metrics.
						p_uncorr( m ) = eval( sprintf( 'd.%s( t ).%s.p_uncorr;', cfg.bands_label{ b }, cfg.global_met{ m } ) );
						
					end		% Loop 3a: Metrics.
					
					% Correct the p values with FDR.
					switch lower( cfg.fdr_type )
						case 'storey'
							[ p_corr, fdr_alpha ] = fdr_storey( p_uncorr, cfg.alpha, false );
							
						case 'by'
							[ p_corr, fdr_alpha ] = fdr_BY( p_uncorr, cfg.alpha, cfg.fdr_dep_g, false );							%#ok<*NASGU>
							
					end
					
					% Loop 3b: Metrics.
					for m = 1 : numel( cfg.global_met )
						
						% Insert corrected p values for the metrics.
						eval( sprintf( 'stats.global_stats.%s( t ).%s.fdr_q = p_corr( m );',				...
							cfg.bands_label{ b }, cfg.global_met{ m } ) );
						eval( sprintf( 'stats.global_stats.%s( t ).%s.fdr_alpha = fdr_alpha( m );',			...
							cfg.bands_label{ b }, cfg.global_met{ m } ) );
						eval( sprintf( 'stats.global_stats.%s( t ).%s.fdr_dim = cfg.fdr_dim_g;',			...
							cfg.bands_label{ b }, cfg.global_met{ m } ) );
						eval( sprintf( 'stats.global_stats.%s( t ).%s.fdr_num = numel( cfg.global_met );',	...
							cfg.bands_label{ b }, cfg.global_met{ m } ) );
						
					end		% Loop 3b: Metrics.
					
				end		% Loop 2: Frequency bands.
				
			end		% Loop 1: Threshold levels.
			
	end
	
	%% Correct p values for local metrics
	d = stats.local_stats;
	
	switch lower( cfg.fdr_dim_l )
		case 'bands'
			
			% Loop 1: Threshold levels.
			for t = 1 : numel( cfg.thresh_lvls )
				
				% Loop 2: Metrics.
				for m = 1 : numel( cfg.local_met )
					
					% Loop 3: Nodes.
					nodes_n = eval( sprintf( 'length( d.%s( t ).%s );', cfg.bands_label{ b }, cfg.local_met{ m } ) );
					for n = 1 : nodes_n
						
						% Loop 4a: Frequency bands.
						p_uncorr = zeros( numel( cfg.bands ), 1 );
						for b = 1 : numel( cfg.bands )
							
							% Extract p values for the frequency bands.
							p_uncorr( b ) = eval( sprintf( 'd.%s( t ).%s( n ).p_uncorr;', cfg.bands_label{ b }, cfg.local_met{ m } ) );
							
						end		% Loop 4a: Frequency bands.
						
						% Correct the p values with FDR.
						switch lower( cfg.fdr_type )
							case 'storey'
								[ p_corr, fdr_alpha ] = fdr_storey( p_uncorr, cfg.alpha, false );
								
							case 'by'
								[ p_corr, fdr_alpha ] = fdr_BY( p_uncorr, cfg.alpha, cfg.fdr_dep_g, false );							%#ok<*NASGU>
								
						end
						
						% Loop 4b: Frequency bands.
						for b = 1 : numel( cfg.bands )
							
							% Insert corrected p values for the frequency bands.
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_q = p_corr( b );',			...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_alpha = fdr_alpha( b );',		...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_dim = cfg.fdr_dim_l;',		...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_num = numel( cfg.bands );',	...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							
						end		% Loop 4b: Frequency bands.
						
					end		% Loop 3: Nodes.
					
				end		% Loop 2: Metrics.
				
			end		% Loop 1: Threshold levels.
			
		case 'metrics'
			
			% Loop 1: Threshold levels.
			for t = 1 : numel( cfg.thresh_lvls )
				
				% Loop 2: Frequency bands.
				for b = 1 : numel( cfg.bands )
					
					% Loop 3: Nodes.
					nodes_n = eval( sprintf( 'length( d.%s( t ).%s );', cfg.bands_label{ b }, cfg.local_met{ 1 } ) );
					for n = 1 : nodes_n
						
						% Loop 4a: Metrics.
						p_uncorr = zeros( numel( cfg.local_met ), 1 );
						for m = 1 : numel( cfg.local_met )
							
							% Extract p values for the metrics.
							p_uncorr( m ) = eval( sprintf( 'd.%s( t ).%s( n ).p_uncorr;', cfg.bands_label{ b }, cfg.local_met{ m } ) );
							
						end		% Loop 4a: Metrics.
						
						% Correct the p values with FDR.
						switch lower( cfg.fdr_type )
							case 'storey'
								[ p_corr, fdr_alpha ] = fdr_storey( p_uncorr, cfg.alpha, false );
								
							case 'by'
								[ p_corr, fdr_alpha ] = fdr_BY( p_uncorr, cfg.alpha, cfg.fdr_dep_g, false );							%#ok<*NASGU>
								
						end
						
						% Loop 4b: Metrics.
						for m = 1 : numel( cfg.local_met )
							
							% Insert corrected p values for the metrics.
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_q = p_corr( m );',				...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_alpha = fdr_alpha( m );',			...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_dim = cfg.fdr_dim_l;',			...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_num = numel( cfg.local_met );',	...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							
						end		% Loop 4b: Metrics.
						
					end		% Loop 3: Nodes.
					
				end		% Loop 2: Frequency bands.
				
			end		% Loop 1: Threshold levels.
			
		case 'nodes'
			
			% Loop 1: Threshold levels.
			for t = 1 : numel( cfg.thresh_lvls )
				
				% Loop 2: Frequency bands.
				for b = 1 : numel( cfg.bands )
					
					% Loop 3: Metrics.
					for m = 1 : numel( cfg.local_met )
						
						% Loop 4a: Nodes.
						nodes_n = eval( sprintf( 'length( d.%s( t ).%s );', cfg.bands_label{ b }, cfg.local_met{ m } ) );
						p_uncorr = zeros( numel( nodes_n ), 1 );
						for n = 1 : nodes_n
							
							% Extract p values for the nodes.
							p_uncorr( n ) = eval( sprintf( 'd.%s( t ).%s( n ).p_uncorr;', cfg.bands_label{ b }, cfg.local_met{ m } ) );
							
						end		% Loop 4a: Nodes.
						
						% Correct the p values with FDR.
						switch lower( cfg.fdr_type )
							case 'storey'
								[ p_corr, fdr_alpha ] = fdr_storey( p_uncorr, cfg.alpha, false );
								
							case 'by'
								[ p_corr, fdr_alpha ] = fdr_BY( p_uncorr, cfg.alpha, cfg.fdr_dep_g, false );							%#ok<*NASGU>
								
						end
						
						% Loop 4b: Nodes.
						for n = 1 : nodes_n
							
							% Insert corrected p values for the nodes.
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_q = p_corr( n );',		...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_alpha = fdr_alpha( n );',	...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_dim = cfg.fdr_dim_l;',	...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							eval( sprintf( 'stats.local_stats.%s( t ).%s( n ).fdr_num = nodes_n;',			...
								cfg.bands_label{ b }, cfg.local_met{ m } ) );
							
						end		% Loop 4b: Nodes.
						
					end		% Loop 3: Metrics.
					
				end		% Loop 2: Frequency bands.
				
			end		% Loop 1: Threshold levels.
			
	end
	
end

% If in use, close the progress bar.
if strcmpi( cfg.prog_bar, 'on' ) && isempty( cfg.recompute )
	delete( wb );
end

% Save the output structure to a file.
save( sprintf( '%s/nonp_perm_gt.mat', cfg.out_dir ), '-struct', 'stats' );
end
