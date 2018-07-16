function stats__pref(varargin)

defaults = dsp3.get_behav_stats_defaults();
params = dsp3.parsestruct( defaults, varargin );

drug_type = params.drug_type;
per_mag = params.per_magnitude;
do_save = params.do_save;

consolidated = dsp3.get_consolidated_data();

labs = fcat.from( consolidated.trial_data.labels );

mag_type = ternary( per_mag, 'magnitude', 'non_magnitude' );

path_components = { 'behavior', dsp3.datedir, drug_type, 'pref', mag_type };
analysis_p = dsp3.analysisp( path_components );

%%

spec = { 'outcomes', 'trialtypes', 'days', 'drugs', 'administration' };

if ( per_mag ), spec{end+1} = 'magnitudes'; end

subsetlabs = dsp3.get_subset( labs', drug_type );

[prefdat, preflabs] = dsp3.get_pref( subsetlabs', setdiff(spec, 'outcomes') );

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
