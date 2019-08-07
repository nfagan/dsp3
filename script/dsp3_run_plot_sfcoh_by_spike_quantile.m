conf = dsp3.config.load();
conf.PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/';

[coh, coh_labs, freqs, t] = dsp3_sfq.load_per_day_sfcoh( conf );

%%

is_time_window_meaned = false;
[band_dat, band_labs] = dsp3_sfq.band_meaned_data( coh, coh_labs', freqs );

if ( is_time_window_meaned )
  band_dat = nanmean( band_dat(:, mask_gele(t, 0, 150)), 2 );
end

%%

sua = dsp3_ct.load_sua_data();
consolidated = dsp3.get_consolidated_data();
[spike_ts, spike_labels, event_ts, event_labels, new_to_orig] = dsp3_ct.linearize_sua( sua );
event_ts(event_ts == 0) = nan;
spikes = mkpair( spike_ts, spike_labels' );

%%

targ_ts = event_ts(:, consolidated.event_key('targAcq'));
targ = dsp3_ct.make_psth( targ_ts, event_labels', spikes, 0, 0.15 );
base_ts = event_ts(:, consolidated.event_key('cueOn'));
base = dsp3_ct.make_psth( base_ts, event_labels', spikes, -0.15, 0 );

%%

to_label = band_labs';
addcat( to_label, 'quantile' );

to_label_mask = fcat.mask( to_label ...
  , @find, 'selected-site' ...
);

num_tiles = 3;

use_spike_data = targ.data - base.data;

coh_unit_ids = combs( to_label, 'unit_uuid', to_label_mask );

unit_mask = fcat.mask( targ.labels ...
  , @find, coh_unit_ids ...
  , @find, {'choice', 'pre'} ...
);

[unit_labs, unit_I] = keepeach( targ.labels', 'unit_uuid', unit_mask );
unit_means = bfw.row_nanmean( use_spike_data, unit_I );

tile_each = { 'region' };
tile_I = findall( unit_labs, tile_each );

for idx = 1:numel(tile_I)
  [unit_I, spk_unit_ids] = findall( unit_labs, 'unit_uuid', tile_I{idx} );
  assert( all(unique(cellfun(@numel, unit_I)) == 1) );
  tile_ind = vertcat( unit_I{:} );

  tiles = quantile( unit_means(tile_ind), num_tiles-1 );
  tiles = [ -inf, tiles, inf ];

  for i = 1:numel(tile_ind)
    unit_mean = unit_means(tile_ind(i));

    for j = 1:numel(tiles)-1
      lb = tiles(j);
      ub = tiles(j+1);

      crit = unit_mean > lb & unit_mean <= ub;

      if ( crit )
        coh_ind = find( to_label, spk_unit_ids{i} );
        setcat( to_label, 'quantile', sprintf('quantile_%d', j), coh_ind );
        break;
      end
    end
  end
end

prune( to_label );

%%  line plot

do_save = true;
is_pro_minus_anti = true;

save_components = { 'sfcoh_by_quantile', 'by_spikes', dsp3.datedir };

save_p = char( dsp3.plotp(save_components) );
analysis_p = char( dsp3.analysisp(save_components) );

pl = plotlabeled.make_common();
pl.x = t;
pl.smooth_func = @(x) smoothdata(x, 'SmoothingFactor', 0.1);
pl.add_smoothing = true;

gcats = { 'quantile' };
pcats = { 'regions', 'bands', 'outcomes' };

proanti_spec = { 'trialtypes', 'bands', 'unit_uuid' };
proanti_mask = fcat.mask( to_label ...
  , @find, {'beta', 'new_gamma'} ...
  , @find, 'selected-site' ...
);

[proanti_dat, proanti_labs] = dsp3.pro_v_anti( band_dat, to_label', proanti_spec, proanti_mask );

if ( is_pro_minus_anti )
  [proanti_dat, proanti_labs] = dsp3.pro_minus_anti( proanti_dat, proanti_labs', proanti_spec );
end

no_nans = find( ~all(isnan(proanti_dat), 2) );

pltdat = proanti_dat(no_nans, :);
pltlabs = keep( proanti_labs', no_nans );

fig_I = findall( pltlabs, 'bands' );

for ii = 1:numel(fig_I)
  subset_plt = pltdat(fig_I{ii}, :);
  subset_labs = pltlabs(fig_I{ii});

  axs = pl.lines( subset_plt, subset_labs, gcats, pcats );
  shared_utils.plot.set_xlims( axs, [-300, 300] );

  ylabel( axs(1), 'Spike-field coherence' );

  if ( do_save )
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, subset_labs, [gcats, pcats], 'lines__' );
  end

  window_means = nanmean( subset_plt(:, t >= 0 & t <= 150), 2 );
  quantiles = fcat.parse( cellstr(subset_labs, 'quantile'), 'quantile_' );

  [scatter_I, scatter_C] = findall( subset_labs, pcats );
  tbls = cell( numel(scatter_I), 1 );

  correlation_types = { 'spearman', 'pearson' };

  for idx = 1:numel(correlation_types)
    for i = 1:numel(scatter_I)
      ind = scatter_I{i};

      [rho, p] = corr( quantiles(ind), window_means(ind), 'rows', 'complete', 'type', correlation_types{idx} );
      tbls{i} = table( rho, p );
      tbls{i}.Properties.RowNames = fcat.strjoin( scatter_C(:, i), ' | ');
    end

    tbl_prefix = correlation_types{idx};

    if ( do_save )
      for i = 1:numel(tbls)
        tbl_labs = prune( subset_labs(scatter_I{i}) );

        dsp3.req_writetable( tbls{i}, analysis_p, tbl_labs, [gcats, pcats], tbl_prefix );
      end
    end
  end
end

%%  scatter plot

do_save = true;
is_pro_minus_anti = false;

save_components = { 'sfcoh_by_quantile', 'by_spikes', dsp3.datedir };

save_p = char( dsp3.plotp(save_components) );
analysis_p = char( dsp3.analysisp(save_components) );

pl = plotlabeled.make_common();

gcats = { 'outcomes' };
pcats = { 'regions', 'bands' };

proanti_spec = { 'trialtypes', 'bands', 'unit_uuid' };
proanti_mask = fcat.mask( to_label ...
  , @find, {'beta', 'new_gamma'} ...
  , @find, 'selected-site' ...
);

[proanti_dat, proanti_labs] = dsp3.pro_v_anti( band_dat, to_label', proanti_spec, proanti_mask );

if ( is_pro_minus_anti )
  [proanti_dat, proanti_labs] = dsp3.pro_minus_anti( proanti_dat, proanti_labs', proanti_spec );
end

no_nans = find( ~isnan(proanti_dat) );

pltdat = proanti_dat(no_nans);
pltlabs = keep( proanti_labs', no_nans );

quantiles = fcat.parse( cellstr(pltlabs, 'quantile'), 'quantile_' );

[axs, ids] = pl.scatter( quantiles, pltdat, pltlabs, gcats, pcats );
plotlabeled.scatter_addcorr( ids, quantiles, pltdat );

ylabel( axs(1), 'Spike-field coherence' );

if ( do_save )
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, pltlabs, [gcats, pcats] );
end

%%  box plot

do_save = false;
is_pro_minus_anti = true;

save_components = { 'sfcoh_by_quantile', 'by_spikes', dsp3.datedir };

save_p = char( dsp3.plotp(save_components) );
analysis_p = char( dsp3.analysisp(save_components) );

pl = plotlabeled.make_common();

xcats = { 'quantile' };
gcats = { 'outcomes' };
pcats = { 'regions', 'bands' };

proanti_spec = { 'trialtypes', 'bands', 'unit_uuid' };
proanti_mask = fcat.mask( to_label ...
  , @find, {'beta', 'new_gamma'} ...
  , @find, 'selected-site' ...
);

[proanti_dat, proanti_labs] = dsp3.pro_v_anti( band_dat, to_label', proanti_spec, proanti_mask );

if ( is_pro_minus_anti )
  [proanti_dat, proanti_labs] = dsp3.pro_minus_anti( proanti_dat, proanti_labs', proanti_spec );
end

pltdat = proanti_dat;
pltlabs = proanti_labs';

anova_spec = { 'trialtypes', 'regions', 'bands', 'outcomes' };
anova_outs = dsp3.anova1( pltdat, pltlabs', anova_spec, 'quantile' );

% axs = pl.( pltdat, pltlabs, xcats, gcats, pcats );
axs = pl.boxplot( pltdat, pltlabs, xcats, [gcats, pcats] );
ylabel( axs(1), 'Spike-field coherence' );

if ( do_save )
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, pltlabs, [gcats, pcats] );
  dsp3.save_anova_outputs( anova_outs, analysis_p, [gcats, pcats] );
end

