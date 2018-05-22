function save_units_to_picto_time(varargin)

defaults = dsp3.get_common_make_defaults();

params = dsp3.parsestruct( defaults, varargin );

unit_p = dsp3.get_intermediate_dir( 'unit_conts' );

consolidated = dsp3.get_consolidated_data();

unit_mats = dsp3.require_intermediate_mats( params.files, unit_p, params.files_containing );

align = consolidated.align;
align_key = consolidated.align_key;

for i = 1:numel(unit_mats)
  fprintf( '\n %d of %d', i, numel(unit_mats) );

  unit_struct = shared_utils.io.fload( unit_mats{i} );

  unit_cont = unit_struct.units;

  unit_cont_picto = dsp3.make_units_to_picto_time( unit_cont, align, align_key );

  unit_struct.units_to_picto_time = unit_cont_picto;

  save( unit_mats{i}, 'unit_struct' );
end

end