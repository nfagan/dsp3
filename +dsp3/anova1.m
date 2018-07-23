function outs = anova1(data, labels, spec, factor, varargin)

assert_ispair( data, labels );
assert_hascat( labels, csunion(spec, factor) );

defaults.mask = rowmask( data );
defaults.comparison_category = 'comparison';
defaults.alpha = 0.05;
defaults.descriptive_funcs = { @mean, @median, @rows, @plotlabeled.sem };

params = dsp3.parsestruct( defaults, varargin );

mask = params.mask;
compcat = params.comparison_category;
alpha = params.alpha;
funcs = params.descriptive_funcs;

addcat( labels, compcat );

[alabs, I] = keepeach( labels', spec, mask );

c_tbls = cell( size(I) );
a_tbls = cell( size(I) );

for i = 1:numel(I)
  grp = removecats( categorical(labels, factor, I{i}) );
  
  [p, tbl, stats] = anova1( data(I{i}), grp, 'off' );
  [cc, c] = dsp3.multcompare( stats );
  
  issig = c(:, end) < alpha;
  sig_comparisons = cc(issig, :);
  
  a_tbls{i} = dsp3.anova_cell2table( tbl );
  c_tbls{i} = dsp3.multcompare_cell2table( sig_comparisons );
end

tblspec = csunion( spec, factor );

[m_tbl, ~, mlabs] = dsp3.descriptive_table( data, labels', tblspec, funcs, mask );

outs.anova_tables = a_tbls;
outs.anova_labels = alabs;
outs.comparison_tables = c_tbls;
outs.descriptive_tables = m_tbl;
outs.descriptive_labels = mlabs;

end