function str = get_datestr(format)

%   GET_DATESTR -- Get the current date as a string.
%
%     IN:
%       - `format` (char) |OPTIONAL|
%     OUT:
%       - `str` (char)

if ( nargin < 1 )
  format = 'mmddyy';
end

str = datestr( now, format );

end