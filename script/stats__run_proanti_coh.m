function stats__run_proanti_coh(conf)

if ( nargin < 1 )
  conf = dsp3.config.load();
end

rev_types = dsp3.get_rev_types();

revs = keys( rev_types );
drug_types = { 'nondrug_wbd', 'drug_wbd' };
epochs = { 'targacq' };
zs = [ false, true ];
pro_minus_antis = [ false, true ];
specs = { 'sites' };

C = dsp3.numel_combvec( revs, drug_types, epochs, zs, pro_minus_antis, specs );
NC = size( C, 2 );

for i = 1:NC
  shared_utils.general.progress( i, NC );
  
  c = C(:, i);
  
  rev = revs{c(1)};
  drug_type = drug_types{c(2)};
  epoch = epochs{c(3)};
  is_z = zs(c(4));
  is_prominus_anti = pro_minus_antis(c(5));
  spec = specs{c(6)};
  
  stats__proanti_coh( ...
      'config',             conf ...
    , 'do_save',            true ...
    , 'drug_type',          drug_type ...
    , 'base_subdir',        rev ...
    , 'remove',             rev_types(rev) ...
    , 'epochs',             epoch ...
    , 'is_z',               is_z ...
    , 'is_pro_minus_anti',  is_prominus_anti ...
    , 'specificity',        spec ...
    , 'measure',            'raw_power' ...
  );
  
end

end