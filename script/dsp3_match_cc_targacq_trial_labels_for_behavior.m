function new_labels = dsp3_match_cc_targacq_trial_labels_for_behavior(orig_labels, new_labels, cats_to_validate)

[orig_I, orig_C] = findall( orig_labels, {'days'} );

allowed_to_mismatch = { 'blocks', 'sessions', 'administration', 'epochs', 'sites' };
cats_to_unify = { 'blocks', 'sessions', 'administration', 'sites' };

cats_to_check = setdiff( cats_to_validate, allowed_to_mismatch );
assert_hascat( new_labels, cats_to_check );

addcat( new_labels, cats_to_unify );

for i = 1:numel(orig_I)
  shared_utils.general.progress( i, numel(orig_I) );
  
  new_ind = find( new_labels, orig_C(:, i) );
  
  if ( numel(new_ind) ~= numel(orig_I{i}) )
    orig_day_ind = find( orig_labels, orig_C{1, i} );
    new_day_ind = find( new_labels, orig_C{1, i} );
    
    orig_channel_inds = findall( orig_labels, 'channels', orig_day_ind );
    nums = cellfun( @numel, orig_channel_inds );
    assert( numel(unique(nums)) == 1, 'Expected replications of trial distributions for each channel.' );
    
    channel_ind = orig_channel_inds{1};
    
    orig_cat = categorical( orig_labels, cats_to_check, channel_ind );
    new_cat = categorical( new_labels, cats_to_check, new_ind );
    
    assert( isequal(size(orig_cat), size(new_cat)), 'Sizes mismatch.' );
    assert( all(all(orig_cat == new_cat)), 'Labels mismatch.' );
    
    orig_values = cellstr( orig_labels, cats_to_unify, channel_ind );
    setcat( new_labels, cats_to_unify, orig_values, new_ind );
  end
end

end