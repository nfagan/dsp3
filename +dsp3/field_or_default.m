function v = field_or_default(s, field, val)

%   FIELD_OR_DEFAULT -- Get field or default value if field does not exist.
%
%     v = ... field_or_value( x, 'example', 10 ) returns x.example, if
%     'example' is a field of struct `x`, or else 10.
%
%     IN:
%       - `s` (struct)
%       - `field` (char)
%       - `val` (/any/)

if ( isfield(s, field) )
  v = s.(field);
else
  v = val;
end

end