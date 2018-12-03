
cons = dsp3.get_consolidated_data( dsp3.config.load );

%%
% stats__runall_combs('funcs', @plot_pref_index_over_time)

plot_pref_index_over_time( ...
    'n_keep_post',          Inf ...
  , 'base_prefix',          'bin_threshold__day' ...
  , 'consolidated',         cons ...
  , 'base_subdir',          'revB' ...
  , 'remove',               dsp3.bad_days_revB ...
  , 'drug_type',            'drug_wbd' ...
  , 'fractional_bin',       false ...
  , 'bin_fraction',         0.25 ...
  , 'do_save',              false ...
  , 'do_permute',           true ...
  , 'per_monkey',           false ...
  , 'apply_bin_threshold',  true ...
);