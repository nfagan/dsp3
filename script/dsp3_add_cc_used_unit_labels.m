function spike_labels = dsp3_add_cc_used_unit_labels(spike_labels, cc_spike_data, cc_used_pairs)

mda_filenames = {};
unit_indices = {};

for i = 1:numel(cc_used_pairs)
  pairs_to_use = cc_used_pairs{i};
  
  for j = 1:numel(pairs_to_use)
    mda_filename = cc_spike_data.all_spike_time{i}.filename;
    mda_filename_ind = find( spike_labels, mda_filename );
    
    unit_ind = find( spike_labels, sprintf('unit_index__%d', pairs_to_use(j)), mda_filename_ind );
    assert( ~isempty(unit_ind) );
  end
end

end