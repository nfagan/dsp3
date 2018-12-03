repadd( 'dsp3/script' );

%%  pro v. anti coh, non drug

rev_types = dsp3.get_rev_types();
conf = dsp3.config.load();

%%

params = dsp3.get_behav_stats_defaults();

params.config = conf;
params.specificity = 'sites';
params.is_pro_minus_anti = false;
params.do_save = true;
params.is_z = false;
params.spectra = true;
params.drug_type = 'nondrug';
params.measure = 'coherence';

% t_windows = { [-250, 0], [-200, 0], [-150, 0], [-100, 0] };
t_windows = { [-100, 100], [-50, 50] };
smooth_funcs = { struct('func', @(x) x, 'type', 'nonsmoothed') ...
  , struct('func', @(x) smooth(x, 5), 'type', 'smoothed') };
keys = { 'orig' };
is_post_minus_pres = [ false ];

inds = dsp3.numel_combvec( t_windows, smooth_funcs, keys, is_post_minus_pres );

for i = 1:size(inds, 2)
  subdir_components = {};
  
  ind = inds(:, i);
  
  t_window = t_windows{ind(1)};
  smooth_info = smooth_funcs{ind(2)};
  key = keys{ind(3)};
  is_post_minus_pre = is_post_minus_pres(ind(4));
  
  params.remove = rev_types(key);
  
  subdir_components{end+1} = key;
  subdir_components{end+1} = smooth_info.type;
  subdir_components{end+1} = sprintf( '%d_%d', t_window(1), t_window(2) );
  
  params.time_window = t_window;
  params.base_subdir = fullfile( params.measure, strjoin(subdir_components, '_') );
  params.smooth_func = smooth_info.func;
  params.is_post_minus_pre = is_post_minus_pre;
  
  stats__proanti_coh( params );
end

%%  gamma-beta coherence ratio, nondrug

params = dsp3.get_behav_stats_defaults();

params.config = conf;
params.do_save = false;
params.is_z = false;
params.epochs = 'targacq';
params.do_plot = false;

params.remove = rev_types('orig');

stats__gamma_beta_ratio( params );

%%  preference 

params = dsp3.get_behav_stats_defaults();

params.config = conf;
params.do_save = true;
params.drug_type = 'nondrug_wbd'; 
params.base_subdir = 'orig';

params.remove = rev_types('orig');

stats__pref( params );

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
