function make_ms_units()

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

  mat = strrep( mdas{i}, 'mda', 'mat' );

  full_filename = fullfile( unit_save_p, mat );

  shared_utils.io.require_dir( unit_save_p );

  save( full_filename, 'units' );
end

end