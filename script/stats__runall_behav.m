%%

drug_type = 'nondrug';
per_magnitude = true;
do_save = true;

inputs = { 'drug_type', drug_type, 'per_magnitude', per_magnitude, 'do_save', do_save };

%%  p correct

stats__percent_correct( inputs{:} );

%%  rt

stats__rt( inputs{:} );

%%  gaze

stats__gaze( inputs{:} );

%%  preference

stats__pref( inputs{:} );

