function v = key_or_default(m, key, val)

%   KEY_OR_DEFAULT -- Get item from map or default value if key is missing.
%
%     IN:
%       - `m` (containers.Map)
%       - `key` (char)
%       - `val` (/any/)
%     OUT:
%       - `v` (/any/)

v = val;
if ( isKey(m, key) ), v = m(key); end

end