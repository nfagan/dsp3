function run_null_granger_over_time(varargin)

defaults = struct();
defaults.date_dir = dsp2.process.format.get_date_dir();
defaults.days_stop = [];
defaults.days_start = 1;

run_params = dsp2.util.general.parsestruct( defaults, varargin );

days_start = run_params.days_start;
days_stop = run_params.days_stop;

%%  RUN_NULL_GRANGER -- initialize, setup paths, etc.

import dsp2.util.cluster.tmp_write;

IS_DRUG = false;
KEEP_FIRST_350 = true;
IS_REPLICATION = false;

rep_postfix = ternary( IS_REPLICATION, '_repl', '' );
first_postfix = ternary( KEEP_FIRST_350, '_350', '' );
subdir_postfix = sprintf( '%s%s', rep_postfix, first_postfix );

dsp2.cluster.init();
conf = dsp2.config.load();
%   setup mvgc toolbox
run( fullfile(conf.PATHS.repositories, 'mvgc_v1.0', 'startup.m') );
%   get signals
io = dsp2.io.get_dsp_h5();
epoch = 'targacq';
tmp_fname = sprintf( 'null_granger_%s.txt', epoch );
tmp_write( '-clear', tmp_fname );
P = io.fullfile( 'Signals/none/complete', epoch );
%   set up save paths
date_dir = run_params.date_dir;
%   new
date_dir = sprintf( '%s%s', date_dir, subdir_postfix );

if ( IS_DRUG )
  save_path = fullfile( conf.PATHS.analyses, 'granger', date_dir, 'drug_effect_null', epoch );
else
  save_path = fullfile( conf.PATHS.analyses, 'granger', date_dir, 'non_drug_null', epoch );
end
dsp2.util.general.require_dir( save_path );
%   determine which files have already been processed
granger_fname = 'granger_segment_';
current_files = dsp2.util.general.dirnames( save_path, '.mat' );
current_days = cellfun( @(x) x(numel(granger_fname)+1:end-4), current_files, 'un', false );
all_days = io.get_days( P );
all_days = setdiff( all_days, current_days );

if ( isempty(days_stop) )
  days_stop = numel( all_days );
else
  assert( days_stop <= numel(all_days), 'Day index (%d) is out of bounds (%d)' ...
    , days_stop, numel(all_days) );
end

all_days = all_days(days_start:days_stop);

%   load all at once for cluster, vs. load one at a time on local
if ( conf.CLUSTER.use_cluster )
  all_days = { all_days };
end

[~, date_sorted] = sort( datenum(cellfun( @(x) x(numel('day__')+1:end), all_days, 'un', 0 ), 'mmddyyyy') );
all_days = all_days(date_sorted);

% all_days = { 'day__05232017' };

%% -- Main routine, for each group of days

for ii = 1:numel(all_days)

  %   load as necessary
  tmp_write( {'Loading %s ... ', epoch}, tmp_fname );
  signals = io.read( P, 'only', all_days{ii} );
  signals = dsp2.process.format.fix_block_number( signals );
  signals = dsp2.process.format.fix_administration( signals );
  if ( ~IS_DRUG && ~IS_REPLICATION )
    [injection, rest] = signals.pop( 'unspecified' );
    if ( ~isempty(injection) )
      if ( KEEP_FIRST_350 )
        injection = injection.parfor_each( 'days', @dsp2.process.format.keep_350, 350 );
      end
      signals = append( injection, rest );
    end
    signals = dsp2.process.manipulations.non_drug_effect( signals );
    signals = signals.collapse( {'drugs', 'administration'} );
  elseif ( IS_REPLICATION )
    signals = signals.collapse( {'drugs', 'administration'} );
  end
  tmp_write( 'Done\n', tmp_fname );

  %%  preprocess signals

  tmp_write( 'Preprocessing signals ... ', tmp_fname );

  if ( strcmp(epoch, 'targacq') )
    signals_ = signals.rm( 'cued' );
  else
    signals_ = signals;
  end

  signals_ = update_min( update_max(signals_) );
  signals_ = dsp2.process.reference.reference_subtract_within_day( signals_ );
  signals_ = signals_.filter();
  signals_ = signals_.rm( 'errors' );
  
  params.days = signals_( 'days' );
  params.n_perms = 100;
  params.n_perms_in_granger = 1;
  params.n_trials = Inf;
  params.max_lags = 5e3;
  params.dist_type = 'ev';
  params.estimate_model_order = false;
  params.fs_divisor = 2;
  params.is_drug = IS_DRUG;
  params.kept_350 = KEPT_FIRST_350;
  params.is_replication = IS_REPLICATION;
  params.time = ''
  
  signals_ = signals_.require_fields( {'context', 'iteration'} );
  signals_( 'context', signals_.where({'self', 'both'}) ) = 'context__selfboth';
  signals_( 'context', signals_.where({'other', 'none'}) ) = 'context__othernone';
  
  for i = 1:numel(time_rois)
    
    time_roi_signals = signals_;
    time_roi_signals.data = time_roi_signals.data(:, time_rois{i});
    
    detrend_func = @dsp2.process.reference.detrend_data;

    time_roi_signals = time_roi_signals.for_each_nd( {'channels', 'days'}, detrend_func );
    
    one_roi = run_one_granger( time_roi_signals, params );
  end

