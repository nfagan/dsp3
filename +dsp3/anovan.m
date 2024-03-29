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
%     See also dsp3.anova1, dsp3.ttest2, dsp3.signrank2

assert_ispair( data, labels );
assert_hascat( labels, csunion(spec, factors) );

defaults.mask = rowmask( data );
defaults.comparison_category = 'comparison';
defaults.alpha = 0.05;
defaults.descriptive_funcs = dsp3.descriptive_funcs();
defaults.anovan_inputs = { 'display', 'off', 'varnames', factors, 'model', 'full' };
defaults.dimension = 'auto';
defaults.remove_nonsignificant_comparisons = true;
defaults.include_per_factor_descriptives = false;
defaults.include_significant_factor_descriptives = false;
defaults.run_multcompare = true;

params = dsp3.parsestruct( defaults, varargin );
validate_params( params );

mask = params.mask;
compcat = params.comparison_category;
alpha = params.alpha;
funcs = params.descriptive_funcs;
anovan_inputs = params.anovan_inputs;
dim = params.dimension;

addcat( labels, compcat );

[alabs, I] = dsp3.keepeach_or_one( labels', spec, mask );

c_tbls = cell( size(I) );
a_tbls = cell( size(I) );

grp_func = @(x, ind) removecats(categorical(labels, x, ind));

for i = 1:numel(I)
  grps = cellfun( @(x) grp_func(x, I{i}), factors, 'un', 0 );
  
  [p, tbl, stats] = anovan( data(I{i}), grps, anovan_inputs{:} );
  
  if ( strcmp(dim, 'auto') )
    sig_dims = find( p < alpha );
    
    if ( numel(factors) == 2 && any(sig_dims == 2) )
      sig_dims = 1:2;
    else
      sig_dims(sig_dims > numel(factors)) = [];
    end
    
  elseif ( strcmp(dim, 'significant') )
    sig_dims = find( p < alpha );
    
  else
    sig_dims = dim;
  end
  
  a_tbls{i} = dsp3.anova_cell2table( tbl );
  
  if ( isempty(sig_dims) && params.remove_nonsignificant_comparisons )
    continue;
  end
  
  if ( params.run_multcompare )
    [cc, c] = dsp3.multcompare( stats, 'dimension', sig_dims );

    issig = c(:, end) < alpha;

    if ( params.remove_nonsignificant_comparisons )
      use_comparisons = cc(issig, :);
    else
      use_comparisons = cc;
    end

    c_tbls{i} = dsp3.multcompare_cell2table( use_comparisons );
  end
end

if ( params.include_significant_factor_descriptives )
  m_tbl = {};
  mlabs = {};
  for i = 1:numel(a_tbls)
    p_factors = vertcat( a_tbls{i}.Prob_F{:} );
    factor_strs = a_tbls{i}.Source(1:end-2);
    sig_factors = factor_strs(p_factors < params.alpha);
    
    for j = 1:numel(sig_factors)
      sig_factor_combs = strsplit( sig_factors{j}, '*' );
      [curr_tbl, ~, curr_labs] = dsp3.descriptive_table( ...
        data, labels', sig_factor_combs, funcs, I{i} );
      m_tbl{end+1, 1} = curr_tbl;
      mlabs{end+1, 1} = curr_labs;
    end
  end
else
  tblspec = csunion( spec, factors );
  [m_tbl, ~, mlabs] = dsp3.descriptive_table( data, labels', tblspec, funcs, mask );

  if ( params.include_per_factor_descriptives )
    m_tbl = { m_tbl };
    mlabs = { mlabs };

    for i = 1:numel(factors)
      use_spec = csunion( spec, factors{i} );

      [d_tbl, ~, dlabs] = dsp3.descriptive_table( data, labels', use_spec, funcs, mask );

      m_tbl{end+1, 1} = d_tbl;
      mlabs{end+1, 1} = dlabs;
    end
  end
end

outs.anova_tables = a_tbls;
outs.anova_labels = alabs;
outs.comparison_tables = c_tbls;
outs.descriptive_tables = m_tbl;
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