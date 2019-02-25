function dsp3_plot_sf_coh_by_anatomy()

coh_mats = shared_utils.io.findmat( dsp3.get_intermediate_dir('summarized_cc_sfcoherence/targacq') );

[coh, coh_labels, freqs, t] = dsp3.load_signal_measure( coh_mats ...
  , 'get_time_series_func', @(m, file) file.t ...
  , 'get_frequencies_func', @(m, file) file.f ...
  , 'get_data_func', @(m, file) file.coherence ...
  , 'get_labels_func', @(m, file) fcat.from(file) ...
  , 'is_cached', true ...
);

%%

[anatomy, anatomy_labels] = dsp3_get_unit_anatomy_info();

%%  clustering

rng( 'default' ); % for reproducibility

if ( hascat(anatomy_labels, 'cluster') )
  rmcat( anatomy_labels, 'cluster' );
end

unique_channel_indices = findall( anatomy_labels, {'channel', 'region', 'days'} );
unique_channel_indices = cellfun( @(x) x(1), unique_channel_indices );

all_cluster_indices = nan( rows(anatomy_labels), 1 );
cluster_I = findall_or_one( anatomy_labels, 'region', unique_channel_indices );

for i = 1:numel(cluster_I)
  full_channel_indices = cluster_I{i};
  
  subset_cluster_anatomy = anatomy(full_channel_indices, :);
  
  eva = evalclusters( subset_cluster_anatomy, 'kmeans' ...
    , 'CalinskiHarabasz', 'KList', 1:10 );

  n_clusters = eva.OptimalK;
  [cluster_indices, cluster_centroids, cluster_distances] = ...
    kmeans( subset_cluster_anatomy, n_clusters );

  all_cluster_indices(full_channel_indices) = cluster_indices;

  unique_cluster_indices = unique( cluster_indices );
  addcat( anatomy_labels, 'cluster' );

  for j = 1:numel(unique_cluster_indices)
    cluster_index = cluster_indices == unique_cluster_indices(j);
    assign_index = full_channel_indices(cluster_index);
    
    setcat( anatomy_labels, 'cluster', sprintf('cluster_%d', j), assign_index );
  end
end

%%

path_components = { 'sf_coh_anatomy', datestr(now, 'mmddyy') };

base_prefix = '';
base_subdir = '';
analysis_p = char( dsp3.analysisp(path_components) );
plot_p = char( dsp3.plotp(path_components) );
do_save = true;

band_labels = anatomy_labels';

bands = dsp3.get_bands( 'map' );

band_names = cssetdiff( keys(bands), 'theta' );
pairs = { {'other', 'none'}, {'self', 'both'} };

analysis_combs = dsp3.numel_combvec( band_names, pairs );

min_coh = -0.1;
max_coh = 0.05;
coh_stp = 0.005;
coh_bins = min_coh:coh_stp:max_coh;
coh_bins = [ -flintmax, coh_bins, flintmax ];

color_map = hot( numel(coh_bins) );

for idx = 1:size(analysis_combs, 2)
shared_utils.general.progress( idx, size(analysis_combs, 2) );

band_name = band_names{analysis_combs(1, idx)};
pair_spec = pairs{analysis_combs(2, idx)};

freq_roi = bands(band_name);

use_t = t >= -250 & t <= 0;
use_f = freqs >= freq_roi(1) & freqs <= freq_roi(2);

per_channel_coh = nan( rows(anatomy), 1 );

for i = 1:numel(unique_channel_indices)
  chan_ind = unique_channel_indices(i);
  
  fp_channel = strrep( band_labels(chan_ind, 'channel'), 'SPK', 'FP' );
  region = band_labels(chan_ind, 'region');
  day = band_labels(chan_ind, 'days');
  
  selectors = [ fp_channel, region, day ];
  
  matching_coh = find( coh_labels, selectors );
  matches_a = find( coh_labels, pair_spec{1}, matching_coh );
  matches_b = find( coh_labels, pair_spec{2}, matching_coh );
  
  mean_a = nanmean( nanmean(nanmean(coh(matches_a, use_f, use_t), 1), 2) );
  mean_b = nanmean( nanmean(nanmean(coh(matches_b, use_f, use_t), 1), 2) );
  
  per_channel_coh(chan_ind) = mean_a - mean_b;
  
  addsetcat( band_labels, 'outcome', sprintf('%s-%s', pair_spec{:}), chan_ind );
end

addsetcat( band_labels, 'band', band_name );

%
% plot coherence
%

figure1 = clf( figure(1) );

plot_spec = { 'region', 'band' };

