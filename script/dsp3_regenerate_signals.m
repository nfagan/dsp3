function dsp3_regenerate_signals(event_name)

if ( nargin < 1 )
  event_name = 'targAcq';
end

dsp2_conf = dsp2.config.load();
dsp3_conf = dsp3.config.load();

dsp2_conf.SIGNALS.EPOCHS.targAcq.win_size = 200;
dsp2_conf = dsp2.config.set.inactivate_epochs( 'all', dsp2_conf );
dsp2_conf = dsp2.config.set.activate_epochs( event_name, dsp2_conf );

%%

dsp2_conf.SIGNALS.handle_missing_trials = 'skip';
[signals, time_info] = dsp2.io.get_signals( 'config', dsp2_conf );

%%

defaults = dsp3.get_common_lfp_defaults();

use_signals = signals.(event_name);

labs = fcat.from( use_signals.labels );

save_p = fullfile( dsp3.dataroot(dsp3_conf), 'intermediates', 'original_aligned_lfp', event_name );
shared_utils.io.require_dir( save_p );

orig_labs = fcat.from( dsp3_load_cc_targacq_labels(dsp3_conf) );

[matched_labs, modified_rows] = dsp3_match_cc_targacq_trial_labels( orig_labs, labs' );
[matched_dat, matched_labs] = dsp3.ref_subtract( use_signals.data, matched_labs );

use_signals = set_data_and_labels( use_signals, matched_dat, SparseLabels.from_fcat(matched_labs) );
[day_I, day_C] = findall( matched_labs, 'days' );

for i = 1:numel(day_I)
  shared_utils.general.progress( i, numel(day_I) );
  
  log_ind = trueat( matched_labs, day_I{i} );
  
  subset = use_signals(log_ind);
  subset.data = dsp3.zpfilter( subset.data, defaults.f1, defaults.f2, defaults.sample_rate, defaults.filter_order );
  
  save_filename = sprintf( 'lfp_%s_%s.mat', day_C{i}, event_name );
  save( fullfile(save_p, save_filename), 'subset' );
end

end