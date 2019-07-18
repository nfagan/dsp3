function results = save_per_trial_norm_psd(targ_event, base_event, varargin)

defaults = dsp3.make.defaults.norm_psd();

inputs = cellfun( @(x) fullfile('original_per_trial_psd', x), {targ_event, base_event}, 'un', 0 );
output = fullfile( 'original_per_trial_norm_psd', targ_event );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = runner.run( @dsp3.make.norm_psd, targ_event, base_event, params );

end