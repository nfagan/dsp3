function outs = anovan2(data, labels, spec, factors, varargin)

%   ANOVAN -- N-Way ANOVA, for each subset.
%
%     outs = ... anovan( data, labels, spec, factors ) runs an N-way ANOVA
%     for the N `factors`, for each subset of `data` identified by a
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
%     outs = ... anovan( 'name', value ) specifies additional paired
%     inputs. Valid inputs are:
%
%       - 'mask' (double, uint64) -- Applies a mask to the data and labels
%         so that combinations are restricted to the rows identified by the
%         mask.
%       - 'alpha' (double) -- Significance threshold. Default is 0.05.
%       - 'descriptive_funcs' (cell array of function_handle) -- Array of
%         handles to functions used to summarize `data`. Default is {@mean,
%         @median, @rows}
%       - 'anovan_inputs' (cell) -- Array of additional inputs to be passed
%         to the built-in anovan function.
%       - 'dimension' (char, double) -- Dimension across which multiple
%         comparisons will be calculated. Default is 'auto', in which case
%         dimensions are chosen based on the significant factors of the
%         model.
%
%     See also dsp3.anova1, dsp3.ttest2, dsp3.signrank2

factors = cellstr( factors );
for i = 1:numel(factors)
  if ( any(factors{i} == '*') )
    error( 'Factor names cannot contain reserved symbol `*`.' );
  end
end

assert_ispair( data, labels );
assert_hascat( labels, csunion(spec, factors) );

defaults.mask = rowmask( data );
defaults.comparison_category = 'comparison';
defaults.alpha = 0.05;
defaults.descriptive_funcs = dsp3.descriptive_funcs();
defaults.anovan_inputs = { 'display', 'off', 'varnames', factors, 'model', 'full' };
defaults.dimension = 'auto';
defaults.only_significant_factor_comparisons = true;
defaults.include_per_factor_descriptives = false;
defaults.remove_nonsignificant_comparisons = false;

params = dsp3.parsestruct( defaults, varargin );
validate_params( params );

mask = params.mask;
compcat = params.comparison_category;
alpha = params.alpha;
funcs = params.descriptive_funcs;
anovan_inputs = params.anovan_inputs;

addcat( labels, compcat );

[alabs, I] = dsp3.keepeach_or_one( labels', spec, mask );

c_tbls = cell( size(I) );
a_tbls = cell( size(I) );

grp_func = @(x, ind) removecats(categorical(labels, x, ind));

for i = 1:numel(I)
  grps = cellfun( @(x) grp_func(x, I{i}), factors, 'un', 0 );
  [p, tbl, stats] = anovan( data(I{i}), grps, anovan_inputs{:} );
  a_tbls{i} = dsp3.anova_cell2table( tbl );
  
  sig_factors = find( p < alpha );
  
  if ( params.only_significant_factor_comparisons )
    compare_factors = sig_factors;
  else
    compare_factors = 1:numel(p);
  end
  
  factor_names = tbl(2:end-2, 1);
  scalar_factors = factor_names(1:numel(factors));
  scalar_indices = arrayfun( @(x) x, 1:numel(factors), 'un', 0 );
  interactions = cellfun( @(x) strsplit(x, '*'), factor_names(numel(factors)+1:end), 'un', 0 );
  interaction_indices = cellfun( @(x) find(ismember(scalar_factors, x)), interactions, 'un', 0 );
  all_indices = [ scalar_indices(:); interaction_indices(:) ];
  compare_indices = all_indices(compare_factors);  
  
  compare_tbls = cell( numel(compare_indices), 1 );
  for j = 1:numel(compare_indices)
    [cc, c] = dsp3.multcompare( stats, 'dimension', compare_indices{j} );
    issig = c(:, end) < alpha;

    if ( params.remove_nonsignificant_comparisons )
      use_comparisons = cc(issig, :);
    else
      use_comparisons = cc;
    end
    
    compare_tbls{j} = dsp3.multcompare_cell2table( use_comparisons );
  end
  
  c_tbls{i} = vertcat( compare_tbls{:} );
end

m_tbls = {};
mlabs = {};

for i = 1:numel(factors)
  inds = nchoosek( 1:numel(factors), i );

  for j = 1:size(inds, 1)
    use_spec = csunion( spec, factors(inds(j, :)) );
    [d_tbl, ~, dlabs] = dsp3.descriptive_table( data, labels', use_spec, funcs, mask );
    m_tbls{end+1, 1} = d_tbl;
    mlabs{end+1, 1} = dlabs;
  end
end

outs.anova_tables = a_tbls;
outs.anova_labels = alabs;
outs.comparison_tables = c_tbls;
outs.descriptive_tables = m_tbls;
outs.descriptive_labels = mlabs;
outs.each = spec;
outs.factors = factors;
outs.source_I = I;

end

function params = validate_params(params)

if ( ischar(params.dimension) )
  params.dimension = validatestring( params.dimension, {'auto', 'significant'} ...
    , mfilename );
end

end