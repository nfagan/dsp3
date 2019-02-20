consolidated = dsp3.get_consolidated_data();

%%

labels = fcat.from( consolidated.trial_data.labels );

prune( keep(labels, findnone(labels, dsp3.bad_days_revB())) );

days_monks = combs( labels, {'days', 'monkeys'} )';