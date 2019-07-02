function out = dsp3_load_day_formatted_aligned_lfp(event_name, varargin)

defaults = dsp3.get_common_make_defaults();
defaults.is_parallel = true;
defaults.config = dsp3.config.load();
defaults.include_data = true;

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;

output_directory = fullfile( dsp3.dataroot(conf), 'analyses', 'reprocessed_signals', event_name );
shared_utils.io.require_dir( output_directory );

loop_runner = shared_utils.pipeline.LoopedMakeRunner();
loop_runner.convert_to_non_saving_with_output();
loop_runner.is_parallel = params.is_parallel;
loop_runner.input_directories = ...
  fullfile( dsp3.get_intermediate_dir('aligned_lfp', conf), event_name );
loop_runner.get_filename_func = @(varargin) strrep(varargin{1}, '.pl2', '.mat');
loop_runner.get_identifier_func = @(varargin) varargin{1}.src_filename;

results = loop_runner.run( @load_aligned, event_name, params );
outputs = [ results([results.success]).output ];

data = vertcat( outputs.data );
labels = vertcat( fcat, outputs.labels );
has_partial_data = vertcat( outputs.has_partial_data );

out = struct();
out.data = data;
out.labels = labels;
out.fs = outputs(1).fs;
out.start = outputs(1).start;
out.stop = outputs(1).stop;
out.step_size = outputs(1).step_size;
out.window_size = outputs(1).window_size;
out.has_partial_data = has_partial_data;

end

function outs = load_aligned(files, event_name, params)

event_file = shared_utils.general.get( files, event_name );

outs = struct();
outs.fs = event_file.sample_rate;
outs.start = round( event_file.params.min_t * event_file.sample_rate );
outs.stop = round( event_file.params.max_t * event_file.sample_rate );
outs.step_size = nan;
outs.window_size = round( event_file.params.window_size * event_file.sample_rate );

if ( params.include_data )
  outs.data = event_file.data;
else
  outs.data = [];
end

outs.has_partial_data = event_file.has_partial_data;
outs.labels = event_file.labels;

end