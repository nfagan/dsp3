is_zs = [ true, false ];
pro_minus_antis = [ true ];
spec_types = { 'blocks', 'sites' };
rev_types = { 'revB', 'revA', 'orig', 'full' };
drug_types = { 'nondrug_wbd' };

C = dsp3.numel_combvec( rev_types, drug_types, spec_types, pro_minus_antis, is_zs );

for i = 1:size(C, 2)
  shared_utils.general.progress( i, size(C, 2) );
  
  inputs = struct();
  
  col = C(:, i);  

  revtype = rev_types{ col(1) };
  drugtype = drug_types{ col(2) };
  spectype = spec_types{ col(3) };
  is_pro_minus_anti = pro_minus_antis( col(4) );
  is_z = is_zs( col(5) );
  
  inputs.is_pro_minus_anti = is_pro_minus_anti;
  inputs.drug_type = drugtype;
  inputs.base_subdir = revtype;
  inputs.specificity = spectype;
  inputs.is_z = is_z;

  switch ( revtype )
    case 'revA'
      inputs.remove = dsp3.bad_days_revA();
    case 'revB'
      inputs.remove = dsp3.bad_days_revB();
    case 'orig'
      inputs.remove = dsp2.process.format.get_bad_days();
    case 'full'
      inputs.remove = {};  % remove nothing
    otherwise
      error( 'Unrecognized revision "%s".', revtype );
  end
  
  stats__proanti_coh( inputs );
end
