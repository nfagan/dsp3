function outs = anovan(data, labels, spec, factors, varargin)

assert_ispair( data, labels );
assert_hascat( labels, csunion(spec, factors) );

defaults.mask = rowmask( data );
defaults.comparison_category = 'comparison';
defaults.alpha = 0.05;
defaults.descriptive_funcs = { @mean, @median, @rows, @plotlabeled.sem };
defaults.anovan_inputs = { 'display', 'off', 'varnames', factors, 'model', 'full' };
defaults.dimension = 'auto';

params = dsp3.parsestruct( defaults, varargin );

mask = params.mask;
compcat = params.comparison_category;
alpha = params.alpha;
funcs = params.descriptive_funcs;
anovan_inputs = params.anovan_inputs;
dim = params.dimension;

addcat( labels, compcat );

[alabs, I] = keepeach( labels', spec, mask );

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