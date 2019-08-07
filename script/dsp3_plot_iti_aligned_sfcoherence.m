mats = shared_utils.io.findmat( dsp3.get_intermediate_dir('summarized_sfcoherence/first-look') );

[coh, labels, freqs, t] = bfw.load_time_frequency_measure( mats ...
  , 'get_labels_func', @(x) x.labels ...
  , 'get_data_func', @(x) x.data ...
  , 'get_freqs_func', @(x) x.f ...
  , 'get_time_func', @(x) x.t ...
);

%%

pro_v_anti = true;
pro_minus_anti = false;

site_mask = fcat.mask( labels ...
  , @find, 'choice' ...
  , @findnone, 'errors' ...
);

site_spec = union( dsp3_ct.site_specificity(), {'duration', 'looks_to'} );
proanti_spec = setdiff( site_spec, 'outcomes' );

[site_labs, site_I] = keepeach( labels', site_spec, site_mask );
site_coh = bfw.row_nanmean( coh, site_I );

if ( pro_v_anti )
  [site_coh, site_labs] = dsp3.pro_v_anti( site_coh, site_labs, proanti_spec );
end

if ( pro_minus_anti )
  [site_coh, site_labs] = dsp3.pro_minus_anti( site_coh, site_labs, proanti_spec );
end

%%

do_save = true;
match_limits = true;
save_p = char( dsp3.plotp({'iti_aligned_spectra', dsp3.datedir}) );

f_ind = freqs >= 10 & freqs <= 100;
t_ind = true( size(t) );

plt_f = freqs(f_ind);
plt_t = t(t_ind) * 1e3;

plt_labs = site_labs';
plt_coh = site_coh;

plt_mask = fcat.mask( plt_labs ...
  , @find, {'monkey', 'bottle', 'no_look'} ...
  , @find, 'long_enough__true' ...
);

fig_cats = { 'regions', 'looks_to', 'duration' };
pcats = { 'regions', 'outcomes', 'trialtypes', 'looks_to', 'duration' };

if ( pro_v_anti )
  fig_cats = setdiff( fig_cats, 'duration' );
end

fig_I = findall( plt_labs, fig_cats, plt_mask );
all_axs = cell( size(fig_I) );
figs = gobjects( size(fig_I) );
all_fig_labs = cell( size(fig_I) );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_spectrogram( plt_f, plt_t );
  pl.sort_combinations = true;
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
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, all_fig_labs{i}, [fig_cats, pcats] );
    close( figs(i) );
  end
end