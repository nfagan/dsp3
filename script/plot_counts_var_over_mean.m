conf = dsp3.config.load();

spike_p = dsp3.get_intermediate_dir( 'per_trial_psth' );

spike_mats = dsp3.require_intermediate_mats( [], spike_p, [] );

full_psth = cell( 1, numel(spike_mats) );

meas_type = 'psth';
do_normalize = true;
baseline_epoch = 'cueOn';
norm_level = 'context';

norm_str = 'non_normalized';

if ( do_normalize )
  assert( strcmp(meas_type, 'psth') );
  norm_str = 'normalized';
end

thresh = 10;

n_trials_per_unit = Container();

for i = 1:numel(spike_mats)
  fprintf( '\n %d of %d', i, numel(spike_mats) );
  
  spikes = shared_utils.io.fload( spike_mats{i} );
  
  spike_info = spikes.psths;
  epochs = setdiff( spike_info.keys(), baseline_epoch );
  
  sub_psth = Container();
  
  got_baseline = false;
  
  for j = 1:numel(epochs)
    one_epoch_spike_info = spike_info(epochs{j});
    measure = one_epoch_spike_info.(meas_type);
    measure = measure.require_fields( 'epochs' );
    measure('epochs') = epochs{j};
    
    raster = one_epoch_spike_info.raster;
    
    [I, C] = raster.get_indices( {'unit_uuid', 'outcomes', 'trialtypes'} );
    
    keep_units = measure.logic( true );
    
    for k = 1:numel(I)
      subset_unit = raster(I{k});
      cts = any( subset_unit.data, 2 );
      
      if ( sum(cts) < thresh )
        keep_units(I{k}) = false;
      end
      
      n_trials_per_unit = append( n_trials_per_unit, set_data(one(subset_unit) ...
        , [sum(cts), size(cts, 1)]) );
    end
    
    if ( do_normalize && ~got_baseline )
      baseline = spike_info(baseline_epoch);
      baseline = baseline.(meas_type);
      baseline = baseline.require_fields( 'epochs' );
      baseline('epochs') = baseline_epoch;
      baseline_data = mean( baseline.data, 2 );
      got_baseline = true;
    end
    
    if ( do_normalize && strcmp(norm_level, 'trial') )
      meas_data = measure.data;
      for k = 1:size(meas_data, 2)
        meas_data(:, k) = meas_data(:, k) - baseline_data;
      end
      measure.data = meas_data;
    elseif ( do_normalize && strcmp(norm_level, 'context') )
      [I, C] = baseline.get_indices( {'unit_uuid', 'contexts', 'trialtypes'} );
      meas_data = measure.data;
      for k = 1:numel(I)
        subset_one_context = mean( baseline_data(I{k}) );
        meas_data(I{k}, :) = meas_data(I{k}, :) ./ subset_one_context;
      end
      norm_str = 'norm_per_context';
    elseif ( do_normalize )
      error( 'Unrecognized norm_level "%s".', norm_level );
    end
    
    measure = measure.keep( keep_units );
    
    sub_psth = append( sub_psth, measure );
    
    psth_t = one_epoch_spike_info.psth_t;
  end
  
  full_psth{i} = sub_psth;
end

ind = cellfun( @isempty, full_psth );
full_psth = full_psth( ~ind );

full_psth = Container.concat( full_psth );

%%

thresh = 10;

[I, C] = n_trials_per_unit.get_indices( {'unit_uuid', 'trialtypes', 'outcomes', 'epochs'} );

all_i = full_psth.logic( true );

for i = 1:numel(I)
  fprintf( '\n %d of %d', i, numel(I) );
  
  n_trials = n_trials_per_unit(I{i});
  
  assert( shape(n_trials, 1) == 1 );
  
  actual_n_trials = n_trials.data(1);
  
  matching_i = full_psth.where( C(i, :) );
  
  if ( actual_n_trials < thresh )
    all_i(matching_i) = false;
  end
end

%%  post minus pre trace

summary_ts = { 'mean', 'var_over_mean' };

inds = dsp3.allcombn( {1:numel(summary_ts)} );

f = figure(1);

