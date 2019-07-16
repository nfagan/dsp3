function save_cell_type_labels(cell_type_labels, filename, conf)

if ( nargin < 3 || isempty(conf) )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

save_p = fullfile( dsp3.dataroot(conf), 'analyses', 'cell_type_compare_baseline', 'cell_type_labels' );
shared_utils.io.require_dir( save_p );

save( fullfile(save_p, filename), 'cell_type_labels' );

end