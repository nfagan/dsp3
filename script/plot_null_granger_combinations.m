conf = dsp3.config.load();

drug_type = 'nondrug';
epoch = 'targacq';
choice_kind = 'pre_choice';

sd_threshold = 1.5;

kept = dsp3_get_granger( ...
    'drug_type',      drug_type ...
  , 'config',         conf ...
  , 'epoch',          epoch ...
  , 'choice_kind',    choice_kind ...
  , 'use_sd_thresh',  false ...
);

thresholded = dsp2.analysis.granger.granger_sd_threshold( kept, sd_threshold ); 

%%


permonks = [false, true];
proantis = [true];
use_threshold = [true, false];
pro_minus_antis = [true];

c = dsp3.numel_combvec( permonks, proantis, use_threshold, pro_minus_antis );

for i = 1:size(c, 2)
  
  is_permonk = permonks( c(1, i) );
  is_proanti = proantis( c(2, i) );
  use_thresh = use_threshold( c(3, i) );
  is_pro_minus_anti = pro_minus_antis( c(4, i) );
  
  plt = ternary( use_thresh, thresholded, kept );
  base_prefix = ternary( use_thresh, 'thresholded', 'non_thresholded' );
  base_subdir = choice_kind;

  plot_null_granger( plt ...
    , 'config',     conf ...
    , 'lims',       [-0.06, 0.06] ...
    , 'base_subdir', base_subdir ...
    , 'base_prefix', base_prefix ...
    , 'drug_type',  drug_type ...
    , 'is_permonk', is_permonk ...
    , 'is_proanti', is_proanti ...
    , 'is_pro_minus_anti', is_pro_minus_anti ...
  );

end

%%