% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

% Central region:
%	Left:	1, 17, 57
%	Right:	2, 18, 58

% Frontal lobe - lateral surface:
%	Left:	3, 7, 11, 13
%	Right:	4, 8, 12, 14

% Frontal lobe - medial surface:
%	Left:	19, 23, 69
%	Right:	20, 24, 70

% Frontal lobe - orbital surface:
%	Left:	5, 9, 15, 21, 25, 27
%	Right:	6, 10, 16, 22, 26, 28

% Temporal lobe - lateral surface:
%	Left:	79, 81, 85, 89
%	Right:	80, 82, 86, 90

% Temporal lobe - medial surface (limbic lobe)
%	Left:	83, 87
%	Right:	84, 88

% Parietal lobe - lateral surface:
%	Left:	59, 61, 63, 65
%	Right:	60, 62, 64, 66

% Precuneus (parietal lobe - medial surface):
%	Left:	67
%	Right:	68

% Occipital lobe - lateral surface:
%	Left:	49, 51, 53
%	Right:	50, 52, 54

% Occipital lobe - medial and inferior surfaces:
%	Left:	43, 45, 47, 55
%	Right:	44, 46, 48, 56

% Cingulate (posterior, middle and anterior):
%	Left:	31, 33, 35
%	Right:	32, 34, 36

% Hippocampus (and parahippocampus):
%	Left:	37, 39
%	Right:	38, 40

% Insula:
%	Left:	29
%	Right:	30

function [ merged, atlas ] = ch_aal_merge( conn, cfg )

%% Configuration

if nargin < 2
	cfg.regions = { ...
		[ 1, 17, 57 ], [ 2, 18, 58 ], ...							% Central region
		[ 3, 7, 11, 13 ], [4, 8, 12, 14 ] ...						% Frontal lobe - lateral surface
		[ 19, 23, 69 ], [ 20, 24, 70 ], ...							% Frontal lobe - medial surface
		[ 5, 9, 15, 21, 25, 27 ], [ 6, 10, 16, 22, 26, 28 ], ...	% Frontal lobe - orbital surface
		[ 79, 81, 85, 89 ], [ 80, 82, 86, 90 ], ...					% Temporal lobe - lateral surface
		[ 83, 87 ], [ 84, 88 ], ...									% Temporal lobe - medial surface (limbic lobe)
		[ 59, 61, 63, 65 ], [ 60, 62, 64, 66 ], ...					% Parietal lobe - lateral surface
		67, 68, ...													% Precuneus (parietal lobe - medial surface)
		[ 49, 51, 53 ], [ 50, 52, 54 ], ...							% Occipital lobe - lateral surface
		[ 43, 45, 47, 55 ], [ 44, 46, 48, 56 ], ...					% Occipital lobe - medial and inferior surfaces
		[ 31, 33, 35 ], [ 32, 34, 36 ], ...							% Cingulate (posterior, middle and anterior)
		[ 37, 39 ], [ 38, 40 ], ...									% Hippocampus (and parahippocampus)
		29, 30 };													% Insula
	
	cfg.names = { ...
		'Left central region',							'Right central region', ...
		'Left frontal lateral surface',					'Right frontal lateral surface', ...
		'Left frontal medial surface',					'Right frontal medial surface', ...
		'Left frontal orbital surface',					'Right frontal orbital surface', ...
		'Left temporal lateral surface',				'Right temporal lateral surface', ...
		'Left temporal medial surface',					'Right temporal medial surface', ...
		'Left parietal lateral surface',				'Right parietal lateral surface', ...
		'Left precuneus',								'Right precuneus', ...
		'Left occipital lateral surface',				'Right occipital lateral surface', ...
		'Left occipital medial and inferior surfaces',	'Right occipital medial and inferior surfaces', ...
		'Left cingulum',								'Right cingulum', ...
		'Left hippocampus',								'Right hippocampus', ...
		'Left insula',									'Right insula' };
	
	cfg.labels = { ...
		'L_CR',			'R_CR', ...
		'L_FL',			'R_FL', ...
		'L_FM',			'R_FM', ...
		'L_FO',			'R_FO', ...
		'L_TL',			'R_TL', ...
		'L_TM',			'R_TM', ...
		'L_PL',			'R_PL', ...
		'L_PQ',			'R_PQ', ...
		'L_OL',			'R_OL', ...
		'L_OMI',		'R_OMI', ...
		'L_CIN',		'R_CIN', ...
		'L_HIP',		'R_HIP', ...
		'L_INS',		'R_INS' };
end
%% Merge regions

% Create the matrix in which to fill in the merged regions.
merged = zeros( numel( cfg.regions ), numel( cfg.regions ) );

% Compute the connectivity values of the merged regions.
for i = 1 : numel( cfg.regions )
	for j = 1 : numel( cfg.regions )
		merged( i, j ) = mean( conn( cfg.regions{ i }, cfg.regions{ j } ), 'all' );
	end
end

% Create the 'merged regions' atlas.
atlas = struct( 'index', cell( numel( cfg.regions ), 1 ), 'name', cell( numel( cfg.regions ), 1 ), ...
	'abbrev', cell( numel( cfg.regions ), 1 ), 'label', cell( numel( cfg.regions ), 1 ) );
for a = 1 : numel( cfg.regions )
	atlas( a ).index	= cfg.regions{ a };
	atlas( a ).name		= cfg.names{ a };
	atlas( a ).abbrev	= cfg.labels{ a };
	atlas( a ).label	= cfg.labels{ a };
end

end