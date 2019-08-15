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

plot_lines( site_dat, site_labs', f, t, params );
plot_spectra( site_dat, site_labs', f, t, params );

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
  
  plt_mask = fcat.mask( labs, mask_inputs{:} );
  
  post_plot_func = @(fig, axs, ~, inds, data, ~) dsp3.compare_series(axs, inds, data, @ranksum ...
    , 'x', x, 'fig', fig ...
  );
  
  [figs, fig_labs] = dsp3.multi_lines( dat, labs, fcats, gcats, pcats ...
    , 'mask', plt_mask ...
    , 'configure_pl_func', @(pl) set_property(pl, 'x', x) ...
    , 'post_plot_func', post_plot_func ...
    , 'match_limits', params.match_ylims ...
  );
  
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

pcats = { 'regions', 'outcomes' };
fcats = { 'outcomes' };

[figs, axs, labs] = dsp3.multi_spectra( site_dat, site_labs, f, t, fcats, pcats ...
  , 'f_mask', f_ind ...
  , 't_mask', t_ind ...
  , 'match_limits', params.match_clims ...
);

if ( params.do_save )
  save_p = get_save_p( params, 'spectra' );
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, labs{i}, [pcats, fcats] );
  end
end

end