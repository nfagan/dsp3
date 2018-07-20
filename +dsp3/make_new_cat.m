function [labs, newcat] = make_new_cat(labs, category)

%   MAKE_NEW_CAT -- Make new category from pattern.
%
%     ... make_new_cat( labs, 'example' ) creates a category name that 
%     begins with 'example'. If 'example' is not a category of `labs`, 
%     the new
%     successive integers, beginning with 1, will be appended to 'example',
%     until the resulting name does not 
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