save_p = fullfile( conf.PATHS.data_root, 'plots', 'psth', datestr(now, 'mmddyy') );

for ii = 1:size(inds, 1)
  
  summary_t = summary_ts{inds{ii, 1}};

  subset_psth = full_psth({'targAcq', 'acc'});
  subset_psth = subset_psth.rm( {'errors', 'unspecified', 'unit_rating__0'} );
  
  subset_psth = subset_psth.add_field( 'summary_t', summary_t );

  [I, C] = subset_psth.get_indices( {'unit_uuid'} );

  mean_each = { 'outcomes', 'administration' };
  ignore_each = { 'blocks', 'sessions', 'administration' };

  if ( strcmp(summary_t, 'var_over_mean') )
    summary_func = @(x, y) nanvar(x, [], 1) ./ nanmean(x, 1);
  elseif ( strcmp(summary_t, 'mean_over_var') )
    summary_func = @(x, y) nanmean(x, 1) / nanvar(x, [], 1);
  elseif ( strcmp(summary_t, 'cv') )
    summary_func = @(x, y) nanstd(x, [], 1) / nanmean(x, 1);
  elseif ( strcmp(summary_t, 'snr') )
    summary_func = @(x, y) nanmean(x, 1) / nanstd(x, [], 1);
  else
    assert( strcmp(summary_t, 'mean'), 'Unrecognized summary t "%s".', summary_t );
    summary_func = @(x, y) rowops.nanmean(x);
  end
  
  [I, C] = subset_psth.get_indices( 'unit_uuid' );
  keep_all = subset_psth.logic( true );
  
  for i = 1:numel(I)
    one_unit = subset_psth(I{i});
    keep_all(I{i}) = all( one_unit.contains({'pre', 'post'}) );
  end
  
  subset_psth = subset_psth(keep_all);
  
%   meaned = subset_psth.each1d( {'outcomes', 'administration', 'unit_uuid'}, @rowops.nanmean );
  
  post_pre = subset_psth.collapse( 'unit_uuid' );
  
%   post_pre = collapse(meaned({'post'}), ignore_each) - collapse(meaned({'pre'}), ignore_each);
%   post_pre('administration') = 'postMinusPre';
  
  figs_each = { 'unit_uuid' };
  panels_are = { 'unit_uuid', 'drugs' };
  lines_are = { 'administration' };
  fnames_are = unique( [figs_each, panels_are, lines_are] );
  
  [I, C] = post_pre.get_indices( figs_each );
  
  for i = 1:numel(I)
    one_unit = post_pre(I{i});
    
    pl = ContainerPlotter();
    pl.x = psth_t;
    pl.y_lim = [0, 8];
    pl.vertical_lines_at = 0;
    pl.add_ribbon = true;
    pl.main_line_width = 1;
    pl.add_smoothing = true;
    pl.summary_function = summary_func;
    pl.y_label = summary_t;
    pl.x_label = sprintf( 'Time (s) from %s', strjoin(one_unit('epochs'), '_') );
    pl.smooth_function = @(x) smooth(x, 7);
    
    clf( f );
    
    pl.plot( one_unit, lines_are, panels_are );
    
    fname = strjoin( flat_uniques(one_unit, fnames_are), '_' );
    full_savep = fullfile( save_p, summary_t );
    
    shared_utils.io.require_dir( full_savep );
    
    shared_utils.plot.save_fig( f, fullfile(full_savep, fname), {'epsc', 'png', 'fig'}, true );
  end
  
end

%%

% t_starts = { [-0.1, 0.1], [-0.25, 0], [0, 0.15] };
% t_starts = { [-0.1, 0.1], [-0.25, 0], [0, 0.15] };
t_starts = { [0, 0.15] };

% summary_ts = { 'mean', 'var_over_mean', 'cv', 'snr' };
summary_ts = { 'var_over_mean' };

inds = dsp3.allcombn({1:numel(t_starts), 1:numel(summary_ts)});

for ii = 1:size(inds, 1)
  
t_start = t_starts{inds{ii, 1}};
summary_t = summary_ts{inds{ii, 2}};

