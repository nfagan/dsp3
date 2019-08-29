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

try
  params = shared_utils.general.parsestruct( params, args );
catch err
  throw( err );
end

end