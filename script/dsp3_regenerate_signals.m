function dsp3_regenerate_signals(event_name, subdir_name, varargin)

narginchk( 2, Inf );

defaults = dsp3.get_common_lfp_defaults();
defaults.time = [];
defaults.per_session = true;

params = dsp3.parsestruct( defaults, varargin );

event_name = validatestring( event_name, {'targAcq', 'targOn', 'cueOn', 'fixOn'}, mfilename, 'event_name' );

dsp2_conf = dsp2.config.load();
dsp3_conf = dsp3.config.load();

dsp2_conf.SIGNALS.EPOCHS.(event_name).win_size = 150;
dsp2_conf = dsp2.config.set.inactivate_epochs( 'all', dsp2_conf );
dsp2_conf = dsp2.config.set.activate_epochs( event_name, dsp2_conf );

if ( ~isempty(params.time) )
  dsp2_conf.SIGNALS.EPOCHS.(event_name).time(1:2) = params.time;
end

db = dsp2.database.get_sqlite_db( 'config', dsp2_conf );
sessions = unique( db.get_fields('session', 'signals') );

if ( ~params.per_session )
  sessions = { sessions };
else
  sessions = get_sessions_by_day( sessions );
end

%%

for idx = 1:numel(sessions)
  shared_utils.general.progress( idx, numel(sessions) );

  dsp2_conf.SIGNALS.handle_missing_trials = 'skip';
  [signals, time_info] = dsp2.io.get_signals( 'config', dsp2_conf, 'single_epoch', true, 'sessions', sessions{idx} );

  %%

  use_signals = signals.(event_name);

  labs = fcat.from( use_signals.labels );

  save_p = fullfile( dsp3.dataroot(dsp3_conf), 'intermediates', 'original_aligned_lfp', subdir_name );
  shared_utils.io.require_dir( save_p );

  switch ( event_name )
    case { 'targAcq', 'cueOn', 'fixOn' } 
      orig_labs = fcat.from( dsp3_load_cc_targacq_labels(dsp3_conf) );
      matched_labs = dsp3_match_cc_targacq_trial_labels( orig_labs, labs' );
    case 'targOn'
      orig_labs = fcat.from( dsp3_load_cc_targon_labels(dsp3_conf) );
      matched_labs = dsp3_match_to_original_cue_labels( orig_labs, labs' );
  %     matched_labs = dsp3_match_to_original_cue_labels( manuscript_cue_labels', test_labs' );
    otherwise
      error( 'Unhandled epoch "%s".', event_name );
  end

  [matched_dat, matched_labs] = dsp3.ref_subtract( use_signals.data, matched_labs );

  use_signals = set_data_and_labels( use_signals, matched_dat, SparseLabels.from_fcat(matched_labs) );
  [day_I, day_C] = findall( matched_labs, 'days' );

  for i = 1:numel(day_I)
    shared_utils.general.progress( i, numel(day_I) );

    log_ind = trueat( matched_labs, day_I{i} );

    subset = use_signals(log_ind);
    subset.data = dsp3.zpfilter( subset.data, params.f1, params.f2, params.sample_rate, params.filter_order );

    if ( params.per_session )
      save_filename = sprintf( 'lfp_%s_%s_%s', day_C{i}, strjoin(sessions{idx}, '_'), event_name );
    else
      save_filename = sprintf( 'lfp_%s_%s.mat', day_C{i}, event_name );
    end
    
    save( fullfile(save_p, save_filename), 'subset' );
  end
end

end

function day_sessions = get_sessions_by_day(sessions)

%%
days = cellfun( @(x) x(3:10), sessions, 'un', 0 );
unique_days = unique( days );
day_sessions = cell( size(unique_days) );

for i = 1:numel(unique_days)
  matches_day = strcmp( days, unique_days{i} );
  day_sessions{i} = sessions(matches_day);
end

end