t_ind = psth_t >= t_start(1) & psth_t <= t_start(2);
% t_ind = psth_t >= -0.25 & psth_t <= 0;
% t_ind = psth_t >= 0 & psth_t <= 0.15;

subset_t = psth_t(t_ind);
t_label = sprintf( '%d_to_%d', round(subset_t(1)*1e3), round(subset_t(end)*1e3) );

subset_psth = full_psth({'targAcq', 'acc'});
subset_psth = subset_psth.rm( {'errors', 'unspecified', 'unit_rating__0'} );

subset_psth.data = nanmean( subset_psth.data(:, t_ind), 2 );

[I, C] = subset_psth.get_indices( {'unit_uuid'} );

mean_each = { 'outcomes' };
% mean_each = {};
ignore_each = { 'blocks', 'sessions', 'administration' };

pre = Container();
post = Container();

if ( strcmp(summary_t, 'var_over_mean') )
  summary_func = @(x) nanvar(x, [], 1) / nanmean(x, 1);
elseif ( strcmp(summary_t, 'mean_over_var') )
  summary_func = @(x) nanmean(x, 1) / nanvar(x, [], 1);
elseif ( strcmp(summary_t, 'cv') )
  summary_func = @(x) nanstd(x, [], 1) / nanmean(x, 1);
elseif ( strcmp(summary_t, 'snr') )
  summary_func = @(x) nanmean(x, 1) / nanstd(x, [], 1);
else
  assert( strcmp(summary_t, 'mean'), 'Unrecognized summary t "%s".', summary_t );
  summary_func = @rowops.nanmean;
end

for i = 1:numel(I)
  
  subset_unit = subset_psth(I{i});
  
  if ( ~all(subset_unit.contains({'pre', 'post'})) )
    continue;
  end
  
  unit_pre = subset_unit({'pre'});
  unit_post = subset_unit({'post'});
  
  unit_pre = unit_pre.each1d( mean_each, summary_func );
  unit_post = unit_post.each1d( mean_each, summary_func );
  
  assert( shapes_match(unit_pre, unit_post) );
  
  assert( eq_ignoring(unit_pre.labels, unit_post.labels, ignore_each) );
  
  pre = append( pre, unit_pre );
  post = append( post, unit_post );
end

%

save_p = fullfile( conf.PATHS.data_root, 'plots', 'population_scatter', t_label, datestr(now, 'mmddyy') );

shared_utils.io.require_dir( save_p );

assert( eq_ignoring(pre.labels, post.labels, ignore_each) );

figs_are = { 'drugs', 'region' };
panels_are = { 'outcomes' };
titles_are = unique( [figs_are, panels_are] );

[I, C] = pre.get_indices( figs_are );

f = figure(1);

colors = containers.Map();
colors('saline') = 'r';
colors('oxytocin') = 'b';

