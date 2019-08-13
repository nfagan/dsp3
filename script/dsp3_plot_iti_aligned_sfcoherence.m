function dsp3_plot_iti_aligned_sfcoherence(varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
defaults.coh = [];
defaults.labels = fcat();
defaults.freqs = [];
defaults.t = [];
defaults.pro_v_anti = false;
defaults.pro_minus_anti = false;
defaults.per_outcome = false;
defaults.per_trial_type = true;
defaults.match_limits = true;
defaults.box_y_lims = [];
defaults.line_ylims = [];
defaults.prefix = '';
defaults.line_smooth_func = @(x) x;
defaults.lines_over_freq = false;
defaults.monkey_minus_bottle = false;

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;

mats = shared_utils.io.findmat( dsp3.get_intermediate_dir('summarized_sfcoherence/first-look', conf) );

coh = params.coh;
if ( isempty(coh) )

  [coh, labels, freqs, t] = bfw.load_time_frequency_measure( mats ...
    , 'get_labels_func', @(x) x.labels ...
    , 'get_data_func', @(x) x.data ...
    , 'get_freqs_func', @(x) x.f ...
    , 'get_time_func', @(x) x.t ...
  );
else
  labels = params.labels';
  freqs = params.freqs;
  t = params.t;
  
  assert_ispair( coh, labels );
  assert( numel(freqs) == size(coh, 2) );
  assert( numel(t) == size(coh, 3) );
end

%%

use_labs = labels';

if ( ~params.per_trial_type )
  collapsecat( use_labs, 'trialtypes' );
end

pro_v_anti = params.pro_v_anti;
pro_minus_anti = params.pro_minus_anti;
is_monkey_minus_bottle = params.monkey_minus_bottle;

site_mask = fcat.mask( use_labs ...
  , @findnone, 'errors' ...
);

site_spec = union( dsp3_ct.site_specificity(), {'duration', 'looks_to'} );
proanti_spec = setdiff( site_spec, 'outcomes' );

[site_labs, site_I] = keepeach( use_labs', site_spec, site_mask );
site_coh = bfw.row_nanmean( coh, site_I );

if ( pro_v_anti )
  [site_coh, site_labs] = dsp3.pro_v_anti( site_coh, site_labs, proanti_spec );
end

if ( pro_minus_anti )
  [site_coh, site_labs] = dsp3.pro_minus_anti( site_coh, site_labs, proanti_spec );
end

if ( is_monkey_minus_bottle )
  [site_coh, site_labs] = monkey_minus_bottle( site_coh, site_labs, setdiff(site_spec, {'looks_to'}) );
end

%%

% plot_boxes( site_coh, site_labs', freqs, t, params );
% plot_spectra( site_coh, site_labs', freqs, t, params );
plot_lines( site_coh, site_labs', freqs, t, params );

% check_outliers( site_coh, site_labs', freqs, t, params );

end

function [coh, labs] = monkey_minus_bottle(coh, labs, spec, varargin)

[coh, labs] = dsp3.sbop( coh, labs', spec, 'monkey', 'bottle', @minus, @(x) nanmean(x, 1), varargin{:} );
setcat( labs, 'looks_to', 'monkey - bottle' );

end

function check_outliers(site_coh, site_labs, freqs, t, params)

%%
t_ind = t >= 0 & t <= 0.15;
f_ind = freqs >= 27 & freqs <= 30;

plt_f = freqs(f_ind);

by_freq = nanmean( site_coh(:, f_ind, t_ind), 3 );
mask = fcat.mask( site_labs ...
  , @findnot, 'no_look' ...
  , @find, 'bla_acc' ...
  , @find, 'long_enough__true' ...
);

save_p = char( dsp3.plotp({'iti_aligned_sfcoh', dsp3.datedir, 'outlier_check'}, params.config) );

for i = 1:size(by_freq, 2)
  subset = by_freq(mask, i);
  subset_labs = prune( site_labs(mask) );
  
  pcats = { 'regions', 'trialtypes', 'looks_to' };
  
  pl = plotlabeled.make_common();
  [axs, inds] = pl.hist( subset, subset_labs, pcats );
  xlim( axs, [0, 1] );
  
  meds = cellfun( @(x) nanmean(subset(x)), inds );
  shared_utils.plot.hold( axs, 'on' );
  
  for j = 1:numel(meds)
    shared_utils.plot.add_vertical_lines( axs(j), meds(j) );
    text( axs(j), meds(j), max(get(axs(j), 'ylim')) - 2, sprintf('M = %0.4f', meds(j)) );
  end
  
  text( axs(1), 0, mean(get(axs(1), 'ylim')), sprintf('F = %0.4f', plt_f(i)) );
  prefix = sprintf( 'freq__%0.4f', plt_f(i) );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, subset_labs, pcats, prefix );
  end
end

end

function plot_spectra(site_coh, site_labs, freqs, t, params)

conf = params.config;
do_save = params.do_save;
pro_v_anti = params.pro_v_anti;
per_outcome = params.per_outcome;

match_limits = params.match_limits;
save_p = char( dsp3.plotp({'iti_aligned_spectra', dsp3.datedir}, conf) );

f_ind = freqs >= 10 & freqs <= 80;
% t_ind = t >= -0.1 & t <= 0.5;
t_ind = true( size(t) );

clims = [];

plt_f = freqs(f_ind);
plt_t = t(t_ind) * 1e3;

plt_labs = site_labs';
plt_coh = site_coh;

plt_mask = fcat.mask( plt_labs ...
  , @findnot, {'no_look'} ...
  , @find, 'long_enough__true' ...
);

fig_cats = { 'looks_to', 'duration', 'regions' };
pcats = { 'outcomes', 'trialtypes', 'looks_to', 'duration', 'regions' };

if ( pro_v_anti )
  fig_cats = setdiff( fig_cats, 'duration' );
end

if ( ~per_outcome )
  pcats = setdiff( pcats, 'outcomes' );
end

fig_I = findall( plt_labs, fig_cats, plt_mask );
all_axs = cell( size(fig_I) );
figs = gobjects( size(fig_I) );
all_fig_labs = cell( size(fig_I) );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_spectrogram( plt_f, plt_t );
  pl.sort_combinations = true;
  pl.add_smoothing = true;
  pl.fig = figure(i);
  
  fig_labs = prune( plt_labs(fig_I{i}) );
  fig_coh = plt_coh(fig_I{i}, f_ind, t_ind);
  
  axs = pl.imagesc( fig_coh, fig_labs, pcats );
  shared_utils.plot.tseries_xticks( axs, plt_t, 5 );
  shared_utils.plot.fseries_yticks( axs, round(flip(plt_f)), 5 );
  
  all_axs{i} = axs;
  all_fig_labs{i} = fig_labs;
  figs(i) = pl.fig;
end

all_axs = vertcat( all_axs{:} );

if ( do_save )
  if ( match_limits )
    shared_utils.plot.match_clims( all_axs );
  end
  if ( ~isempty(clims) )
    shared_utils.plot.set_clims( all_axs, clims );
  end
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, all_fig_labs{i}, [fig_cats, pcats] );
    close( figs(i) );
  end
end

end

function plot_lines(site_coh, site_labs, freqs, t, params)

do_save = params.do_save;
conf = params.config;
match_limits = params.match_limits;
per_outcome = params.per_outcome;
pro_v_anti = params.pro_v_anti;
save_p = char( dsp3.plotp({'iti_aligned_lines', dsp3.datedir}, conf) );
smooth_func = params.line_smooth_func;

f_ind = freqs >= 10 & freqs <= 80;
t_ind = t >= -0.3 & t <= 0.3;

over_freq = params.lines_over_freq;

if ( over_freq )
  t_ind = t >= 0 & t <= 0.15;
end

ylims = params.line_ylims;

plt_f = freqs(f_ind);
plt_t = t(t_ind) * 1e3;

plt_labs = site_labs';
plt_coh = site_coh;

if ( ~over_freq )
  [plt_coh, plt_labs] = dsp3.get_band_means( plt_coh, plt_labs', freqs, dsp3.get_bands('map') );
end

plt_mask = fcat.mask( plt_labs ...
  , @findnot, {'no_look'} ...
  , @find, 'long_enough__true' ...
);

if ( ~over_freq )
  plt_mask = find( plt_labs, {'beta', 'new_gamma'}, plt_mask );
end

fig_cats = { 'duration' };
gcats = { 'looks_to' };
pcats = { 'regions', 'outcomes', 'trialtypes', 'duration' };

if ( ~over_freq )
  pcats{end+1} = 'bands';
  fig_cats{end+1} = 'bands';
end

if ( pro_v_anti )
  fig_cats = setdiff( fig_cats, 'duration' );
end

if ( ~per_outcome )
  pcats = setdiff( pcats, 'outcomes' );
end

fig_I = findall( plt_labs, fig_cats, plt_mask );
all_axs = cell( size(fig_I) );
figs = gobjects( size(fig_I) );
all_fig_labs = cell( size(fig_I) );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.fig = figure(i);
  pl.x = ternary( over_freq, plt_f, plt_t );
  pl.add_smoothing = true;
  pl.smooth_func = smooth_func;
%   pl.summary_func = @plotlabeled.nanmedian;
  
  fig_labs = prune( plt_labs(fig_I{i}) );
  
  if ( over_freq )
    fig_coh = plt_coh(fig_I{i}, f_ind, t_ind);
    fig_coh = squeeze( nanmedian(fig_coh, 3) );
  else
    fig_coh = plt_coh(fig_I{i}, t_ind);
  end
  
  [axs, hs, inds] = pl.lines( fig_coh, fig_labs, gcats, pcats );  
  add_stats( axs, hs, inds, pl.x, fig_coh );
  
  all_axs{i} = axs;
  all_fig_labs{i} = fig_labs;
  figs(i) = pl.fig;
end

all_axs = vertcat( all_axs{:} );

if ( do_save )
  if ( match_limits )
    shared_utils.plot.match_ylims( all_axs );
  end
  if ( ~isempty(ylims) )
    shared_utils.plot.set_ylims( all_axs, ylims );
  end
  
  freq_prefix = ternary( over_freq, 'freq', 'time' );
  prefix = sprintf('over-%s-%s', freq_prefix, params.prefix );
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, all_fig_labs{i}, [fig_cats, pcats], prefix);
    close( figs(i) );
  end
end

end

function add_stats(axs, hs, inds, x, fig_coh)

p_threshs = [ 0.001, 0.01, 0.05 ];
p_colors = { 'r', 'g', 'y' };

for i = 1:numel(axs)
  ax = axs(i);
  inds_ax = inds{i};
  set( ax, 'nextplot', 'add' );
  
  if ( numel(inds_ax) ~= 2 )
    warning( 'Expected 2 lines for comparison; got %d.', numel(inds_ax) );
    continue;
  end
  
  for j = 1:size(fig_coh, 2)
    a = fig_coh(inds_ax{1}, j);
    b = fig_coh(inds_ax{2}, j);
    
    p = ranksum( a, b );
    use_color = '';
    
    for k = numel(p_threshs):-1:1
      if ( p < p_threshs(k) )
        use_color = p_colors{k};
      end
    end
    
    if ( ~isempty(use_color) )
      lims = get( ax, 'ylim' );
      plot( ax, x(j), lims(2), sprintf('%s*', use_color) );
    end
  end
end

end

function plot_boxes(site_coh, site_labs, freqs, t, params)

do_save = params.do_save;
conf = params.config;
pro_v_anti = params.pro_v_anti;
per_outcome = params.per_outcome;

match_limits = params.match_limits;
save_p = char( dsp3.plotp({'iti_aligned_box_plots', dsp3.datedir}, conf) );

t_ind = t >= 0 & t <= 0.15;

ylims = params.box_y_lims;

plt_labs = site_labs';
plt_coh = squeeze( nanmean(site_coh(:, :, t_ind), 3) );
[plt_coh, plt_labs] = dsp3.get_band_means( plt_coh, plt_labs', freqs, dsp3.get_bands('map') );

plt_mask = fcat.mask( plt_labs, find(~isnan(plt_coh)) ...
  , @findnot, {'no_look'} ...
  , @find, 'long_enough__true' ...
  , @find, {'beta', 'new_gamma'} ...
);

fig_cats = { 'duration', 'bands' };
gcats = { 'looks_to' };
pcats = { 'regions', 'outcomes', 'trialtypes', 'duration', 'bands' };

if ( pro_v_anti )
  fig_cats = setdiff( fig_cats, 'duration' );
end

if ( ~per_outcome )
  pcats = setdiff( pcats, 'outcomes' );
end

fig_I = findall( plt_labs, fig_cats, plt_mask );
all_axs = cell( size(fig_I) );
figs = gobjects( size(fig_I) );
all_fig_labs = cell( size(fig_I) );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.fig = figure(i);
  
  fig_labs = prune( plt_labs(fig_I{i}) );
  fig_coh = plt_coh(fig_I{i});
  
%   axs = pl.errorbar( fig_coh, fig_labs, gcats, {}, pcats );  
  axs = pl.boxplot( fig_coh, fig_labs, gcats, pcats );
  
  all_axs{i} = axs;
  all_fig_labs{i} = fig_labs;
  figs(i) = pl.fig;
end

all_axs = vertcat( all_axs{:} );

if ( do_save )
  if ( match_limits )
    shared_utils.plot.match_ylims( all_axs );
  end
  if ( ~isempty(ylims) )
    shared_utils.plot.match_ylims( all_axs, ylims );
  end
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, all_fig_labs{i}, [fig_cats, pcats], params.prefix );
    close( figs(i) );
  end
end

end