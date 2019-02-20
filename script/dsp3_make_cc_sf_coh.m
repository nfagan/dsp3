function results = dsp3_make_cc_sf_coh(spike_times, spike_labels, event_times, event_labels, varargin)

assert_ispair( spike_times, spike_labels );
assert_ispair( event_times, event_labels );

defaults = dsp3.make.defaults.cc_sfcoherence();
params = dsp3.parsestruct( defaults, varargin );

epoch = params.epoch;
conf = params.config;

input_dir = fullfile( 'signals', 'none', epoch );
output_dir = 'cc_sfcoherence';

runner = shared_utils.pipeline.LoopedMakeRunner();
runner.input_directories = dsp3.get_intermediate_dir( input_dir, conf );
runner.output_directory = char( dsp3.get_intermediate_dir(output_dir, conf) );
runner.is_parallel = params.is_parallel;
runner.get_identifier_func = @(varargin) varargin{1}.unified_filename;

results = runner.run( @dsp3.make.cc_sfcoherence ...
  , spike_times, spike_labels, event_times, event_labels, params );

end