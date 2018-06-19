function varargout = get_bands(flag)

bands = { [4, 8], [15, 25], [45, 60] };
bandnames = { 'theta', 'beta', 'gamma' };

flags = { 'map' };
flag_str = strjoin( flags, ' | ' );

if ( nargin == 1 )
  assert( strcmp(flag, 'map'), 'Unrecognized flag "%s".\n Options are:\n%s', flag, flag_str );
  assert( nargout == 1 || nargout == 0, 'Too many outputs.' );
  
  varargout{1} = containers.Map( bandnames, bands );
  return;
end

varargout{1} = bands;

if ( nargout > 1 )
  varargout{2} = bandnames;
end

end