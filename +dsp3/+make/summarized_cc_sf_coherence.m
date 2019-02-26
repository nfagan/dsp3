function out_file = summarized_cc_sf_coherence(files, varargin)

defaults = dsp3.make.defaults.summarized_cc_sf_coherence();
params = dsp3.parsestruct( defaults, varargin );

coh_file = shared_utils.general.get( files, params.epoch );

labels = fcat.from( coh_file.labels, coh_file.categories );
data = coh_file.coherence;

assert_ispair( data, labels );

mean_spec = { 'channels', 'regions', 'spike_regions', 'spike_channels', 'days', 'sites' ...
  , 'outcomes', 'blocks', 'sessions', 'trialtypes' };

[new_labels, I] = keepeach( labels', mean_spec );

new_data = rowop( data, I, @(x) nanmean(x, 1) );

out_file = coh_file;
out_file.params = params;
out_file.coherence = new_data;
[out_file.labels, out_file.categories] = categorical( new_labels );

end