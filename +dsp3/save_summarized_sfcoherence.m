function results = save_summarized_sfcoherence(event_name, varargin)

defaults = dsp3.make.defaults.summarized_coherence();

inputs = { fullfile('per_trial_spike_field_coherence', event_name) };
output = fullfile( 'summarized_sfcoherence', event_name );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = runner.run( @dsp3.make.summarized_coherence, event_name, params );

end