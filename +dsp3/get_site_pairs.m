function map = get_site_pairs(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

fname = fullfile( dsp3.dataroot(conf), 'constants', 'pairs.mat' );
map = shared_utils.io.fload( fname );

end