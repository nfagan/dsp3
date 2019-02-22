function defaults = summarized_cc_sf_coherence()

defaults = dsp3.get_common_make_defaults();
defaults.config = dsp3.config.load();
defaults.epoch = 'targacq';

end