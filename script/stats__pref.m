function stats__pref(varargin)

defaults = dsp3.get_behav_stats_defaults();
params = dsp3.parsestruct( defaults, varargin );

drug_type = params.drug_type;
per_mag = params.per_magnitude;
per_monk = params.per_monkey;
do_save = params.do_save;
bs = params.base_subdir;
conf = params.config;

if ( isempty(params.consolidated) )
  consolidated = dsp3.get_consolidated_data( conf );
else
  consolidated = params.consolidated;
end

labs = fcat.from( consolidated.trial_data.labels );

mag_type = ternary( per_mag, 'magnitude', 'non_magnitude' );
is_drug = dsp3.isdrug( drug_type );

path_components = { 'behavior', dsp3.datedir, bs, drug_type, 'pref', mag_type };
analysis_p = char( dsp3.analysisp(path_components, conf) );
plot_p = char( dsp3.plotp(path_components, conf) );

%%

spec = { 'outcomes', 'trialtypes', 'days', 'drugs', 'administration' };

if ( per_mag ), spec{end+1} = 'magnitudes'; end

subsetlabs = dsp3.get_subset( labs', drug_type );

[prefdat, preflabs] = dsp3.get_pref( subsetlabs', setdiff(spec, 'outcomes') );

prefdat = indexpair( prefdat, preflabs, findnone(preflabs, params.remove) );

replace( preflabs, 'selfMinusBoth', 'selfboth' );
replace( preflabs, 'otherMinusNone', 'othernone' );

%%  sign rank against 0 preference

prefix = 'preference__stats';

uselabs = preflabs';
usedat = prefdat;

mask = find( uselabs, 'choice' );

[tlabs, I] = keepeach( uselabs', setdiff(spec, 'days'), mask );

funcs = { @median, @mean, @plotlabeled.sem, @signrank };
names = { 'median', 'mean', 'sem', 'p value' };
assert( numel(funcs) == numel(names) );

vals = cellfun( @(x) rownan(rows(x)), cell(size(funcs)), 'un', 0 );

for i = 1:numel(I)
  X = usedat(I{i});
  for j = 1:numel(funcs)
    vals{j}(i) = funcs{j}( X );
  end
end

[t, rc] = tabular( tlabs, spec );

t_vals = cellfun( @(x) cellrefs(x, t), vals, 'un', 0 );

repset( addcat(rc{1}, 'measure'), 'measure', names );

ps_tbl = fcat.table( vertcat(t_vals{:}), rc{:} );

if ( do_save )
  dsp3.savetbl( ps_tbl, analysis_p, tlabs, spec, prefix );
end

%%  anova with magnitude

if ( per_mag )

  uselabs = preflabs';
  usedat = prefdat;

  alpha = 0.05;
  factor = 'magnitudes';
  anovas_each = setdiff( spec, union(cellstr(factor), {'days'}) );

  mask = setdiff( find(uselabs, 'choice'), find(uselabs, 'errors') );

  addcat( uselabs, 'comparison' );
  [alabs, I] = keepeach( uselabs', anovas_each, mask );
  clabs = fcat();
  tbls = cell( size(I) );

  for i = 1:numel(I)

    grp = removecats( categorical(uselabs, factor, I{i}) );
    [p, tbl, stats] = anova1( usedat(I{i}), grp, 'off' );
    [c, ~, ~, g] = multcompare( stats, 'display', 'off' );

    cg = arrayfun( @(x) g(x), c(:, 1:2) );
    cc = [ cg, arrayfun(@(x) x, c(:, 3:end), 'un', 0) ];

    is_sig = c(:, end) < alpha;

    sig_c = cc(is_sig, :);

    for j = 1:size(sig_c, 1)
      setcat( uselabs, 'comparison', sprintf('%s vs %s', sig_c{j, 1:2}) );
      append1( clabs, uselabs, I{i} );
    end

    tbls{i} = cell2table( tbl(2:end, :), 'VariableNames', fcat.trim(tbl(1, 1:end)) );
  end

  if ( do_save )
    for i = 1:numel(tbls)
      dsp3.savetbl( tbls{i}, analysis_p, alabs(i), anovas_each, 'pref__magnitude__anovas' );
    end
  end

  %
  % means
  %

  [meanlabs, I] = keepeach( uselabs', setdiff(spec, 'days'), mask );
  means = rownanmean( usedat, I );
  devs = rowop( usedat, I, @plotlabeled.nansem );

  [t, rc] = tabular( meanlabs, setdiff(spec, 'days') );

  repset( addcat(rc{2}, 'measure'), 'measure', {'mean', 'sem'} );

  t_means = cellrefs( means, t );
  t_devs = cellrefs( devs, t );

  tbl = fcat.table( [t_means, t_devs], rc{:} );

  if ( do_save )
    dsp3.savetbl( tbl, analysis_p, meanlabs, anovas_each, 'pref__magnitude__descriptives' );
  end

end

%%  per mag plot

if ( per_mag )
  prefix = 'per_magnitude_preference';
  
  uselabs = preflabs';
  usedat = prefdat;
  
  if ( ~per_monk ), collapsecat(uselabs, 'monkeys'); end
  
  pl = plotlabeled.make_common();
  pl.sort_combinations = true;
  pl.group_order = { 'low', 'medium', 'high' };
  
  mask = fcat.mask( uselabs, @find, 'choice' );
  xcats = 'outcomes';
  gcats = 'magnitudes';
  pcats = dsp3.nonun_or_all( uselabs, {'trialtypes', 'monkeys'} );
  
  pl.bar( usedat(mask), uselabs(mask), xcats, gcats, pcats );
  
  if ( do_save )
    fnames = unique( cshorzcat(xcats, gcats, pcats) );
    fnames = dsp3.nonun_or_all( uselabs, fnames );
    
    dsp3.req_savefig( gcf, plot_p, uselabs(mask), fnames, prefix );
  end
end

%%  drug plot

if ( is_drug )
  prefix = 'preference';
  
  uselabs = preflabs';
  usedat = prefdat;
  
  if ( ~per_monk ), collapsecat(uselabs, 'monkeys'); end
  
  pl = plotlabeled.make_common();
  pl.sort_combinations = true;
  pl.x_order = { 'saline', 'oxytocin' };
  pl.group_order = { 'pre', 'post' };
  
  mask = fcat.mask( uselabs, @find, 'choice' );
  xcats = 'drugs';
  gcats = 'administration';
  pcats = { 'outcomes', 'monkeys' };
  
  pcats = dsp3.nonun_or_all( uselabs, pcats );
  
  pl.bar( usedat(mask), uselabs(mask), xcats, gcats, pcats );
  
  if ( do_save )
    fnames = unique( cshorzcat(xcats, gcats, pcats) );
    fnames = dsp3.nonun_or_all( uselabs, fnames );
    
    dsp3.req_savefig( gcf, plot_p, uselabs(mask), fnames, prefix );
  end
else
  prefix = 'preference';
  
  uselabs = preflabs';
  usedat = prefdat;
  
  if ( ~per_monk ), collapsecat(uselabs, 'monkeys'); end
  
  pl = plotlabeled.make_common();
  pl.sort_combinations = true;
  
  mask = fcat.mask( uselabs, @find, 'choice' );
  xcats = 'outcomes';
  gcats = 'drugs';
  pcats = { 'monkeys' };
  
  pcats = dsp3.nonun_or_all( uselabs, pcats );
  
  pl.bar( usedat(mask), uselabs(mask), xcats, gcats, pcats );
  
  if ( do_save )
    fnames = unique( cshorzcat(xcats, gcats, pcats) );
    fnames = dsp3.nonun_or_all( uselabs, fnames );
    
    dsp3.req_savefig( gcf, plot_p, uselabs(mask), fnames, prefix );
  end  
end

end


