function data = max_normalize(data, labels, each, varargin)

norm_I = findall( labels, each, varargin{:} );
clns = colons( ndims(data)-1 );

for i = 1:numel(norm_I)
  norm_ind = norm_I{i};
  subset = data( norm_ind, clns{:} );  
  max_elements = max( subset, [], 1 );
  data(norm_ind, clns{:}) = subset ./ max_elements;
end

end