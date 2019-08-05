function coh_labels = add_agent_selectivity_labels_to_sfcoh(cell_type_labels, coh_labels)

[unit_I, unit_C] = findall( cell_type_labels, {'unit_uuid', 'cc_unit_index', 'cc_data_index'} );
addcat( coh_labels, 'agent_selectivity' );

for i = 1:numel(unit_I)
  match_ind = find( coh_labels, unit_C(2:3, i) );
  unit_id = combs( coh_labels, 'unit_uuid', match_ind );
  
  agent_label = combs( cell_type_labels, 'outcomes', unit_I{i} );
  assert( numel(agent_label) == 1, 'Expected one agent label for "%s".', unit_C{1, i} );
  
  setcat( coh_labels, 'agent_selectivity', agent_label, match_ind );
end

end