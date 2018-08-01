to_rem = dsp2.process.format.get_bad_days();
rev = 'full';

revs = { 'orig', 'full', 'revA', 'revB' };
days = { dsp2.process.format.get_bad_days() ...
  , {}, dsp3.bad_days_revA(), dsp3.bad_days_revB() };

assert( numel(revs) == numel(days) );

for i = 1:numel(days)

  stats__proanti_coh('do_save',true, 'drug_type', 'drug_wbd' ...
    , 'smooth_func', @(x) smooth(x, 5) ...
    , 'remove', days{i}, 'base_subdir', revs{i}, 'base_prefix', 'smoothed' );
end