function [out_data, out_labels, f, t] = dsp3_linearize_high_res_cc_sfcoh(sfcoh, filename, spike_region, condition_start, num_conditions, subset_start, num_subset)

conditions = { 'self', 'both', 'other', 'none' };
labels = prune( addcat(fcat.from(sfcoh.labels.labels), {'lfp_channels', 'unit_uuid'}) );
lfp_channels = cellfun( @(x) sprintf('lfp_%s', x), cellstr(labels, 'channels'), 'un', 0 );

coh_data = sfcoh.coher_data;
assert( numel(coh_data) == numel(conditions), 'Number of conditions mismatch.' );

lfp_region = char( setdiff({'bla', 'acc'}, spike_region) );

out_labels = fcat();
out_data = {};

all_channels = combs( labels, {'channels', 'regions'}, find(labels, lfp_region) );
if ( isempty(all_channels) )
  channel_ind = [];
else
  channel_ind = find( labels, all_channels(:, 1) );
end

for i = condition_start:condition_start+num_conditions-1
  cond_ind = find( labels, conditions{i}, channel_ind );
  coh_subset = coh_data{i};
  num_trials = numel( cond_ind );
  
  for j = subset_start:subset_start+num_subset-1
    pair_c = coh_subset{j}.C;
    combined_data = permute( cat(3, pair_c{:}), [2, 1, 3] );
    assert( rows(combined_data) == num_trials, 'Number of trials mismatch.' );
    
    curr_rows = rows( out_labels );
    assign_ind = curr_rows+1:curr_rows+num_trials;
    
    append( out_labels, labels, cond_ind );
    
    if ( ~isempty(out_labels) )
      region_str = sprintf( '%s_%s', spike_region, lfp_region );
      
      setcat( out_labels, 'regions', region_str, assign_ind );
      setcat( out_labels, 'lfp_channels', lfp_channels(cond_ind), assign_ind );
      setcat( out_labels, 'channels', sprintf('channel-%s', shared_utils.general.uuid()), assign_ind );
      setcat( out_labels, 'unit_uuid', sprintf('unit_uuid-%s', shared_utils.general.uuid()), assign_ind );
    end
    
    out_data{end+1, 1} = combined_data;
  end
end

if ( ~isempty(out_labels) )
  addsetcat( out_labels, 'mda_filename', filename );
end

out_data = vertcat( out_data{:} );

f = linspace( 0, 500, size(out_data, 2) );
t = -500:5:500;

assert( numel(t) == size(out_data, 3), 'Time mismatch.' );

end