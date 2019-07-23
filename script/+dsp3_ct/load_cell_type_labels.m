function cell_type_labels = load_cell_type_labels(filename, conf)

if ( nargin < 2 || isempty(conf) )
  conf = dsp3.config.load();
end

load_file = fullfile( dsp3.dataroot(conf), 'analyses' ...
  , 'cell_type_compare_baseline', 'cell_type_labels', filename );

cell_type_labels = shared_utils.io.fload( load_file );

end