function [out_props, out_labs, totals, total_labs] = p_significant_per_outcome_received_forgone(ps, labels, each_I)

assert_ispair( ps, labels );

outcomes = { 'self', 'both', 'other', 'none' };
type_labels = [ outcomes, {'received', 'forgone'} ];

out_labs = fcat();
out_props = [];
totals = zeros( numel(each_I), 1 );
total_labs = fcat();

for i = 1:numel(each_I)
  unit_inds = findall( labels, 'unit_uuid', each_I{i} );
  
  counts_per_type = zeros( 1, 6 );
  check_types = false( 1, 6 );
  num_task_modulated = 0;
  
  for j = 1:numel(unit_inds)
    inds = cellfun( @(x) find(labels, x, unit_inds{j}), outcomes, 'un', 0 );
    sigs = cellfun( @(x) any(ps(x) < 0.05), inds );
    
    num_sigs = nnz( sigs );
    
    check_types(1) = num_sigs == 1 && sigs(1);
    check_types(2) = num_sigs == 1 && sigs(2);
    check_types(3) = num_sigs == 1 && sigs(3);
    check_types(4) = num_sigs == 1 && sigs(4);
    
    check_types(5) = (sigs(1) || sigs(2)) && ~(sigs(3) || sigs(4));
    check_types(6) = (sigs(3) || sigs(4)) && ~(sigs(1) || sigs(2));
    
    for k = 1:numel(check_types)      
      counts_per_type(k) = counts_per_type(k) + check_types(k);
    end
    
    if ( check_types(5) || check_types(6) )
      num_task_modulated = num_task_modulated + 1;
    end
  end
  
%   props = counts_per_type / numel( unit_inds );
  props = counts_per_type;
%   props = counts_per_type / num_task_modulated;
  
  for j = 1:numel(props)
    append1( out_labs, labels, each_I{i} );
    setcat( out_labs, 'outcomes', type_labels{j}, rows(out_labs) );
  end
  
  out_props = [ out_props; props(:) ];
  
  append1( total_labs, labels, each_I{i} );
  totals(i) = numel( unit_inds );
end

end