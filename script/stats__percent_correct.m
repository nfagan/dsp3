function stats__percent_correct(varargin)

defaults = dsp3.get_behav_stats_defaults();
params = dsp3.parsestruct( defaults, varargin );

per_magnitude = params.per_magnitude;
drug_type = params.drug_type;
do_save = params.do_save;

mag_type = ternary( per_magnitude, 'magnitude', 'non_magnitude' );

conf = params.config;
bs = params.base_subdir;

path_components = { 'behavior', dsp3.datedir, bs, drug_type, 'percent_correct', mag_type };

plot_p = char( dsp3.plotp(path_components, conf) );
analysis_p = char( dsp3.analysisp(path_components, conf) );

%%

if ( isempty(params.consolidated) )
  combined = dsp3.get_consolidated_data( conf );
else
  combined = params.consolidated;
end

behav = require_fields( combined.trial_data, {'channels', 'regions', 'sites'} );
%   choice errors are choice trials where choice time is 0
choice_err = combined.events.data(:, combined.event_key('targAcq')) == 0 & where(behav, 'choice');
behav.data(:, end+1) = choice_err;
behav = dsp3.get_subset( behav, drug_type );

%%

behavdat = behav.data;
behavlabs = fcat.from( behav.labels );

behavdat = indexpair( behavdat, behavlabs, findnone(behavlabs, params.remove) );

setcat( addcat(behavlabs, 'drugtypes'), 'drugtypes', drug_type );
setcat( addcat(behavlabs, 'errortypes'), 'errortypes', 'no_errors' );

errs_ind = trueat( behavlabs, find(behavlabs, 'errors') );
choice_errs = errs_ind & behavdat(:, end);
init_errs = errs_ind & ~choice_errs;

setcat( behavlabs, 'errortypes', 'error__initial_fixation', find(init_errs) );
setcat( behavlabs, 'errortypes', 'error__choice', find(choice_errs) );

%% percent correct

