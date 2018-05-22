function save_ms_units(varargin)

%
% post_2 -> post
% 1052017 -> 01052017
%

defaults = dsp3.get_common_make_defaults();

params = dsp3.parsestruct( defaults, varargin );

conf = dsp3.config.load();

ms_p = fullfile( conf.PATHS.data_root, 'mountain_sort', 'firings' );
mdas = shared_utils.io.dirnames( ms_p, '.mda', false );

trial_data_p = dsp3.get_intermediate_dir( 'consolidated' );
trial_data_m = shared_utils.io.find( trial_data_p, '.mat' );

assert( numel(trial_data_m) == 1 );

consolidated = shared_utils.io.fload( trial_data_m{1} );

xls_unit_map = dsp3.get_unit_xls_map();
pl2_info = consolidated.pl2_info;

unit_save_p = dsp3.get_intermediate_dir( 'units' );

for i = 1:numel(mdas)
  units = dsp3.make_ms_units( xls_unit_map, pl2_info.channel_map ...
    , pl2_info.start_times, pl2_info.files, pl2_info.sessions, pl2_info.days, ms_p, mdas{i} );

  if ( isempty(units) )
    continue; 
  end

  mat = strrep( mdas{i}, 'mda', 'mat' );

  output_file = fullfile( unit_save_p, mat );

  if ( dsp3.conditional_skip_file(output_file, params.overwrite) )
    continue;
  end

  full_filename = fullfile( unit_save_p, mat );

  shared_utils.io.require_dir( unit_save_p );

  unit_struct = struct();
  unit_struct.units = units;
  unit_struct.file = mat;

  save( full_filename, 'unit_struct' );
end

end