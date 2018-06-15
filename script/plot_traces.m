conf = dsp3.config.load();

plot_p = fullfile( conf.PATHS.data_root, 'plots', 'traces', datestr(now, 'mmddyy') );

%%

signal_file = dsp3.load_one_intermediate( 'signals/none/targacq', 'day__01052017');

%%

measure = signal_file.measure;
measure.trial_stats.min = zeros( shape(measure, 1), 1 );
measure.trial_stats.max = zeros( size(measure.trial_stats.min) ); 
measure = dsp2.process.reference.reference_subtract_within_day( measure );

t_series = dsp3.get_matrix_t( measure );

%%

signals = measure.data;
siglabs = fcat.from( measure.labels );

n_trials = 10;
first_trial = 10;

for idx = 1:n_trials

trial_n = idx + first_trial;
[some_labs, I] = keepeach( siglabs', {'trialtypes', 'outcomes', 'days', 'regions'} );
I = cellfun( @(x) x(trial_n), I, 'un', false );

some_signals = cell2mat( cellfun(@(x) signals(x, :), I, 'un', false) );

[~, I] = remove( some_labs, {'errors', 'ref', 'cued'} );

to_plt = labeled( some_signals(I, :), some_labs );

do_save = true;

I = findall( to_plt, 'outcomes' );

for i = 1:numel(I)  
  pl = plotlabeled();
  pl.shape = [2, 1];
  pl.one_legend = true;
  pl.x = t_series;
  
  plt = prune( to_plt(I{i}) );
  
  axs = pl.lines( plt, 'days', {'regions', 'outcomes'} );
  
  arrayfun( @(x) set(x, 'nextplot', 'add'), axs );
  
  shared_utils.plot.add_vertical_lines( axs, 0 );
  arrayfun( @(x) xlabel(x, 'Time (ms) from choice'), axs );
  
  fname = joincat( getlabels(plt), {'days', 'regions', 'outcomes'} );
  fname = sprintf( 'trial__%d_%s', trial_n, fname );
  
  if ( do_save )
    full_plotp = fullfile( plot_p, joincat(plt, 'outcomes') );
    
    shared_utils.io.require_dir( full_plotp )
    
    shared_utils.plot.save_fig( gcf, fullfile(full_plotp, fname), {'epsc', 'png', 'fig'}, true );
  end
end

end