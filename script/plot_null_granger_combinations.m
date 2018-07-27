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


permonks = [false];
proantis = [true];
use_threshold = [true, false];

c = dsp3.ncombvec( numel(permonks), numel(proantis), numel(use_threshold) );

for i = 1:size(c, 2)
  
  is_permonk = permonks( c(1, i) );
  is_proanti = proantis( c(2, i) );
  use_thresh = use_threshold( c(3, i) );
  
  plt = ternary( use_thresh, thresholded, kept );
  base_prefix = ternary( use_thresh, 'thresholded', 'non_thresholded' );
  base_subdir = choice_kind;

  plot_null_granger( plt ...
    , 'config',     conf ...
    , 'lims',       [-0.04, 0.04] ...
    , 'base_subdir', base_subdir ...
    , 'base_prefix', base_prefix ...
    , 'drug_type',  drug_type ...
    , 'is_permonk', is_permonk ...
    , 'is_proanti', is_proanti ...
  );

end

%%