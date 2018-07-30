function tf = iseven(x)

%   ISEVEN -- True if input is a real-valued even integer.
%
%     IN:
%       - `x` (/numeric/)
%     OUT:
%       - `tf` (logical)

tf = mod( x, 2 ) == 0;

end