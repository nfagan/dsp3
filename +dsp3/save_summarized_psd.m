function results = save_summarized_psd(output_subdir, varargin)

defaults = dsp3.make.defaults.summarized_psd();
params = dsp3.parsestruct( defaults, varargin );

inputs = { fullfile(params.input_subdir, output_subdir) };
output = fullfile( 'original_summarized_psd', output_subdir );

[~, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = runner.run( @dsp3.make.summarized_psd, output_subdir, params );

end