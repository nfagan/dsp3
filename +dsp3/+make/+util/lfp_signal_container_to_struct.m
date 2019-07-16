function lfp_file = lfp_signal_container_to_struct(signal_cont, event_name)

% Convert SignalContainer to format expected by dsp3.make.coherence

sample_rate = signal_cont.fs;
start = signal_cont.start;
stop = signal_cont.stop;
window_size = signal_cont.window_size;

lfp_file = struct();
lfp_file.src_filename = char( signal_cont('days') );

lfp_file.params = struct();
lfp_file.params.min_t = start / sample_rate;
lfp_file.params.max_t = stop / sample_rate;
lfp_file.params.window_size = window_size / sample_rate;
lfp_file.params.event_name = event_name;

lfp_file.sample_rate = sample_rate;
lfp_file.data = signal_cont.data;
lfp_file.labels = fcat.from( signal_cont.labels );
lfp_file.t = start:stop+window_size-1;
lfp_file.has_parial_data = false( size(signal_cont.data, 1), 1 );

renamecat( lfp_file.labels, 'regions', 'region' );
renamecat( lfp_file.labels, 'channels', 'channel' );

end