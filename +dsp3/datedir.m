function d = datedir(when)
if ( nargin < 1 ), when = now; end
d = datestr( when, 'mmddyy' );
end