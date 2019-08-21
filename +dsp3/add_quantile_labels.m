function labels = add_quantile_labels(labels, quantile_indices, quant_cat, quant_labels)

%   ADD_QUANTILE_LABELS -- Associate quantile indices with labels.
%
%     dsp3.add_quantile_labels( labels, quant_indices, quant_category );
%     generates labels of the form '$quant_category__$quant_index', for
%     each index in `quant_indices`. `labels` and `quant_indices` must have
%     the same number of rows.
%
%     dsp3.add_quantile_labels( ..., quant_labels ); specifies the labels 
%     for each index in `quant_indices`. 

assert_ispair( quantile_indices, labels );
addcat( labels, quant_cat );

unique_inds = unique( quantile_indices(~isnan(quantile_indices)) );

if ( nargin > 3 )
  quant_labels = cellstr( quant_labels );
  
  if ( numel(unique_inds) ~= numel(quant_labels) || ...
      any(unique_inds < 1 | unique_inds > numel(quant_labels)) )
    error( ['Number of unique quantile indices (%d) does not match number' ...
      , ' of quantile labels (%d).'], numel(unique_inds), numel(quant_labels) );
  end
else
  quant_labels = arrayfun( @(x) sprintf('%s__%d', quant_cat, x), unique_inds, 'un', 0 );
end

for i = 1:numel(unique_inds)
  unq_ind = find( quantile_indices == unique_inds(i) );
  setcat( labels, quant_cat, quant_labels{unique_inds(i)}, unq_ind );
end

end