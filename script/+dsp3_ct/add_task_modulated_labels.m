function labels = add_task_modulated_labels(labels, cell_type_labels)

labels = add_received_forgone_labels( labels, cell_type_labels );
task_modulated = find( labels, {'cell_type_received', 'cell_type_forgone'} );
setcat( labels, 'cell_type', 'cell_type_task_modulated', task_modulated );

end

function labels = add_received_forgone_labels(labels, cell_type_labels)

[unit_I, unit_C] = findall( labels, 'unit_uuid' );
kinds = { 'received', 'forgone', 'not_significant' };
addcat( labels, 'cell_type' );

for i = 1:numel(unit_I)
  cell_type_ind = find( cell_type_labels, unit_C(:, i) );
  inds = cellfun( @(x) find(cell_type_labels, x, cell_type_ind), kinds, 'un', 0 );
  counts = cellfun( @numel, inds );
  
  if ( nnz(counts) > 1 )
    error( 'Cell classified as received or forgone or not_significant' );
  end
  
  [~, kind_ind] = max( counts );
  
  setcat( labels, 'cell_type', sprintf('cell_type_%s', kinds{kind_ind}), unit_I{i} );
end

prune( labels );

end