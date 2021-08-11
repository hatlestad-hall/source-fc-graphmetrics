% Copyright (C) 2020-2021, Christoffer Hatlestad-Hall

function node_values = get_node_values( local_metrics )
node_values = struct;
metrics = fieldnames( local_metrics );
for m = 1 : numel( metrics )
	for n = 1 : length( local_metrics( 1 ).degree )
		for s = 1 : length( local_metrics )
			try
				eval( sprintf( 'node_values( n ).%s( s ) = local_metrics( s ).%s( n );', metrics{ m }, metrics{ m } ) );
			catch
				eval( sprintf( 'node_values( n ).%s( s ) = 0;', metrics{ m } ) );
			end
		end
	end
end
end