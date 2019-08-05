function [to_keep, num_missing] = find_sites_with_all_outcomes(site_labs, spec, mask)

if ( nargin < 3 )
  mask = rowmask( site_labs );
end

spec = setdiff( spec, 'outcomes' );

site_I = findall( site_labs, spec, mask );
to_keep = {};
outs = combs( site_labs, 'outcomes', mask );
num_missing = 0;

for i = 1:numel(site_I)
  cts = count( site_labs, outs, site_I{i} );
  
  if ( ~any(cts == 0) )
    to_keep{end+1, 1} = site_I{i};
  else
    num_missing = num_missing + 1;
  end
end

to_keep = vertcat( to_keep{:} );

end