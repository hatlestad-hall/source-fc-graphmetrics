% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

% Input alternatives for 'region' (add suffix '-l' or '-r' for left or right only, respectively).
%
% Frontal lobe:			'frontal'
%	Regions, left:	3, 5, 7, 9, 11, 13, 15, 19, 21, 23, 25, 27, 69
%	Regions, right:	4, 6, 8, 10, 12, 14, 16, 20, 22, 24, 26, 28, 70
%
% Temporal lobe:		'temporal'
%	Regions, left:	79, 81, 85, 89
%	Regions, right:	80, 82, 86, 90
%
% Parietal lobe:		'parietal'
%	Regions, left:	59, 61, 63, 65, 67
%	Regions, right:	60, 62, 64, 66, 68
%
% Occipital lobe:		'occipital'
%	Regions, left:	43, 45, 47, 49, 51, 53, 55
%	Regions, right:	44, 46, 48, 50, 52, 54, 56
%
% Central region:		'central'
%	Regions, left:	1, 17, 57
%	Regions, right:	2, 18, 58
%
% Limbic lobe:			'limbic'
%	Regions, left:	31, 33, 35, 37, 39, 83, 87
%	Regions, right:	32, 34, 36, 38, 40, 84, 88
%
% Subcortical nuclei:	'subcortical'
%	Regions, left:	41, 71, 73, 75, 77
%	Regions, right:	42, 72, 74, 76, 78
%
% Insular cortex:		'insula'
%	Regions, left:	29
%	Regions, right:	30
%
% Default mode network:	'dmn'
%	Original:
%		Regions, left:	5, 7, 9, 27, 31, 35, 37, 39, 61, 65, 67, 81, 83, 85, 87, 89
%		Regions, right: 6, 8, 10, 28, 32, 36, 38, 40, 62, 66, 68, 82, 84, 86, 88, 90
%
%	Revised:
%		Regions, left:	3, 5, 7, 9,  23, 27, 31, 35, 37, 39, 63, 65, 67, 87
%		Regions, right: 4, 6, 8, 10, 24, 28, 32, 36, 38, 40, 64, 66, 68, 88
%
% Central-executive network: 'cen'
%	Regions, left:	3, 7, 13, 59, 61, 63, 67, 89
%	Regions, right:	4, 8, 14, 60, 62, 64, 68, 90
%
% Salience network: 'sn'
%	Regions, left:	29, 31, 83, 87, 89
%	Regions, right:	30, 32, 84, 88, 90
%
% Cortical regions:		'cortical'
%	All regions except those listed under 'subcortical'.
%
function [ nodes, nodes_bin ] = ch_aal_regions( region )

% If input argument is string or character, place it in a cell array.
if ischar( region ) || isstring( region )
	region = { region };
end

% Define the output array, 'nodes'.
nodes_bin = false( 90, 1 );

