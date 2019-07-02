function dsp3_generate_cc_targacq_trial_labels()

file_p = 'H:\data\cc_dictator\mua';
mats = shared_utils.io.find( file_p, '.mat' );
mats = shared_utils.io.filter_files(mats, 'targacq', 'days');
mats = shared_utils.io.filter_files(mats, {}, 'spikes');

orig_labels = fcat();

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  signals = shared_utils.io.fload( mats{i} );
  append( orig_labels, fcat.from(signals.labels) );
end

save_filename = fullfile( dsp3.dataroot(), 'constants', 'cc_targacq_trial_labels.mat' );
to_save = gather( orig_labels );
save( save_filename, 'to_save' );

end