function targ_labels = label_agent_selective_units(targ_labels, cell_type_labels)

[unit_I, unit_C] = findall( targ_labels, 'unit_uuid' );
addcat( targ_labels, 'agent_selectivity' );

for i = 1:numel(unit_I)
  type_ind = find( cell_type_labels, unit_C{i} );
  assert( numel(type_ind) == 1 );
  agent_selectivity = cellstr( cell_type_labels, 'outcomes', type_ind );
  setcat( targ_labels, 'agent_selectivity', agent_selectivity, unit_I{i} );
end

end