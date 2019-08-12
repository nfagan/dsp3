function [site_coh, site_labs, site_I] = site_meaned_sfcoh(data, labels, mask, sites_each, row_func)

if ( nargin < 5 )
  row_func = @bfw.row_nanmean;
end

if ( nargin < 3 || (iscell(mask) && isempty(mask)) )
  mask = rowmask( labels );
end

if ( nargin < 4 )
  sites_each = dsp3_ct.site_specificity();
end

assert_ispair( data, labels );

[site_labs, site_I] = keepeach( labels, sites_each, mask );

site_coh = row_func( data, site_I );

end