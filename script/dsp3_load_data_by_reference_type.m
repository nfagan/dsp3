function [coh, coh_labs, f, t] = dsp3_load_data_by_reference_type(old_dir, new_dir)

old_mats = shared_utils.io.findmat( old_dir );
new_mats = shared_utils.io.findmat( new_dir );

get_labels_func = @(x) x.labels;
load_inputs = { 'get_labels_func', get_labels_func };

[old_coh, old_labels, f, t] = bfw.load_time_frequency_measure( old_mats, load_inputs{:} );
[new_coh, new_labels] = bfw.load_time_frequency_measure( new_mats, load_inputs{:} );

if ( ~isempty(old_labels) )
  addsetcat( old_labels, 'reference_method', 'reference_subtract' );
end

if ( ~isempty(new_labels) )
  addsetcat( new_labels, 'reference_method', 'bipolar_derivation' );
end

coh_labs = append( old_labels', new_labels );
coh = [ old_coh; new_coh ];

end