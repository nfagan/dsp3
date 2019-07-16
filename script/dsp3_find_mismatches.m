function mismatches_a = dsp3_find_mismatches(labels_to_check_a, labels_to_check_b, cats_to_validate)

if ( nargin < 3 )
  cats_to_validate = { 'days', 'administration' };
end

[orig_site_inds, orig_site_values] = findall( labels_to_check_a, {'days', 'regions', 'channels'} );
mismatch = {};

for i = 1:numel(orig_site_inds)
  orig_cats = categorical( labels_to_check_a, cats_to_validate, orig_site_inds{i} );
  matching_ind = find( labels_to_check_b, orig_site_values(:, i) );
  
  new_cats = categorical( labels_to_check_b, cats_to_validate, matching_ind );
  
  matches = all( all(orig_cats == new_cats) );
  
  if ( ~matches )
    mismatch{end+1, 1} = orig_site_inds{i};
  end
end

mismatches_a = vertcat( mismatch{:} );

end