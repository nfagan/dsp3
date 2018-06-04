function progress(n, N, n_indents, prefix)

if ( nargin < 3 )
  n_indents = 0;
end

if ( nargin < 4 )
  prefix = '';
end

str = repmat( '\t', 1, n_indents );

if ( isempty(prefix) )
  fprintf( ['\n', str, ' %d of %d'], n, N );
else
  fprintf( ['\n', str, '%s: %d of %d'], prefix, n, N );
end

end