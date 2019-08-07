function dsp3_make_cc_used_sfcoh_pairs_labels(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

sfcoh_p = fullfile( dsp3.dataroot(conf), 'data', 'sfcoh' );

cc_spike_data = load( fullfile(sfcoh_p, 'dictator_game_SUAdata_pre.mat') );
acc_pairs = shared_utils.io.fload( fullfile(sfcoh_p, 'coher_usedpairsACC.mat') );
bla_pairs = shared_utils.io.fload( fullfile(sfcoh_p, 'coher_usedpairsBLA.mat') );

acc_coh = load( fullfile(sfcoh_p, 'sfc_pre_acc_spike_all_withsame.mat') );
bla_coh = load( fullfile(sfcoh_p, 'sfc_pre_bla_spike_all_withsame.mat') );

joined_pairs = bla_pairs;
joined_pairs(1:numel(acc_pairs)) = acc_pairs;

joined_coh = bla_coh.coher_data_all;
joined_coh(1:numel(acc_coh.coher_data_all)) = acc_coh.coher_data_all;

linear_spike_data = dsp3_linearize_cc_sua_data( cc_spike_data );

end