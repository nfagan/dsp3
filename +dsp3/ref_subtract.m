function [newdata, newlabels, rest_I] = ref_subtract(data, labels, mask)

if ( nargin < 3 )
  mask = rowmask( labels );
end

assert_ispair( data, labels );
assert_hascat( labels, {'days', 'regions', 'channels'} );

% Reference subtract separately for each day.
I = findall( labels, {'days'}, mask );
n_ref = count( labels, 'ref', mask );
n_trials = rows( data ) - n_ref;

newdata = nan( n_trials, notsize(data, 1) );
newlabels = fcat();

stp = 1;
rest_I = {};

for i = 1:numel(I)
  ref_ind = find( labels, 'ref', I{i} );  
  rest_ind = findnone( labels, 'ref', I{i} );
  
  n_per_channel = numel( ref_ind );
  
  % Find all channels that are not the `ref` channel
  target_channel_inds = findall( labels, 'channels', rest_ind );
  
  for j = 1:numel(target_channel_inds)
    current_channel_ind = target_channel_inds{j};
    
    assert( numel(current_channel_ind) == n_per_channel ...
      , 'Number of reference trials does not match number of target-channel trials.' );
    
    sub_data = data(current_channel_ind, :) - data(ref_ind, :);
    
    newdata(stp:stp+n_per_channel-1, :) = sub_data;
    append( newlabels, labels, current_channel_ind );
    
    stp = stp + n_per_channel;
    rest_I{end+1, 1} = current_channel_ind;
  end
end

prune( newlabels );

% assert( nnz(isnan(newdata)) == 0, 'Some trials were not subtracted.' );
assert_ispair( newdata, newlabels );

rest_I = vertcat( rest_I{:} );

end