[plot_labels, plot_I] = keepeach_or_one( band_labels', plot_spec, unique_channel_indices );
sp_shape = plotlabeled.get_subplot_shape( numel(plot_I) );

for i = 1:numel(plot_I)
  coh_ax = subplot( sp_shape(1), sp_shape(2), i, 'parent', figure1 );

  is_select_channel = plot_I{i};

  use_channel_coh = per_channel_coh(is_select_channel);
  use_anatomy_labels = prune( band_labels(is_select_channel) );

  assert_ispair( use_channel_coh, use_anatomy_labels );
  
  coh_bin = arrayfun( @(x) find(histc(x, coh_bins)), use_channel_coh, 'un', 0 );
  coh_bin(isnan(use_channel_coh)) = {1};
  coh_bin = vertcat( coh_bin{:} );

  xyz = arrayfun( @(x) anatomy(is_select_channel, x), 1:3, 'un', 0 );

  h = scatter3( coh_ax, xyz{:}, [], color_map(coh_bin, :), 'filled' );
  
  plot_C = combs( band_labels, {'region', 'outcome'}, plot_I{i} );
  plot_C = unique( plot_C );
  plot_C = strjoin( plot_C(:)', ' | ' );
  
  xlabel( coh_ax, 'AP' );
  ylabel( coh_ax, 'ML' );
  zlabel( coh_ax, 'Z' );
  
  title( plot_C );
end

colormap( color_map );
colorbar_handle = colorbar;
shared_utils.plot.set_clims( coh_ax, [min_coh, max_coh] );

shared_utils.plot.fullscreen( figure1 );

%
% stats
%

use_data = per_channel_coh;
use_labels = band_labels';

spec = { 'region', 'outcome', 'band' };
mask = intersect( unique_channel_indices, find(~isnan(use_data)) );

anova_results = dsp3.anova1( use_data, use_labels, spec, 'cluster' ...
  , 'mask', mask ...
);

if ( do_save )
  a_tbls = anova_results.anova_tables;
  a_labs = anova_results.anova_labels;
  m_tbls = anova_results.descriptive_tables;
  m_labs = anova_results.descriptive_labels;
  c_tbls = anova_results.comparison_tables;
  is_sig = anova_results.is_anova_significant;
  
%   use_subdir = strjoin( unique(cshorzcat(pair_spec(:)', band_name)), '_' );

  band_subdir = band_name;
  pair_subdir = strjoin( pair_spec(:)', '_' );
  
  use_analysis_p = fullfile( analysis_p, base_subdir, band_subdir, pair_subdir );
  use_plot_p = fullfile( plot_p, base_subdir, band_subdir, pair_subdir );
  
  anova_p = fullfile( use_analysis_p, 'anova' );
  comparisons_p = fullfile( use_analysis_p, 'comparisons' );
  descriptives_p = fullfile( use_analysis_p, 'descriptives' );

  for i = 1:numel(a_tbls)    
    sig_prefix = ternary( is_sig(i), 'significant_', 'not-significant_' );
    
    full_prefix = sprintf( '%s%s', base_prefix, sig_prefix );
    
    dsp3.savetbl( a_tbls{i}, anova_p, a_labs(i), spec, full_prefix );
    dsp3.savetbl( c_tbls{i}, comparisons_p, a_labs(i), spec, full_prefix );
  end

  dsp3.savetbl( m_tbls, descriptives_p, m_labs, spec, full_prefix );
  
  dsp3.req_savefig( figure1, use_plot_p, plot_labels, plot_spec, base_prefix );
end

end

coh_view = get( coh_ax, 'view' );

%%  

%
% plot cluster indices
%

plot_spec = { 'region' };

[plot_labels, plot_I] = keepeach_or_one( anatomy_labels', plot_spec, unique_channel_indices );

% + 1 for unassigned (NaN) cluster
n_unique_clusters = numel( unique(all_cluster_indices(~isnan(all_cluster_indices))) ) + 1;
cluster_color_map = hsv( n_unique_clusters );

for i = 1:numel(plot_I)
  figure2 = clf( figure(2) );
  
  cluster_ax = cla( axes('parent', figure2) );
  set( cluster_ax, 'nextplot', 'replace' );

  is_select_channel = plot_I{i};
  cluster_indices = all_cluster_indices(is_select_channel);

  xyz = arrayfun( @(x) anatomy(is_select_channel, x), 1:3, 'un', 0 );
  
  is_nan_cluster_index = isnan( cluster_indices );
  non_nan_cluster_indices = cluster_indices(~is_nan_cluster_index);
  non_nan_unique_cluster_indices = unique( non_nan_cluster_indices );
  cluster_labels = arrayfun( @(x) sprintf('cluster-%d', x), non_nan_unique_cluster_indices, 'un', 0 );
  
  hs = gobjects( numel(non_nan_unique_cluster_indices), 1 );
  for j = 1:numel(non_nan_unique_cluster_indices)
    cluster_index = non_nan_unique_cluster_indices(j);
    
    is_cluster_subset = cluster_indices == cluster_index;
    
    sub_xyz = cellfun( @(x) x(is_cluster_subset), xyz, 'un', 0 );
    % nan cluster is cluster 1, hence + 1
    cluster_color = cluster_color_map(cluster_index + 1, :);
    
    hs(j) = scatter3( cluster_ax, sub_xyz{:}, [], cluster_color, 'filled' );
    set( cluster_ax, 'nextplot', 'add' );
  end
  
  hold( cluster_ax, 'off' );
  grid( cluster_ax, 'on' );
  legend( hs, cluster_labels );
  view( cluster_ax, coh_view );
  
  plot_C = combs( anatomy_labels, {'region'}, plot_I{i} );
  plot_C = unique( plot_C );
  plot_C = strjoin( plot_C(:)', ' | ' );
  
  xlabel( cluster_ax, 'AP' );
  ylabel( cluster_ax, 'ML' );
  zlabel( cluster_ax, 'Z' );
  
  title( plot_C );
  
  shared_utils.plot.fullscreen( figure2 );

  if ( do_save )
    use_plot_p = fullfile( plot_p, base_subdir, 'clusters' );

    dsp3.req_savefig( figure2, use_plot_p, prune(plot_labels(i)), plot_spec, base_prefix );
  end
end

end