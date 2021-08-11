%% About

% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function f = plot_nonp_perm_gt_local( stats )
%% Configuration
	
% Frequency bands to plot (should correspond to variable names in result structure).
cfg.bands		= { 'theta', 'alpha', 'low_beta', 'high_beta', 'gamma' };
cfg.b_titles	= { 'Theta', 'Alpha', 'Low-beta', 'High-beta', 'Gamma' };

% Threshold levels to plot (should be character vectors corresponding to 'config.thresh_lvls' in result structure).
cfg.thresh_lvls	= { '25', '30', '35', '40', '45', '50', '55', '60', '65', '70', '75' };

% Metrics to plot.
cfg.metrics		= { 'clust_coeff', 'lambda', 'strength', 'eigenvector_centrality' };
cfg.m_titles	= { 'Clustering coefficient', 'Characteristic path length', 'Node strength', 'Eigenvector centrality' };

% Nodes to plot.
cfg.nodes		= 1 : 26;

% Plot uncorrected p values or FDR corrected q values ('p', 'q' or 'fdr_p' ).
cfg.p			= 'q';

% Mark significant nodes/thresholds.
cfg.mark_sig	= true;
cfg.alpha		= 0.10;
	
%% Prepare

% Load the result structure.
if nargin < 1
	[ file, path ] = uigetfile( '*.mat', 'Select results file' );
	if isnumeric( file ) && ~logical( file )
		return
	end
	stats = load( sprintf( '%s/%s', path, file ) );
end

% Get the indices corresponding to the specified threshold levels.
thresh_ind = find( contains( stats.config.thresh_lvls, cfg.thresh_lvls ) ); %#ok<NASGU>

%% Plot scaled images of node p/q values

% Create figure for metric plots.
f = figure;
fullfig( f );

% Set the subplot order.
sp_order = 1 : numel( cfg.bands ) * numel( cfg.metrics );

% Loop metrics.
for m = 1 : numel( cfg.metrics )
	
	% Get current metric.
	metric = cfg.metrics{ m };
	
	% Loop bands.
	for b = 1 : numel( cfg.bands )
		
		% Get band data.
		d = eval( sprintf( 'stats.local_stats.%s;', cfg.bands{ b } ) );
		
		% Create data array
		pvals = zeros( length( cfg.nodes ), numel( cfg.thresh_lvls ) );
		palph = repmat( cfg.alpha, size( pvals ) );
		
		% Loop thresholds.
		for t = 1 : numel( cfg.thresh_lvls )
			
			% Loop nodes.
			for n = 1 : length( cfg.nodes )
				
				% Get p/q value.
				switch lower( cfg.p )
					case 'q'
						pvals( n, t )	= eval( sprintf( 'd( thresh_ind( t ) ).%s( cfg.nodes( n ) ).fdr_q;', metric ) );
					case 'p'
						pvals( n, t )	= eval( sprintf( 'd( thresh_ind( t ) ).%s( cfg.nodes( n ) ).p_uncorr;', metric ) );
					case 'fdr_p'
						pvals( n, t )	= eval( sprintf( 'd( thresh_ind( t ) ).%s( cfg.nodes( n ) ).p_uncorr;', metric ) );
						palph( n, t )	= eval( sprintf( 'd( thresh_ind( t ) ).%s( cfg.nodes( n ) ).fdr_alpha;', metric ) );
				end
			end
		end
		
		% Plot the data as a scaled image (0-1).
		subplot( numel( cfg.metrics ), numel( cfg.bands ), sp_order( b + ( ( m - 1 ) * numel( cfg.bands ) ) ) );
		im = imagesc( pvals );
		set( gca, 'XTick', 1 : t, 'XTickLabel', cfg.thresh_lvls, 'YGrid', 'off', 'FontSize', 8, 'FontName', 'Calibri', 'CLim', [ 0, 0.30 ], ...
			'TitleFontSizeMultiplier', 1.25, 'LabelFontSizeMultiplier', 1.1, 'YTick', 1 : 2 : length( cfg.nodes ), ...
			'TickLabelInterpreter', 'none', 'ColorScale', 'linear' );
		load( 'bluemap.mat' );
		colormap( bluemap );
		xlabel( 'Density threshold (%)', 'FontWeight', 'bold' );
		ylabel( 'Nodes', 'FontWeight', 'bold', 'Interpreter', 'none' );
		colorbar( 'Ticks', 0.0 : 0.05 : 0.30 );
		if m == 1
			title( cfg.b_titles{ b }, 'FontWeight', 'bold' );
		end
		
		% If enabled, mark the significant nodes/thresholds.
		if cfg.mark_sig == true
			[ sign_y, sign_x ] = find( pvals < palph );
			% [ sign_y, sign_x ] = find( pvals < cfg.alpha );
			text( gca, sign_x - 0.1726, sign_y - 0.28505, '\ast', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 6 );
		end
		
	end
end
end