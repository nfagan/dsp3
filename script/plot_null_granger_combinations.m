conf = dsp3.config.load();

drug_type = 'old';
epoch = 'targacq';

kept = dsp3_get_granger( 'drug_type', drug_type, 'config', conf, 'epoch', epoch );

%%

permonks = [true, false];
proantis = [true, false];

c = combvec( 1:numel(permonks), 1:numel(proantis) );

for i = 1:size(c, 2)
  
  is_permonk = permonks( c(1, i) );
  is_proanti = proantis( c(2, i) );

  plot_null_granger( kept ...
    , 'drug_type',  drug_type ...
    , 'is_permonk', is_permonk ...
    , 'is_proanti', is_proanti ...
    , 'config',     conf ...
  );

end

%%