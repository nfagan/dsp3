conf = dsp3.set_dataroot( '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3' );

look_outs = dsp3_identify_first_iti_look_target( ...
    'config', conf ...
  , 'require_fixation', false ...
  , 'min_fixation_length_secs', 0.01 ...
  , 'look_back', -3.3 ...
);

%%

labels = look_outs.labels';

mask = fcat.mask( labels ...
  , @find, 'choice' ...
  , @findnone, 'errors' ...
  , @find, 'hitch' ...
);

[props, prop_labels] = proportions_of( labels, {'days', 'outcomes', 'trialtypes'}, {'looks_to'}, mask );
prune( count_labels );

pl = plotlabeled.make_common();

axs = pl.bar( props, prop_labels, 'looks_to', 'duration', {'outcomes', 'trialtypes', 'monkeys'} );

%%

look_outs = dsp3_find_iti_looks( ...
    'config', conf ...
  , 'require_fixation', false ...
  , 'look_back', -3.3 ...
);

%%

labels = dsp3_add_iti_first_look_labels( look_outs.labels', look_outs, 0.15 );

mask = fcat.mask( labels ...
  , @find, 'choice' ...
  , @findnone, 'errors' ...
);

[props, prop_labels] = proportions_of( labels, {'days', 'outcomes', 'trialtypes'}, {'looks_to', 'duration'}, mask );
prune( prop_labels );

pl = plotlabeled.make_common();

plt_mask = fcat.mask( prop_labels ...
  , @findnone, 'no_look' ...
);

axs = pl.bar( props(plt_mask), prop_labels(plt_mask), 'looks_to', 'duration', {'outcomes', 'trialtypes'} );