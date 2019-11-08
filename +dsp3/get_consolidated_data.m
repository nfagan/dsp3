function [dat, fname] = get_consolidated_data(conf)

if ( nargin < 1 ), conf = dsp3.config.load(); end

consolidated_p = dsp3.get_intermediate_dir( 'consolidated', conf );

consolidated_mats = shared_utils.io.find( consolidated_p, '.mat' );
filenames = shared_utils.io.filenames( consolidated_mats );
remove_ind = cellfun( @(x) x(1) == '.', filenames );
consolidated_mats = consolidated_mats(~remove_ind);

assert( numel(consolidated_mats) == 1, ['Expected to find 1 .mat file in "%s";' ...
, ' instead there were %d.'], consolidated_p, numel(consolidated_mats) );

fname = consolidated_mats{1};

dat = shared_utils.io.fload( fname );

end