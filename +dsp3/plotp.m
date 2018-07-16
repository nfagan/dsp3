function p = plotp(varargin)

try
  p = dsp3.datap( 'plots', varargin{:} );
catch err
  throw( err );
end

end