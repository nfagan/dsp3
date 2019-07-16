function out_labs = label_cell_type(ps, labels, each_I)

assert_ispair( ps, labels );

outcomes = { 'self', 'both', 'other', 'none', 'self_and_both', 'other_and_none' };
type_labels = [ outcomes, {'received', 'forgone'}, {'not_significant'} ];

out_labs = fcat();

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
    
    for k = 1:numel(check_types)      
      if ( check_types(k) )
        append1( out_labs, labels, unit_inds{j} );
        setcat( out_labs, 'outcomes', type_labels{k}, rows(out_labs) );
      end
    end
  end
end

end