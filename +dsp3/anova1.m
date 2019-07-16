function outs = anova1(data, labels, spec, factor, varargin)

%   ANOVA1 -- 1-Way ANOVA, for each subset.
%
%     outs = ... anova1( data, labels, spec, factor ) runs a 1-way ANOVA
%     for the group `factor`, for each subset of `data` identified by a
%     combination of labels in `spec` categories. `labels` is an fcat
%     object with the same number of rows as `data`. `outs` is a struct
%     with the following fields:
%
%       - 'anova_tables' (cell array of table) -- Mx1 cell array of anova
%         tables for the M label combinations.
%       - 'anova_labels' (fcat) -- MxN fcat object identifying rows of
%         'anova_tables'.
%       - 'comparison_tables' (cell array of table) -- Mx1 cell array of
%         tables for the significant multiple comparisons for the M label
%         combinations. Rows of 'comparison_tables' are identified by
%         'anova_labels'.
%       - 'descriptive_tables' (table) -- Table of descriptive statistics
%         of `data`.
%       - 'descriptive_labels (fcat) -- MxN fcat object identifying rows of
%         'descriptive_tables'.
%
%     outs = ... anova1( 'name', value ) specifies additional paired
%     inputs. Valid inputs are:
%
%       - 'mask' (double, uint64) -- Applies a mask to the data and labels
%         so that combinations are restricted to the rows identified by the
%         mask.
%       - 'alpha' (double) -- Significance threshold. Default is 0.05.
%       - 'descriptive_funcs' (cell array of function_handle) -- Array of
%         handles to functions used to summarize `data`. Default is {@mean,
%         @median, @rows}
%
%     Specify `spec` as an empty cell array ({}) to perform the analysis
%     once on the whole set of `data`.
%
%     See also dsp3.ttest2, dsp3.anovan, dsp3.signrank1

assert_ispair( data, labels );
assert_hascat( labels, csunion(spec, factor) );

defaults.mask = rowmask( data );
defaults.comparison_category = 'comparison';
defaults.alpha = 0.05;
defaults.descriptive_funcs = dsp3.descriptive_funcs();
defaults.remove_nonsignificant_comparisons = true;

params = dsp3.parsestruct( defaults, varargin );

mask = params.mask;
compcat = params.comparison_category;
alpha = params.alpha;
funcs = params.descriptive_funcs;

addcat( labels, compcat );

[alabs, I] = dsp3.keepeach_or_one( labels', spec, mask );

c_tbls = cell( size(I) );
a_tbls = cell( size(I) );
is_anova_significant = false( numel(I), 1 );

parfor i = 1:numel(I)
  grp = removecats( categorical(labels, factor, I{i}) );
  
  [p, tbl, stats] = anova1( data(I{i}), grp, 'off' );
  
  if ( ~isnan(p) && stats.df > 0 )
    [cc, c] = dsp3.multcompare( stats );
  
    if ( params.remove_nonsignificant_comparisons )
      issig = c(:, end) < alpha;
      cc = cc(issig, :);
    end
  else
    cc = cell( 0, 6 );
  end
  
  a_tbls{i} = dsp3.anova_cell2table( tbl );
  c_tbls{i} = dsp3.multcompare_cell2table( cc );
  is_anova_significant(i) = p < alpha;
end

tblspec = csunion( spec, factor );

[m_tbl, ~, mlabs] = dsp3.descriptive_table( data, labels', tblspec, funcs, mask );

outs.anova_tables = a_tbls;
outs.anova_labels = alabs;
outs.comparison_tables = c_tbls;
outs.descriptive_tables = m_tbl;
outs.descriptive_labels = mlabs;
outs.is_anova_significant = is_anova_significant;

end