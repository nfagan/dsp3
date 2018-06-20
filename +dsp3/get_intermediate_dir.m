function p = get_intermediate_dir(kind, conf)

import shared_utils.assertions.*;

if ( nargin < 2 || isempty(conf) )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

data_p = conf.PATHS.data_root;

if ( isa(kind, 'char') )
  p = fullfile( data_p, 'intermediates', kind );
else
  p = cellfun( @(x) fullfile(data_p, 'intermediates', x), kind, 'un', 0 );
end

end