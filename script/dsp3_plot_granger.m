function dsp3_plot_granger(granger, varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
defaults.pro_v_anti = false;
defaults.time_window = [0, 150];
defaults.match_ylims = true;
defaults.match_clims = true;
defaults.prefix = '';

params = dsp3.parsestruct( defaults, varargin );

if ( isempty(granger) )
  granger = dsp3_gr.load_granger( '081319', params.config );
end

%%

pro_v_anti = params.pro_v_anti;

dat = abs( granger.data );
dat(isinf(dat)) = nan;

site_labs = granger.labels';
site_dat = dat;

base_mask = get_base_mask( site_labs );

site_spec = setdiff( dsp3_ct.site_specificity(), 'unit_uuid' );
proanti_spec = setdiff( site_spec, 'outcomes' );

if ( pro_v_anti )
  [site_dat, site_labs] = dsp3.pro_v_anti( site_dat, site_labs', proanti_spec, base_mask );
end

f = guard_empty( granger.f, @(f) f{1}(1:501) );
t = guard_empty( granger.t, @(t) t{1}(1, :) );

plot_spectra( site_dat, site_labs', f, t, params );
plot_lines( site_dat, site_labs', f, t, params );

end

function base_mask = get_base_mask(labs)

base_mask = fcat.mask( labs ...
  , @find, 'choice' ...
  , @find, 'pre' ...
);

end

function plot_lines(site_dat, site_labs, f, t, params)

f_ind = f >= 10 & f <= 80;

for idx = 1:2
  over_freq = idx == 1;
  prefix = params.prefix;
  
  fcats = {};
  pcats = { 'regions', 'trialtypes' };
  gcats = { 'outcomes' };
  
  if ( over_freq )
    t_ind = t >= params.time_window(1) & t <= params.time_window(2);
    dat = nanmean( site_dat(:, f_ind, t_ind), 3 );
    labs = site_labs';
    x = f(f_ind);
    prefix = sprintf( 'over-freq-%s', prefix );
    mask_inputs = {};
  else
    t_ind = t >= -300 & t <= 300;
    [dat, labs] = dsp3.get_band_means( site_dat(:, :, t_ind), site_labs', f, dsp3.get_bands('map') );
    x = t(t_ind);
    
    fcats{end+1} = 'bands';
    pcats{end+1} = 'bands';
    prefix = sprintf( 'over-time-%s', prefix );
    mask_inputs = { @find, {'beta', 'new_gamma'} };
  end
  
  pl = plotlabeled.make_common();
  pl.x = x;
  
  plt_mask = fcat.mask( labs, mask_inputs{:} );
  
  fig_I = findall_or_one( labs, fcats, plt_mask );  
  figs = gobjects( size(fig_I) );
  all_axs = cell( size(fig_I) );
  fig_labs = cell( size(fig_I) );
  
  for i = 1:numel(fig_I)
    pl.fig = figure(i);
    
    fig_ind = fig_I{i};
    
    plt_dat = dat(fig_ind, :);
    plt_labs = prune( labs(fig_ind) );
    
    [axs, ~, inds] = pl.lines( plt_dat, plt_labs, gcats, pcats );
    
    try 
      dsp3.compare_series( axs, inds, plt_dat, @ranksum ...
        , 'x', pl.x ...
        , 'fig', pl.fig ...
      );
    catch err
      warning( err.message );
    end
    
    figs(i) = pl.fig;
    all_axs{i} = axs;
    fig_labs{i} = plt_labs;
  end
  
  if ( params.match_ylims )
    axs = vertcat( all_axs{:} );
    shared_utils.plot.match_ylims( axs );
  end
  
  if ( params.do_save )
    save_p = get_save_p( params, 'lines' );
    
    for i = 1:numel(fig_I)
      shared_utils.plot.fullscreen( figs(i) );
      dsp3.req_savefig( figs(i), save_p, fig_labs{i}, [pcats, fcats], prefix );
    end
  end
end

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( dsp3.dataroot(params.config), 'plots', 'granger', dsp3.datedir ...
  , params.base_subdir, varargin{:} );

end

function plot_spectra(site_dat, site_labs, f, t, params)

f_ind = f >= 10 & f <= 80;
t_ind = t >= -300 & t <= 300;

plt_f = f(f_ind);
plt_t = t(t_ind);

pl = plotlabeled.make_spectrogram( plt_f, plt_t );

plt_labs = site_labs';
plt_dat = site_dat(:, f_ind, t_ind);

pcats = { 'regions', 'outcomes' };
fcats = { 'outcomes' };

fig_I = findall_or_one( plt_labs, fcats );
all_axs = cell( size(fig_I) );
all_labs = cell( size(fig_I) );
figs = gobjects( size(fig_I) );

for i = 1:numel(fig_I)
  fig_dat = plt_dat(fig_I{i}, :, :);
  fig_labs = prune( plt_labs(fig_I{i}) );
  
  if ( params.match_clims )
    figs(i) = figure(i);
  end
  
  pl.fig = figs(i);

  axs = pl.imagesc( fig_dat, fig_labs, pcats );
  shared_utils.plot.fseries_yticks( axs, round(flip(plt_f)), 5 );
  shared_utils.plot.tseries_xticks( axs, plt_t, 5 );

  shared_utils.plot.hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, find(plt_t == 0) );
  
  all_axs{i} = axs;
  all_labs{i} = fig_labs;
end

if ( params.match_clims )
  shared_utils.plot.match_clims( vertcat(all_axs{:}) );
end

if ( params.do_save )
  save_p = get_save_p( params, 'spectra' );
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, all_labs{i}, [pcats, fcats] );
  end
end

end