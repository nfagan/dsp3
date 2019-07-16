function out_file = summarized_psd(files, event_name, varargin)

defaults = dsp3.make.defaults.summarized_psd();
params = dsp3.parsestruct( defaults, varargin );

psd_file = shared_utils.general.get( files, event_name );

[labels, ind] = dsp3.get_subset( psd_file.labels', params.subset );
data = psd_file.data(ind, :, :);

[summarized_labels, I] = keepeach( labels', params.summary_spec );
summarized_data = rowop( data, I, params.summary_func );

out_file = psd_file;
out_file.params = shared_utils.struct.union( params, psd_file.params );
out_file.data = summarized_data;
out_file.labels = summarized_labels;

end