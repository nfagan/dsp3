function [dat, labs] = band_meaned_data(data, labels, freqs, each, mask)

assert_ispair( data, labels );

if ( nargin < 4 )
  each = { 'trialtypes', 'regions', 'channels', 'days', 'outcomes', 'unit_uuid' };
end

if ( nargin < 5 )
  mask = rowmask( labels );
end

[mean_labs, mean_I] = keepeach( labels', each, mask );
mean_coh = bfw.row_nanmean( data, mean_I );

bands = dsp3.get_bands( 'map' );
[dat, labs] = dsp3.get_band_means( mean_coh, mean_labs', freqs, bands );

end