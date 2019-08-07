mat_p = '/Users/Nick/Desktop/targacq';
mats = shared_utils.io.findmat( mat_p );

[data, labels, freqs, t] = bfw.load_time_frequency_measure( mats ...
  , 'get_data_func', @(x) x.measure.data ...
  , 'get_labels_func', @(x) fcat.from(x.measure.labels) ...
  , 'get_freqs_func', @(x) x.measure.frequencies ...
  , 'get_time_func', @(x) get_time_series(x.measure) ...
);

%%

[subset_labels, subset_I] = keepeach( labels' ...
  , {'administration', 'channels', 'days', 'epochs', 'outcomes', 'regions', 'sites', 'trialtypes'} );

subset_data = bfw.row_nanmean( data, subset_I );

cont = Container( subset_data, SparseLabels.from_fcat(subset_labels) );
cont = SignalContainer( cont );
cont.start = min(t);
cont.stop = max(t);
cont.step_size = nanmedian( diff(t) );
cont.window_size = 150;

save( fullfile(fileparts(mat_p), 'combined.mat'), 'cont' );