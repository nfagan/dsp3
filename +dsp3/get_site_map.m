function map = get_site_map(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

fname = fullfile( dsp3.dataroot(conf), 'constants', 'site_map.mat' );
map = shared_utils.io.fload( fname );

end