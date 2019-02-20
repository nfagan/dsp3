%%
xls_p = fullfile( dsp3.dataroot(), 'xls', 'KURO_HITCH_Sites Coordinates_with_unit_ids.xlsx' );
[~, ~, xls_raw] = xlsread( xls_p );

[anatomy, anatomy_labels] = dsp3_anatomy_xls_to_data_and_labels( xls_raw );

%%

unit_mats = shared_utils.io.findmat( dsp3.get_intermediate_dir('unit_conts') );

unit_data = [];
unit_labels = fcat();

for i = 1:numel(unit_mats)
  shared_utils.general.progress( i, numel(unit_mats) );
  
  unit_file = shared_utils.io.fload( unit_mats{i} );
  
  unit_data = [ unit_data; unit_file.units.data ];
  append( unit_labels, fcat.from(unit_file.units.labels) );
end

%%

only_units = rowmask( unit_labels );  % use all units

[unit_I, unit_file_uuids] = findall( unit_labels, 'unit_uuid', only_units );
[anat_I, anatomy_uuids] = findall( anatomy_labels, 'unit_uuid' );

for i = 1:numel(unit_I)
  anatomy_mask = find( anatomy_labels, unit_file_uuids{i} );
  
  if ( isempty(anatomy_mask) )
    continue;
  end
  
  unit_file_reg = combs( unit_labels, {'region', 'channel'}, unit_I{i} );
  anatomy_reg = combs( anatomy_labels, {'region', 'channel'}, anatomy_mask );
  
  % Ensure regions + channels are the same for each unit uuid
  assert( numel(unit_file_reg) == 2 && numel(anatomy_reg) == 2 );
  assert( all(strcmp(anatomy_reg, unit_file_reg)) );
end