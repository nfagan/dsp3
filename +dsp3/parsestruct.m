function params = parsestruct(params,args)

assert( iscell(args), 'Arguments must be cell array.' );

if ( numel(args) == 1 && isstruct(args{1}) )
  args = dsp3.struct2varargin( args{1} );
end

names = fieldnames(params);

nArgs = length(args);

if round(nArgs/2)~=nArgs/2
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