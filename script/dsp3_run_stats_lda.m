bands = dsp3.get_bands( 'map' );

freq_roi_name = 'beta';
freq_roi = bands(freq_roi_name);

% freq_roi_name = '55_65_gamma';
% freq_roi = [ 55, 65 ];

stats__lda( ...
      'underlying_measure', 'sfcoherence' ...
    , 'specificity', 'contexts' ...
    , 'plot_per_site', false ...
    , 'over_frequency', false ...
    , 'xlims', [-150, 150] ...
    , 'freq_window', freq_roi ...
    , 'freq_roi_name', freq_roi_name ...
    , 'smooth_func', @(x) x ...
    , 'do_save', true ...
    , 'stats_time_window', [50, 150] ...
    , 'line_evaluation', 'signrank' ...
    , 'take_mean_time_window_for_stats', true ...
    , 'base_subdir', 'mean_time_window' ...
    , 'pro_v_anti_lines_are', 'p' ...
    , 'pro_v_anti_ylims', [-6, 6] ...
    , 'lines_v_null_ylims', [49, 56] ...
    , 'make_figs', true ...
);

%%  compare bands

bands = dsp3.get_bands( 'map' );

freq_roi_names = { 'beta', 'new_gamma' };
freq_rois = cellfun( @(x) bands(x), freq_roi_names, 'un', 0 );

% freq_roi_name = '55_65_gamma';
% freq_roi = [ 55, 65 ];

stats__lda( ...
      'underlying_measure', 'sfcoherence' ...
    , 'specificity', 'contexts' ...
    , 'plot_per_site', false ...
    , 'over_frequency', false ...
    , 'xlims', [-150, 150] ...
    , 'freq_window', freq_rois ...
    , 'freq_roi_name', freq_roi_names ...
    , 'smooth_func', @(x) x ...
    , 'do_save', true ...
    , 'stats_time_window', [-50, 50] ...
    , 'line_evaluation', 'signrank' ...
    , 'take_mean_time_window_for_stats', true ...
    , 'base_subdir', 'mean_time_window' ...
    , 'pro_v_anti_lines_are', 'p' ...
    , 'pro_v_anti_ylims', [-6, 6] ...
    , 'lines_v_null_ylims', [49, 56] ...
    , 'make_figs', true ...
    , 'plot_spec', { 'days' } ...
);

%%

% [-50, 50] -> beta (bla_s -> acc_f): z = 12.2 p < 0.0001
%           -> gamma (acc_s -> bla_f): z = -11.9, p < 0.0001
%
% [50, 150] -> beta (bla_s -> acc_f): z = -12.02, p < 0.0001
%           -> gamma (acc_s -> bla_f): z = 12.21 p < 0.0001
