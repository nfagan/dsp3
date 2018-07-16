function [banddat, bandlabs, I] = get_band_means(data, labels, freqs, bands, bandnames)

fdim = 2;
tdim = 3;

narginchk( 4, 5 );

if ( nargin == 5 )
  assert( numel(bands) == numel(bandnames), 'Bands must match bandnames.' );
else
  shared_utils.assertions.assert__isa( bands, 'containers.Map', 'the band map' );
  bandnames = keys( bands );
  bands = values( bands );
end

assert_rowsmatch( data, labels );
assert( numel(freqs) == size(data, fdim), 'Frequencies do not correspond to data.' );

rdat = rows( data );
nbands = numel( bands );

newsz = [ rdat*nbands, size(data, tdim) ];

banddat = zeros( newsz );
I = zeros( size(banddat) );

bandcat = 'bands';
bandlabs = repset( addcat(labels, bandcat), bandcat, bandnames );

stp = 1;
full_inds = 1:rdat;
clns = colons( ndims(data)-1 );

for i = 1:numel(bands)
  f_ind = freqs >= bands{i}(1) & freqs <= bands{i}(2);
  
  roi_data = squeeze( nanmean(dimref(data, f_ind, fdim), fdim) );
  
  rinds = stp:stp+rdat-1;
  
  I(rinds) = full_inds;
  banddat(rinds, clns{:}) = roi_data;
  stp = stp + rdat;
end

prune( bandlabs );

end