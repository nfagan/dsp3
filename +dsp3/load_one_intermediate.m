function x = load_one_intermediate(kind, name, conf)

if ( nargin < 3 || isempty(conf) ), conf = dsp3.config.load(); end
if ( nargin < 2 ), name = ''; end

dsp3.util.assertions.assert__is_config( conf );

intermediate_dir = dsp3.get_intermediate_dir( kind, conf );

mats = shared_utils.io.find( intermediate_dir, '.mat' );

x = [];

if ( numel(mats) == 0 ), return; end

if ( isempty(name) )
  x = shared_utils.io.fload( mats{1} );
  return;
end

mats = shared_utils.cell.containing( mats, name );

if ( isempty(mats) ), return; end

x = shared_utils.io.fload( mats{1} );

end