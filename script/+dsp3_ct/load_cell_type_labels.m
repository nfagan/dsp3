function [cell_type_labels, new_to_orig] = load_cell_type_labels(filename, conf)

if ( nargin < 2 || isempty(conf) )
  conf = dsp3.config.load();
end

load_file = fullfile( dsp3.dataroot(conf), 'analyses' ...
  , 'cell_type_compare_baseline', 'cell_type_labels', filename );

outs = load( load_file );
cell_type_labels = outs.cell_type_labels;
new_to_orig = outs.new_to_orig;

end