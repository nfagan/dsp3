function dat = get_consolidated_data(conf)

if ( nargin < 1 ), conf = dsp3.config.load(); end

consolidated_p = dsp3.get_intermediate_dir( 'consolidated', conf );

consolidated_mats = shared_utils.io.find( consolidated_p, '.mat' );

assert( numel(consolidated_mats) == 1, ['Expected to find 1 .mat file in "%s";' ...
, ' instead there were %d.'], consolidated_p, numel(consolidated_mats) );

dat = shared_utils.io.fload( consolidated_mats{1} );

end