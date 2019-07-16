function outs = signrank1(data, labels, spec, varargin)

%   SIGNRANK1 -- Wilcoxon signed rank test for zero median, for each subset.
%
%     outs = dsp3.signrank1( data, labels, spec ) performs a signed rank
%     test of the hypothesis that `data` come from a distribution whose
%     median is zero, separately for each subset of `data` identified by a
%     combination of labels in `spec` categories. `labels` is an fcat 
%     object with the same number of rows as `data`. `outs` is a struct 
%     with the following fields:
%
%       - 'sr_tables' (cell array of table) -- Mx1 cell array of sign-rank 
%         tables for the M label combinations.
%       - 'sr_labels' (fcat) -- MxN fcat object identifying rows of
%         'sr_tables'.
%       - 'descriptive_tables' (table) -- Table of descriptive statistics
%         of `data`.
%       - 'descriptive_labels (fcat) -- MxN fcat object identifying rows of
%         'descriptive_tables'.
%       - 'descriptive_specificity' (cell array of strings) -- Categories
%         used to generate descriptive statistics of `data`.
%
%     outs = dsp3.signrank1( 'name', value ) specifies additional paired
%     inputs. Valid inputs are:
%
%       - 'mask' (double, uint64) -- Applies a mask to the data and labels
%         so that combinations are restricted to the rows identified by the
%         mask.
%       - 'descriptive_funcs' (cell array of function_handle) -- Array of
%         handles to functions used to summarize `data`. Default is {@mean,
%         @median, @rows}
%
%     See also dsp3.signrank2, dsp3.ranksum, dsp3.anova1

defaults.mask = rowmask( data );
defaults.descriptive_funcs = dsp3.descriptive_funcs();

params = dsp3.parsestruct( defaults, varargin );

assert_ispair( data, labels );

mask = params.mask;
funcs = params.descriptive_funcs;

[slabs, I] = dsp3.keepeach_or_one( labels', spec, mask );

signrank_tbls = cell( numel(I), 1 );

for i = 1:numel(I)
  [p, ~, stats] = signrank( data(I{i}) );
  stats.p = p;
  
  signrank_tbls{i} = struct2table( stats );
end

[m_tbl, ~, mlabs] = dsp3.descriptive_table( data, labels', spec, funcs, mask );

outs.sr_tables = signrank_tbls;
outs.sr_labels = slabs;
outs.descriptive_tables = m_tbl;
outs.descriptive_labels = mlabs;
outs.descriptive_specificity = spec;

end