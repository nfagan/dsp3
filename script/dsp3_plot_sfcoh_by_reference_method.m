function dsp3_plot_sfcoh_by_reference_method(varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
defaults.coh = [];
defaults.labels = [];
defaults.f = [];
defaults.t = [];
defaults.pro_v_anti = true;
defaults.pro_minus_anti = false;

params = dsp3.parsestruct( defaults, varargin );

coh = params.coh;

if ( isempty(coh) )
  [coh, coh_labs, f, t] = load_data( params.config );
else
  coh = params.coh;
  coh_labs = params.labels';
  f = params.f;
  t = params.t;
end

assert_ispair( coh, coh_labs );

%%

base_mask = get_base_mask( coh_labs );

%%

use_coh = coh;
use_labs = coh_labs';

%%

site_spec = dsp3_ct.site_specificity();
ref_spec = union( site_spec, {'reference_method'} );
pa_spec = setdiff( ref_spec, {'outcomes'} );

[site_labs, site_I] = keepeach( use_labs', ref_spec, base_mask );
site_coh = bfw.row_nanmean( use_coh, site_I );

if ( params.pro_v_anti )
  [site_coh, site_labs] = dsp3.pro_v_anti( site_coh, site_labs', pa_spec );
end

if ( params.pro_minus_anti )
  [site_coh, site_labs] = dsp3.pro_minus_anti( site_coh, site_labs', pa_spec );
end

%%

plot_bars( site_coh, site_labs', f, t, params );
plot_spectra( site_coh, site_labs', f, t, params );

end

function plot_bars(coh, labels, f, t, params)

%%

t_ind = t >= 0 & t <= 0.15;
band_coh = nanmean( coh(:, :, t_ind), 3 );
band_names = { 'beta', 'new_gamma' };

[band_coh, band_labs] = dsp3.get_band_means( band_coh, labels', f, dsp3.some_bands(band_names), band_names );

fcats = { 'bands' };
gcats = { 'reference_method', 'outcomes' };
pcats = { 'regions', 'bands' };

pl = plotlabeled.make_common();
% pl.y_lims = [0.68, 0.71];
[figs, axs] = pl.figures( @boxplot, band_coh, band_labs, fcats, gcats, pcats );

end

function plot_spectra(coh, labels, f, t, params)

fcats = { 'outcomes' };
pcats = { 'regions', 'reference_method' };
pcats = union( pcats, fcats );

[figs, axs, labs] = dsp3.multi_spectra( coh, labels, f, t, fcats, pcats ...
  , 'f_mask', f >= 10 & f <= 80 ...
  , 't_mask', t >= -0.3 & t <= 0.3 ...
  , 'match_limits', true ...
  , 'configure_pl_func', @(pl) pl.set_property('panel_order', {'pro', 'anti'}) ...
);

if ( params.do_save )
  save_p = get_save_p( params, 'spectra' );
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, labs{i}, pcats );
  end
end

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( dsp3.dataroot(params.config), 'plots', 'sfcoh_by_reference_type' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end

function [coh, coh_labs, f, t] = load_data(conf)

[coh, coh_labs, f, t] = dsp3_load_sfcoh_by_reference_type( conf );

end

function base_mask = get_base_mask(labels)

base_mask = keep_days_with_both_directions( labels );

base_mask = fcat.mask( labels, base_mask ...
  , @findnone, 'errors' ...
  , @find, {'choice', 'pre'} ...
);

end

function keep_I = keep_days_with_both_directions(labels)

new_ind = find( labels, 'bipolar_derivation' );
[day_I, day_C] = findall( labels, 'days', new_ind );

regions = combs( labels, 'regions' );
use_inds = [];

for i = 1:numel(day_I)
  all_dirs = all( count(labels, regions, day_I{i}) > 0 );
  
  if ( all_dirs )
    use_inds(end+1, 1) = i;
  end
end

keep_days = { day_C{use_inds} };
keep_I = find( labels, keep_days );

end

