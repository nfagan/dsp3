function [null_perf, null_labels] = null_context_lda(psth, each_I, iters)

assert_ispair( psth );

null_perf = cell( iters, 1 );
null_labels = cell( iters, 1 );

psth_labs = psth.labels';

parfor i = 1:iters
  tmp_labs = dsp3_ct.shuffle_within( psth_labs, each_I, 'outcomes' );
  
  copy_psth = psth;
  copy_psth.labels = tmp_labs;
  
  [null_perf{i}, null_labels{i}] = dsp3_ct.lda_cell_type_per_context( copy_psth, each_I );
end

null_perf = vertcat( null_perf{:} );
null_labels = vertcat( fcat, null_labels{:} );

end