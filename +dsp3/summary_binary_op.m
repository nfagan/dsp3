function [dat, labs] = summary_binary_op(data, labels, spec, a, b, opfunc, sfunc, varargin)

assert_ispair( data, labels );
assert_hascat( labels, spec );

if ( nargin < 7 || isempty(sfunc) )
  sfunc = @(x) nanmean( x, 1 );
end

[labs, I] = keepeach( labels', spec, varargin{:} );

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