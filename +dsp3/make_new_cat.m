function [labs, newcat] = make_new_cat(labs, category)

%   MAKE_NEW_CAT -- Make new category from pattern.
%
%     IN:
%       - `labs` (fcat)
%       - `category` (char)
%     OUT:
%       - `labs` (fcat)
%       - `newcat` (char)

newcat = category;
stp = 1;

while ( hascat(labs, newcat) )
  newcat = sprintf( '%s%d', category, stp );
  stp = stp + 1;
end

end