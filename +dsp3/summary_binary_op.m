function [dat, labs, I] = summary_binary_op(data, labels, spec, a, b, opfunc, sfunc, varargin)

%   SUMMARY_BINARY_OP -- Apply binary operation to data subsets.
%
%     [newdata, newlabs] = dsp3.summary_binary_op( data, labels, spec, a, b, opfunc )
%     applies the binary operation `opfunc` to subsets of data identified
%     by the label combinations `a` and `b`, first averaging across each
%     subset, separately for each combination of labels in `spec` 
%     categories.
%
%     ... = dsp3.summary_binary_op( ..., sfunc ) uses `sfunc` to collapse the
%     subsets, instead of `@nanmean`.
%
%     ... = dsp3.summary_binary_op( ..., mask ) restricts subsets to the rows
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
  
  summarized_a = sfunc( data(a_ind, clns{:}) );
  summarized_b = sfunc( data(b_ind, clns{:}) );
  
  dat(i, clns{:}) = opfunc( summarized_a, summarized_b );
end

end