function run_plot_sfcoh_by_lfp_site_quantile(coh, coh_labs, freqs, t, psd, psd_labs)

conf = dsp3.config.load();
conf.PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/';

coh_t_min = 0;
coh_t_max = 150;

if ( nargin < 6 )
  % Load coherence
  [coh, coh_labs, freqs, t] = dsp3_sfq.load_per_day_sfcoh( conf );
  [coh, coh_labs] = dsp3_sfq.band_meaned_data( coh, coh_labs', freqs );
  coh = nanmean( coh(:, mask_gele(t, coh_t_min, coh_t_max)), 2 );

  dsp3_sfq.add_spike_lfp_region_labels( coh_labs );
  
  % Load power
  [psd, psd_labs, psd_freqs, psd_t] = dsp3_sfq.load_summarized_psd();
  psd = psd(:, mask_gele(psd_freqs, 0, 100), :);
  assert( size(psd, 2) == numel(freqs) && size(psd, 3) == numel(t) );

  psd_mask = fcat.mask( psd_labs ...
    , @find, {'choice', 'pre'} ...
    , @findnone, 'errors' ...
  );

  psd_each = { 'trialtypes', 'regions', 'channels', 'days' };
  [psd, psd_labs] = dsp3_sfq.band_meaned_data( psd, psd_labs', freqs, psd_each, psd_mask );

  psd_t_min = 0;
  psd_t_max = 150;

  psd = nanmean( psd(:, mask_gele(t, psd_t_min, psd_t_max)), 2 );
end

[quant_labs, quant_mask, quants_of] = make_quantile_labels( psd, psd_labs' );

%%

is_pro_minus_anti = true;
do_save = true;

save_components = { 'sfcoh_by_quantile', 'by_lfp_site', dsp3.datedir };
plot_p = char( dsp3.plotp(save_components) );
analysis_p = char( dsp3.analysisp(save_components) );

to_label = addcat( coh_labs', 'quantile' );

[quant_I, quant_C] = findall( quant_labs, {'regions', 'bands'}, quant_mask );

for i = 1:numel(quant_I)
  region = quant_C{1, i};
  band = quant_C{2, i};
  
  region_search_str = sprintf( 'lfp_%s', region );
  
  [site_I, site_C] = findall( quant_labs, quants_of, quant_I{i} );
  
  for j = 1:numel(site_I)
    quant_name = combs( quant_labs, 'quantile', site_I{j} );
    assert( numel(quant_name) == 1 );
    
    match_site_ind = find( to_label, [site_C(:, j)', region_search_str] );
    
    if ( isempty(match_site_ind) )
      continue;
    end
    
    setcat( to_label, 'quantile', quant_name, match_site_ind );
  end
  
  proanti_mask = fcat.mask( to_label ...
    , @find, {'beta', 'new_gamma', region_search_str} ...
    , @find, 'selected-site' ...
  );

  proanti_spec = { 'trialtypes', 'bands', 'channels', 'regions', 'days' };

  [proanti_dat, proanti_labs] = dsp3.pro_v_anti( coh, to_label', proanti_spec, proanti_mask );

  if ( is_pro_minus_anti )
    [proanti_dat, proanti_labs] = dsp3.pro_minus_anti( proanti_dat, proanti_labs', proanti_spec );
  end
  
%   box_plot_and_anova( proanti_dat, proanti_labs', band, region, plot_p, analysis_p, do_save );
  scatter_plot_and_stats( proanti_dat, proanti_labs', band, region, plot_p, analysis_p, do_save );
end

end

function scatter_plot_and_stats(proanti_dat, proanti_labs, band, region, plot_p, analysis_p, do_save)

%%

pl = plotlabeled.make_common();
  
gcats = { 'outcomes' };
pcats = { 'regions', 'bands' };

no_nans = find( ~isnan(proanti_dat) );

pltdat = proanti_dat(no_nans);
pltlabs = keep( proanti_labs', no_nans );

quantiles = fcat.parse( cellstr(proanti_labs, 'quantile', no_nans), 'quantile_' );

[axs, ids] = pl.scatter( quantiles, pltdat, pltlabs, gcats, pcats );
plotlabeled.scatter_addcorr( ids, quantiles, pltdat );

if ( do_save )
  prefix = sprintf( 'quantiles_of_%s_%s_field__', band, region );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, plot_p, pltlabs, [gcats, pcats], prefix );
%   dsp3.save_anova_outputs( anova_outs, analysis_p, [gcats, pcats], prefix );
end

end

function box_plot_and_anova(proanti_dat, proanti_labs, band, region, plot_p, analysis_p, do_save)

pl = plotlabeled.make_common();
  
xcats = { 'quantile' };
gcats = { 'outcomes' };
pcats = { 'regions', 'bands' };

pltdat = proanti_dat;
pltlabs = proanti_labs';

axs = pl.boxplot( pltdat, pltlabs, xcats, [gcats, pcats] );
ylabel( axs(1), 'Spike-field coherence' );

anova_spec = { 'trialtypes', 'regions', 'bands', 'outcomes' };
anova_outs = dsp3.anova1( pltdat, pltlabs', anova_spec, 'quantile' );

if ( do_save )
  prefix = sprintf( 'quantiles_of_%s_%s_field__', band, region );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, plot_p, pltlabs, [gcats, pcats], prefix );
  dsp3.save_anova_outputs( anova_outs, analysis_p, [gcats, pcats], prefix );
end

end

function [quant_labs, quant_mask, quants_of] = make_quantile_labels(psd, psd_labs)

num_tiles = 3;

% separate quantiles for each region + band
quants_each = { 'regions', 'bands' }; 

% sites
quants_of = { 'channels', 'days' };

% only choice + pre
quant_mask = fcat.mask( psd_labs ...
  , @find, {'choice', 'pre', 'beta', 'new_gamma'} ...
);

quant_labs = dsp3_sfq.quantiles_each( psd, psd_labs, num_tiles, quants_each, quants_of, quant_mask );

end


