%% About
% Plot the results obtained from 'nonparametric_permutation_gt'

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function [ f, means, stdevs ] = plot_nonp_perm_gt_results( stats )
%% Configuration

% Frequency bands to plot (should correspond to variable names in result structure).
cfg.bands		= { 'theta', 'alpha', 'low_beta', 'high_beta', 'gamma' };
cfg.b_titles	= { 'Theta', 'Alpha', 'Low-beta', 'High-beta', 'Gamma' };

% Threshold levels to plot (should be character vectors corresponding to 'config.thresh_lvls' in result structure).
cfg.thresh_lvls	= { '25', '30', '35', '40', '45', '50', '55', '60', '65', '70', '75' };

% Metrics to plot.
cfg.g_metrics	= { 'clust_coeff', 'lambda', 'small_world' };
cfg.g_m_titles	= { 'Clustering coefficient', 'Characteristic path length', 'Small worldness' };

cfg.l_metrics	= { 'clust_coeff', 'lambda', 'strength', 'eigenvector_centrality' };
cfg.l_m_titles	= { 'Clustering coefficient', 'Characteristic path length', 'Node strength', 'Eigenvector centrality' };

% Y axis limits and ticks (metrics plots only).
% cfg.g_ylim		= {	[ 0.325, 0.580 ],		[ 3.25, 7.25 ],		[ 0.925, 1.375 ] };
% cfg.g_ytick		= {	0.35 : 0.05 : 0.55,		3.5 : 0.5 : 7.0,	0.95 : 0.05 : 1.35 };
cfg.g_ylim		= {	[ 0.925, 1.550 ],		[ 0.925, 1.300 ],		[ 0.925, 1.375 ] };
cfg.g_ytick		= {	1.00 : 0.10 : 1.50,		0.95 : 0.05 : 1.275,	0.95 : 0.05 : 1.35 };

cfg.l_ylim		= { [], [ 3.5, 8.5 ],	[ 0.5, 6.5 ],	[ -0.025, 0.225] };
cfg.l_ytick		= { [], 4 : 1 : 8,		1 : 1 : 6,		0 : 0.05 : 0.2 };

% Plot p and effect size means.
cfg.mean_p		= false;
cfg.mean_effs	= false;

% Mark significant DT levels with grey rectangle.
cfg.mark_sign	= true;

% Group names.
cfg.groups		= { 'TLE', 'HC' };

% Plot colours.
cfg.colors		= { [ 0.75, 0.1, 0.1 ], [ 0.1, 0.1, 0.75 ] };

% Insert legend.
cfg.legend		= 'on';
cfg.lgnd_g_pos	= { 'northeast', 'northeast', 'northeast' };
cfg.lgnd_l_pos	= { 'northwest', 'northeast', 'northwest', 'northwest' };
cfg.lgnd_column = 1;

%% Prepare

% Load the result structure.
if nargin < 1
	[ file, path ] = uigetfile( '*.mat', 'Select results file' );
	if isnumeric( file ) && ~logical( file )
		return
	end
	stats = load( sprintf( '%s/%s', path, file ) );
end

% Open dialogue box for specification of global or local metrics.
netw_level = questdlg( 'Select network level', 'Network level', 'Global', 'Local', 'Cancel', 'Global' );
if strcmp( netw_level, 'Cancel' )
	return
end

% If local level was selected, open list for specification of nodes.
if strcmp( netw_level, 'Local' )
	node_indices	= cellfun( @strcat, cellfun( @num2str, num2cell( [ stats.atlas.index ] ), 'UniformOutput', false ), ...
		repmat( { ' - ' }, size( [ stats.atlas.index ] ) ), 'UniformOutput', false );
	node_list		= strcat( node_indices, repmat( { ' ' }, size( [ stats.atlas.index ] ) ), { stats.atlas.label } );
	node_ind = listdlg( 'ListString', node_list, 'Name', 'Nodes', 'PromptString', 'Select nodes to plot' );
	if isempty( node_ind )
		return
	end
	cfg.metrics		= cfg.l_metrics;
	cfg.m_titles	= cfg.l_m_titles;
	cfg.lgnd_pos	= cfg.lgnd_l_pos;
