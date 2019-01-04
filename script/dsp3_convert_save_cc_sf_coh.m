acc = load( '/Users/Nick/Desktop/sfc_precued_acc_spike_bla_field_all.mat' );
bla = load( '/Users/Nick/Desktop/sfc_precued_bla_spike_acc_field_all.mat' );

acc = acc.coher_data_all;
bla = bla.coher_data_all;

[data, labels] = dsp3_get_converted_cc_sf_data( acc, bla, true );

%%

save_p = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh';

labs = gather( labels );

save( fullfile(save_p, 'cc_sf_coh_labels_nan_cued.mat'), 'labs' );
save( fullfile(save_p, 'cc_sf_coh_data_nan_cued.mat'), 'data', '-v7.3' );