function [new_labels, modified_rows] = dsp3_match_cc_targacq_trial_labels(orig_labels, new_labels)

new_days = combs( new_labels, 'days' );

[orig_I, orig_C] = findall( orig_labels, {'days', 'sessions', 'administration', 'drugs'} ...
  , findor(orig_labels, new_days) ...
);

allowed_to_mismatch = { 'blocks', 'sessions', 'administration', 'epochs', 'sites' };
cats_to_unify = { 'blocks', 'sessions', 'administration', 'sites' };

cats_to_check = setdiff( getcats(orig_labels), allowed_to_mismatch );
assert_hascat( new_labels, cats_to_check );

addcat( new_labels, cats_to_unify );

no_new_ref = findnone( new_labels, 'ref' );

modified_rows = {};

for i = 1:numel(orig_I)
  shared_utils.general.progress( i, numel(orig_I) );
  
  new_ind = find( new_labels, orig_C(:, i), no_new_ref );
  
  if ( numel(new_ind) ~= numel(orig_I{i}) )
    orig_day_ind = find( orig_labels, orig_C{1, i} );
    new_day_ind = find( new_labels, orig_C{1, i}, no_new_ref );
    
    assert( numel(orig_day_ind) == numel(new_day_ind), 'Number of trials mismatch.' );
    
    [orig_channel_inds, orig_channels] = findall( orig_labels, 'channels', orig_day_ind );
    
    for j = 1:numel(orig_channel_inds)
      orig_channel_ind = orig_channel_inds{j};
      new_channel_ind = find( new_labels, orig_channels{j}, new_day_ind );
      
      if ( numel(new_channel_ind) ~= numel(orig_channel_ind) )
        error( 'Number of trials for channel "%s" mismatch.', orig_channels{j} );
      end
      
      orig_day_labels = categorical( orig_labels, cats_to_check, orig_channel_ind );
      new_day_labels = categorical( new_labels, cats_to_check, new_channel_ind );
      
%       try
      assert( all(all(orig_day_labels == new_day_labels)), 'Trial labels mismatch' );
      
      orig_values = cellstr( orig_labels, cats_to_unify, orig_channel_ind );
      setcat( new_labels, cats_to_unify, orig_values, new_channel_ind );
      
      modified_rows{end+1, 1} = new_channel_ind;
    end
  end
end

modified_rows = vertcat( modified_rows{:} );

end