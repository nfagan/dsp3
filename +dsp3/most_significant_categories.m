function c = most_significant_categories(labs, n)

%   MOST_SIGNIFICANT_CATEGORIES -- Non-uniform categories with fewest unique entries.
%
%     cs = dsp3.most_significant_categories( labels, n ); returns the `n`
%     most significant categories in the fcat object `labels`. A maximally
%     significant category is one with the fewest number of unique entries,
%     out of the set of categories that are non-uniform (i.e., have at
%     least two unique entries). Categories in `cs` are sorted in ascending
%     order with respect to the number of unique entries in each.
%
%     If fewer than `n` categories are non-uniform, then `cs` will contain 
%     some non-uniform categories. If `n` is larger than the number of
%     categories in `labels`, `cs` will be the complete set of categories
%     of `labels` (i.e., no error is thrown).
%
%     c = dsp3.most_significant_categories( labels ); returns the most
%     significant category in `labels`, according to the definition above.
%
%     See also fcat, dsp3.nonun_or_all, dsp3.nonun_or_other

if ( nargin < 2 )
  n = 1;
end

cats = getcats( labs, 'nonuniform' );

if ( n > numel(cats) )
  cats = getcats( labs );
end

n = min( n, numel(cats) );

ns = zeros( 1, numel(cats) );

for i = 1:numel(cats)
  ns(i) = numel( incat(labs, cats{i}) );  
end

[~, sorted_I] = sort( ns );

sorted_cats = cats(sorted_I);

c = sorted_cats(1:n);

end