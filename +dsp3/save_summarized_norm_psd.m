function results = save_summarized_norm_psd(event_name, varargin)

defaults = dsp3.make.defaults.summarized_psd();

inputs = { fullfile('original_per_trial_norm_psd', event_name) };
output = fullfile( 'original_summarized_norm_psd', event_name );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = runner.run( @dsp3.make.summarized_psd, event_name, params );

end