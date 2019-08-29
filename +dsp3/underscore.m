function b = underscore(a)

%   UNDERSCORE -- Add underscore pre- and postfix.
%
%     b = dsp3.underscore( 'eg' ) returns '_eg_'.

b = sprintf( '_%s_', a );
end