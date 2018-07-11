function s = prefix(s1, s2, join_char)
if ( nargin < 3 ), join_char = '_'; end
s = sprintf( '%s%s%s', s1, join_char, s2 );
end