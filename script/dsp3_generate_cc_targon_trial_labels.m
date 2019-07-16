function dsp3_generate_cc_targon_trial_labels()

file_p = 'H:\data\cc_dictator\cued_data';
mats = shared_utils.io.findmat( file_p );

manuscript_cue_labels = fcat();

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  mat_file = shared_utils.io.fload( mats{i} );
  append( manuscript_cue_labels, fcat.from(mat_file.labels) );
end

save_filename = fullfile( dsp3.dataroot(), 'constants', 'cc_targon_trial_labels.mat' );
to_save = gather( manuscript_cue_labels );
save( save_filename, 'to_save' );

end