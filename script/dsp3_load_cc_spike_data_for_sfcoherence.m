function [spike_ts, spike_labels] = dsp3_load_cc_spike_data_for_sfcoherence(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

spike_data = dsp3_load_spike_times( ...
  'config', conf ...
);

sfcoh_p = fullfile( dsp3.dataroot(conf), 'data', 'sfcoh' );
cc_spike_data = load( fullfile(sfcoh_p, 'dictator_game_SUAdata_pre.mat') );
linear_spike_data = dsp3_linearize_cc_sua_data( cc_spike_data );

spike_match_ind = find( spike_data.labels, combs(linear_spike_data.spike_labels, 'session_ids') );

spike_ts = spike_data.spikes(spike_match_ind);
spike_labels = prune( spike_data.labels(spike_match_ind) );

end