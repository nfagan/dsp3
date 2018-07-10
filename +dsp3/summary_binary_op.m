function [dat, labs] = summary_binary_op( data, labels, spec, a, b, opfunc, sfunc, mask )

assert( rowsmatch(data, labels), 'Number of rows of data and labels must match.' );
assert( isa(labels, 'fcat'), 'Labels must be an fcat object; was "%s".', class(labels) );

if ( nargin < 7 || isempty(sfunc) )
  sfunc = @(x) nanmean( x, 1 );
end

if ( nargin < 8 )
  [labs, I] = keepeach( labels', spec );
else
  [labs, I] = keepeach( labels', spec, mask );
end

dat = zeros( joinsize(I, data) );
clns = colons( ndims(data)-1 );

for i = 1:numel(I)
  a_ind = find( labels, a, I{i} );
  b_ind = find( labels, b, I{i} );
  
  summarized_a = sfunc( rowref(data, a_ind) );
  summarized_b = sfunc( rowref(data, b_ind) );
  
  dat(i, clns{:}) = opfunc( summarized_a, summarized_b );
end

end