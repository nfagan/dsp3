function outs = pro_v_anti_z(data, labs, mean_spec, N)

%   PRO_V_ANTI_Z -- Z-transform data by shuffling outcome labels, within
%     context.
%
%     IN:
%       - `data` (double)
%       - `labs` (fcat)
%       - `mean_spec` (cell array of strings, char)
%       - `N` (double)

sans_outcomes = setdiff( mean_spec, 'outcomes' );

data_sz = size( data );
colons = repmat( {':'}, 1, ndims(data)-1 );

[zlabs, I] = keepeach( labs', sans_outcomes );
zdat = zeros( [length(zlabs), data_sz(2:end)] );
zdists = cell( size(I) );
realdat = zdat;

for i = 1:numel(I)
  ind = I{i};

  [real_inds, outs] = findall( labs, 'outcomes', ind );

  assert( numel(outs) == 2, 'Expected 2 outcomes; %d were present', numel(outs) );

  n1 = numel( real_inds{1} );
  n2 = numel( real_inds{2} );

  assert( n1 + n2 == numel(ind) );
  
  real_diff = get_difference( data, real_inds, outs );
  
  null_diffs = zeros( [N, data_sz(2:end)] );

  for j = 1:N
    shuff_ind = ind( randperm(numel(ind)) );
    ind1 = shuff_ind(1:n1);
    ind2 = shuff_ind(n1+1:end);

    null_diffs(j, colons{:}) = get_difference( data, {ind1, ind2}, outs );
  end
  
  means = nanmean( null_diffs, 1 );
  devs = nanstd( null_diffs, [], 1 );
  zs = (real_diff - means) ./ devs;
  
  zdat(i, colons{:}) = zs;
  realdat(i, colons{:}) = real_diff;
  zdists{i} = null_diffs;
end

zdistlabs = repmat( zlabs', N );
zdists = vertcat( zdists{:} );

outs = struct();
outs.zlabs = zlabs;
outs.zdat = zdat;
outs.realdat = realdat;
outs.zdistlabs = zdistlabs;
outs.zdists = zdists;

end

function d = get_difference(data, inds, outs)

assert( numel(inds) == numel(outs) );

[sb_exists, sb_ind] = ismember( outs, {'self', 'both'} );
[on_exists, on_ind] = ismember( outs, {'other', 'none'} );
  
assert( xor(all(sb_exists), all(on_exists)) && xor(any(sb_exists), any(on_exists)) );

if ( all(sb_exists) ), use_ind = sb_ind; else, use_ind = on_ind; end

inda = inds{use_ind(1)};
indb = inds{use_ind(2)};

d1 = nanmean( rowref(data, inda), 1 );
d2 = nanmean( rowref(data, indb), 1 );

d = d1 - d2;

end