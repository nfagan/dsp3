function sua_data = load_sua_data(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

load_file = fullfile( conf.PATHS.data_root, 'analyses', 'processed_units' ...
  , 'dictator_game_SUAdata_pre.mat' );

sua_data = load( load_file );

end