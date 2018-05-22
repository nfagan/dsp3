function save_unit_containers(varargin)

defaults = dsp3.get_common_make_defaults();

params = dsp3.parsestruct( defaults, varargin );

unit_p = dsp3.get_intermediate_dir( 'units' );
output_p = dsp3.get_intermediate_dir( 'unit_conts' );

unit_mats = dsp3.require_intermediate_mats( params.files, unit_p, params.files_containing );

for i = 1:numel(unit_mats)
  fprintf( '\n %d of %d', i, numel(unit_mats) );

  unit_struct = shared_utils.io.fload( unit_mats{i} );
  units = unit_struct.units;

  output_file = fullfile( output_p, unit_struct.file );

  if ( dsp3.conditional_skip_file(output_file, params.overwrite) )
    continue;
  end
  
  unit_cont = dsp3.get_unit_container( units );

  output_unit_struct = struct();
  output_unit_struct.units = unit_cont;
  output_unit_struct.file = unit_struct.file;

  shared_utils.io.require_dir( output_p );
  
  save( output_file, 'output_unit_struct' );    
end

end