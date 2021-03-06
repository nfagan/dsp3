function out = psd(files, event_name, varargin)

defaults = dsp3.make.defaults.psd();
defaults.step_size = 0.05;

params = dsp3.parsestruct( defaults, varargin );

lfp_file = shared_utils.general.get( files, event_name );
lfp_file = params.transform_func( lfp_file );

data = lfp_file.data;

labels = lfp_file.labels';

if ( hascat(labels, 'region') )
  renamecat( labels, 'region', 'regions' );
end

if ( hascat(labels, 'channel') )
  renamecat( labels, 'channel', 'channels' );
end

if ( params.reference_subtract )
  [data, labels] = params.reference_func( data, labels' );
end

if ( params.filter )
  data = dsp3.zpfilter( data, params.f1, params.f2, lfp_file.sample_rate, params.filter_order );
end

window_size = lfp_file.params.window_size * lfp_file.sample_rate;
step_size = params.step_size * lfp_file.sample_rate;

windowed_data = shared_utils.array.bin3d( data, window_size, step_size );
time_series = shared_utils.vector.slidebin( lfp_file.t, window_size, step_size, true );
time_series = cellfun( @(x) x(1), time_series );

if ( ~isempty(windowed_data) )
  assert( numel(time_series) == size(windowed_data, 3), 'Time series mismatch.' );
else
  time_series = [];
  f = [];
  complete_psd = [];
end

num_time_bins = numel( time_series );

for i = 1:num_time_bins  
  [psd, f] = mtspectrumc( windowed_data(:, :, i)', params.chronux_params );
  
  if ( i == 1 )
    complete_psd = nan( size(psd, 2), size(psd, 1), num_time_bins );
  end
  
  complete_psd(:, :, i) = psd';
end

assert_ispair( complete_psd, labels );

out = struct();
out.params = params;
out.src_filename = lfp_file.src_filename;
out.data = complete_psd;
out.labels = labels;
out.t = time_series;
out.f = f;

end