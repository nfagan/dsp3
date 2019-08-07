function mask = site_pair_mask(labels, site_pairs)

[day_I, day_C] = findall( labels, 'days' );
mask = [];

for i = 1:numel(day_I)
  day_ind = strcmp( site_pairs.days, day_C{1, i} );
  
  if ( nnz(day_ind) > 0 )
    regions = site_pairs.channel_key;
    
    for j = 1:numel(regions)
      chans = site_pairs.channels{day_ind}(:, j);
      reg_mask = find( labels, regions{j}, day_I{i} );
      mask = union( mask, findor(labels, chans, reg_mask) );
    end
  end
end

end