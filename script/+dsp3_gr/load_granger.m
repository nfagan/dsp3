function granger = load_granger(subdir, conf)

if ( nargin < 2 )
  conf = dsp3.config.load();
end

filepath = fullfile( dsp3.dataroot(conf), 'analyses', 'granger', subdir, 'granger.mat' );
granger = shared_utils.io.fload( filepath );

end