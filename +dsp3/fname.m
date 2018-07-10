function s = fname(labs, cats, varargin)

%   FNAME -- Generate filename from label(s) in category(ies).
%
%     s = ... fname( L, C ) generates a character vector `s` from the
%     unique labels in categories `C` of fcat object `L`.
%
%     s = ... fname( L, C, MASK ) only pulls labels from rows of `L`
%     identified by `MASK`.
%
%     See also fcat/fcat, fcat.trim, fcat.strjoin, fcat/joincat
%
%     IN:
%       - `labs` (fcat)
%       - `cats` (cell array of strings, char)
%       - `mask` (uint64) |OPTIONAL|
%     OUT:
%       - `s` (char)

c = combs( labs, cats, varargin{:} );
s = fcat.trim( strjoin(unique(c), '_') );

end