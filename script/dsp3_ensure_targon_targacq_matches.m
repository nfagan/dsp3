orig_targon_labels = fcat.from( dsp3_load_cc_targon_labels() );
orig_targacq_labels = fcat.from( dsp3_load_cc_targacq_labels() );

%%

new_p = fullfile( dsp3.get_intermediate_dir('original_aligned_lfp'), 'targOn' );
new_mats = shared_utils.io.findmat( new_p );

new_targon_labels = fcat();

for i = 1:numel(new_mats)
  shared_utils.general.progress( i, numel(new_mats) );
  signals = shared_utils.io.fload( new_mats{i} );
  append( new_targon_labels, fcat.from(signals.labels) );
end

%%

no_ref = prune( orig_targon_labels(findnone(orig_targon_labels, 'ref')) );

mismatches = dsp3_find_mismatches( no_ref, orig_targon_labels ...
 , {'days', 'administration', 'channels', 'regions', 'outcomes', 'trials'} );

