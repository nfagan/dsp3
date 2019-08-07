function out_file = summarized_coherence(files, event_name, varargin)

defaults = dsp3.make.defaults.summarized_coherence();
params = dsp3.parsestruct( defaults, varargin );

coh_file = shared_utils.general.get( files, event_name );
coh_labels = copy( params.get_labels_func(coh_file) );

[labels, ind] = dsp3.get_subset( coh_labels, params.subset );
data = coh_file.data(ind, :, :);

[summarized_labels, I] = keepeach( labels', params.summary_spec );
summarized_data = rowop( data, I, params.summary_func );

out_file = coh_file;
out_file.params = shared_utils.struct.union( params, coh_file.params );
out_file.data = summarized_data;
out_file.labels = summarized_labels;

end