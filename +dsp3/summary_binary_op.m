function [dat, labs] = summary_binary_op(data, labels, spec, a, b, opfunc, sfunc, varargin)

%   SUMMARY_BINARY_OP -- Apply binary operation to data subsets.
%
%     [newdata, newlabs] = summary_binary_op( data, labels, spec, a, b, opfunc )
%     performs the binary operation `opfunc` on subsets of data identified
%     by the label combinations `a` and `b`, first averaging across each
%     subset, separately for each combination of labels in `spec` 
%     categories.
%
%     ... = summary_binary_op( ..., sfunc ) uses `sfunc` to collapse the
%     subsets, instead of `@nanmean`.
%
%     ... = summary_binary_op( ..., mask ) restricts subsets to the rows
%     contained in the uint64 index vector `mask`.
%
%     This function is commonly used to subtract or divide subset-means 
%
%     EX //
%
%     f = fcat.example();
%     d = fcat.example( 'smalldata' );
%
%     % for each 'monkey', subtract the mean of 'scrambled' from the
%     % mean of 'outdoors'.
%     [data, labels] = dsp3.summary_binary_op( d, f', 'monkey', 'outdoors' ...
%       , 'scrambled', @minus )
%
%     See also fcat/findall
%
%     IN:
%       - `data` (double)
%       - `labels` (fcat)
%       - `spec` (cell array of strings, char)
%       - `a` (cell array of strings, char)
%       - `b` (cell array of strings, char)
%       - `opfunc` (function_handle)
%       - `sfunc` (function_handle)
%       - `mask` (uint64, double) |OPTIONAL|
%     OUT:
%       - `dat` (double)
%       - `labs` (fcat)       

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