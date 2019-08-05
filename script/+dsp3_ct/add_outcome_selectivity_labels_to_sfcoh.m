function coh_labels = add_outcome_selectivity_labels_to_sfcoh(cell_type_labels, coh_labels)

[unit_I, unit_C] = findall( cell_type_labels, {'unit_uuid', 'cc_unit_index', 'cc_data_index'} );
addcat( coh_labels, 'outcome_selectivity' );

for i = 1:numel(unit_I)
  match_ind = find( coh_labels, unit_C(2:3, i) );
  
  outcome_label = combs( cell_type_labels, 'outcomes', unit_I{i} );
  is_ns = any( strcmp(outcome_label, 'not_significant') );
  
  if ( numel(outcome_label) ~= 1 )
    assert( ~is_ns, 'Cannot mix-and-match not_significant and significant labels.' );
  end
  
  if ( ~is_ns )
    outcome_label = 'outcome_selective';
  end
  
  setcat( coh_labels, 'outcome_selectivity', outcome_label, match_ind );
end

end