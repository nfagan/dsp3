conf = dsp3.config.load();
dr = conf.PATHS.data_root;
datedir = datestr( now, 'mmddyy' );
plot_p = fullfile( dr, 'plots', 'behavior', datedir, 'percent_correct' );
analysis_p = fullfile( dr, 'analyses', 'behavior', datedir );

%%

drug_type = 'nondrug';

combined = dsp3.get_consolidated_data();

behav = require_fields( combined.trial_data, {'channels', 'regions', 'sites'} );
%   choice errors are choice trials where choice time is 0
choice_err = combined.events.data(:, combined.event_key('targAcq')) == 0 & where(behav, 'choice');
behav.data(:, end+1) = choice_err;
behav = dsp3.get_subset( behav, drug_type );

%%

behavdat = behav.data;
behavlabs = fcat.from( behav.labels );

setcat( addcat(behavlabs, 'errortypes'), 'errortypes', 'no_errors' );

errs_ind = trueat( behavlabs, find(behavlabs, 'errors') );
choice_errs = errs_ind & behavdat(:, end);
init_errs = errs_ind & ~choice_errs;

setcat( behavlabs, 'errortypes', 'error__initial_fixation', find(init_errs) );
setcat( behavlabs, 'errortypes', 'error__choice', find(choice_errs) );

%% percent correct

[errorlabs, I] = prune( only(behavlabs', 'choice') );
errordat = behavdat(I, :);

[errlabs, I] = keepeach( errorlabs', {'days', 'trialtypes', 'administration'} );

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

do_save = false;

prefix = 'pcorrect_good_trials';
% prefix = 'pcorrect';

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.y_lims = [0, 101];

plt = labeled( pcorr, errlabs );

axs = pl.bar( plt, 'contexts', 'trialtypes', 'trialtypes' );

arrayfun( @(x) ylabel(x, 'Percent Correct'), axs );

if ( do_save )
  fname = joincat( prune(getlabels(plt)), {'contexts', 'trialtypes'} );
  fname = sprintf( '%s_%s', prefix, fname );
  
  shared_utils.io.require_dir( plot_p );
  shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );
end

%%  table -- percent correct

tdat = pcorr;
tlabs = errlabs';

per_context = false;

if ( ~per_context )
  collapsecat( tlabs, 'contexts' );
end

[t, rc] = tabular( tlabs, {'contexts', 'trialtypes', 'drugs', 'administration'} );

means = cellfun( @(x) mean(tdat(x)), t );
errs = cellfun( @(x) plotlabeled.sem(tdat(x)), t );

rc{2} = repset( addcat(rc{2}, 'measure'), 'measure', {'mean', 'sem'} );

tbl = fcat.table( [means, errs], rc{:} )


% means = rowmean( pcorr, I );









