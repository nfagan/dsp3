function params = parsestruct(params, args)

%   PARSESTRUCT -- Convert varargin inputs to struct.
%
%     params = parsestruct( S, {NAME1, VALUE1, ...} )
%     assigns to `VALUE1` to field `NAME1` of struct `S`, and so on for any
%     additional number of ('name', value) pair inputs. Each field must be
%     a present fieldname of `S`.
%
%     params = parsestruct( S, {S2} ) where `S2` is a struct, assigns the
%     values of `S2` to the corresponding fields of `S`. All fields of `S2`
%     must be fields of `S`, but `S` can have additional fields.
%
%     IN:
%       - `params` (struct)
%       - `args` (cell)
%     OUT:
%       - `params` (struct)

assert( iscell(args), 'Arguments must be cell array.' );

if ( numel(args) == 1 && isstruct(args{1}) )
  args = dsp3.struct2varargin( args{1} );
end

names = fieldnames(params);

nArgs = length(args);

if ( ~dsp3.iseven(nArgs) )
   error('Name-value pairs are incomplete!')
end

for pair = reshape(args,2,[])
   inpName = pair{1};
   if any(strcmp(inpName,names))
      params.(inpName) = pair{2};
   else
      error('%s is not a recognized parameter name',inpName)
   end
end