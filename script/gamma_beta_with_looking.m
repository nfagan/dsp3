conf = dsp3.config.load();

base_plotp = fullfile( conf.PATHS.data_root, 'plots', 'gamma_beta_looking', datestr(now, 'mmddyy') );

drug_type = 'nondrug';

combined = dsp3.get_consolidated_data();

behav = require_fields( combined.trial_data, {'channels', 'regions', 'sites'} );

behav = dsp3.get_subset( behav, drug_type );

behav = dsp2.process.format.rm_bad_days( behav );

behav_key = combined.trial_key;

%%

late_looks_ind = behav_key( 'lateBottleLookCount' );

did_look = behav.data(:, late_looks_ind) > 0;
did_looklabs = fcat.from( behav.labels );

%%

coh_p = dsp3.get_intermediate_dir( 'coherence/targacq' );

C = combs( did_looklabs, 'days' );

time_roi = [ -200, 0 ];
freq_rois = { [15, 30], [45, 60] };
band_names = { 'beta', 'gamma' };

ratios = Container();

for i = 1:size(C, 2)
  fprintf( '\n %d of %d', i, size(C, 2) );
  
  coh_filename = fullfile( coh_p, C{i} );
  
  coh_file = shared_utils.io.fload( [coh_filename, '.mat'] );
  
  coh = coh_file.measure;
  coh = dsp3.get_subset( coh, drug_type, {'days', 'sites', 'channels', 'regions'} );
  
  all_meaned = Container();
  
  for j = 1:numel(band_names)
    meaned = time_freq_mean( coh, time_roi, freq_rois{j} );
    meaned = require_fields( meaned, 'bands' );
    meaned('bands') = band_names{j};
    all_meaned = append( all_meaned, meaned );
  end
  
  non_ratio = all_meaned;
  ratio = all_meaned({'gamma'}) ./ all_meaned({'beta'});
  
  ratios = extend( ratios, ratio, non_ratio );  
end

%%

ratio = ratios.data;
ratiolabs = fcat.from( ratios.labels );

addcat( ratiolabs, 'did_look' );
setcat( ratiolabs, 'did_look', 'did_look_false' );

[I, C] = findall( ratiolabs, {'days', 'sites', 'channels', 'regions', 'bands'} );

num_didlook = find( did_look );

all_didlook = false( rows(ratiolabs), 1 );

for i = 1:numel(I)
  day = C{1, i};
  
  matching_behav = find( did_looklabs, day );
  
  assert( numel(matching_behav) == numel(I{i}) );
  assert( all(diff(matching_behav) == 1) && all(diff(I{i}) == 1) );
  
  all_didlook(I{i}) = did_look(matching_behav);  
end

setcat( ratiolabs, 'did_look', 'did_look_true', find(all_didlook) );


%%  per outcome gamma beta ratio

add_logscale = true;
do_save = false;

[pltlabs, I] = remove( ratiolabs', {'errors', 'cued', 'gamma', 'beta'} );

plt = labeled( ratio(I), pltlabs );

mean_spec = { 'days', 'sites', 'channels', 'outcomes', 'regions', 'bands', 'trialtypes' };

[~, mean_ind] = eachindex( plt, mean_spec, @rownanmean );

x_is = { 'bands' };
groups_are = { 'outcomes' };
panels_are = { 'trialtypes' };

figure(1);
clf();

pl = plotlabeled();
pl.one_legend = true;
pl.error_func = @plotlabeled.nansem;
pl.group_order = { 'self', 'both', 'other', 'none' };
pl.y_lims = [ 0.95, 0.98 ];
pl.x_tick_rotation = 0;

axs = pl.bar( plt, x_is, groups_are, panels_are );

if ( add_logscale )
  set( axs, 'yscale', 'log' );
end

if ( do_save )
  plot_p = base_plotp;
  shared_utils.io.require_dir( plot_p );
  fname = joincat( prune(getlabels(plt)), {'bands', 'trialtypes', 'outcomes'} );
  shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );
end

%%  pro v. anti gamma vs. betag

