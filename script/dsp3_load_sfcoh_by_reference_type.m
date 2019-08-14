function [coh, coh_labs, f, t] = dsp3_load_sfcoh_by_reference_type(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

intermediate_dir = dsp3.get_intermediate_dir( 'summarized_sfcoherence', conf );
old_subdir = 'targAcq-150-original-reference-method';
new_subdir = 'targAcq-150';

old_dir = fullfile( intermediate_dir, old_subdir );
new_dir = fullfile( intermediate_dir, new_subdir );

[coh, coh_labs, f, t] = dsp3_load_data_by_reference_type( old_dir, new_dir );

end