function labels = add_site_labels(labels, site_spec)

if ( nargin < 2 )
  site_spec = { 'days', 'channels', 'regions', 'unit_uuid' };
end

site_I = findall( labels, site_spec );
addcat( labels, 'sites' );

for i = 1:numel(site_I)
  setcat( labels, 'sites', sprintf('site__%d', i), site_I{i} );
end

end