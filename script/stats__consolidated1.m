repadd( 'dsp3/script' );

%%  pro v. anti coh / power, non drug

rev_types = dsp3.get_rev_types();

conf = dsp3.config.load();
params = dsp3.get_behav_stats_defaults();

params.config = conf;
params.specificity = 'sites';
params.is_pro_minus_anti = false;
params.do_save = true;
params.is_z = false;
params.spectra = false;
params.measure = 'coherence'; % raw_power
params.drug_type = 'nondrug';

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

%%  preference index over time, drug

cons = dsp3.get_consolidated_data( dsp3.config.load );
rev_types = dsp3.get_rev_types();

rev_type = 'revB';

plot_pref_index_over_time( ...
    'n_keep_post',          Inf ...
  , 'base_prefix',          'bin_threshold__day' ...
  , 'consolidated',         cons ...
  , 'base_subdir',          rev_type ...
  , 'remove',               rev_types(rev_type) ...
  , 'drug_type',            'drug_wbd' ...
  , 'fractional_bin',       true ...
  , 'bin_fraction',         0.25 ...
  , 'do_save',              true ...
  , 'do_permute',           true ...
  , 'per_monkey',           false ...
  , 'apply_bin_threshold',  true ...
);

