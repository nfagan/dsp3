function coh_labels = add_first_look_labels_to_sfcoh(coh_labels, look_labels)

label_mask = fcat.mask( look_labels ...
  , @find, {'pre', 'choice'} ...
  , @findnone, 'errors' ...
);

[site_I, site_C] = findall( coh_labels, {'days', 'outcomes', 'channels', 'regions', 'unit_uuid'} );

cats_to_validate = { 'trials', 'outcomes', 'magnitudes', 'blocks', 'sessions' };
cats_to_assign = { 'duration', 'looks_to' };

addcat( coh_labels, cats_to_assign );

for i = 1:numel(site_I)
  coh_trials = cellstr( coh_labels, cats_to_validate, site_I{i} );
  
  match_ind = find( look_labels, site_C(1:2, i), label_mask );
  matched_trials = cellstr( look_labels, cats_to_validate, match_ind );
  
  select_inds = 1:rows( coh_trials );
  
  if ( ~isequal(size(matched_trials), size(coh_trials)) )
    assert( rows(matched_trials) > rows(coh_trials) );
    assert( isequal(coh_trials, matched_trials(select_inds, :)) );    
  else
    assert( isequal(coh_trials, matched_trials) );
  end
  
  src_inds = match_ind(select_inds);
  dest_inds = site_I{i}(select_inds);
  
  src_values = cellstr( look_labels, cats_to_assign, src_inds );
  setcat( coh_labels, cats_to_assign, src_values, dest_inds );
end

prune( coh_labels );

end