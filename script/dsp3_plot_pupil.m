consolidated = load( fullfile(pupil.get_dataroot(), 'consolidated', 'consolidated.mat') );
gaze = consolidated.gaze;
events = consolidated.events;
event_key = consolidated.event_key;

%%

[traces, t, params] = pupil.get_plotted_data( gaze, events, event_key ...
  , 'within_trial', true ...
  , 'start', -0.2 ...
  , 'stop', 1 ...
  , 'epochs', {'targOn', 'targAcq'} ...
  , 'remove_errors', false ...
);

%%

conf = dsp3.config.load();
save_p = char( dsp3.plotp({'pupil', dsp3.datedir}, conf) );

%%

subdir = 'targon_and_targacq';
do_save = true;

trace_data = traces.data;
trace_labels = fcat.from( traces.labels );

trialtype_mask = union( find(trace_labels, {'targAcq', 'choice'}), find(trace_labels, {'targOn', 'cued'}) );
% trialtype_mask = find( trace_labels, {'targOn'} );

mask = fcat.mask( trace_labels, trialtype_mask ...
  , @find, {'pre'} ...
  , @findnone, 'errors' ...
);

pl = plotlabeled.make_common();
% pl.error_func = @plotlabeled.nanstd;
pl.x = t;

[figs, axs, labs, fig_I] = dsp3.multi_plot( @lines, trace_data, trace_labels ...
  , {}, 'trialtypes', {'outcomes'} ...
  , 'mask', mask ...
  , 'pl', pl ...
);

spec = { 'trialtypes', 'outcomes' };

if ( do_save )
  dsp3.req_savefigs( figs, fullfile(save_p, subdir), labs, spec );
end
