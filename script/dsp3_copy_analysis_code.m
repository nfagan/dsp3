func_names = { ...
    'stats__rt', 'stats__n_incomplete', 'stats__pref', 'stats__gaze', 'stats__rt' ... % fig 1.
  , 'dsp3_ct.plot_sfcoh_by_look_type' ...
  , 'dsp3_run_stats_lda' ...  % fig 5.
  , 'dsp3_sfq.run_plot_sfcoh_by_lfp_site_quantile' ...
  , 'dsp3_run_plot_sfcoh_by_spike_quantile' ... % fig s3a.
  , 'dsp3_plot_psd_new' ...
};
  
out_p = '/Users/Nick/Documents/Chang Lab Work/papers/specialized-medial-prefontal-amygdala-coordination/code';

for i = 1:numel(func_names)
  func_name = func_names{i};
  file_path = which( func_name );
  first_package_dir = min( strfind(file_path, '+') );
  
  full_out_p = out_p;
  
  if ( ~isempty(first_package_dir) )
    rest = file_path(first_package_dir:end);
    split = strsplit( rest, filesep );
    full_out_p = fullfile( full_out_p, split{1:end-1} );
    func_name = split{end};
  end
  
  if ( ~endsWith(func_name, '.m') )
    func_name = [ func_name, '.m' ];
  end
  
  shared_utils.io.require_dir( full_out_p );
  copyfile( file_path, fullfile(full_out_p, func_name) );
end