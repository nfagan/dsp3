function keep_inds = sample_sites(labels, each, mask)

I = findall( labels, each, mask );

inds = {};

for i = 1:numel(I)
  site_I = findall( labels, 'sites', I{i} );
  num_keep = numel( site_I ) - 1;  
  perm = sort( randperm(numel(site_I), num_keep) );
  site_I = site_I(perm);
  inds{end+1, 1} = vertcat( site_I{:} );
end

keep_inds = sort( vertcat(inds{:}) );

end