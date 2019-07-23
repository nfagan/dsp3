conf = dsp3.config.load();

sf_coh_p = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh/';

acc_file = fullfile( sf_coh_p, 'sfc_pre_acc_spike_all_withsame.mat' );
bla_file = fullfile( sf_coh_p, 'sfc_pre_bla_spike_all_withsame.mat' );
spk_file = fullfile( sf_coh_p, 'dictator_game_SUAdata_pre.mat' );
acc_pairs_file = fullfile( sf_coh_p, 'coher_usedpairsACC.mat' );
bla_pairs_file = fullfile( sf_coh_p, 'coher_usedpairsBLA.mat' );

acc = load( acc_file );
bla = load( bla_file );
spk = load( spk_file );
acc_pairs = shared_utils.io.fload( acc_pairs_file );
bla_pairs = shared_utils.io.fload( bla_pairs_file );

acc = acc.coher_data_all;
bla = bla.coher_data_all;

targacq_labels = fcat.from( dsp3_load_cc_targacq_labels() );

%%

num_cells = cellfun( @(x) numel(x.data), spk.all_spike_time );
[coh_dat, coh_labs] = ...
  dsp3_linearize_cc_sf( acc, bla, spk.all_spike_time, spk.all_event_time, targacq_labels ...
  , acc_pairs, bla_pairs ...
);

%%

save( fullfile(sf_coh_p, 'cc_sf_coh_data_redux.mat'), 'coh_dat', '-v7.3' );
save( fullfile(sf_coh_p, 'cc_sf_coh_labels_redux.mat'), 'coh_labs' );

%%

psd_file = dsp3.load_one_intermediate( 'original_summarized_psd/targAcq-150-cc' );
t = psd_file.t;
f = psd_file.f;

per_day_save_p = fullfile( sf_coh_p, 'per_day' );
shared_utils.io.require_dir( per_day_save_p );

dsp3_save_pre_choice_linearized_sf_coh( per_day_save_p, coh_dat, coh_labs, f, t );