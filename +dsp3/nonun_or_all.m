function c = nonun_or_all(labs, cats, always)

%   NONUN_OR_ALL -- Filter out uniform categories, if possible.
%
%     c = nonun_or_all( labs, cats ) returns the subset of categories
%     `cats` that are non-uniform in the fcat object `labs`. If none of 
%     `cats` are non-uniform, then `c` is `cats`.
%
%     c = nonun_or_all( ..., always_include ) includes the categories
%     `always_include` regardless of whether they are uniform.
%
%     A non-uniform category is one for which multiple different labels are
%     present entries in the category.
%
%     See also dsp3.nonun_or_other
%
%     IN:
%       - `labs` (fcat)
%       - `cats` (cell array of strings, char)
%       - `always` (cell array of strings, char) |OPTIONAL|
%     OUT:
%       - `c` (cell array of strings)

c = cssetdiff( cats, getcats(labs, 'un') );

if ( isempty(c) )
  c = cats; 
end

if ( nargin > 2 )
  c = csunion( c, always );
end

end