conf = dsp3.config.load();

shared = dsp3.get_consolidated_data();

trial_data = shared.trial_data;
trial_key = shared.trial_key;

save_p = fullfile( conf.PATHS.data_root, 'public', 'wang_collab' );

%%

subset_data = only( trial_data, {'saline', 'oxytocin'} );

keep_fields = { 'administration', 'blocks', 'contexts', 'days', 'drugs' ...
  , 'magnitudes', 'monkeys', 'outcomes', 'sessions', 'trials', 'trialtypes' };

rmfields = setdiff( categories(subset_data), keep_fields );

subset_data = rm_fields( subset_data, rmfields );

orig_monks = subset_data( 'monkeys', : );

subset_data = rm_fields( subset_data, 'monkeys' );
subset_data = add_field( subset_data, 'subjects', orig_monks );

labs = full( subset_data.labels );

all_data = labs.labels;
all_fields = labs.fields;

N = numel( all_fields );

%%

all_look_data = subset_data.data;

look_types = { 'GazeQuantity', 'LookCount' };
looks_to = { '', 'Bottle' };

C = allcomb( {look_types, looks_to} );

for i = 1:size(C, 1)
  
  look_type = C{i, 1};
  look_to = C{i, 2};
  
  read_key = sprintf( 'late%s%s', look_to, look_type );
  
  %   fix mislabeled bottle vs. monk
  if ( strcmp(look_to, 'Bottle') )
    save_key = sprintf( 'subject_%s', look_type );
  else
    save_key = sprintf( 'bottle_%s', look_type );
  end
  
  col = trial_key(read_key);
  
  look_data = all_look_data(:, col);
  
  all_fields{N+i} = save_key;
  all_data(:, N+i) = arrayfun( @(x) {x}, look_data );
    
end

%%

fname = 'consolidated.mat';

shared = struct();
shared.data = all_data;
shared.key = all_fields;

shared_utils.io.require_dir( save_p );

save( fullfile(save_p, fname), 'shared' );


