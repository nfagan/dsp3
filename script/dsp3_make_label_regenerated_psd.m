defaults = dsp3.make.defaults.summarized_psd();
defaults.summary_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes' };

dsp3.save_summarized_psd( 'targOn-150-cc', defaults );

%%

event_name = 'targOn-150-cc';

defaults = dsp3.make.defaults.psd();
defaults.transform_func = @(x) dsp3.make.util.lfp_signal_container_to_struct( x, event_name );
% defaults.summary_spec = { 'days', 'regions', 'channels', 'administration', 'outcomes', 'trialtypes' };

inputs = { fullfile('original_aligned_lfp', event_name) };
output = fullfile( 'original_per_trial_psd', event_name );

[params, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, {} );
runner.get_identifier_func = @(varargin) char(varargin{1}('days'));
runner.get_filename_func = @(varargin) sprintf('%s.mat', varargin{1});

% Data are already reference subtracted and filtered
results = runner.run( @dsp3.make.psd, event_name, params ...
  , 'reference_subtract', true ...
  , 'filter', true ...
);