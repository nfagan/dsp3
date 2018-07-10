function p = dataroot(conf)

if ( nargin < 1 )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

p = conf.PATHS.data_root;

end