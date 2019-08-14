function defaults = summarized_psd(varargin)

defaults = dsp3.get_common_make_defaults( varargin{:} );
defaults.summary_func = @(x) nanmedian( x, 1 );
defaults.summary_spec = { 'days', 'regions', 'channels', 'sessions', 'blocks', 'outcomes', 'trialtypes' };
defaults.subset = 'nondrug_wbd';
defaults.input_subdir = 'original_per_trial_psd';
defaults.output_subdir = 'original_summarized_psd';

end