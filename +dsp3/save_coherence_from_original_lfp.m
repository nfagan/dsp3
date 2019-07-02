function results = save_coherence_from_original_lfp(event_name, site_pairs, varargin)

defaults = dsp3.make.defaults.coherence();
defaults.transform_func = @(x) transform_func( x, event_name );

inputs = { fullfile('original_aligned_lfp', event_name) };
output = fullfile( 'original_per_trial_coherence', event_name );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );
runner.get_identifier_func = @(varargin) char(varargin{1}('days'));
runner.get_filename_func = @(varargin) sprintf('%s.mat', varargin{1});

% Data are already reference subtracted and filtered
results = runner.run( @dsp3.make.coherence, event_name, site_pairs, params ...
  , 'reference_subtract', false ...
  , 'filter', false ...
);

end

function lfp_file = transform_func(signal_cont, event_name)

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