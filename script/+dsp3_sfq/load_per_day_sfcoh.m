function [data, labels, freqs, t] = load_per_day_sfcoh(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

load_p = fullfile( dsp3.dataroot(conf), 'data', 'sfcoh', 'per_day' );
mats = shared_utils.io.findmat( load_p );

[data, labels, freqs, t] = bfw.load_time_frequency_measure( mats ...
  , 'get_labels_func', @(x) x.labels ...
);

end