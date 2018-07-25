
function save(conf)

%   SAVE -- Save the config file.

dsp3.util.assertions.assert__is_config( conf );
const = dsp3.config.constants();
fprintf( '\n Config file saved\n\n' );
save( fullfile(const.config_folder, const.config_filename), 'conf' );

dsp3.config.load( '-clear' );

end