function outs = ranksum(data, labels, spec, a, b, varargin)

%   RANKSUM -- Wilcoxon rank sum test for equal medians, for each subset.
%
%     outs = ... ranksum( data, labels, spec, a, b, factors ) performs a 
%     two-sided rank sum test of the hypothesis that two independent 
%     samples identified by label(s) `a` and `b` come from distributions
%     with equal medians, for each subset of `data` identified by a
%     combination of labels in `spec` categories. `labels` is an fcat
%     object with the same number of rows as `data`. `outs` is a struct
%     with the following fields:
%
%       - 'rs_tables' (cell array of table) -- Mx1 cell array of t-tables
%         for the M label combinations.
%       - 'rs_labels' (fcat) -- MxN fcat object identifying rows of
%         'rs_tables'.
%       - 'descriptive_tables' (table) -- Table of descriptive statistics
%         of `data`.
%       - 'descriptive_labels (fcat) -- MxN fcat object identifying rows of
%         'descriptive_tables'.
%       - 'descriptive_specificity' (cell array of strings) -- Categories
%         used to generate descriptive statistics of `data`.
%
%     outs = ... ranksum( 'name', value ) specifies additional paired
%     inputs. Valid inputs are:
%
%       - 'mask' (double, uint64) -- Applies a mask to the data and labels
%         so that combinations are restricted to the rows identified by the
%         mask.
%       - 'descriptive_funcs' (cell array of function_handle) -- Array of
%         handles to functions used to summarize `data`. Default is {@mean,
%         @median, @rows}
%       - 'ranksum_inputs' (cell) -- Array of additional inputs to be 
%         passed to the built-in ranksum function.
%       - 'test_category' (cell array of strings, char, NaN) -- Additional
%         category(ies) (beyond `spec`) to use to generate descriptive
%         statistics of `data`. Default is NaN, in which case the
%         additional categories are chosen automatically based on the
%         categories of `a` and `b`.
%       - 'allow_missing_labels' (logical) -- If false (default) all labels 
%         in `a` and `b` must be present in the object `labels`.
%
%     IN:
%       - `data` (double)
%       - `labels` (fcat)
%       - `spec` (cell array of strings, char)
%       - `a` (cell array of strings, char)
%       - `b` (cell array of strings, char)
%     OUT:
%       - `outs` (struct)

defaults.mask = rowmask( data );
defaults.descriptive_funcs = dsp3.descriptive_funcs();
defaults.test_category = NaN;
defaults.ranksum_inputs = {};
defaults.allow_missing_labels = false;

params = dsp3.parsestruct( defaults, varargin );

mask = params.mask;
funcs = params.descriptive_funcs;
testcat = params.test_category;
ranksum_inputs = params.ranksum_inputs;

[tlabs, I] = dsp3.keepeach_or_one( labels', spec, mask );

if ( ~params.allow_missing_labels )
  assert_haslab( labels, csunion(a, b) );
end

t_tbls = cell( size(I) );

for i = 1:numel(I)
  ind_a = find( labels, a, I{i} );
  ind_b = find( labels, b, I{i} );
  
  [p, ~, stats] = ranksum( rowref(data, ind_a), rowref(data, ind_b), ranksum_inputs{:} );
  
  stats.p = p;
  
  t_tbls{i} = struct2table( stats );
end

desc_spec = spec;

if ( ~isnan(testcat) )
  desc_spec = csunion( desc_spec, testcat );
else
  desc_spec = tryadd_additional_cats( labels, desc_spec, a, b );
end

[m_tbl, ~, mlabs] = dsp3.descriptive_table( data, labels', desc_spec, funcs, mask );

outs.rs_tables = t_tbls;
outs.rs_labels = tlabs;
outs.descriptive_tables = m_tbl;
outs.descriptive_labels = mlabs;
outs.descriptive_specificity = desc_spec;

end

function spec = tryadd_additional_cats(labs, spec, a, b)
spec = tryadd_additional_cat( labs, spec, a );
spec = tryadd_additional_cat( labs, spec, b );
end

function spec = tryadd_additional_cat(labs, spec, a)

if ( ~all(haslab(labs, a)) )
  return;
end

spec = csunion( spec, whichcat(labs, a) );

end