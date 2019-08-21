function [quants, each_I] = quantiles_each(dat, labs, num_tiles, each, quants_of, mask)

%   QUANTILES_EACH -- Get quantiles for subsets of data.
%
%     quantiles = dsp3.quantiles_each( data, labels, num_tiles, each, of );
%     returns quantile indices for each element of the vector `data`.
%     Quantiles are computed separately for each combination of labels in
%     `each` categories, and across combinations of labels in `of`
%     categories. `num_tiles` gives the number of quantiles to compute, and
%     must be >= 2.
%
%     quantiles = dsp3.quantiles_each( ..., mask ); for the uint64 index
%     vector `mask` applies a mask to the data and labels such that 
%     combinations of labels (and their associated quantiles) are only 
%     computed for elements selected by the mask. Rows of `data` not
%     selected by `mask` are NaN in the output `quantiles`.
%
%     See also dsp3.anova1, dsp3.ttest2, dsp3.multi_plot, proportions_of

assert_ispair( dat, labs );
validateattributes( dat, {'double', 'single'}, {'vector'}, mfilename, 'data' );
validateattributes( num_tiles, {'double', 'single'}, {'scalar', '>=', 2}, mfilename, 'num quantiles' );

if ( nargin < 6 )
  mask = rowmask( labs );
end

each_I = findall_or_one( labs, each, mask );
quants = nan( rows(dat), 1 );

for i = 1:numel(each_I)
  of_I = findall_or_one( labs, quants_of, each_I{i} );
  
  tile_ind = vertcat( of_I{:} );
  
  if ( num_tiles == 2 )
    tiles = nanmedian( dat(tile_ind) );
  else
    tiles = quantile( dat(tile_ind), num_tiles-1 );
  end
  
  tiles = [ -inf, tiles, inf ];
  
  for j = 1:numel(tile_ind)
    val = dat(tile_ind(j));

    for k = 1:numel(tiles)-1
      lb = tiles(k);
      ub = tiles(k+1);

      crit = val > lb & val <= ub;

      if ( crit )
        quants(tile_ind(j)) = k;
        break;
      end
    end
  end
end

end