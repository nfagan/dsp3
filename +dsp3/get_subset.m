function data = get_subset( data, drug_type, keep_spec )

if ( nargin < 3 )
  keep_spec = 'days';
end

if ( strcmp(drug_type, 'nondrug') )
  [unspc, tmp_behav] = data.pop( 'unspecified' );
  if ( ~isempty(unspc) )
    unspc = unspc.for_each( keep_spec, @dsp2.process.format.keep_350, 350 ); 
  end
  tmp_behav = append( tmp_behav, unspc );
  data = dsp2.process.manipulations.non_drug_effect( tmp_behav );
  data('drugs') = '<drugs>';
elseif ( strcmp(drug_type, 'drug') )
  data = data.rm( 'unspecified' );
else
  assert( strcmp(drug_type, 'unspecified'), 'Unrecognized drug type "%s"', drug_type );
  data = data.only( 'unspecified' );
end

data = dsp2.process.format.rm_bad_days( data );

end