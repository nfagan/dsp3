function varargout = get_subset( fullset, drug_type, keep_spec )

if ( isa(fullset, 'Container') )
  if ( nargin < 3 ), keep_spec = 'days'; end
  
  subset = get_cont_subset( fullset, drug_type, keep_spec );
  assert( nargout == 1, 'Indices not supported with Container input.' );
  
  varargout{1} = subset;
else
  if ( nargin < 3 ), keep_spec = {}; end
  
  assert( isa(fullset, 'fcat'), 'Labels must be "fcat" or "Container"; were "%s".' ...
    , class(fullset) );
  
  [labs, I] = get_fcat_subset( fullset, drug_type, keep_spec );
  
  varargout{1} = labs;
  
  if ( nargout > 1 ), varargout{2} = I; end
end

end

function [labs, I] = get_fcat_subset(labs, kind, addtl)

bad_days_ind = trueat( labs, findor(labs, dsp2.process.format.get_bad_days()) );
good_days_ind = find( ~bad_days_ind );

switch ( kind )
  case { 'nondrug', 'nondrug_wbd' }
    %   keep first 350 trials for non-injection "unspecified" days.
    if ( isempty(addtl) )
      each_inds = { 1:length(labs) }; 
    else
      each_inds = findall( labs, addtl );
    end
    
    unspc_ind = trueat( labs, [] );
    
    for i = 1:numel(each_inds)
      mask = find( labs, 'unspecified', each_inds{i} );
      first_ind = dsp3.find_first_trials( labs, 350, mask );
      unspc_ind = unspc_ind | trueat( labs, first_ind );
    end
    
    %   keep pre only for saline and oxytocin days
    sal_pre_ind = trueat( labs, find(labs, {'saline', 'pre'}) );
    oxy_pre_ind = trueat( labs, find(labs, {'oxytocin', 'pre'}) );  
    
    I = sal_pre_ind | oxy_pre_ind | unspc_ind;
    
    if ( strcmp(kind, 'nondrug') )
      I = find( I & ~bad_days_ind );
    else
      I = find( I );
    end
    
    keep( labs, I );
    
    if ( ~isempty(labs) )
      setcat( labs, 'administration', 'pre' );
      setcat( labs, 'drugs', makecollapsed(labs, 'drugs') );
    end
  case 'drug'
    %
    % regular drug
    I = findor( labs, {'saline', 'oxytocin'}, good_days_ind );
    keep( labs, I );
  case 'drug_wbd'
    %
    % drug with bad days
    I = findor( labs, {'saline', 'oxytocin'} );
    keep( labs, I );
  case 'full'
    I = good_days_ind;
    keep( labs, I );
  otherwise
    error( 'Unrecognized subset "%s".', kind );
end

end

function data = get_cont_subset(data, drug_type, keep_spec)

rem_bad = true;

if ( dsp3.isnondrug(drug_type) )
  [unspc, tmp_behav] = data.pop( 'unspecified' );
  if ( ~isempty(unspc) )
    unspc = unspc.for_each( keep_spec, @dsp2.process.format.keep_350, 350 ); 
  end
  tmp_behav = append( tmp_behav, unspc );
  data = dsp2.process.manipulations.non_drug_effect( tmp_behav );
  data('drugs') = '<drugs>';
  rem_bad = strcmp( drug_type, 'nondrug' );
elseif ( dsp3.isdrug(drug_type) )
  data = data.rm( 'unspecified' );
  rem_bad = strcmp( drug_type, 'drug' );
elseif ( strcmp(drug_type, 'full') )
  %
else
  assert( strcmp(drug_type, 'unspecified'), 'Unrecognized drug type "%s"', drug_type );
  data = data.only( 'unspecified' );
end

if ( rem_bad )
  data = dsp2.process.format.rm_bad_days( data );
end

end