[errorlabs, I] = prune( only(behavlabs', 'choice') );
errordat = behavdat(I, :);

pcorr_spec = {'days', 'trialtypes', 'administration'};

if ( per_magnitude ), pcorr_spec{end+1} = 'magnitudes'; end

[errlabs, I] = keepeach( errorlabs', pcorr_spec );

% errlab = 'errors';
errlab = 'error__choice';
err_data = cellfun( @(x) zeros(numel(I), 1), cell(2, 1), 'un', 0 );

for i = 1:numel(I)
  sb_ind = find( errorlabs, {'selfboth', 'no_errors', 'error__choice'}, I{i} );
  on_ind = find( errorlabs, {'othernone', 'no_errors', 'error__choice'}, I{i} );
  
  sb_errs = find( errorlabs, errlab, sb_ind );
  on_errs = find( errorlabs, errlab, on_ind );
  
  err_data{1}(i) = 1 - (numel(sb_errs) / numel(sb_ind));
  err_data{2}(i) = 1 - (numel(on_errs) / numel(on_ind));
end

repset( errlabs, 'contexts', {'selfboth', 'othernone'} );

pcorr = vertcat( err_data{:} );
pcorr = pcorr * 100;

%%  n correct

per_monk = true;

prefix = 'n_correct';

spec = { 'monkeys', 'administration', 'drugs' };

setcat( addcat(behavlabs, 'correct'), 'correct', 'correct_true' );
setcat( behavlabs, 'correct', 'correct_false', find(behavlabs, 'errors') );

[corrlabs, I] = keepeach( behavlabs', {'days', 'administration'} );

corrind = find( behavlabs, 'correct_true' );

ncorr = cellfun( @(x) numel(intersect(x, corrind)), I );

if ( ~per_monk )
  collapsecat( corrlabs, 'monkeys' );
end
  
[meanlabs, I] = keepeach( corrlabs', spec );
meancorr = rowmean( ncorr, I );
stdcorr = rowop( ncorr, I, @(x) std(x, [], 1) );

use_labs = repset( addcat(meanlabs', 'measure'), 'measure', {'mean', 'std'} );

[T, rc] = tabular( use_labs, spec, 'measure' );
dat = [ meancorr; stdcorr ];
T = fcat.table( cellfun(@(x) dat(x), T, 'un', false), rc{:} );

if ( do_save )
  fname = fcat.trim( joincat(prune(use_labs), spec) );
  fname = sprintf( '%s_%s_%s.csv', prefix, drug_type, fname );
  full_analysisp = fullfile( analysis_p, 'n_correct' );
  shared_utils.io.require_dir( full_analysisp );
  writetable( T, fullfile(full_analysisp, fname), 'WriteRowNames', true );
end

%%  n sessions

per_monk = true;

prefix = 'n_sessions__';

spec = { 'drugs', 'monkeys' };

daylabs = keepeach( behavlabs', union(spec, {'days'}) );

if ( ~per_monk )
  collapsecat( daylabs, 'monkeys' );
end

[countlabs, I] = keepeach( daylabs', spec );
cts = cellfun( @numel, I );

[t, rc] = tabular( countlabs, spec );

dat = cellfun( @(x) cts(x), t );

T = fcat.table( dat, rc{:} );

if ( do_save )
  fname = fcat.trim( joincat(prune(countlabs), spec) );
  fname = sprintf( '%s_%s_%s.csv', prefix, drug_type, fname );
  full_analysisp = fullfile( analysis_p, 'n_sessions' );
  shared_utils.io.require_dir( full_analysisp );
  writetable( T, fullfile(full_analysisp, fname), 'WriteRowNames', true );
end

%%  plot p correct

prefix = 'pcorrect_good_trials';
% prefix = 'pcorrect';

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.y_lims = [0, 101];
pl.group_order = { 'low', 'medium', 'high' };

plt = labeled( pcorr, errlabs );

axs = pl.bar( plt, 'contexts', 'magnitudes', 'trialtypes' );

arrayfun( @(x) ylabel(x, 'Percent Correct'), axs );

if ( do_save )
  fname = joincat( prune(getlabels(plt)), {'contexts', 'trialtypes'} );
  fname = sprintf( '%s_%s', prefix, fname );
  
  shared_utils.io.require_dir( plot_p );
  shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );
end

%%  table -- percent correct

prefix = 'pcorrect_descriptives__';

for i = 1:2

  tdat = pcorr;
  tlabs = errlabs';

  per_context = i == 1;

  if ( ~per_context )
    collapsecat( tlabs, 'contexts' );
  end

  spec = {'contexts', 'trialtypes', 'drugs', 'administration', 'magnitudes', 'drugtypes'};

  [t, rc] = tabular( tlabs, spec );

  means = cellfun( @(x) mean(tdat(x)), t );
  errs = cellfun( @(x) plotlabeled.sem(tdat(x)), t );

  repset( addcat(rc{1}, 'measure'), 'measure', {'mean', 'sem'} );

  tbl = fcat.table( [means; errs], rc{:} );

  if ( do_save )
    shared_utils.io.require_dir( analysis_p );
    fname = dsp3.prefix( prefix, dsp3.fname(tlabs, spec) );
    dsp3.writetable( tbl, fullfile(analysis_p, fname) );  
  end

end

%%  stats -- percent correct, pro v. anti

prefix = 'pcorrect_stats__';

use_labs = setcat( addcat(errlabs', 'measure'), 'measure', 'p value' );
use_dat = pcorr;

mask = find( use_labs, 'choice' );

[tlabs, I] = keepeach( use_labs', setdiff(spec, {'contexts', 'days'}), mask );

pairs = {  {'selfboth', 'othernone'} };

repset( tlabs, 'outcomes', cellfun(@(x) strjoin(x, ' vs. '), pairs, 'un', 0) );
ps = rowzeros( rows(tlabs) );

for j = 1:numel(pairs)
  for i = 1:numel(I)
    ind_a = find( use_labs, pairs{j}{1}, I{i} );
    ind_b = find( use_labs, pairs{j}{2}, I{i} );

    [h, p, ~, stats] = ttest2( use_dat(ind_a), use_dat(ind_b) );
    
    stp = i + (j-1)*numel(I);
    
    ps(stp) = p;
  end
end

rowcats = dsp3.nonun_or_all( tlabs, {'measure', 'outcomes', 'drugs', 'administration'} );
colcats = dsp3.nonun_or_all( tlabs, {'trialtypes', 'magnitudes'} );

[t, rc] = tabular( tlabs, rowcats, colcats );

ps_tbl = fcat.table( cellfun(@(x) ps(x), t), rc{:} );

if ( do_save )
  shared_utils.io.require_dir( analysis_p );
  fname = dsp3.prefix( prefix, dsp3.fname(tlabs, union(spec, {'measure'})) );
  dsp3.writetable( ps_tbl, fullfile(analysis_p, fname) );  
end

%%  anova with magnitude

if ( per_magnitude )

  spec = union( pcorr_spec, 'contexts' );

  uselabs = addcat( errlabs', 'comparison' );
  usedat = pcorr;

  alpha = 0.05;

  mask = setdiff( find(uselabs, 'choice'), find(uselabs, 'errors') );

  factors = { 'contexts', 'magnitudes' };

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
    dsp3.savetbl( a_tbl, analysis_p, clabs, anovas_each, 'p_corr__magnitudes__comparisons' );
    dsp3.savetbl( m_tbl, analysis_p, meanlabs, anovas_each, 'p_corr__magnitudes__descriptives' );

    for i = 1:numel(tbls)
      dsp3.savetbl( tbls{i}, analysis_p, alabs(i), anovas_each, 'p_corr__magnitudes__anova' );
    end
  end

end

%%  anova with magnitude

if ( per_magnitude )
  
  base_prefix = 'pcorr__magnitudes__within_context';

  spec = csunion( pcorr_spec, 'contexts' );

  uselabs = addcat( errlabs', 'comparison' );
  usedat = pcorr;

  alpha = 0.05;

  mask = setdiff( find(uselabs, 'choice'), find(uselabs, 'errors') );

  factors = { 'magnitudes' };

  anovas_each = cssetdiff( spec, csunion(factors, {'days'}) );
  [alabs, I] = keepeach( uselabs', anovas_each, mask );

  clabs = fcat();
  sig_comparisons = {};
  tbls = cell( size(I) );

  for i = 1:numel(I)

    grp = removecats( categorical(uselabs, factors{1}, I{i}) );

    [p, tbl, stats] = anova1( usedat(I{i}), grp, 'off' );

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
    dsp3.savetbl( a_tbl, analysis_p, clabs, anovas_each, sprintf('%s__comparisons', base_prefix) );
    dsp3.savetbl( m_tbl, analysis_p, meanlabs, anovas_each, sprintf('%s__descriptives', base_prefix) );

    for i = 1:numel(tbls)
      dsp3.savetbl( tbls{i}, analysis_p, alabs(i), anovas_each, sprintf('%s__anova', base_prefix) );
    end
  end

end

%% drug

if ( dsp3.isdrug(drug_type) )
  
  base_prefix = 'pcorr';
  
  uselabs = errlabs';
  usedat = pcorr;
  
  opfunc = @minus;
  sfunc = @nanmean;
  
  sub_a = 'post';
  sub_b = 'pre';
  
  subspec = cssetdiff( csunion(pcorr_spec, 'contexts'), 'administration' );
  tspec = cssetdiff( subspec, 'days' );
  
  a = 'oxytocin';
  b = 'saline';
    
  [subdat, sublabs] = dsp3.summary_binary_op( usedat, uselabs', subspec, sub_a, sub_b, opfunc, sfunc );
  
  outs = dsp3.ttest2( subdat, sublabs', tspec, a, b );
  
  if ( do_save )
    t_tbls = outs.t_tables;
    t_labs = outs.t_labels;
    m_tbls = outs.descriptive_tables;
    m_labs = outs.descriptive_labels;
    
    for i = 1:numel(t_tbls)
      dsp3.savetbl( t_tbls{i}, analysis_p, t_labs(i), tspec, sprintf('%s__ttest', base_prefix) );
    end
    
    dsp3.savetbl( m_tbls, analysis_p, m_labs, tspec, sprintf('%s__descriptives', base_prefix) );
  end
end

