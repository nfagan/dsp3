unipolar_pdc = shared_utils.io.fload( '/Users/Nick/Downloads/sivPDCabs12data.mat' );
bipolar_pdc = shared_utils.io.fload( '/Users/Nick/Downloads/choice_siv_bipolar_PDCabs12data.mat' );

base_save_p = char( dsp3.plotp({'pdc', 'reference_method_comparison', dsp3.datedir}) );

%%

[uni_data, uni_labels, freqs, t] = dsp3_pdc.convert_cc_pdc( unipolar_pdc );
[bi_data, bi_labels] = dsp3_pdc.convert_cc_pdc( bipolar_pdc );

addsetcat( uni_labels, 'reference', 'unipolar' );
addsetcat( bi_labels, 'reference', 'bipolar' );

pdc_labels = [ uni_labels'; bi_labels ];
pdc_data = [ uni_data; bi_data ];

%%

base_mask = fcat.mask( pdc_labels ...
  , @find, dsp3_pdc.bipolar_vs_unipolar_days() ...
);

%%

do_band_mean = true;
do_time_mean = true;
do_pro_v_anti = true;
do_max_norm = false;

t_ind = t >= 0 & t <= 150;

[band_data, band_labs] = indexpair( pdc_data, pdc_labels', base_mask );

if ( do_time_mean )
  band_data = squeeze( nanmean(band_data(:, :, t_ind), 3) );
end

if ( do_band_mean )
  [bands, band_names] = dsp3.some_bands( {'beta', 'new_gamma'} );
  [band_data, band_labs] = dsp3.get_band_means( band_data, band_labs, freqs, bands, band_names );
else
  addcat( band_labs, 'bands' );
end

if ( do_pro_v_anti )
  [band_data, band_labs] = dsp3.pro_v_anti( band_data, band_labs' ...
    , setdiff(getcats(band_labs), 'outcomes') );
end

norm_each = { 'bands', 'reference', 'regions', 'outcomes' };

if ( do_max_norm )
  band_data = dsp3_pdc.max_normalize( band_data, band_labs, norm_each );
end

%%

do_save = false;
save_p = fullfile( base_save_p, 'stats' );

t_mask = fcat.mask( band_labs ...
  , @find, {'bla_acc', 'new_gamma'} ...
);

t_mask = rowmask( band_labs );

test_each = union( setdiff(norm_each, 'reference'), 'outcomes' ); 

ttest_outs = dsp3.ttest2( band_data, band_labs', test_each ...
  , 'unipolar', 'bipolar', 'mask', t_mask );
t_ps = cellfun( @(x) x.p, ttest_outs.t_tables );
t_values = cellfun( @(x) x.tstat, ttest_outs.t_tables );
row_cats = {'outcomes', 'regions', 'bands'};
row_lab = fcat.strjoin( cellstr(ttest_outs.t_labels, row_cats)', ' | ' )';

t_tbl = table( row_lab, t_ps, t_values );

rs_outs = dsp3.ranksum( band_data, band_labs', setdiff(norm_each, 'reference') ...
  , 'unipolar', 'bipolar', 'mask', t_mask );
rs_ps = cellfun( @(x) x.p, rs_outs.rs_tables );
rs_tbl = table( cellstr(rs_outs.rs_labels, 'outcomes'), rs_ps );

if ( do_save )
  t_save_p = fullfile( save_p, 't-tables' );
  dsp3.req_writetable( t_tbl, t_save_p, ttest_outs.t_labels, row_cats );
end

%%  corr

unipolar_ind = find( band_labs, 'unipolar' );
unipolar_ind = dsp3_pdc.sample_sites( band_labs, {'regions', 'days'}, unipolar_ind );
bipolar_ind = find( band_labs, 'bipolar' );

corr_mask = union( unipolar_ind, bipolar_ind );
corr_I = findall( band_labs, setdiff(getcats(band_labs), {'reference', 'sites'}), corr_mask );
corr_labels = fcat();

X = [];
Y = [];

for i = 1:numel(corr_I)
  uni = rowref( band_data, find(band_labs, 'unipolar', corr_I{i}) );
  bi = rowref( band_data, find(band_labs, 'bipolar', corr_I{i}) );
  
  X = [ X; uni ];
  Y = [ Y; bi ];
  
  append1( corr_labels, band_labs, corr_I{i}, rows(uni) );
end

pl = plotlabeled.make_common();

plt_mask = fcat.mask( corr_labels ...
  , @find, {'acc_bla', 'new_gamma'} ...
);

gcats = {};
pcats = { 'bands', 'regions', 'outcomes' };

x_ = X(plt_mask);
y_ = Y(plt_mask);
labs_ = prune( corr_labels(plt_mask) );

% [axs, inds] = pl.scatter( x_, y_, labs_, gcats, pcats );
% plotlabeled.scatter_addcorr( inds, x_, y_ );

%%  hist

do_save = true;
save_p = fullfile( base_save_p, 'hist' );

pl = plotlabeled.make_common();
pl.hist_add_summary_line = true;

fcats = { 'regions', 'bands' };
pcats = { 'outcomes', 'reference', 'regions', 'bands' };

plt_mask = fcat.mask( band_labs ...
  , @find, {'bla_acc'} ...
);

plt_labs = band_labs(plt_mask);
plt_dat = rowref( band_data, plt_mask );

[figs, axs, I] = pl.figures( @hist, plt_dat, plt_labs, fcats, pcats, 100 );
shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

if ( do_save )
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(plt_labs(I{i})), [fcats, pcats] );
  end
end

%%  grouped hist

do_save = true;
save_p = fullfile( base_save_p, 'grouped-hist' );

fcats = { 'regions' };
gcats = { 'reference' };
pcats = { 'outcomes', 'regions', 'bands' };

% plt_mask = fcat.mask( band_labs ...
%   , @find, {'bla_acc'} ...
% );

plt_mask = rowmask( band_labs );

[figs, axs, I] = dsp3.grouped_hist( band_data, band_labs, fcats, gcats, pcats ...
  , 'mask', plt_mask ...
  , 'plot_inputs', {50} ...
  , 'add_summary_line', true ...
  , 'add_summary_text', false ...
  , 'y_lims', [0, 30] ...
);

shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );
shared_utils.plot.alpha( axs, 1 );

if ( do_save )
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(band_labs(I{i})), [fcats, pcats] );
  end
