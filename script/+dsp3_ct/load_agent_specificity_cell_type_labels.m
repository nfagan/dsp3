function cell_type_labels = load_agent_specificity_cell_type_labels(datedir, filename, conf)

if ( nargin < 3 || isempty(conf) )
  conf = dsp3.config.load();
end

load_file = fullfile( dsp3.dataroot(conf), 'analyses' ...
  , 'cell_type_agent_specificity', datedir, filename );

cell_type_labels = shared_utils.io.fload( load_file );

end