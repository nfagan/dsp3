function labels = shuffle_within(labels, each_I, within)

for i = 1:numel(each_I)
  within_I = findall( labels, within, each_I{i} );
  
  all_inds = vertcat( within_I{:} );
  all_values = cellstr( labels, within, all_inds );
  
  shuff_ind = randperm( numel(all_values) );
  all_values = all_values(shuff_ind);
  
  setcat( labels, within, all_values, all_inds );
end

end