end

%%  lines

pl = plotlabeled.make_common();
pl.x = freqs;
pl.smooth_func = @(x) smoothdata(x, 'smoothingfactor', 0.5 );
pl.add_smoothing = true;

fcats = {};
gcats = { 'reference' };
pcats = { 'outcomes', 'regions' };

[figs, axs, I] = pl.figures( @lines, band_data, band_labs, fcats, gcats, pcats );

%%  spectra

plt_freqs = freqs;
plt_t = t;

pl = plotlabeled.make_spectrogram( plt_freqs, plt_t );

fcats = { 'regions' };
pcats = { 'outcomes', 'reference', 'regions' };

[figs, axs, I] = pl.figures( @imagesc, band_data, band_labs, fcats, pcats );

shared_utils.plot.tseries_xticks( axs, plt_t, 5 );
shared_utils.plot.fseries_yticks( axs, flip(plt_freqs), 10 );
shared_utils.plot.match_clims( axs );

%%  bar

save_p = fullfile( base_save_p, 'bar' );

do_save = true;

pl = plotlabeled.make_common();
pl.x_order = { 'self', 'both', 'other', 'none' };

fcats = {};
xcats = { 'outcomes' };
gcats = { 'reference' };
pcats = { 'bands', 'regions' };

[figs, axs, I] = pl.figures( @bar, band_data, band_labs, fcats, xcats, gcats, pcats );
shared_utils.plot.match_ylims( axs );

if ( do_save )
  save_each = [ xcats, gcats, pcats, fcats ];
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(band_labs(I{i})), save_each );
  end
end

%%  boxplot

save_p = fullfile( base_save_p, 'boxplot' );
do_save = true;

pl = plotlabeled.make_common();
pl.x_order = { 'self', 'both', 'other', 'none' };

fcats = { 'regions' };
xcats = {};
gcats = { 'reference' };
pcats = { 'bands', 'regions', 'outcomes' };

[figs, axs, I] = pl.figures( @boxplot, band_data, band_labs, fcats, gcats, pcats );
shared_utils.plot.match_ylims( axs );

if ( do_save )
  save_each = [ gcats, pcats, fcats ];
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(band_labs(I{i})), save_each );
  end
end