end

end

function all_data = run_one_granger(signals_, params)

days = params.days;
n_perms = params.n_perms;
n_perms_in_granger = params.n_perms_in_granger;
n_trials = params.n_trials;
max_lags = params.max_lags;
estimate_model_order = params.estimate_model_order;
fs_divisor = params.fs_divisor;
dist_type = params.dist_type;

%   shuffle_within = { 'context', 'trialtypes' };
shuffle_within = { 'context', 'trialtypes', 'drugs', 'administration' };

all_data = Container();

for i = 1:numel(days)

  tmp_write( {'Processing %s (%d of %d)\n', days{i}, i, numel(days)}, tmp_fname );

  one_day = signals_.only( days{i} );
  cmbs = one_day.pcombs( shuffle_within );
  conts = cell( size(cmbs, 1), 1 );

  try
    for j = 1:size(cmbs, 1)
      iters = cell( 1, n_perms+1 );
      parfor k = 1:n_perms+1
        warning( 'off', 'all' );
        ctx = one_day.only( cmbs(j, :) );
        chans = ctx.labels.flat_uniques( 'channels' );
        n_trials_this_context = sum( ctx.where(chans{1}) );
        if ( k < n_perms+1 )
          ind = randperm( n_trials_this_context );
        else
          %   don't permute the last subset
          ind = 1:n_trials_this_context;
        end
        %   shuffle
        shuff_func = @(x) n_dimension_op(x, @(y) y(ind, :));
        ctx = ctx.for_each( {'days', 'channels', 'regions'}, shuff_func );
        outs = ctx.labels.flat_uniques( 'outcomes' );
        out_cont = Container();
        for h = 1:numel(outs)
          G = dsp2.analysis.playground.run_granger( ...
            ctx.only(outs{h}), 'bla', 'acc', n_trials, n_perms_in_granger ...
            , 'dist', dist_type ...
            , 'max_lags', max_lags ...
            , 'do_permute', false ...
            , 'estimate_model_order', estimate_model_order ...
            , 'fs_divisor', fs_divisor ...
          );
          G.labels = G.labels.set_field( 'iteration', sprintf('iteration__%d', k) );
          out_cont = out_cont.append( G );
        end
        out_cont = out_cont.require_fields( 'permuted' );
        if ( k < n_perms+1 )
          out_cont( 'permuted' ) = 'permuted__true';
        else
          out_cont( 'permuted' ) = 'permuted__false';
        end
        iters{k} = out_cont;
      end
      conts{j} = extend( iters{:} );
    end
  catch err
    tmp_write( {'Error on %s\n:%s\n', days{i}, err.message}, tmp_fname );
    continue;
  end

  warning( 'on', 'all' );

  conts = extend( conts{:} );
  conts = dsp2.analysis.granger.convert_null_granger( conts );
  
  all_data = append( all_data, conts );
end

end

function c = ternary(cond, a, b)
if ( cond )
  c = a;
else
  c = b;
end
end
