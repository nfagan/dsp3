function a = nonun_or_other(labs, other)

%   NONUN_OR_OTHER -- Conditionally get non-uniform categories.
%
%     A = nonun_or_other( labs ) returns either the non-uniform categories
%     of `labs`, or all categories of `labs`, if no categories are
%     non-uniform.
%
%     A = nonun_or_other( labs, OTHER ) returns either the non-uniform
%     categories of `labs`, or `OTHER`, if no categories are non-uniform.
%
%     A non-uniform category is one for which multiple different labels 
%     are present entries in the category.
%
%     See also fcat/getcats
%
%     IN:
%       - `labs` (fcat)
%       - `other` (cell array of strings)
%     OUT:
%       - `a` (cell array of strings)

if ( nargin < 2 ), other = getcats( labs ); end
nonun = getcats( labs, 'nonuniform' );
a = ternary( ~isempty(nonun), nonun, cellstr(other) );

end