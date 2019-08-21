function labs = quantiles_each(dat, labs, num_tiles, each, quants_of, mask)

assert_ispair( dat, labs );
validateattributes( dat, {'double', 'single'}, {'vector'}, mfilename, 'data' );

quant_cat = 'quantile';
addcat( labs, quant_cat );

if ( nargin < 6 )
  mask = rowmask( labs );
end

each_I = findall_or_one( labs, each, mask );

for i = 1:numel(each_I)
  of_I = findall_or_one( labs, quants_of, each_I{i} );
  
  tile_ind = vertcat( of_I{:} );

  tiles = quantile( dat(tile_ind), num_tiles-1 );
  tiles = [ -inf, tiles, inf ];
  
  for j = 1:numel(tile_ind)
    val = dat(tile_ind(j));

    for k = 1:numel(tiles)-1
      lb = tiles(k);
      ub = tiles(k+1);

      crit = val > lb & val <= ub;

      if ( crit )
        setcat( labs, quant_cat, sprintf('%s_%d', quant_cat, k), tile_ind(j) );
        break;
      end
    end
  end
end

prune( labs );

end