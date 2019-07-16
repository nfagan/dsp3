function [out_counts, out_labs, totals, total_labs] = count_significant(ps, labels, each_I)

assert_ispair( ps, labels );

outcomes = { 'self', 'both', 'other', 'none', 'self_and_both', 'other_and_none' };
type_labels = [ outcomes, {'received', 'forgone'}, {'not_significant', 'total'} ];

out_labs = fcat();
out_counts = [];
totals = zeros( numel(each_I), 1 );
total_labs = fcat();

for i = 1:numel(each_I)
  unit_inds = findall( labels, 'unit_uuid', each_I{i} );
  
  cts = zeros( 1, numel(type_labels) );
  check_types = false( size(cts) );
  
  for j = 1:numel(unit_inds)
    inds = cellfun( @(x) find(labels, x, unit_inds{j}), outcomes, 'un', 0 );
    sigs = cellfun( @(x) any(ps(x) < 0.05), inds );
    
    num_sigs = nnz( sigs );
    
    check_types(1) = num_sigs == 1 && sigs(1);
    check_types(2) = num_sigs == 1 && sigs(2);
    check_types(3) = num_sigs == 1 && sigs(3);
    check_types(4) = num_sigs == 1 && sigs(4);
    
    check_types(5) = sigs(1) && sigs(2) && ~sigs(3) && ~sigs(4);
    check_types(6) = sigs(3) && sigs(4) && ~sigs(1) && ~sigs(2);
    
    check_types(7) = (sigs(1) || sigs(2)) && ~(sigs(3) || sigs(4));
    check_types(8) = (sigs(3) || sigs(4)) && ~(sigs(1) || sigs(2));
    
    check_types(9) = ~any( check_types(1:8) );
    check_types(10) = true;
    
    for k = 1:numel(check_types)      
      cts(k) = cts(k) + check_types(k);
    end
  end
  
  for j = 1:numel(cts)
    append1( out_labs, labels, each_I{i} );
    setcat( out_labs, 'outcomes', type_labels{j}, rows(out_labs) );
  end
  
  out_counts = [ out_counts; cts(:) ];
  
  append1( total_labs, labels, each_I{i} );
  totals(i) = numel( unit_inds );
end

end