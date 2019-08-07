look_outs = dsp3_find_iti_looks( ...
  'require_fixation', false ...
  , 'look_back', -3.3 ...
);

%%

look_labels = dsp3_add_iti_first_look_labels( look_outs.labels', look_outs, 0.15 );

%%

dsp3.save_lfp_aligned_to_look_events( ...
    'event_name', 'first-look' ...
  , 'first_look_outputs', look_outs ...
  , 'is_parallel', true ...
  , 'overwrite', true ...
);

%%

dsp3.save_coherence( 'first-look', dsp3.get_site_pairs() ...
  , 'reference_subtract', true ...
  , 'filter', true ...
  , 'overwrite', true ...
);

%%

labels_func = @(coh) dsp3_use_first_look_labels_for_summarized_coherence( coh, look_labels, look_outs.event_ind );

base_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes' };

coh_defaults = dsp3.make.defaults.summarized_coherence();
coh_defaults.summary_spec = union( base_spec, {'looks_to', 'duration'} );

dsp3.save_summarized_coherence_from_new_lfp( 'first-look' ...
  , coh_defaults ...
  , 'get_labels_func', labels_func ...
  , 'overwrite', true ...
  , 'is_parallel', true ...
  , 'configure_runner_func', @(runner) runner.set_error_handler('error') ...
);