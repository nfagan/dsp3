function band_ranges = some_bands(band_names, varargin)

narginchk( 1, 3 );

if ( nargin == 1 )
  bands = dsp3.get_bands( 'map' );

elseif ( nargin == 2 )
  validateattributes( varargin{1}, {'containers.Map'}, {}, mfilename, 'band map' );
  bands = varargin{1};
else
  validateattributes( varargin{1}, {'cell'}, {}, mfilename, 'bands' );
  validateattributes( varargin{2}, {'cell'}, {'numel', numel(varargin{1})} ...
    , mfilename, 'band names' );
  
  bands = containers.Map();
  
  for i = 1:numel(varargin{2})
    bands(varargin{2}{i}) = varargin{1}{i};
  end
end

band_names = cellstr( band_names );
band_ranges = cell( size(band_names) );

for i = 1:numel(band_names)
  band_ranges{i} = bands(band_names{i});
end

end