% Loop through all entries of 'region'.
for r = 1 : numel( region )
	region_nodes = [ ];
	
	% Frontal lobe.
	if startsWith( region{ r }, 'frontal', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 3, 5, 7, 9, 11, 13, 15, 19, 21, 23, 25, 27, 69 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 4, 6, 8, 10, 12, 14, 16, 20, 22, 24, 26, 28, 70 ];
		else
			region_nodes = [ 3, 5, 7, 9, 11, 13, 15, 19, 21, 23, 25, 27, 69, 4, 6, 8, 10, 12, 14, 16, 20, 22, 24, 26, 28, 70 ];
		end
	end
	
	% Temporal lobe.
	if startsWith( region{ r }, 'temporal', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 79, 81, 85, 89 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 80, 82, 86, 90 ];
		else
			region_nodes = [ 79, 81, 85, 89, 80, 82, 86, 90 ];
		end
	end
	
	% Parietal lobe.
	if startsWith( region{ r }, 'parietal', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 59, 61, 63, 65, 67 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 60, 62, 64, 66, 68 ];
		else
			region_nodes = [ 59, 61, 63, 65, 67, 60, 62, 64, 66, 68 ];
		end
	end
	
	% Occipital lobe.
	if startsWith( region{ r }, 'occipital', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 43, 45, 47, 49, 51, 53, 55 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 44, 46, 48, 50, 52, 54, 56 ];
		else
			region_nodes = [ 43, 45, 47, 49, 51, 53, 55, 44, 46, 48, 50, 52, 54, 56 ];
		end
	end
	
	% Central region.
	if startsWith( region{ r }, 'central', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 1, 17, 57 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 2, 18, 58 ];
		else
			region_nodes = [ 1, 17, 57, 2, 18, 58 ];
		end
	end
	
	% Limbic lobe.
	if startsWith( region{ r }, 'limbic', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 31, 33, 35, 37, 39, 83, 87 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 32, 34, 36, 38, 40, 84, 88 ];
		else
			region_nodes = [ 31, 33, 35, 37, 39, 83, 87, 32, 34, 36, 38, 40, 84, 88 ];
		end
	end
	
	% Subcortical nuclei.
	if startsWith( region{ r }, 'subcortical', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 41, 71, 73, 75, 77 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 42, 72, 74, 76, 78 ];
		else
			region_nodes = [ 41, 71, 73, 75, 77, 42, 72, 74, 76, 78 ];
		end
	end
	
	% Insular cortex.
	if startsWith( region{ r }, 'insula', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = 29;
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = 30;
		else
			region_nodes = [ 29, 30 ];
		end
	end
	
	% Cortical regions.
	if startsWith( region{ r }, 'cortical', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 3, 5, 7, 9, 11, 13, 15, 19, 21, 23, 25, 27, 69, 79, 81, 85, 89, 59, 61, 63, 65, 67, ...
				43, 45, 47, 49, 51, 53, 55, 1, 17, 57, 31, 33, 35, 37, 39, 83, 87, 29 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 4, 6, 8, 10, 12, 14, 16, 20, 22, 24, 26, 28, 70, 80, 82, 86, 90, 60, 62, 64, 66, 68, ...
				44, 46, 48, 50, 52, 54, 56, 2, 18, 58, 32, 34, 36, 38, 40, 84, 88, 30 ];
		else
			region_nodes = [ 3, 5, 7, 9, 11, 13, 15, 19, 21, 23, 25, 27, 69, 79, 81, 85, 89, 59, 61, 63, 65, 67, ...
				43, 45, 47, 49, 51, 53, 55, 1, 17, 57, 31, 33, 35, 37, 39, 83, 87, 29, ...
				4, 6, 8, 10, 12, 14, 16, 20, 22, 24, 26, 28, 70, 80, 82, 86, 90, 60, 62, 64, 66, 68, ...
				44, 46, 48, 50, 52, 54, 56, 2, 18, 58, 32, 34, 36, 38, 40, 84, 88, 30 ];
		end
	end
	
	% Default mode network.
	if startsWith( region{ r }, 'dmn', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 3, 5, 7, 9,  23, 27, 31, 35, 37, 39, 63, 65, 67, 87 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 4, 6, 8, 10, 24, 28, 32, 36, 38, 40, 64, 66, 68, 88 ];
		else
			region_nodes = [ 3, 5, 7, 9,  23, 27, 31, 35, 37, 39, 63, 65, 67, 87, ...
				4, 6, 8, 10, 24, 28, 32, 36, 38, 40, 64, 66, 68, 88 ];
		end
	end
	
	% Central executive network.
	if startsWith( region{ r }, 'cen', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 3, 7, 13, 59, 61, 63, 67, 89 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 4, 8, 14, 60, 62, 64, 68, 90 ];
		else
			region_nodes = [ 3, 7, 13, 59, 61, 63, 67, 89, ...
				4, 8, 14, 60, 62, 64, 68, 90 ];
		end
	end
	
	% Salience network.
	if startsWith( region{ r }, 'sn', 'IgnoreCase', true )
		if endsWith( region{ r }, '-l', 'IgnoreCase', true )
			region_nodes = [ 29, 31, 83, 87, 89 ];
		elseif endsWith( region{ r }, '-r', 'IgnoreCase', true )
			region_nodes = [ 30, 32, 84, 88, 90 ];
		else
			region_nodes = [ 29, 31, 83, 87, 89, ...
				30, 32, 84, 88, 90 ];
		end
	end
	
	
	% Add the region nodes to the output array, 'nodes'.
	nodes_bin( region_nodes ) = 1;
	
end

% Get the selected regions' indices.
nodes = find( nodes_bin == 1 );

end