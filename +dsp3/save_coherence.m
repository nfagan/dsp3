function results = save_coherence(event_name, site_pairs, varargin)

defaults = dsp3.make.defaults.coherence();

inputs = { fullfile('aligned_lfp', event_name) };
output = fullfile( 'per_trial_coherence', event_name );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = runner.run( @dsp3.make.coherence, event_name, site_pairs, params );

end