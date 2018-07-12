consolidated = dsp3.get_consolidated_data();

labs = fcat.from( consolidated.trial_data.labels );
rt = consolidated.reaction_time;

analysis_p = dsp3.analysisp( {'behavior', dsp3.datedir} );
plot_p = dsp3.plotp( {'behavior', dsp3.datedir} );

%%

drug_type = 'nondrug';
per_mag = true;
do_save = true;

spec = { 'outcomes', 'trialtypes', 'days', 'drugs', 'administration' };

if ( per_mag ), spec{end+1} = 'magnitudes'; end

[subsetlabs, I] = dsp3.get_subset( labs', drug_type );
subsetrt = rt(I);

[subsetlabs, I] = keepeach( subsetlabs, spec );
subsetrt = rownanmean( subsetrt, I );


%%  compare means

prefix = 'rt__stats';

mask = find( subsetlabs, 'choice' );

[tlabs, I] = keepeach( subsetlabs', setdiff(spec, {'outcomes', 'days'}), mask );
setcat( addcat(tlabs, 'measure'), 'measure', 'p value' );

pairs = { 
    {'self', 'both'} ...
  , {'self', 'other'} ...
  , {'self', 'none'} ...
  , {'both', 'other'} ...
  , {'both', 'none'} ...
  , {'other', 'none'} ...
  };

repset( tlabs, 'outcomes', cellfun(@(x) strjoin(x, ' vs. '), pairs, 'un', 0) );
ps = rowzeros( rows(tlabs) );

for j = 1:numel(pairs)
  for i = 1:numel(I)
    ind_a = find( subsetlabs, pairs{j}{1}, I{i} );
    ind_b = find( subsetlabs, pairs{j}{2}, I{i} );

    [h, p, ~, stats] = ttest2( subsetrt(ind_a), subsetrt(ind_b) );
    
    stp = i + (j-1)*numel(I);
    
    ps(stp) = p;
  end
end

[t, rc] = tabular( tlabs, {'outcomes', 'measure'}, {'trialtypes', 'magnitudes'} );

ps_tbl = fcat.table( cellfun(@(x) ps(x), t), rc{:} );

if ( do_save )
  dsp3.savetbl( ps_tbl, analysis_p, tlabs, spec, prefix );
end

%%  get means & devs

prefix = 'rt__descriptives';

mask = setdiff( find(subsetlabs, 'choice'), find(subsetlabs, 'errors') );

[meanlabs, I] = keepeach( subsetlabs', setdiff(spec, {'days'}), mask );

means = rownanmean( subsetrt, I );
devs = rowop( subsetrt, I, @plotlabeled.nansem );

[t, rc] = tabular( meanlabs, 'outcomes', {'trialtypes', 'drugs', 'magnitudes'} );

t_means = cellfun( @(x) means(x), t );
t_devs = cellfun( @(x) devs(x), t );

repset( addcat(rc{1}, 'measure'), 'measure', {'mean', 'sem'} );

means_tbl = fcat.table( [t_means; t_devs], rc{:} );

if ( do_save )
  dsp3.savetbl( means_tbl, analysis_p, tlabs, spec, prefix );
end

%%  anova with magnitude

uselabs = addcat( subsetlabs', 'comparison' );
usedat = subsetrt;

alpha = 0.05;

mask = setdiff( find(uselabs, 'choice'), find(uselabs, 'errors') );

factors = { 'outcomes', 'magnitudes' };

anovas_each = setdiff( spec, union(factors, {'days'}) );
[alabs, I] = keepeach( uselabs', anovas_each, mask );

clabs = fcat();
sig_comparisons = {};
tbls = cell( size(I) );

for i = 1:numel(I)
  
  grps = cellfun( @(x) removecats(categorical(uselabs, x, I{i})), factors, 'un', 0 );
  
  [p, tbl, stats] = anovan( usedat(I{i}), grps, 'display', 'off', 'varnames', factors, 'model', 'full' );
  
  sig_dims = find( p < alpha );
  sig_dims(sig_dims > numel(factors)) = [];
  
  [c, ~, ~, g] = multcompare( stats, 'display', 'off', 'dimension', sig_dims );  
  
  cg = arrayfun( @(x) g(x), c(:, 1:2) );
  cc = [ cg, arrayfun(@(x) x, c(:, 3:end), 'un', 0) ];
  
  is_sig = c(:, end) < alpha;
  
  sig_c = cc(is_sig, :);
  
  for j = 1:size(sig_c, 1)
    setcat( uselabs, 'comparison', sprintf('%s vs %s', sig_c{j, 1:2}) );
    append1( clabs, uselabs, I{i} );
  end
  
  sig_comparisons = [ sig_comparisons; sig_c ];
  tbls{i} = cell2table( tbl(2:end, :), 'VariableNames', matlab.lang.makeValidName( tbl(1, :)) );
end

%   mean table
[meanlabs, I] = keepeach( uselabs', setdiff(spec, 'days'), mask );
means = rownanmean( usedat, I );
devs = rowop( usedat, I, @plotlabeled.nansem );

[t, rc] = tabular( meanlabs, setdiff(spec, 'days') );
t_means = cellrefs( means, t );
t_devs = cellrefs( devs, t );

repset( addcat(rc{2}, 'measure'), 'measure', {'mean', 'sem'} );

m_tbl = fcat.table( [t_means, t_devs], rc{:} );

%   comparisons table
[t, rc] = tabular( clabs, union(anovas_each, 'comparison') );
t_mean_diffs = cellrefs( sig_comparisons(:, 4), t );
t_ps = cellrefs( sig_comparisons(:, 6), t );
repset( addcat(rc{2}, 'measure'), 'measure', {'mean difference', 'p value'} );

a_tbl = fcat.table( [t_mean_diffs, t_ps], rc{:} );

if ( do_save )
  dsp3.savetbl( a_tbl, analysis_p, clabs, anovas_each, 'rt__magnitudes__comparisons' );
  dsp3.savetbl( m_tbl, analysis_p, meanlabs, anovas_each, 'rt__magnitudes__descriptives' );
  
  for i = 1:numel(tbls)
    dsp3.savetbl( tbls{i}, analysis_p, alabs(i), anovas_each, 'rt__magnitudes__anova' );
  end
end



%%

prefix = 'rt';

pl = plotlabeled();
pl.summary_func = @plotlabeled.nanmean;
pl.error_func = @plotlabeled.nansem;
pl.x_order = { 'self', 'both', 'other', 'none' };

mask = setdiff( find(pltlabs, 'choice'), find( pltlabs, {'errors'}) );

pl.bar( pltdat(mask), pltlabs(mask), 'outcomes', 'drugs', 'trialtypes' );

if ( do_save )
  fname = dsp3.prefix( prefix, dsp3.fname(pltlabs, {'outcomes', 'drugs', 'trialtypes'}) );
  dsp3.savefig( gcf, fullfile(plot_p, fname) );
end