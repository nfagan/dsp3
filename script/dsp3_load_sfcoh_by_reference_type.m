function [coh, coh_labs, f, t] = dsp3_load_sfcoh_by_reference_type(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

intermediate_dir = dsp3.get_intermediate_dir( 'summarized_sfcoherence', conf );
old_subdir = 'targAcq-150-original-reference-method';
new_subdir = 'targAcq-150';

old_mats = shared_utils.io.findmat( fullfile(intermediate_dir, old_subdir) );
new_mats = shared_utils.io.findmat( fullfile(intermediate_dir, new_subdir) );

get_labels_func = @(x) x.labels;
load_inputs = { 'get_labels_func', get_labels_func };

[old_coh, old_labels, f, t] = bfw.load_time_frequency_measure( old_mats, load_inputs{:} );
[new_coh, new_labels] = bfw.load_time_frequency_measure( new_mats, load_inputs{:} );

addsetcat( old_labels, 'reference_method', 'reference_subtract' );
addsetcat( new_labels, 'reference_method', 'bipolar_derivation' );

coh_labs = append( old_labels', new_labels );
coh = [ old_coh; new_coh ];

end