function tf_measure_to_signal_container(data, labels, freqs, t, window_size, step_size)

if ( nargin < 5 )
  window_size = nan;
end

if ( nargin < 6 )
  step_size = nan;
end

assert_ispair( data, labels );
assert( size(data, 2) == numel(freqs), 'Frequencies do not correspond to 2nd dimension.' );
assert( size(data, 3) == numel(t), 'Time do not correspond to 3rd dimension.' );

labs = SparseLabels.from_fcat( labels );
cont = SignalContainer( Container(data, labs) );

cont.start = min( t );
cont.stop = max( t );
cont.frequencies = freqs;
cont.step_size = step_size;
cont.window_size = window_size;

end