function [dat, labs] = a_summary_minus_b(data, labels, spec, a, b, func, varargin)

%   A_SUMMARY_MINUS_B -- Subtract average of `B` from average of `A`, for
%     each subset.
%
%     [D, L] = a_summary_minus_b( data, labs, spec, a, b ) subtracts an 
%     average of rows of `data` identified by label `b` from an average of 
%     rows identified by label `a`, separately for each label combination 
%     in categories identified by `spec`. `labs` is an fcat object with the
%     same number of rows as `data`. Output `D` is the result of the
%     subtraction; output `L` is an fcat object identifying rows of `D`.
%
%     [...] = a_summary_minus_b( ..., func ) uses `func` to collapse rows
%     of `data`, instead of `nanmean()`.
%
%     [...] = a_summary_minus_b( ..., mask ) draws combinations from the
%     subset of rows identified by the uint64 index vector `mask`.
%
%     IN:
%       - `data` (/T/)
%       - `labels` (fcat)
%       - `spec` (cell array of strings, char)
%       - `a` (cell array of strings, char)
%       - `b` (cell array of strings, char)
%       - `func` (function_handle) |OPTIONAL|
%       - `mask` (uint64) |OPTIONAL|
%     OUT:
%       - `dat` (/T/)
%       - `labs` (fcat)

assert_rowsmatch( data, labels );
assert_hascat( labels, spec );
assert( isa(labels, 'fcat'), 'Labels must be an fcat object; was "%s".', class(labels) );

if ( nargin < 6 || isempty(func) )
  func = @(x) nanmean( x, 1 );
end

[labs, I] = keepeach( labels', spec, varargin{:} );

dat = zeros( joinsize(I, data) );
clns = colons( ndims(data)-1 );

for i = 1:numel(I)
  a_ind = find( labels, a, I{i} );
  b_ind = find( labels, b, I{i} );
  
  summarized_a = func( rowref(data, a_ind) );
  summarized_b = func( rowref(data, b_ind) );
  
  dat(i, clns{:}) = summarized_a - summarized_b;
end

end