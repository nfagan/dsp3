function defaults = summarized_coherence(varargin)

defaults = dsp3.get_common_make_defaults( varargin{:} );
defaults.summary_func = @(x) nanmedian( x, 1 );
defaults.summary_spec = { 'days', 'regions', 'channels', 'sessions', 'blocks', 'outcomes', 'trialtypes' };
defaults.subset = 'nondrug_wbd';
defaults.get_labels_func = @(coh_file) coh_file.labels;

end