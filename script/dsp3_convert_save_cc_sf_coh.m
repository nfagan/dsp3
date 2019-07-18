% acc_file = '/Users/Nick/Desktop/sfc_precued_acc_spike_bla_field_all.mat';
% bla_file = '/Users/Nick/Desktop/sfc_precued_bla_spike_acc_field_all.mat';

acc_file = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh/sfc_pre_acc_spike_all_withsame.mat';
bla_file = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh/sfc_pre_bla_spike_all_withsame.mat';
spk_file = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh/dictator_game_SUAdata_pre.mat';

acc = load( acc_file );
bla = load( bla_file );
spk = load( spk_file );

acc = acc.coher_data_all;
bla = bla.coher_data_all;

[data, labels] = dsp3_get_converted_cc_sf_data( acc, bla, spk, true );

%%

save_p = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh';

labs = gather( labels );

save( fullfile(save_p, 'cc_sf_coh_labels_nan_cued.mat'), 'labs' );
save( fullfile(save_p, 'cc_sf_coh_data_nan_cued.mat'), 'data', '-v7.3' );