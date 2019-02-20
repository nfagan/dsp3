conf = dsp3.config.load();

dr = dsp3.dataroot( conf );

cc_spike_data = load( fullfile(dr, 'public', 'cc_sfcoh', 'dictator_game_SUAdata_pre.mat') );

%%

linear_spike_data = dsp3_linearize_cc_sua_data( cc_spike_data );

consolidated = dsp3.get_consolidated_data( conf );
events = consolidated.events;
event_key = consolidated.event_key;

event_times = events.data(:, event_key('targAcq'));
event_labels = fcat.from( events.labels );

%%

spike_times = linear_spike_data.spike_times;
spike_labels = linear_spike_data.spike_labels;

dsp3_make_cc_sf_coh( spike_times, spike_labels, event_times, event_labels ...
  , 'is_parallel', false ...
  , 'config', conf ...
);