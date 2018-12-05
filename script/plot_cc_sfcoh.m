mats = shared_utils.io.findmat( '~/Desktop' );

try
  acc = shared_utils.io.fload( mats{1} );
catch err
  warning( err.message );
  acc = {};
end

try
  bla = shared_utils.io.fload( mats{2} );
catch err
  warning( err.message );
  bla = {};
end

[data, labels] = dsp3_get_converted_cc_sf_data( acc, bla );

%%

cont = Container( data, SparseLabels.from_fcat(labels) );
cont = SignalContainer( cont );
cont.frequencies = linspace( 0, 500, size(data, 2) );
cont.start = -500;
cont.stop = 500;
cont.step_size = 50;
cont.window_size = 150;
cont.fs = 1e3;

%%

to_lda = keep_within_freqs( remove_nans_and_infs(cont), [0, 20] );
to_lda = only( to_lda, 'day__30' );
dsp2.analysis.lda.script.run_null_lda_cc_sf( to_lda );

%%

spec = { 'sites', 'outcomes' };

[meanlabs, I] = keepeach( labels', spec );
meandat = rowop( data, I, @(x) nanmean(x, 1) );

[meandat, meanlabs] = dsp3.pro_v_anti( meandat, meanlabs', 'sites' );

%%

pltdat = meandat;
pltlabs = meanlabs';

t = -500:50:500;
freqs = linspace( 0, 500, size(pltdat, 2) );

f_ind = freqs >= 0 & freqs <= 100;

pl = plotlabeled.make_spectrogram( freqs(f_ind), t );

pcats = { 'outcomes' };

axs = pl.imagesc( pltdat(:, f_ind, :), pltlabs, pcats );
shared_utils.plot.tseries_xticks( axs, t, 5 );
shared_utils.plot.fseries_yticks( axs, round(flip(freqs(f_ind))), 5 );

