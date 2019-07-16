function [rs_ps, rs_labels] = ranksum_baseline_target(targ, base, rs_each, mask_inputs)

assert_ispair( targ );
assert_ispair( base );

targ_rate = targ.data;
targ_labels = targ.labels';

base_rate = base.data;
base_labels = base.labels';

combined_rates = [ targ_rate; base_rate ];
base_labels = addsetcat( base_labels', 'epoch', 'baseline' );
targ_labels = addsetcat( targ_labels', 'epoch', 'target' );
combined_labels = [ targ_labels'; base_labels ];

rs_mask = fcat.mask( combined_labels, mask_inputs{:} );

sr_outs = dsp3.ranksum( combined_rates, combined_labels', rs_each, 'baseline', 'target' ...
  , 'mask', rs_mask ...
);

rs_ps = cellfun( @(x) x.p, sr_outs.rs_tables );
rs_labels = sr_outs.rs_labels';

end