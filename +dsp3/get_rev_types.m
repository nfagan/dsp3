function rev_types = get_rev_types()

rev_types = containers.Map();

rev_types('revA') = dsp3.bad_days_revA();
rev_types('revB') = dsp3.bad_days_revB();
rev_types('orig') = dsp2.process.format.get_bad_days();
rev_types('full') = {};


end