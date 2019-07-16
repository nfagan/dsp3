function new = dsp3_match_to_original_cue_labels(orig, new)

mismatches_a = dsp3_find_mismatches( new, orig, {'days', 'administration'} );
mismatch_days = combs( new, 'days', mismatches_a );

cats_to_validate = { 'trials', 'outcomes', 'channels', 'regions', 'sites' };
cats_to_assign = { 'administration', 'blocks', 'sessions' };

for i = 1:numel(mismatch_days)
  full_day_ind = find( new, mismatch_days{i} );
  full_day_ind_orig = find( orig, mismatch_days{i} );

  if ( numel(full_day_ind) ~= numel(full_day_ind_orig) )
    error( 'Day subsets do not match.' );
  end

  trial_seq_orig = categorical( orig, cats_to_validate, full_day_ind_orig );
  trial_seq_new = categorical( new, cats_to_validate, full_day_ind );

  matches = all( all(trial_seq_new == trial_seq_orig) );

  if ( ~matches )
    error( 'Day "%s" does not match.', mismatch_days{i} );
  end

  values_to_assign = cellstr( orig, cats_to_assign, full_day_ind_orig );
  setcat( new, cats_to_assign, values_to_assign, full_day_ind );
end

end