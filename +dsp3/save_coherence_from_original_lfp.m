function results = save_coherence_from_original_lfp(event_name, site_pairs, varargin)

defaults = dsp3.make.defaults.coherence();
defaults.transform_func = @(x) dsp3.make.util.lfp_signal_container_to_struct( x, event_name );

inputs = { fullfile('original_aligned_lfp', event_name) };
output = fullfile( 'original_per_trial_coherence', event_name );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );
runner.get_identifier_func = @(varargin) char(varargin{1}('days'));
runner.get_filename_func = @(varargin) sprintf('%s.mat', varargin{1});

% Data are already reference subtracted and filtered
results = runner.run( @dsp3.make.coherence, event_name, site_pairs, params ...
  , 'reference_subtract', false ...
  , 'filter', false ...
);

end