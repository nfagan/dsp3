function sfcoherence(files, event_name, spike_ts, spike_labels, varargin)

assert_ispair( spike_ts, spike_labels );

defaults = dsp3.make.defaults.coherence();
params = dsp3.parsestruct( defaults, varargin );

lfp_file = shared_utils.general.get( files, event_name );
lfp_file = params.transform_func( lfp_file );

data = lfp_file.data;

labels = lfp_file.labels';
renamecat( labels, 'region', 'regions' );
renamecat( labels, 'channel', 'channels' );

if ( params.reference_subtract )
  [data, labels, kept_I] = dsp3.ref_subtract( data, labels' );
end

if ( params.filter )
  data = dsp3.zpfilter( data, params.f1, params.f2, lfp_file.sample_rate, params.filter_order );
end

window_size = lfp_file.params.window_size * lfp_file.sample_rate;
step_size = params.step_size * lfp_file.sample_rate;

windowed_data = shared_utils.array.bin3d( data, window_size, step_size );

time_series = get_time_series( lfp_file, params.step_size );
assert( numel(time_series) == size(windowed_data, 3), 'Time series mismatch.' );

d = 10;

end