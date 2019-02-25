function defaults = summarized_cc_sf_coherence()

defaults = dsp3.get_common_make_defaults();
defaults.config = dsp3.config.load();
defaults.overwrite = false;
defaults.is_parallel = true;
defaults.skip_existing = true;
defaults.epoch = 'targacq';

end