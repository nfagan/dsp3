function [dat, labs] = a_summary_minus_b(data, labels, spec, a, b, func, mask)

if ( nargin < 6 )
  func = @(x) nanmean( x, 1 );
end

if ( nargin < 7 )
  [labs, I] = keepeach( labels', spec );
else
  [labs, I] = keepeach( labels', spec, mask );
end

dat = zeros( [numel(I), notsize(data, 1)] );
clns = colons( ndims(data)-1 );

for i = 1:numel(I)
  a_ind = find( labels, a, I{i} );
  b_ind = find( labels, b, I{i} );
  
  summarized_a = func( rowref(data, a_ind) );
  summarized_b = func( rowref(data, b_ind) );
  
  dat(i, clns{:}) = summarized_a - summarized_b;
end

end