consolidated = dsp3.get_consolidated_data();

labs = fcat.from( consolidated.trial_data.labels );

analysis_p = dsp3.analysisp( {'behavior', dsp3.datedir} );

%%

drug_type = 'nondrug';
per_mag = true;
do_save = true;

spec = { 'outcomes', 'trialtypes', 'days', 'drugs', 'administration' };

if ( per_mag ), spec{end+1} = 'magnitudes'; end

[subsetlabs, I] = dsp3.get_subset( labs', drug_type );
subsetdata = consolidated.trial_data.data(I, :);
trialkey = consolidated.trial_key;

[countdat, countlabs, newcats] = dsp3.get_gaze_counts( subsetdata, subsetlabs', trialkey );

%   make binary
countdat(countdat > 0) = 1;

spec = union( spec, newcats );

%%

uselabs = countlabs';
usedat = countdat;

[plabs, I] = keepeach( uselabs', spec );
pdat = rowop( usedat, I, @pnz );

%%

uselabs = plabs';
usedat = pdat;

replace( uselabs, 'bottle', 'looks to bottle' );
replace( uselabs, 'monkey', 'looks to monkey' );

alpha = 0.05;

each_ts = setdiff( spec, {'outcomes', 'days'} );
each_means = setdiff( spec, 'days' );

mask = setdiff( find(uselabs, 'choice'), find(uselabs, 'errors') );

[tlabs, I] = keepeach( uselabs', each_ts, mask );

alabs = fcat();
sig_comparisons = {};

addcat( uselabs, 'comparison' );

tbls = cell( size(I) );

for i = 1:numel(I)
  
  grp = removecats( categorical(uselabs, 'outcomes', I{i}) );
  
  [p, tbl, stats] = anova1( usedat(I{i}), grp, 'off' );
  [c, ms, h, names] = multcompare( stats, 'display', 'off' );
  
  cg = arrayfun( @(x) names(x), c(:, 1:2) );
  cc = [ cg, arrayfun(@(x) x, c(:, 3:end), 'un', 0) ];
  
  is_sig = c(:, end) < alpha;
  
  sig_c = cc(is_sig, :);
  
  for j = 1:size(sig_c, 1)
    setcat( uselabs, 'comparison', sprintf('%s vs %s', sig_c{j, 1:2}) );
    append1( alabs, uselabs, I{i} );
  end
  
  sig_comparisons = [ sig_comparisons; sig_c ];
  tbls{i} = tbl;
end

[meanlabs, I] = keepeach( uselabs', each_means, mask );
means = rowmean( usedat, I );
errs = rowop( usedat, I, @plotlabeled.sem );

%   mean table
[t, rc] = tabular( meanlabs, each_means );
t_means = cellrefs( means, t );
t_devs = cellrefs( errs, t );

repset( addcat(rc{2}, 'measure'), 'measure', {'mean', 'sem'} );
mean_tbl = fcat.table( [t_means, t_devs], rc{:} );

%   anova table
[t, rc] = tabular( alabs, union(each_ts, 'comparison') );
t_mean_diffs = cellrefs( sig_comparisons(:, 4), t );
t_ps = cellrefs( sig_comparisons(:, 6), t );
repset( addcat(rc{2}, 'measure'), 'measure', {'mean difference', 'p value'} );

a_tbl = fcat.table( [t_mean_diffs, t_ps], rc{:} );

mean_prefix = 'gaze__means';
mult_prefix = 'gaze__multiple_comparisons';
anova_prefix = 'gaze__anova';

if ( do_save )
  shared_utils.io.require_dir( analysis_p );
  mean_fname = dsp3.prefix( mean_prefix, dsp3.fname(meanlabs, each_means) );
  dsp3.writetable( mean_tbl, fullfile(analysis_p, mean_fname) );  
  
  anova_fname = dsp3.prefix( mult_prefix, dsp3.fname(alabs, each_ts) );
  dsp3.writetable( a_tbl, fullfile(analysis_p, anova_fname) );
  
  for i = 1:numel(tbls)
    anova_tbl_fname = dsp3.prefix( anova_prefix, dsp3.fname(tlabs, each_ts, i) );
    dsp3.writetable( cell2table(tbls{i}), fullfile(analysis_p, anova_tbl_fname) );
  end
end

%%  t bottle none vs. monkey other

prefix = 'gaze__t';

uselabs = plabs';
usedat = pdat;

mask = find( uselabs, {'choice', 'other', 'none'} );

each_ts = setdiff( spec, {'outcomes', 'days', 'looks_to'} );

[tlabs, I] = keepeach( uselabs', each_ts, mask );
addcat( tlabs, 'comparison' );

tbl = table;

for i = 1:numel(I)
  
  ind_other_monk = find( uselabs, {'other', 'monkey'}, I{i} );
  ind_none_bottle = find( uselabs, {'none', 'bottle'}, I{i} );
  
  other_monk = usedat(ind_other_monk);
  none_bottle = usedat(ind_none_bottle);
  
  [h, p, ~, stats] = ttest2( other_monk, none_bottle );
  
  tbl = [ tbl; struct2table(stats) ];
  
  setcat( tlabs, 'comparison', 'other vs. none', i );
end

row_names = fcat.strjoin( combs(tlabs, union(each_ts, {'comparison'})), [], ' | ' );

tbl.Properties.RowNames = row_names(:);

if ( do_save )
  dsp3.savetbl( tbl, analysis_p, tlabs, each_ts, prefix );
end

%%  anova with magnitude

uselabs = addcat( plabs', 'comparison' );
usedat = pdat;

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
  dsp3.savetbl( a_tbl, analysis_p, clabs, anovas_each, 'gaze__magnitudes__comparisons' );
  dsp3.savetbl( m_tbl, analysis_p, meanlabs, anovas_each, 'gaze__magnitudes__descriptives' );
  
  for i = 1:numel(tbls)
    dsp3.savetbl( tbls{i}, analysis_p, alabs(i), anovas_each, 'gaze__magnitudes__anova' );
  end
end

%%  plot

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.x_order = { 'self', 'both', 'other', 'none' };

pltdat = pdat;
pltlabs = plabs';

xcats = { 'outcomes' };
gcats = { 'looks_to' };
pcats = { 'trialtypes', 'look_measure' };

mask = setdiff( find(pltlabs, 'choice'), find(pltlabs, 'errors') );

pl.errorbar( pltdat(mask), pltlabs(mask), xcats, gcats, pcats );



