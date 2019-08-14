function results = save_psd(input_subdir, output_subdir, varargin)

defaults = dsp3.make.defaults.psd();

inputs = { fullfile('aligned_lfp', input_subdir) };
output = fullfile( 'per_trial_psd', output_subdir );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );
runner.save_func = @(path, var) save(path, 'var', '-v7.3');

results = runner.run( @dsp3.make.psd, input_subdir, params );

end