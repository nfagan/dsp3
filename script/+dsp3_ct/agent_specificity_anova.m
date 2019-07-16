function anova_outs = agent_specificity_anova(targ_data, targ_labels)

assert_ispair( targ_data, targ_labels );

anovas_each = { 'unit_uuid', 'trialtypes', 'region' };
anova_factor = 'outcomes';

mask = fcat.mask( targ_labels ...
  , @findnone, {'post', 'cued', 'errors', 'both'} ...
);

anova_outs = dsp3.anova1( targ_data, targ_labels', anovas_each, anova_factor ...
  , 'mask', mask ...
);

end