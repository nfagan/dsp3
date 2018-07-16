function p = analysisp(varargin)

try
  p = dsp3.datap( 'analyses', varargin{:} );
catch err
  throw( err );
end

end