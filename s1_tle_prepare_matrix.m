%% Step 1: Prepare the connectivity matrix
%
% Created:		27 Apr 2020
% Last edit:	08 Apr 2021
%
% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall
%
% ----
%
% The output from this step is a comprehensive connectivity matrix where all subjects are included.
% A <node x node x subject> matrix is created for each frequency band.
%
% The output matrices is compatible with the NBS toolbox.
%
%

%% Configuration

% Frequency bands to extract. One *.mat file is created for each.
cfg.bands		= { 'Theta', 'Alpha', 'Beta', 'Gamma' };

% Total number of nodes.
cfg.nb_nodes	= 90;

% Connectivity measure to extract ('plv' or 'ciplv').
cfg.conn		= 'plv';

% AAL atlas file (must be on path).
cfg.atlas		= 'AAL';

% AAL regions to include (nodes; see ch_aal_regions for options).
cfg.regions		= 'sn';

% Option to save NBS compatible matrix.
cfg.nbs			= 'on';

% Option to set the main diagonal to 1 (for NBS compatibility?).
cfg.nbs_comp	= 'on';

%% Preparation

% Add support functions to MATLAB path.
AddPath( 'support' );

%% Input and output selection

% Select the input files (*.mat).
files = ch_selectfiles( 'mat', 'on' );

% Select the output directory.
output_dir	= [ uigetdir( sprintf( '%s/../', files( 1 ).folder ), 'Select output directory' ) '/' ];
if numel( output_dir ) < 3, return; end

%% Prepare connectivity matrix (node x node x subject)

% Get the specified AAL nodes.
if ~strcmpi( cfg.regions, 'all' )
	nodes = ch_aal_regions( cfg.regions );
else
	nodes = 1 : cfg.nb_nodes;
end

% Load the AAL atlas file, and extract just the selected nodes.
tmp_atlas = load( cfg.atlas );
atlas = eval( sprintf( 'tmp_atlas.%s', char( fieldnames( tmp_atlas ) ) ) );
atlas = atlas( nodes );

% Loop all specified frequency bands.
for band = 1 : numel( cfg.bands )
	
	% Create the frequency band's matrix, for memory allocation.
	band_conn				= struct(  );
	band_conn.freq_band		= cfg.bands{ band };
	band_conn.conn_matrix	= zeros( length( nodes ), length( nodes ), numel( files ) );
	band_conn.avg_conn		= zeros( numel( files ), 1 );
	band_conn.subjects		= cell( numel( files ), 1 );
	band_conn.atlas			= atlas;

	% Loop all the subjects.
	for subject = 1 : numel( files )
	
		% Load the subject data.
		subj_data = load( sprintf( '%s/%s', files( subject ).folder, files( subject ).name ) );
		
		% Add the subject's data to the band connectivity struct.
		if strcmpi( cfg.conn, 'ciplv' )
			band_conn.conn_matrix( :, :, subject )	= double( subj_data.band( band ).ciplv_rms( nodes, nodes ) );
		else
			band_conn.conn_matrix( :, :, subject )	= double( subj_data.band( band ).plv_rms( nodes, nodes ) );
		end
		band_conn.subjects{ subject }			= subj_data.subject;
		
		% Compute the average connectivity.
		upper_tri						= triu( band_conn.conn_matrix( :, :, subject ), 1 );
		upper_tri( upper_tri == 0 )		= NaN;
		band_conn.avg_conn( subject )	= mean( mean( upper_tri, 'omitnan' ), 'omitnan' );
		
		% If enabled, set the main diagonal of the connectivity matrix to 1.
		if strcmpi ( cfg.nbs_comp, 'on' )
			w										= band_conn.conn_matrix( :, :, subject );
			w( 1 : length( nodes ) + 1 : end )				= 1;
			band_conn.conn_matrix( :, :, subject )	= w;
		end
	end
	
	% If enabled, save the connectivity matrix for NBS use.
	if strcmpi( cfg.nbs, 'on' )
		if ~exist( sprintf( '%s%s/', output_dir, 'NBS' ), 'dir' )
			mkdir( sprintf( '%s%s/', output_dir, 'NBS' ) );
		end
		conn_matrix = band_conn.conn_matrix;
		save( sprintf( '%s%s/%s.mat', output_dir, 'NBS', cfg.bands{ band } ), 'conn_matrix' );
	end
	
	% Save the frequency band struct.
	save( sprintf( '%s%s.mat', output_dir, cfg.bands{ band } ), '-struct', 'band_conn' );
end