for idx = 1:numel(I)
  pre_subset = pre(I{idx});
  post_subset = post(I{idx});
  
  [J, C2] = pre_subset.get_indices( panels_are );
  
  assert( eq_ignoring(pre_subset.labels, post_subset.labels, ignore_each) );
  
  clf( f );
  
  sh = shared_utils.plot.get_subplot_shape( numel(J) );
  
  axs = gobjects( 1, numel(J) );
  
  for jdx = 1:numel(J)
    pre_one_panel = pre_subset(J{jdx});
    post_one_panel = post_subset(J{jdx});
    
    color_str = sprintf( '%so', colors(C{idx, 1}) );
    
    pre_data = pre_one_panel.data;
    post_data = post_one_panel.data;
    
    axs(jdx) = subplot( sh(1), sh(2), jdx );
    plot( pre_one_panel.data, post_one_panel.data, color_str, 'markersize', 3 );
    
    axis( 'square' );
    
    title_labs = strjoin( flat_uniques(pre_one_panel, titles_are), ' | ' );
    
    title( title_labs );    
  end
  
  ylims = cell2mat( arrayfun(@(x) get(x, 'ylim'), axs, 'un', false)' );
  xlims = cell2mat( arrayfun(@(x) get(x, 'xlim'), axs, 'un', false)' );
  combined = [ ylims; xlims ];
  lims = [ min(combined(:, 1)), max(combined(:, 2)) ];
  
  set( axs, 'nextplot', 'add' );
  
  for j = 1:numel(axs)
    plot( axs(j), lims, lims, 'k--' );
  end
  
%   lims = [0, 12];
  
  set( axs, 'ylim', lims );
  set( axs, 'xlim', lims );
  
  if ( strcmp(summary_t, 'var_over_mean') )
    meas_label = strrep( summary_t, '_', ' ' );
  elseif ( strcmp(summary_t, 'mean_over_var') )
    meas_label = strrep( summary_t, '_', ' ' );
  else
    meas_label = summary_t;
  end
  
  arrayfun( @(x) xlabel(x, sprintf('%s pre', meas_label)), axs );
  arrayfun( @(x) ylabel(x, sprintf('%s post', meas_label)), axs );
  
  filename = strjoin( flat_uniques(pre_subset, titles_are), '_' );
  filename = sprintf( '%s_%s', summary_t, filename );
  filename = sprintf( '%s_%s', meas_type, filename );
  filename = sprintf( '%s_%s', norm_str, filename );
  
  shared_utils.plot.save_fig( f, fullfile(save_p, filename), {'epsc', 'png', 'fig'}, true );
  
end

%  hist

pl = ContainerPlotter();
pl.shape = [4, 2];

f = figure(1);

figs_are = { 'drugs', 'region' };
groups_are = 'administration';
panels_are = { 'outcomes', 'drugs', 'administration' };
titles_are = unique( [figs_are, panels_are] );

combined = append( pre, post );

[I, C] = combined.get_indices( figs_are );

for idx = 1:numel(I)
  subset = combined(I{idx});
  
  clf( f );
  
  axs = pl.hist( subset, 100, [], panels_are );
      
  filename = strjoin( flat_uniques(subset, titles_are), '_' );
  filename = sprintf( '%s_%s', summary_t, filename );
  filename = sprintf( 'hist_%s', filename );
  filename = sprintf( '%s_%s', norm_str, filename );
  
  shared_utils.plot.save_fig( f, fullfile(save_p, filename), {'epsc', 'png', 'fig'}, true );
  
end

%  bar

if ( strcmp(summary_t, 'var_over_mean') )
  meas_label = strrep( summary_t, '_', ' ' );
elseif ( strcmp(summary_t, 'mean_over_var') )
  meas_label = strrep( summary_t, '_', ' ' );
else
  meas_label = summary_t;
end

pl = ContainerPlotter();
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;
pl.shape = [];
% pl.y_lim = [-1, 1];
pl.order_by = { 'pre', 'post' };
% pl.order_by = { 'self', 'both', 'other', 'none' };
pl.y_label = meas_label;

f = figure(1);

figs_are = { 'region' };
% x_is = 'outcomes';
x_is = 'administration';
groups_are = 'drugs';
panels_are = { 'region', 'outcomes' };
titles_are = unique( [figs_are, panels_are] );

to_clpse = { 'blocks', 'sessions' };

% combined = collapse(post, to_clpse) - collapse(pre, to_clpse);
combined = append( post, pre );

[I, C] = combined.get_indices( figs_are );

for idx = 1:numel(I)
  subset = combined(I{idx});
  
  clf( f );
  colormap( 'default' );
  
  axs = pl.bar( subset, x_is, groups_are, panels_are );
   
  filename = strjoin( flat_uniques(subset, titles_are), '_' );
  filename = sprintf( '%s_%s', summary_t, filename );
  filename = sprintf( 'bar_%s', filename );
  filename = sprintf( '%s_%s', norm_str, filename );
  
  f_edits = FigureEdits( f );
  f_edits.one_legend();
  
  shared_utils.plot.save_fig( f, fullfile(save_p, filename), {'epsc', 'png', 'fig'}, true );
  
end


end

%%

x = labeler.from( full_psth.labels );
[y, cats] = categorical( x );

%%

subset_cats = { 'session_ids', 'channel', 'pl2_file' };

ind = cellfun( @(x) find(strcmp(cats, x)), subset_cats );

tic; [I, C] = findall( x, subset_cats ); toc;

tic; [I2, C2] = loc_findall_categorical( y(:, ind) ); toc;




