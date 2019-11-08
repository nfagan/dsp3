function consolidated = load_fixed_consolidated_data(varargin)

consolidated = dsp3.get_consolidated_data( varargin{:} );
updated_labels_p = fullfile( dsp3.dataroot(varargin{:}), 'labels', 'fixed_event_labels.mat' );
labels = shared_utils.io.fload( updated_labels_p );
consolidated.events.labels = labels;


end