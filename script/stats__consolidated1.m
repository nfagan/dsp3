repadd( 'dsp3/script' );

%%  pro v. anti coh, non drug

rev_types = dsp3.get_rev_types();

conf = dsp3.config.load();
params = dsp3.get_behav_stats_defaults();

params.config = conf;
params.specificity = 'sites';
params.is_pro_minus_anti = false;
params.do_save = true;
params.is_z = true;
params.spectra = false;

params.remove = rev_types('orig');

stats__proanti_coh( params );

%%  gamma-beta coherence ratio, nondrug

params = dsp3.get_behav_stats_defaults();

params.config = conf;
params.do_save = false;
params.is_z = false;
params.epochs = 'targacq';
params.do_plot = false;

params.remove = rev_types('orig');

stats__gamma_beta_ratio( params );