else
	node_ind		= 1;
	cfg.metrics		= cfg.g_metrics;
	cfg.m_titles	= cfg.g_m_titles;
	cfg.lgnd_pos	= cfg.lgnd_g_pos;
end

% Get the indices corresponding to the specified threshold levels.
thresh_ind = find( contains( stats.config.thresh_lvls, cfg.thresh_lvls ) ); %#ok<NASGU>

% Create the structure for storing across-thresholds mean p/q values and effect sizes.
means = repmat( { struct( 'metric', cell( numel( cfg.metrics ), 1 ), 'mean_p', cell( numel( cfg.metrics ), 1 ), ...
	'mean_q', cell( numel( cfg.metrics ), 1 ), 'mean_eff_size', cell( numel( cfg.metrics ), 1 ) ) }, [ 1, length( node_ind ) ] );
for mm = 1 : numel( means )
	for mmm = 1 : numel( cfg.metrics )
		means{ mm }( mmm ).metric = cfg.metrics{ mmm };
	end
end

% Create the structure for storing across-thresholds standard deviation p/q values and effect sizes.
stdevs = repmat( { struct( 'metric', cell( numel( cfg.metrics ), 1 ), 'sd_p', cell( numel( cfg.metrics ), 1 ), ...
	'sd_q', cell( numel( cfg.metrics ), 1 ), 'sd_eff_size', cell( numel( cfg.metrics ), 1 ) ) }, [ 1, length( node_ind ) ] );
for mm = 1 : numel( stdevs )
	for mmm = 1 : numel( cfg.metrics )
		stdevs{ mm }( mmm ).metric = cfg.metrics{ mmm };
	end
end

%% Plot group means and nonparametric permutation p values across thresholds

