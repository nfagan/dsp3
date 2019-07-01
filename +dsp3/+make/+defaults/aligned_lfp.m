function defaults = aligned_lfp(varargin)

defaults = dsp3.get_common_make_defaults( varargin{:} );
defaults.is_parallel = true;
defaults.config = dsp3.config.load();
defaults.min_t = -0.5;
defaults.max_t = 0.5;
defaults.window_size = 0.15;
defaults.event_name = '';
defaults.consolidated_data = [];

end