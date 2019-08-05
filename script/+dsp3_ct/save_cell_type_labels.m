function save_cell_type_labels(cell_type_labels, new_to_orig, filename, conf)

if ( nargin < 4 || isempty(conf) )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

save_p = fullfile( dsp3.dataroot(conf), 'analyses', 'cell_type_compare_baseline', 'cell_type_labels' );
shared_utils.io.require_dir( save_p );

%%
[unit_I, unit_C] = findall( cell_type_labels, {'cc_data_index', 'cc_unit_index'} );

cc_new_to_orig = [];
cc_cell_types = {};

for i = 1:numel(unit_I)
  data_index = fcat.parse( unit_C{1, i}, 'cc_data_index__' );
  unit_index = fcat.parse( unit_C{2, i}, 'cc_unit_index__' );
  
  cc_new_to_orig(end+1, :) = [ data_index, unit_index ];
  
  outcomes = combs( cell_type_labels, 'outcomes', unit_I{i} );
  
  if ( any(strcmp(outcomes, 'not_significant')) )
    cc_cell_types{end+1, 1} = 'not_outcome_selective';
  else
    cc_cell_types{end+1, 1} = 'outcome_selective';
  end
end

cc_cell_type_labels = struct();
cc_cell_type_labels.labels = gather( cell_type_labels );
cc_cell_type_labels.cell_types = cc_cell_types;
cc_cell_type_labels.new_to_original = cc_new_to_orig;

%%

save( fullfile(save_p, filename), 'cell_type_labels', 'new_to_orig' );
save( fullfile(save_p, sprintf('cc_%s', filename)), 'cc_cell_type_labels' );

end