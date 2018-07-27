function b = underscore(a)

%   UNDERSCORE -- Add underscore pre- and postfix.
%
%     b = ... underscore( 'eg' ) returns '_eg_'.
%
%     IN:
%       - `a` (char)
%     OUT:
%       - `b` (char)

b = sprintf( '_%s_', a );
end