function p = get_intermediate_dir(kind, conf)

import shared_utils.assertions.*;

if ( nargin < 2 || isempty(conf) )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

data_p = conf.PATHS.data_root;

p = shared_utils.io.fullfiles( data_p, 'intermediates', kind );

end