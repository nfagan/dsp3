function corr_outs = dsp3_plot_correlated_sf_coh_by_anatomy(varargin)

defaults = struct();
defaults.is_cached = true;
defaults.save_plots = true;
defaults.config = dsp3.config.load();
defaults.correlation_type = 'pearson';
defaults.base_subdir = '';
defaults.post_hoc_correction_func = @fdr_post_hoc_correct;

params = dsp3.parsestruct( defaults, varargin );

coh_mats = shared_utils.io.findmat( dsp3.get_intermediate_dir('summarized_cc_sfcoherence/targacq') );

[coh, coh_labels, freqs, t] = dsp3.load_signal_measure( coh_mats ...
  , 'get_time_series_func', @(~, file) file.t ...
  , 'get_frequencies_func', @(~, file) file.f ...
  , 'get_data_func', @(~, file) file.coherence ...
  , 'get_labels_func', @(~, file) fcat.from(file) ...
  , 'is_cached', params.is_cached ...
);

%%

[anatomy, anatomy_labels, anatomy_key] = dsp3_get_unit_anatomy_info();

%%

unique_channel_indices = findall( anatomy_labels, {'channel', 'region', 'days'} );
unique_channel_indices = cellfun( @(x) x(1), unique_channel_indices );

per_channel_anatomy = anatomy(unique_channel_indices, :);
per_channel_labels = prune( anatomy_labels(unique_channel_indices) );

%%  pca on anatomy

[pca_coeff, pca_score] = pca( per_channel_anatomy );

per_channel_anatomy(:, end+1) = pca_score(:, 1);
anatomy_key(size(per_channel_anatomy, 2)) = 'PC-1';

%%  correlate each dimension separately

mean_spec = { 'regions', 'spike_regions', 'spike_channels', 'days', 'trialtypes' };

