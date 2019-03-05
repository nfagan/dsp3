function dsp3_check_contexts()

db_path = fullfile( dsp3.dataroot(), 'database' );
db_name = 'dictator_signals.sqlite';

db = dsp2.database.DictatorSignalsDB( db_path, db_name );

trial_info = db.get_fields( '*', 'trial_info' );
trial_info_fields = db.get_field_names( 'trial_info' );

db.close();

%%

cue_type = cell2mat( trial_info(:, strcmp(trial_info_fields, 'cueType')) );
fixed_on = cell2mat( trial_info(:, strcmp(trial_info_fields, 'fix')) );

is_choice = logical( cell2mat(trial_info(:, strcmp(trial_info_fields, 'trialType'))) );

is_self =  (cue_type == 0 & fixed_on == 1) | (cue_type == 1 & fixed_on == 2);
is_both =  (cue_type == 1 & fixed_on == 1) | (cue_type == 0 & fixed_on == 2);
is_other = (cue_type == 2 & fixed_on == 1) | (cue_type == 3 & fixed_on == 2);
is_none =  (cue_type == 3 & fixed_on == 1) | (cue_type == 2 & fixed_on == 2);
is_errors = ~any( [is_self, is_both, is_other, is_none], 2 );

is_cue_fixation = ~is_choice & fixed_on == 1;

%   define trialtypes

%   define contexts
selfboth_context = (cue_type == 0 | cue_type == 1) & is_choice;
othernone_othernone = (cue_type == 2 | cue_type == 3) & is_choice;

is_cue_self_context = cue_type == 0 & ~is_choice;
is_cue_both_context = cue_type == 1 & ~is_choice;
is_cue_other_context = cue_type == 2 & ~is_choice;
is_cue_none_context = cue_type == 3 & ~is_choice;

end