function defaults = cc_sfcoherence()

defaults = dsp3.get_common_make_defaults();
defaults.overwrite = false;
defaults.is_parallel = true;
defaults.config = dsp3.config.load();
defaults.chronux_params = struct( 'Fs', 1e3, 'tapers', [1.5, 2] );
defaults.epoch = 'targacq';
defaults.filter = true;
defaults.reference_subtract = true;
defaults.f1 = 2.5;
defaults.f2 = 250;
defaults.filter_order = 2;
defaults.sample_rate = 1e3;

end