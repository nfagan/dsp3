function results = save_sfcoherence(input_subdir, output_subdir, spike_ts, spike_labels, varargin)

defaults = dsp3.make.defaults.coherence();

inputs = { fullfile('aligned_lfp', input_subdir) };
output = fullfile( 'per_trial_spike_field_coherence', output_subdir );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );
runner.save_func = @(path, var) save(path, 'var', '-v7.3');

results = runner.run( @dsp3.make.sfcoherence, input_subdir, spike_ts, spike_labels, params );

end