[pltlabs, I] = remove( ratiolabs', {'errors', 'cued', 'gamma_rdivide_beta'} );
pltdata = ratio(I);

mean_spec = { 'days', 'sites', 'channels', 'regions', 'trialtypes' };

[y, I] = keepeach( pltlabs', mean_spec );

all_labs = fcat();
all_ratios = [];

for i = 1:numel(I)
  dsp3.progress( i, numel(I) );
  
  outs = { 'self', 'both', 'other', 'none' };
  pairs = { {'self', 'both'}, {'other', 'none'} };
  
  for j = 1:numel(pairs)
    
    gamma1 = pltdata( intersect(I{i}, find(pltlabs, { pairs{j}{1}, 'gamma' })) );
    beta1 = pltdata( intersect(I{i}, find(pltlabs, { pairs{j}{1}, 'beta'})) );
    gamma2 = pltdata( intersect(I{i}, find(pltlabs, { pairs{j}{2}, 'gamma' })) );
    beta2 = pltdata( intersect(I{i}, find(pltlabs, { pairs{j}{2}, 'beta'})) );
    
    c_ratio1 = nanmean( gamma1, 1 ) ./ nanmean( beta1, 1 );
    c_ratio2 = nanmean( gamma2, 1 ) ./ nanmean( beta2, 1 );
    
    setcat( y, 'outcomes', sprintf('%s_minus_%s', pairs{j}{1}, pairs{j}{2}) );
    
    append( all_labs, y(i) );
    all_ratios = [ all_ratios; (c_ratio1 - c_ratio2) ];
  end  
end


%%

x_is = { 'bands' };
groups_are = { 'outcomes' };
panels_are = { 'trialtypes' };

figure(1);
clf();

plt = labeled( all_ratios, all_labs );

pl = plotlabeled();
pl.one_legend = true;
pl.error_func = @plotlabeled.nansem;
pl.group_order = { 'self', 'both', 'other', 'none' };
% pl.y_lims = [ 0.77, 0.84 ];

axs = pl.bar( plt, x_is, groups_are, panels_are );

% set( axs, 'yscale', 'log' );

%%





%%

do_save = true;
add_logscale = false;

[pltlabs, I] = remove( ratiolabs', {'errors', 'cued', 'gamma', 'beta'} );
plt = labeled( ratio(I), pltlabs );

pltlabs = getlabels( plt );
pltdata = plt.data;

[y, I] = keepeach( pltlabs', setdiff(mean_spec, 'outcomes') );

on_diffs = zeros( numel(I), 1 );
sb_diffs = zeros( size(on_diffs) );

for i = 1:numel(I)
  self_ind = intersect( I{i}, find(pltlabs, 'self') );
  both_ind = intersect( I{i}, find(pltlabs, 'both') );
  other_ind = intersect( I{i}, find(pltlabs, 'other') );
  none_ind = intersect( I{i}, find(pltlabs, 'none') );
  
  self_means = nanmean( pltdata(self_ind, :), 1 );
  both_means = nanmean( pltdata(both_ind, :), 1 );
  other_means = nanmean( pltdata(other_ind, :), 1 );
  none_means = nanmean( pltdata(none_ind, :), 1 );
  
  on_diffs(i) = other_means - none_means;
  sb_diffs(i) = self_means - both_means;
end

plt_on = labeled( on_diffs, y );
plt_sb = labeled( sb_diffs, y );

plt_on('outcomes') = 'otherMinusNone';
plt_sb('outcomes') = 'selfMinusBoth';

plt = append( plt_on, plt_sb );

pl = plotlabeled();
pl.fig = figure(2);
pl.one_legend = true;
pl.summary_func = @plotlabeled.nanmean;
pl.error_func = @plotlabeled.nansem;
pl.group_order = { 'self', 'both', 'other', 'none' };

axs = pl.bar( plt, x_is, groups_are, panels_are );

if ( add_logscale )
  set( axs, 'yscale', 'log' );
end

if ( do_save )
  plot_p = base_plotp;
  shared_utils.io.require_dir( plot_p );
  fname = joincat( prune(getlabels(plt)), {'bands', 'trialtypes', 'outcomes'} );
  shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );
end

%%