% Loop nodes (only applicable if network level is local).
for n = 1 : length( node_ind )
	
	% Loop metrics.
	for m = 1 : numel( cfg.metrics )
		
		% Get current metric.
		metric = cfg.metrics{ m };
		
		% Create figure for metric plots.
		f( n, m ) = figure;
		fullfig( f( n, m ) );
		
		% Set the subplot order.
		sp_order = 1 : numel( cfg.bands ) * 3;
		
		% Loop bands.
		for b = 1 : numel( cfg.bands )
			
			% Get band data.
			if strcmp( netw_level, 'Local' )
				d = eval( sprintf( 'stats.local_stats.%s;', cfg.bands{ b } ) );
			else
				d = eval( sprintf( 'stats.global_stats.%s;', cfg.bands{ b } ) );
			end
			
			% Create data arrays.
			mean_1	= zeros( numel( cfg.thresh_lvls ), 1 );
			bcaci_1	= zeros( numel( cfg.thresh_lvls ), 2 );
			
			mean_2	= zeros( numel( cfg.thresh_lvls ), 1 );
			bcaci_2	= zeros( numel( cfg.thresh_lvls ), 2 );
			
			punc	= zeros( numel( cfg.thresh_lvls ), 1 );
			pfdr	= zeros( numel( cfg.thresh_lvls ), 1 );
			
			% Loop thresholds.
			for t = 1 : numel( cfg.thresh_lvls )
				
				% Calculate group means and BCa confidence intervals.
				if strcmp( netw_level, 'Local' )
					data_1	= eval( sprintf( 'd( thresh_ind( t ) ).%s( node_ind( n ) ).%s;', metric, cfg.groups{ 1 } ) );
				else
					data_1	= eval( sprintf( 'd( thresh_ind( t ) ).%s.%s;', metric, cfg.groups{ 1 } ) );
				end
				mean_1( t, 1 )	= nanmean( data_1 );
				bcaci_1( t, : ) = bootci( 1000, @mean, data_1 );
				
				if strcmp( netw_level, 'Local' )
					data_2	= eval( sprintf( 'd( thresh_ind( t ) ).%s( node_ind( n ) ).%s;', metric, cfg.groups{ 2 } ) );
				else
					data_2	= eval( sprintf( 'd( thresh_ind( t ) ).%s.%s;', metric, cfg.groups{ 2 } ) );
				end
				mean_2( t, 1 )	= nanmean( data_2 );
				bcaci_2( t, : ) = bootci( 1000, @mean, data_2 );
				
				% Get uncorrected p and FDR q.
				if strcmp( netw_level, 'Local' )
					punc( t, 1 )	= eval( sprintf( 'd( thresh_ind( t ) ).%s( node_ind( n ) ).p_uncorr;', metric ) );
					pfdr( t, 1 )	= eval( sprintf( 'd( thresh_ind( t ) ).%s( node_ind( n ) ).fdr_q;', metric ) );
				else
					punc( t, 1 )	= eval( sprintf( 'd( thresh_ind( t ) ).%s.p_uncorr;', metric ) );
					pfdr( t, 1 )	= eval( sprintf( 'd( thresh_ind( t ) ).%s.fdr_q;', metric ) );
				end
				
				% Get effect size estimate.
				if strcmp( netw_level, 'Local' )
					effs( t, 1 )	= eval( sprintf( 'd( thresh_ind( t ) ).%s( node_ind( n ) ).eff_size;', metric ) );				%#ok<*AGROW>
				else
					effs( t, 1 )	= eval( sprintf( 'd( thresh_ind( t ) ).%s.eff_size;', metric ) );
				end
			end
			
			% Plot group means in top row.
			subplot( 3, numel( cfg.bands ), sp_order( b ) );
			l = plot( [ mean_1, mean_2 ], 'Marker', 'o', 'MarkerSize', 4, 'LineWidth', 0.5 );
			set( gca, 'XLim', [ 0.5, t + 0.5 ], 'XTick', 1 : t, 'XTickLabel', cfg.thresh_lvls, 'YGrid', 'off', 'FontSize', 11, ...
				'FontName', 'Calibri', ...
				'TitleFontSizeMultiplier', 1.25, 'LabelFontSizeMultiplier', 1.1 );
			if strcmp( netw_level, 'Local' ) && ~isempty( cfg.l_ylim{ m } )
				set( gca, 'YLim', cfg.l_ylim{ m }, 'YTick', cfg.l_ytick{ m } );
			elseif strcmp( netw_level, 'Global' ) && ~isempty( cfg.g_ylim{ m } )
				set( gca, 'YLim', cfg.g_ylim{ m }, 'YTick', cfg.g_ytick{ m } );
			end
			
			% Plot bootstrapped 95% confidence interval.
			hold on;
			ci_x = [ 1 : numel( cfg.thresh_lvls ); 1 : numel( cfg.thresh_lvls ) ]';
			line( ci_x' - 0.15, bcaci_1', 'Color', [ cfg.colors{ 1 }, 0.35 ], 'LineWidth', 1.25, 'Marker', '.' );
			line( ci_x' + 0.15, bcaci_2', 'Color', [ cfg.colors{ 2 }, 0.35 ], 'LineWidth', 1.25, 'Marker', '.' );
			
			% Set colours.
			set( l( 1 ), 'Color', cfg.colors{ 1 }, 'MarkerFaceColor', cfg.colors{ 1 } );
			set( l( 2 ), 'Color', cfg.colors{ 2 }, 'MarkerFaceColor', cfg.colors{ 2 } );
			
			% Add axes titles, subplot title and legend.
			%xlabel( 'Density threshold (%)', 'FontWeight', 'bold', 'Interpreter', 'none' );
			%ylabel( cfg.m_titles{ m }, 'FontWeight', 'bold' );
			title( cfg.b_titles{ b }, 'FontWeight', 'bold' );
			if strcmpi( cfg.legend, 'on' ) && sp_order( b ) == cfg.lgnd_column
				legend( 'FE', 'HC', 'Location', cfg.lgnd_pos{ m }, 'Box', 'off', 'FontWeight', 'bold' );
			end
			
			% If enabled, plot grey rectangles over the significant DT levels.
			if cfg.mark_sign == true
				
				% Get the significant DT levels.
				sign_dt = find( pfdr < 0.10 );
				
				% Define the positions of the rectangles.
				rect_pos = zeros( length( sign_dt ), 4 );
				for d = 1 : length( sign_dt )
					y_lim = get( gca, 'YLim' );
					rect_pos( d, : ) = [ sign_dt( d ) - 0.5, y_lim( 1 ), 1, y_lim( 2 ) - y_lim( 1 ) ];
				end
				
				% Draw the rectangles.
				for d = 1 : size( rect_pos, 1 )
					rectangle( 'Position', rect_pos( d, : ), 'FaceColor', [ 0.2, 0.2, 0.2, 0.2 ], 'LineStyle', 'none' );
				end
			end
			
			% Plot uncorrected and FDR corrected p values in middle row.
			subplot( 3, numel( cfg.bands ), sp_order( b + numel( cfg.bands ) ) );
			lp = plot( [ punc, pfdr ], 'Marker', 'o', 'MarkerSize', 4, 'LineWidth', 0.5 );
			set( gca, 'XLim', [ 0.5, t + 0.5 ], 'XTick', 1 : t, 'XTickLabel', cfg.thresh_lvls, 'YGrid', 'off', 'FontSize', 11, ...
				'FontName', 'Calibri', ...
				'TitleFontSizeMultiplier', 1.25, 'LabelFontSizeMultiplier', 1.1, 'YLim', [ -0.05, 1.05 ], 'YTick', 0 : 0.1 : 1 );
			
			% Set colours and axes labels.
			set( lp( 1 ), 'Color', [ 0.1, 0.1, 0.75 ], 'MarkerFaceColor', [ 0.1, 0.1, 0.75 ] );
			set( lp( 2 ), 'Color', [ 0.1, 0.75, 0.1 ], 'MarkerFaceColor', [ 0.1, 0.75, 0.1 ] );
			%xlabel( 'Density threshold (%)', 'FontWeight', 'bold', 'Interpreter', 'none' );
			%ylabel( '\itp / q', 'FontWeight', 'bold' );
			
			% Plot dashed alpha line.
			hold on;
			line( [ 0.5, t + 0.5 ], [ stats.config.alpha, stats.config.alpha ], 'LineStyle', '--', 'Color', [ 0.75, 0.1, 0.1 ] );
			
			% If enabled, plot means.
			if cfg.mean_p
				hold on;
				line( [ 0.5, t + 0.5 ], [ nanmean( punc ), nanmean( punc ) ], 'LineStyle', ':', 'Color', [ 0.1, 0.1, 0.75 ], 'LineWidth', 1 );
				means{ n }( m ).mean_p( b ).band	= cfg.bands{ b };
				means{ n }( m ).mean_p( b ).value	= nanmean( punc );
				stdevs{ n }( m ).sd_p( b ).band		= cfg.bands{ b };
				stdevs{ n }( m ).sd_p( b ).value	= nanstd( punc );
				line( [ 0.5, t + 0.5 ], [ nanmean( pfdr ), nanmean( pfdr ) ], 'LineStyle', ':', 'Color', [ 0.1, 0.75, 0.1 ], 'LineWidth', 1 );
				means{ n }( m ).mean_q( b ).band	= cfg.bands{ b };
				means{ n }( m ).mean_q( b ).value	= nanmean( pfdr );
				stdevs{ n }( m ).sd_q( b ).band		= cfg.bands{ b };
				stdevs{ n }( m ).sd_q( b ).value	= nanstd( pfdr );
			end
			
			% If enabled, plot legend.
			if strcmpi( cfg.legend, 'on' ) && sp_order( b ) == cfg.lgnd_column
				legend( 'Uncorrected \it p', 'FDR(+) \it q', 'Location', cfg.lgnd_pos{ m }, 'Box', 'off', 'FontWeight', 'bold' );
			end
			
			% If enabled, plot grey rectangles over the significant DT levels.
			if cfg.mark_sign == true
				
				% Get the significant DT levels.
				sign_dt = find( pfdr < 0.10 );
				
				% Define the positions of the rectangles.
				rect_pos = zeros( length( sign_dt ), 4 );
				for d = 1 : length( sign_dt )
					y_lim = get( gca, 'YLim' );
					rect_pos( d, : ) = [ sign_dt( d ) - 0.5, y_lim( 1 ), 1, y_lim( 2 ) - y_lim( 1 ) ];
				end
				
				% Draw the rectangles.
				for d = 1 : size( rect_pos, 1 )
					rectangle( 'Position', rect_pos( d, : ), 'FaceColor', [ 0.2, 0.2, 0.2, 0.2 ], 'LineStyle', 'none' );
				end
			end
			
			% Plot effect size estimates in bottom row.
			subplot( 3, numel( cfg.bands ), sp_order( b + ( numel( cfg.bands ) * 2 ) ) );
			les = plot( effs, 'Marker', 'o', 'MarkerSize', 4, 'LineWidth', 0.5 );
			set( gca, 'XLim', [ 0.5, t + 0.5 ], 'XTick', 1 : t, 'XTickLabel', cfg.thresh_lvls, 'YGrid', 'off', 'FontSize', 11, ...
				'FontName', 'Calibri', ...
				'TitleFontSizeMultiplier', 1.25, 'LabelFontSizeMultiplier', 1.1, 'YLim', [ -1.10, 1.10 ], 'YTick', -1 : 0.2 : 1 );
			
			% Set colours and axes labels.
			set( les( 1 ), 'Color', [ 0.75, 0.1, 0.1 ], 'MarkerFaceColor', [ 0.75, 0.1, 0.1 ] );
			%xlabel( 'Density threshold (%)', 'FontWeight', 'bold', 'Interpreter', 'none' );
			%ylabel( 'Effect size', 'FontWeight', 'bold' );
			
			% Plot solid y = 0 line.
			hold on;
			line( [ 0.5, t + 0.5 ], [ 0, 0 ], 'LineStyle', '-', 'Color', [ 0.1, 0.1, 0.1 ] );
			
			% If enabled, plot mean.
			if cfg.mean_effs
				hold on;
				line( [ 0.5, t + 0.5 ], [ nanmean( effs ), nanmean( effs ) ], 'LineStyle', ':', 'Color', [ 0.75, 0.1, 0.1 ], 'LineWidth', 1 );
				means{ n }( m ).mean_eff_size( b ).band		= cfg.bands{ b };
				means{ n }( m ).mean_eff_size( b ).value	= nanmean( effs );
				stdevs{ n }( m ).sd_eff_size( b ).band		= cfg.bands{ b };
				stdevs{ n }( m ).sd_eff_size( b ).value		= nanstd( effs );
			end
			
			% If enabled, plot legend.
			if strcmpi( cfg.legend, 'on' ) && strcmpi( stats.config.eff_size, 'hedgesg' ) && sp_order( b ) == cfg.lgnd_column
				legend( 'Hedge''s \it g', 'Location', cfg.lgnd_pos{ m }, 'Box', 'off', 'FontWeight', 'bold' );
			end
			
			% If enabled, plot grey rectangles over the significant DT levels.
			if cfg.mark_sign == true
				
				% Get the significant DT levels.
				sign_dt = find( pfdr < 0.10 );
				
				% Define the positions of the rectangles.
				rect_pos = zeros( length( sign_dt ), 4 );
				for d = 1 : length( sign_dt )
					y_lim = get( gca, 'YLim' );
					rect_pos( d, : ) = [ sign_dt( d ) - 0.5, y_lim( 1 ), 1, y_lim( 2 ) - y_lim( 1 ) ];
				end
				
				% Draw the rectangles.
				for d = 1 : size( rect_pos, 1 )
					rectangle( 'Position', rect_pos( d, : ), 'FaceColor', [ 0.2, 0.2, 0.2, 0.2 ], 'LineStyle', 'none' );
				end
			end
			
		end
		
		% Add figure title.
		if strcmp( netw_level, 'Local' )
			sgtitle( sprintf( '%s - %s', stats.atlas( node_ind( n ) ).name, cfg.m_titles{ m } ), 'FontWeight', 'bold' );
		else
			sgtitle( cfg.m_titles{ m }, 'FontWeight', 'bold' );
		end
		
	end
	
end
end