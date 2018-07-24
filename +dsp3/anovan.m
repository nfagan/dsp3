function outs = anovan(data, labels, spec, factors, varargin)

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
%     IN:
%       - `data` (double)
%       - `labels` (fcat)
%       - `spec` (cell array of strings, char)
%       - `factors` (cell array of strings)
%     OUT:
%       - `outs` (struct)

assert_ispair( data, labels );
assert_hascat( labels, csunion(spec, factors) );

defaults.mask = rowmask( data );
defaults.comparison_category = 'comparison';
defaults.alpha = 0.05;
defaults.descriptive_funcs = { @mean, @median, @rows, @plotlabeled.sem };
defaults.anovan_inputs = { 'display', 'off', 'varnames', factors, 'model', 'full' };
defaults.dimension = 'auto';

params = dsp3.parsestruct( defaults, varargin );
validate_params( params );

mask = params.mask;
compcat = params.comparison_category;
alpha = params.alpha;
funcs = params.descriptive_funcs;
anovan_inputs = params.anovan_inputs;
dim = params.dimension;

addcat( labels, compcat );

if ( iscell(spec) && isempty(spec) )
  alabs = one( labels' );
  I = { mask };
else
  [alabs, I] = keepeach( labels', spec, mask );
end

c_tbls = cell( size(I) );
a_tbls = cell( size(I) );

grp_func = @(x, ind) removecats(categorical(labels, x, ind));

for i = 1:numel(I)
  grps = cellfun( @(x) grp_func(x, I{i}), factors, 'un', 0 );
  
  [p, tbl, stats] = anovan( data(I{i}), grps, anovan_inputs{:} );
  
  if ( strcmp(dim, 'auto') )
    sig_dims = find( p < alpha );
    sig_dims(sig_dims > numel(factors)) = [];
  else
    sig_dims = dim;
  end
  
  if ( isempty(sig_dims) )
    continue;
  end
  
  [cc, c] = dsp3.multcompare( stats, 'dimension', sig_dims );
  
  issig = c(:, end) < alpha;
  sig_comparisons = cc(issig, :);
  
  a_tbls{i} = dsp3.anova_cell2table( tbl );
  c_tbls{i} = dsp3.multcompare_cell2table( sig_comparisons );
end

tblspec = csunion( spec, factors );

[m_tbl, ~, mlabs] = dsp3.descriptive_table( data, labels', tblspec, funcs, mask );

outs.anova_tables = a_tbls;
outs.anova_labels = alabs;
outs.comparison_tables = c_tbls;
outs.descriptive_tables = m_tbl;
outs.descriptive_labels = mlabs;

end

function validate_params(params)

if ( ischar(params.dimension) )
  assert( strcmpi(params.dimension, 'auto'), 'Dimension must be numeric, or "auto".' );
end

end