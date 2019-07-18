psd_p = dsp3.get_intermediate_dir( 'original_summarized_psd' );
full_psd_p = fullfile( psd_p, 'targAcq-150-cc' );
psd_mats = shared_utils.io.findmat( full_psd_p );

[psd, psd_labs, freqs, t] = bfw.load_time_frequency_measure( psd_mats ...
  , 'get_labels_func', @(x) x.labels ...
);

%%

proanti_each = { 'days', 'sites', 'channels', 'regions', 'trialtypes' };
[proanti, proanti_labs] = dsp3.pro_v_anti( psd, psd_labs', proanti_each );

%%

f_ind = mask_gele( freqs, 10, 80 );
t_ind = mask_gele( t, -500, 500 );

plt_freqs = freqs(f_ind);
plt_t = t(t_ind);

pl = plotlabeled.make_spectrogram( round(plt_freqs), plt_t );

mask = fcat.mask( proanti_labs ...
  , @find, {'choice', 'acc'} ...
);

pltdat = proanti(mask, f_ind, t_ind);
pltdat(isinf(pltdat)) = nan;

pltlabs = prune( proanti_labs(mask) );

nan_rows = any( any(isnan(pltdat), 3), 2 );
pltdat = pltdat(~nan_rows, :, :);
keep( pltlabs, find(~nan_rows) );

axs = pl.imagesc( pltdat, pltlabs, {'regions', 'outcomes', 'trialtypes'} );

shared_utils.plot.tseries_xticks( axs, plt_t );
shared_utils.plot.fseries_yticks( axs, round(flip(plt_freqs)), 5 );

% shared_utils.plot.set_clims( axs, [-2.6, 2.1] );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, find(plt_t == 0) ); %#ok

%%

save_p = char( dsp3.plotp({'psd_lines', dsp3.datedir}) );
do_save = true;

bands = dsp3.get_bands( 'map' );

[band_dat, band_labs] = dsp3.get_band_means( psd, psd_labs', freqs, bands );

band_dat(isinf(band_dat)) = nan;
nan_rows = any( any(isnan(band_dat), 3), 2 );
band_dat = band_dat(~nan_rows, :, :);
keep( band_labs, find(~nan_rows) );

proanti_each = { 'days', 'sites', 'channels', 'regions', 'trialtypes', 'bands' };
[proanti, proanti_labs] = dsp3.pro_v_anti( band_dat, band_labs', proanti_each );
[proanti, proanti_labs] = dsp3.pro_minus_anti( proanti, proanti_labs', proanti_each );

is_pro_anti = true;

if ( is_pro_anti )
  pltdat = proanti;
  pltlabs = proanti_labs';
else
  pltdat = band_dat;
  pltlabs = band_labs';
end

t_ind = mask_gele( t, -350, 350 );

pl = plotlabeled.make_common();
pl.x = t(t_ind);
pl.add_errors = true;
pl.smooth_func = @(x) smooth(x, 3);
pl.add_smoothing = true;
% pl.y_lims = [ -2.5e-7, 2.5e-7 ];

mask = fcat.mask( pltlabs...
  , @find, {'choice', 'beta'} ...
  , @findnone, 'errors' ...
);

pltdat = pltdat(mask, t_ind);
pltlabs = prune( pltlabs(mask) );

pcats = { 'trialtypes', 'bands' };

axs = pl.lines( pltdat, pltlabs, {'outcomes', 'regions'}, pcats );

if ( do_save )
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, pltlabs, pcats );
end


