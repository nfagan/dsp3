conf = dsp3.config.load();
consolidated = dsp3.get_consolidated_data( conf );
sua = dsp3_ct.load_sua_data( conf );
[spike_ts, spike_labels, event_ts, event_labels, new_to_orig] = ...
  dsp3_ct.linearize_sua( sua );

event_ts(event_ts == 0) = nan;

spikes = mkpair( spike_ts, spike_labels' );

%%

dsp3_ct.run_agent_specificity_combinations( consolidated, spikes ...
  , new_to_orig, event_ts, event_labels', conf );

%%