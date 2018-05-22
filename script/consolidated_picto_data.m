function save_consolidated_data()

conf = dsp3.config.load();

output_p = dsp3.get_intermediate_dir( 'consolidated' );
filename = 'trial_data.mat';

%%  get raw data from database

db = dsp2.database.get_sqlite_db();

align = db.get_fields( '*', 'align' );
align_field_names = db.get_field_names( 'align' );
signals = db.get_fields( {'file', 'session'}, 'signals' );
all_evt_fields = db.get_field_names( 'events' );
desired_evt_fields = setdiff( all_evt_fields, {'id', 'folder'} );
events = db.get_fields( desired_evt_fields, 'events' );
trial_info = db.get_fields( '*', 'trial_info' );
trial_info_fields = db.get_field_names( 'trial_info' );
meta = db.get_fields( '*', 'meta' );
meta_fields = db.get_field_names( 'meta' );

pl2_full_files = signals(:, 1);
pl2_files = cell( size(pl2_full_files) );

for i = 1:numel(pl2_files)
  [~, pl2] = fileparts( pl2_full_files{i} );
  pl2_files{i} = [ pl2, '.pl2' ];
end

pl2_channel_map = dsp2.process.format.get_pl2_channel_map( db );

unique_pl2s = unique( pl2_files );
pl2_sessions = cell( size(unique_pl2s) );
pl2_start_times = zeros( size(unique_pl2s) );

for i = 1:numel(unique_pl2s)
  ind = strcmp( pl2_files, unique_pl2s{i} );
  unique_sessions = unique( signals(ind, 2) );
  unique_pl2_full_files = unique( pl2_full_files(ind) );
  assert( numel(unique_sessions) == 1 );
  assert( numel(unique_pl2_full_files) == 1 );
  pl2_sessions{i} = unique_sessions{1};
  pl2_start_times(i) = dsp3.get_pl2_start_time_s( unique_pl2_full_files{1} );
end

event_info_key = containers.Map();
for i = 1:numel(desired_evt_fields)
  event_info_key(desired_evt_fields{i}) = i;
end

trial_info_key = containers.Map();
for i = 1:numel(trial_info_fields)
  trial_info_key(trial_info_fields{i}) = i;
end

%%  get trial labels

trial_data_labels = dsp2.process.format.build_labels( trial_info, trial_info_fields, meta, meta_fields );

trial_data_cont = Container( false(shape(trial_data_labels, 1), 1), trial_data_labels );

trial_data_cont = dsp__post_process( trial_data_cont );
trial_data_cont = trial_data_cont.remove_empty_indices();

info_keys = setdiff( trial_info_key.keys(), {'id', 'session', 'folder'} );
info_cols = cellfun( @(x) trial_info_key(x), info_keys );

[I, C] = trial_data_cont.get_indices( 'session_ids' );

reshaped_info = zeros( shape(trial_data_cont, 1), numel(info_cols) );

for i = 1:numel(I)
  matching_info_ind = strcmp( trial_info(:, trial_info_key('session')), C(i, :) );
  assert( sum(matching_info_ind) == sum(I{i}) );
  reshaped_info(I{i}, :) = cell2mat( trial_info(matching_info_ind, info_cols) );
end

trial_data_col_key = containers.Map();
for i = 1:numel(info_keys)
  trial_data_col_key(info_keys{i}) = i;
end

trial_data_cont.data = reshaped_info;

%%  get events
[I, C] = trial_data_cont.get_indices( 'session_ids' );

event_keys = setdiff( event_info_key.keys(), 'session' );
event_cols = cellfun( @(x) event_info_key(x), event_keys );

reshaped_events = zeros( shape(trial_data_cont, 1), numel(event_cols) );

for i = 1:numel(I)
  matching_evt_data_ind = strcmp( events(:, event_info_key('session')), C(i, :) );
  assert( sum(matching_evt_data_ind) == sum(I{i}) );
  reshaped_events(I{i}, :) = cell2mat( events(matching_evt_data_ind, event_cols) );
end

event_info_col_key = containers.Map();
for i = 1:numel(event_keys)
  event_info_col_key(event_keys{i}) = i;
end

event_data_cont = Container( reshaped_events, trial_data_labels );

%%  get alignment

[I, C] = trial_data_cont.get_indices( 'session_ids' );

align_sesh_col_ind = strcmp( align_field_names, 'session' );
plex_col_ind = strcmp( align_field_names, 'plex' );
picto_col_ind = strcmp( align_field_names, 'picto' );
align_sessions = align(:, align_sesh_col_ind);
align_plex = cell2mat( align(:, plex_col_ind) );
align_picto = cell2mat( align(:, picto_col_ind) );

align_cont = Container();

align_key = containers.Map();
align_key('plex') = 1;
align_key('picto') = 2;

for i = 1:size(C, 1)
  matching_id_ind = strcmp( align_sessions, C(i, :) );
  align_data = [ align_plex(matching_id_ind), align_picto(matching_id_ind) ];
  align_cont_this_session = Container( align_data, one(trial_data_cont.labels.keep(I{i})) );
  align_cont = append( align_cont, align_cont_this_session );
end

%%

pl2_days = cell( size(pl2_sessions) );

for i = 1:numel(pl2_sessions)
  days = align_cont.uniques_where( 'days', pl2_sessions{i} );
  assert( numel(days) == 1 );
  pl2_days{i} = days{1};
end

%%

pl2_info = struct();
pl2_info.start_times = pl2_start_times;
pl2_info.files = unique_pl2s;
pl2_info.sessions = pl2_sessions;
pl2_info.days = pl2_days;
pl2_info.channel_map = pl2_channel_map;

%%  store intermediates

all_trial_data = struct();
all_trial_data.align = align_cont;
all_trial_data.align_key = align_key;
all_trial_data.trial_data = trial_data_cont;
all_trial_data.trial_key = trial_data_col_key;
all_trial_data.events = event_data_cont;
all_trial_data.event_key = event_info_col_key;

all_trial_data.pl2_info = pl2_info;

shared_utils.io.require_dir( output_p );
save( fullfile(output_p, filename), 'all_trial_data' );
