conf = dsp3.config.load();
dr = conf.PATHS.data_root;
datedir = datestr( now, 'mmddyy' );
plot_p = fullfile( dr, 'plots', 'behavior', datedir, 'percent_correct' );
analysis_p = fullfile( dr, 'analyses', 'behavior', datedir );

%%

drug_type = 'nondrug';
per_magnitude = true;

combined = dsp3.get_consolidated_data();

behav = require_fields( combined.trial_data, {'channels', 'regions', 'sites'} );
%   choice errors are choice trials where choice time is 0
choice_err = combined.events.data(:, combined.event_key('targAcq')) == 0 & where(behav, 'choice');
behav.data(:, end+1) = choice_err;
behav = dsp3.get_subset( behav, drug_type );

%%

behavdat = behav.data;
behavlabs = fcat.from( behav.labels );

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

do_save = false;
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
T = fcat.table( cellfun(@(x) dat(x), T, 'un', false), rc{:} )

if ( do_save )
  fname = fcat.trim( joincat(prune(use_labs), spec) );
  fname = sprintf( '%s_%s_%s.csv', prefix, drug_type, fname );
  full_analysisp = fullfile( analysis_p, 'n_correct' );
  shared_utils.io.require_dir( full_analysisp );
  writetable( T, fullfile(full_analysisp, fname), 'WriteRowNames', true );
end

%%  n sessions

do_save = false;
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

T = fcat.table( dat, rc{:} )

if ( do_save )
  fname = fcat.trim( joincat(prune(countlabs), spec) );
  fname = sprintf( '%s_%s_%s.csv', prefix, drug_type, fname );
  full_analysisp = fullfile( analysis_p, 'n_sessions' );
  shared_utils.io.require_dir( full_analysisp );
  writetable( T, fullfile(full_analysisp, fname), 'WriteRowNames', true );
end

%%  plot p correct

do_save = true;

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

do_save = true;
prefix = 'pcorrect_descriptives__';

tdat = pcorr;
tlabs = errlabs';

per_context = false;

if ( ~per_context )
  collapsecat( tlabs, 'contexts' );
end

spec = {'contexts', 'trialtypes', 'drugs', 'administration', 'magnitudes', 'drugtypes'};

[t, rc] = tabular( tlabs, spec );

means = cellfun( @(x) mean(tdat(x)), t );
errs = cellfun( @(x) plotlabeled.sem(tdat(x)), t );

repset( addcat(rc{1}, 'measure'), 'measure', {'mean', 'sem'} );

tbl = fcat.table( [means; errs], rc{:} )

if ( do_save )
  shared_utils.io.require_dir( analysis_p );
  fname = dsp3.prefix( prefix, dsp3.fname(tlabs, spec) );
  dsp3.writetable( tbl, fullfile(analysis_p, fname) );  
end

%%  stats -- percent correct, pro v. anti

do_save = true;
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

[t, rc] = tabular( tlabs, {'measure', 'outcomes'}, {'trialtypes', 'magnitudes'} );

ps_tbl = fcat.table( cellfun(@(x) ps(x), t), rc{:} );

if ( do_save )
  shared_utils.io.require_dir( analysis_p );
  fname = dsp3.prefix( prefix, dsp3.fname(tlabs, union(spec, {'measure'})) );
  dsp3.writetable( ps_tbl, fullfile(analysis_p, fname) );  
end

%%  anova with magnitude

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


