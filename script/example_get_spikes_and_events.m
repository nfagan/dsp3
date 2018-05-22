unit_p = dsp3.get_intermediate_dir( 'unit_conts' );

consolidated = dsp3.get_consolidated_data();

events = consolidated.events;

unit_mats = dsp3.require_intermediate_mats( [], unit_p, [] );

for i = 1:numel(unit_mats)
  fprintf( '\n %d of %d', i, numel(unit_mats) );
  
  units_file = shared_utils.io.fload( unit_mats{i} );
  
  units = units_file.units_to_picto_time;
  
  session = units('session_ids');
  
  assert( numel(session) == 1 );
  
  subset_events = only( events, session );
  
  [I, C] = get_indices( units, 'unit_uuid' );
  
  for j = 1:numel(I)
    one_unit = units(I{j});
    
    assert( shape(one_unit, 1) == 1 );
    
    data = one_unit.data{1};
    
    region = one_unit('region');
    channel = one_unit('channel');
  end
  
end