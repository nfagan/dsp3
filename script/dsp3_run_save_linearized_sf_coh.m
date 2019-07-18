conf = dsp3.config.load();

acc_file = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh/sfc_pre_acc_spike_all_withsame.mat';
bla_file = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh/sfc_pre_bla_spike_all_withsame.mat';
spk_file = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh/dictator_game_SUAdata_pre.mat';

acc = load( acc_file );
bla = load( bla_file );
spk = load( spk_file );

acc = acc.coher_data_all;
bla = bla.coher_data_all;

targacq_labels = fcat.from( dsp3_load_cc_targacq_labels() );

%%

num_cells = cellfun( @(x) numel(x.data), spk.all_spike_time );
dsp3_linearize_cc_sf( acc, bla, spk.all_spike_time, spk.all_event_time, targacq_labels );