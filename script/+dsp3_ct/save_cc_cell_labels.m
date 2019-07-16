conf = dsp3.config.load();
consolidated = dsp3.get_consolidated_data( conf );
sua = dsp3_ct.load_sua_data( conf );
[spike_ts, spike_labels, event_ts, event_labels, new_to_orig] = dsp3_ct.linearize_sua( sua );
%%

ct_labels = dsp3_ct.load_cell_type_labels( 'targAcq.mat' );

ct_labels = dsp3_ct.add_task_modulated_labels( ct_labels', ct_labels );
ct_labels = prune( ct_labels );

keepeach( ct_labels, 'unit_uuid' );
labs = gather( ct_labels );
cell_types = ct_labels(:, 'cell_type');

out = struct();
out.labels = labs;
out.cell_types = cell_types;
out.new_to_original = new_to_orig;

file_path = fullfile( dsp3.dataroot(conf), 'analyses' ...
  , 'cell_type_compare_baseline', 'cell_type_labels', 'new_to_original.mat' );
save( file_path, 'out' );