[pro_coh, pro_labels] = ...
  calculate_difference_in_summarized_sfcoh_per_channel( coh, coh_labels', mean_spec, 'other', 'none' );
setcat( pro_labels, 'outcomes', 'pro' );

[anti_coh, anti_labels] = ...
  calculate_difference_in_summarized_sfcoh_per_channel( coh, coh_labels', mean_spec, 'self', 'both' );
setcat( anti_labels, 'outcomes', 'anti' );

proanti_coh = [ pro_coh; anti_coh ];
proanti_labels = [ pro_labels; anti_labels ];

t_ind = t >= -250 & t <= 0;
t_meaned = squeeze( nanmean(proanti_coh(:, :, t_ind), 3) );
bands = dsp3.get_bands( 'map' );

[proanti_coh, proanti_labels] = ...
  dsp3.get_band_means( t_meaned, proanti_labels', freqs, bands );

[matched_anatomy, is_missing] = ...
  match_anatomy_to_coherence( per_channel_anatomy, per_channel_labels, proanti_labels' );

proanti_coh(is_missing, :) = [];
matched_anatomy(is_missing, :) = [];
prune( keep(proanti_labels, find(~is_missing)) );

assert_ispair( proanti_coh, proanti_labels );

%%  correlate each dimension separately

to_corr_labels = proanti_labels';
to_corr_coh = proanti_coh;
to_corr_anatomy = matched_anatomy;

to_corr_mask = fcat.mask( to_corr_labels ...
  , @findnot, {'bla', 'spike_bla'} ...
  , @findnot, {'acc', 'spike_acc'} ...
);

corr_each = { 'bands', 'outcomes', 'spike_regions', 'regions', 'trialtypes' };

corr_outs = correlate_coherence_anatomy( to_corr_coh, to_corr_anatomy ...
  , to_corr_labels', corr_each, anatomy_key, to_corr_mask, params );

%%  plot

plot_corr_data( corr_outs, to_corr_coh, to_corr_anatomy, to_corr_labels', corr_each, params );


end

function plot_corr_data(corr_outs, to_corr_coh, to_corr_anatomy, to_corr_labels, corr_each, params)

do_save = params.save_plots;
conf = params.config;

base_plot_p = char( dsp3.plotp({'sf_coh_anatomy', 'correlations', datestr(now, 'mmddyy')}, conf) );
base_subdir = params.base_subdir;

corr_data = corr_outs.corr_data;
corr_labels = corr_outs.corr_labels';
corr_I = corr_outs.corr_I;
anatomy_dim_indices = corr_outs.anatomy_dimension_indices;
line_coeffs = corr_outs.line_coeffs;

plot_p = fullfile( base_plot_p, base_subdir );

fcats = { 'bands', 'spike_regions', 'outcomes' };

figure_mask = fcat.mask( corr_labels, @findnone, 'theta' );
figure_I = findall( corr_labels, fcats, figure_mask );

for i = 1:numel(figure_I)
  use_fig = gcf;
  clf( use_fig );
  
  corr_inds = figure_I{i};
  panel_inds = corr_I(figure_I{i});
  plot_labels = prune( corr_labels(corr_inds) );
  
  subplot_shape = plotlabeled.get_subplot_shape( numel(panel_inds) );
  axs = gobjects( numel(panel_inds), 1 );
  
  for j = 1:numel(panel_inds)
    ax = subplot( subplot_shape(1), subplot_shape(2), j );
    hold( ax, 'off' );
    
    corr_ind = corr_inds(j);
    anatomy_dim_index = anatomy_dim_indices(corr_ind);
    
    panel_ind = panel_inds{j};
    X = to_corr_anatomy(panel_ind, anatomy_dim_index);
    Y = to_corr_coh(panel_ind);
    line_coeff = line_coeffs(corr_ind, :);
    
    scatter( ax, X, Y );
    hold( ax, 'on' );
    plot( ax, X, polyval(line_coeff, X) );
    
    axs(j) = ax;
    
    C = combs( to_corr_labels, corr_each, panel_ind );
    C{end+1} = char( corr_labels(corr_ind, 'anatomy_dimension') );
    
    title_str = strjoin( C, ' | ' );
    title_str = strrep( title_str, '_', ' ');
    
    title( ax, title_str );
  end
  
  shared_utils.plot.fullscreen( use_fig );
  shared_utils.plot.match_ylims( axs );
  
  for j = 1:numel(panel_inds)
    xlims = get( axs(j), 'xlim' );
    ylims = get( axs(j), 'ylim' );
    
    x_coord = xlims(2) - (xlims(2) - xlims(1)) * 0.1;
    y_coord = ylims(2) - (ylims(2) - ylims(1)) * 0.1;
    
    corr_ind = corr_inds(j);
    r = corr_data(corr_ind, 1);
    p = corr_data(corr_ind, 2);
    
    threshs = [ 0.05, 0.001, 1e-4 ];
    
    sig_str = '';
    
    for k = 1:numel(threshs)
      if ( p < threshs(k) )
        sig_str = sprintf( '%s*', sig_str );
      end
    end
    
    corr_str = sprintf( 'R=%0.2f, P=%0.4f%s', r, p, sig_str );
    
    text( x_coord, y_coord, corr_str, 'parent', axs(j) );
  end
  
  if ( do_save )    
    dsp3.req_savefig( use_fig, plot_p, plot_labels, fcats );
  end
end

end

function outs = correlate_coherence_anatomy(to_corr_coh, to_corr_anatomy ...
  , to_corr_labels, corr_each, anatomy_key, corr_mask, params)

anatomy_dim_indices = keys( anatomy_key );

all_corr_labels = fcat();
all_corr_data = [];
all_I = {};
all_coeffs = [];
all_anatomy_dim_indices = [];

for i = 1:numel(anatomy_dim_indices)
  
  anatomy_dim_index = anatomy_dim_indices{i};
  
  [corr_labels, corr_I] = keepeach( to_corr_labels', corr_each, corr_mask );
  anatomy_this_dim = to_corr_anatomy(:, anatomy_dim_index);
  
  for j = 1:numel(corr_I)
    X = anatomy_this_dim(corr_I{j});
    Y = to_corr_coh(corr_I{j});
    
    is_non_nan = ~isnan( X ) & ~isnan( Y );
    
    [r, p] = corr( X(is_non_nan), Y(is_non_nan), 'type', params.correlation_type );
    
    all_corr_data = [ all_corr_data; [r, p] ];
    all_I{end+1, 1} = corr_I{j};
    all_coeffs(end+1, :) = polyfit( X(is_non_nan), Y(is_non_nan), 1 );
    all_anatomy_dim_indices(end+1) = anatomy_dim_index;
  end
  
  addsetcat( corr_labels, 'anatomy_dimension', anatomy_key(anatomy_dim_index) );
  append( all_corr_labels, corr_labels );
end

[all_corr_data, all_corr_labels] = params.post_hoc_correction_func( all_corr_data, all_corr_labels' );

outs = struct();
outs.corr_data = all_corr_data;
outs.corr_labels = all_corr_labels;
outs.corr_I = all_I;
outs.line_coeffs = all_coeffs;
outs.anatomy_dimension_indices = all_anatomy_dim_indices;

end

function [corr_data, corr_labels] = fdr_post_hoc_correct(corr_data, corr_labels)

I = findall( corr_labels, {'bands', 'spike_regions', 'outcomes'} );

for i = 1:numel(I)
  ps = corr_data(I{i}, 2);
  corr_data(I{i}, 2) = dsp3.fdr( ps );
end

end

function [corr_data, corr_labels] = default_post_hoc_correct_func(corr_data, corr_labels)
% No correction
end

function [matched, missing_coh] = match_anatomy_to_coherence(anatomy, anatomy_labels, coh_labels)

assert_ispair( anatomy, anatomy_labels );

[coh_I, coh_C] = findall( coh_labels, {'spike_channels', 'spike_regions', 'days'} );

matched = nan( joinsize(coh_labels, anatomy) );
missing_anatomy = false( size(coh_I) );
missing_coh = false( rows(coh_labels), 1 );

for i = 1:numel(coh_I)
  coh_ind = coh_I{i};
  current_identifiers = coh_C(:, i);
  
  channel = current_identifiers(1);
  region = strrep( current_identifiers(2), 'spike_', '' );
  day = current_identifiers(3);
  
  selectors = cshorzcat( channel, region, day );
  
  anatomy_ind = find( anatomy_labels, selectors );  
  
  if ( isempty(anatomy_ind) )
    missing_anatomy(i) = true;
    missing_coh(coh_ind) = true;
    continue;
  end
  
  assert( numel(anatomy_ind) == 1 );
  
  for j = 1:numel(coh_ind)
    matched(coh_ind(j), :) = anatomy(anatomy_ind, :);
  end
end

end

function [data, labels] = ...
  calculate_difference_in_summarized_sfcoh_per_channel(coh, coh_labels, spec, a, b)

[data, labels] = dsp3.summary_binary_op( coh, coh_labels', spec, a, b ...
, @minus, @(x) nanmean(x, 1) );

end