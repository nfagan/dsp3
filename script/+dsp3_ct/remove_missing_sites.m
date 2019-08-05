function [site_coh, site_labs] = remove_missing_sites(site_coh, site_labs, site_spec, mask)

assert_ispair( site_coh, site_labs );

if ( nargin < 3 )
  site_spec = dsp3_ct.site_specificity();
end

if ( nargin < 4 )
  mask = rowmask( site_labs );
end

no_nans = intersect( find(~any(any(isnan(site_coh), 2), 3)), mask );

site_coh = site_coh(no_nans, :, :);
keep( site_labs, no_nans );

to_keep = dsp3_ct.find_sites_with_all_outcomes( site_labs, site_spec );

site_coh = site_coh(to_keep, :, :);
keep( site_labs, to_keep );

prune( site_labs );

end