function results = save_summarized_coherence(event_name, input_directory, output_directory, varargin)

defaults = dsp3.make.defaults.summarized_coherence();

inputs = { fullfile(input_directory, event_name) };
output = fullfile( output_directory, event_name );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = runner.run( @dsp3.make.summarized_coherence, event_name, params );

end