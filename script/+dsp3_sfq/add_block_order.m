function labels = add_block_order(labels, mask)

if ( nargin < 2 )
  mask = rowmask( labels );
end

[day_I, days] = findall( labels, 'days', mask );
day_strs = datenum( cellfun(@(x) x(numel('day__')+1:end), days, 'un', 0), 'mmddyyyy' );
[~, sorted_day_ind] = sort( day_strs );
sorted_day_I = day_I(sorted_day_ind);

addcat( labels, 'block_order' );
block_order = 1;

for i = 1:numel(sorted_day_I)
  [sesh_I, sesh_C] = findall( labels, {'sessions', 'blocks'}, sorted_day_I{i} );
  sesh_nums = fcat.parse( sesh_C(1, :), 'session__' );
  block_nums = fcat.parse( sesh_C(2, :), 'block__' );
  
  [~, sesh_ind] = sortrows( [sesh_nums; block_nums]' );
  
  sesh_I = sesh_I(sesh_ind);
  
  for j = 1:numel(sesh_I)
    setcat( labels, 'block_order', sprintf('block_order__%d', block_order), sesh_I{j} );
    block_order = block_order + 1;
  end
end

prune( labels );

end