function results = dsp3_make_summarized_cc_sf_coh(varargin)

defaults = dsp3.get_common_make_defaults();
params = dsp3.parsestruct( defaults, varargin );

epoch = params.epoch;
conf = params.config;

input_dir = fullfile( 'cc_sfcoherence', epoch );
output_dir = fullfile( 'summarized_cc_sfcoherence', epoch );

runner = shared_utils.pipeline.LoopedMakeRunner();
runner.input_directories = dsp3.get_intermediate_dir( input_dir, conf );
runner.output_directory = char( dsp3.get_intermediate_dir(output_dir, conf) );
runner.is_parallel = params.is_parallel;
runner.get_identifier_func = @(varargin) varargin{1}.unified_filename;
runner.overwrite = params.overwrite;
runner.save_func = @(filename, out) save(filename, 'out', '-v7.3');

results = runner.run( @dsp3.make.summarized_cc_sf_coherence, params );

end