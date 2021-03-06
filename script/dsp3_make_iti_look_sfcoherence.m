conf = dsp3.config.load();
spike_data = dsp3_load_spike_times( ...
  'config', conf ...
);

look_outs = dsp3_find_iti_looks( ...
  'require_fixation', false ...
  , 'look_back', -3.3 ...
);

%%
sfcoh_p = fullfile( dsp3.dataroot(conf), 'data', 'sfcoh' );
cc_spike_data = load( fullfile(sfcoh_p, 'dictator_game_SUAdata_pre.mat') );
linear_spike_data = dsp3_linearize_cc_sua_data( cc_spike_data );

spike_match_ind = find( spike_data.labels, combs(linear_spike_data.spike_labels, 'session_ids') );

spike_ts = spike_data.spikes(spike_match_ind);
spike_labels = prune( spike_data.labels(spike_match_ind) );

%%

dsp3_sfcoherence_from_iti_looking( spike_ts, spike_labels, look_outs ...
  , 'event_name', 'first-look' ...
  , 'consolidated', dsp3.get_consolidated_data() ...
  , 'is_parallel', true ...
  , 'overwrite', true ...
  , 'skip_existing', false ...
);

%%

look_labels = dsp3_add_iti_first_look_labels( look_outs.labels', look_outs, 0.15 );

%%

labels_func = @(coh) dsp3_use_first_look_labels_for_summarized_sfcoherence( coh, look_labels, look_outs.event_ind );

base_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes', 'unit_uuid' };

coh_defaults = dsp3.make.defaults.summarized_coherence();
coh_defaults.summary_spec = union( base_spec, {'looks_to', 'duration'} );

dsp3.save_summarized_sfcoherence( 'first-look' ...
  , coh_defaults ...
  , 'get_labels_func', labels_func ...
  , 'is_parallel', true ...
  , 'overwrite', false ...
  , 'skip_existing', true ...
);