function p = plotp(components, conf)

if ( nargin < 2 )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

if ( ~iscell(components) ), components = { components }; end

base_plotp = fullfile( conf.PATHS.data_root, 'plots' );
p = fullfile( base_plotp, components{:} );

end