function labels = dsp3_load_cc_targacq_labels(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

file_path = fullfile( dsp3.dataroot(conf), 'constants', 'cc_targacq_trial_labels.mat' );
labels = shared_utils.io.fload( file_path );

end