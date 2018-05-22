conf = dsp3.config.load();

meas = 'coherence';
epochs = { 'targacq', 'targon', 'reward' };
manips = { 'pro_v_anti' };
clpses = { {'trials', 'monkeys'} };
is_new_data_sets = { false, true };
is_within_sites = { true };
use_post_only_drugs = { false };
kind = 'nanmedian_2';

C = allcomb( {epochs, clpses, manips, is_new_data_sets ...
  , is_within_sites, use_post_only_drugs} );

F = figure(1);

for idx = 1:size(C, 1)

fprintf( '\n\t %d of %d', idx, size(C, 1) );
  
epoch = C{idx, 1};
clpse = C{idx, 2};
manip = C{idx, 3};
is_new_data_set = C{idx, 4};
is_within_site = C{idx, 5};
use_post_only_drug = C{idx, 6};

coh = dsp2.io.get_processed_measure( {meas, epoch, manip, clpse}, kind );

if ( is_new_data_set )
	coh = coh.rm( {'day__05172016', 'day__05192016' 'day__02142017'} );
end

if ( use_post_only_drug && ~isempty(strfind(manip, 'drug')) )
  coh = coh({'post'});
end

if ( isempty(coh) ), continue; end

m_within = {'days', 'outcomes', 'administration', 'trialtypes'};

if ( is_within_site )
  m_within = union( m_within, {'sites', 'regions', 'channels'} );
end

meaned = coh.each1d( m_within, @rowops.nanmean );

date_dir = dsp2.process.format.get_date_dir();

if ( is_within_site )
  site_dir = 'within_site';
else
  site_dir = 'within_day';
end

if ( is_new_data_set )
  data_dir = 'new_data_set';
else
  data_dir = 'old_data_set';
end

save_p = fullfile( conf.PATHS.data_root, 'plots', 'gamma_beta_corr' ...
  , date_dir, data_dir, site_dir, manip );
shared_utils.io.require_dir( save_p );

%%%  ratio

if ( strcmp(epoch, 'reward') )
  time_roi = [ 50, 250 ];
elseif ( strcmp(epoch, 'targacq') )
  time_roi = [ -200, 0 ];
elseif ( strcmp(epoch, 'targon') )
  time_roi = [ 0, 200 ];
else
  error( 'Unrecognized epoch ''%s''.', epoch );
end

freq_rois = { [15, 30], [45, 60] };
band_names = { 'beta', 'gamma' };

freq_meaned = Container();

for i = 1:numel(freq_rois)
  freq_meaned_one = meaned.time_freq_mean( time_roi, freq_rois{i} );
  freq_meaned_one = freq_meaned_one.require_fields( 'bands' );
  freq_meaned_one( 'bands' ) = band_names{i};
  freq_meaned = freq_meaned.append( freq_meaned_one );
end

gamma = freq_meaned({'gamma'});
beta = freq_meaned({'beta'});

plots_are = { 'trialtypes', 'drugs' };
panels_are = { 'outcomes', 'trialtypes', 'epochs', 'administration' };

[plot_indices, plot_cmbs] = gamma.get_indices( plots_are );

for j = 1:numel(plot_indices)
  
  plot_subset_gamma = gamma(plot_indices{j});
  plot_subset_beta = beta(plot_cmbs(j, :));
  
  assert( eq_ignoring(plot_subset_gamma.labels, plot_subset_beta.labels, {'bands'}) );

  [panel_indices, panel_cmbs] = plot_subset_gamma.get_indices( panels_are );

  pl = ContainerPlotter();
  pl.default();

  sub_shape = shared_utils.plot.get_subplot_shape( numel(panel_indices) );

  clf( F );

%   xlims = [0.6, 1];
%   ylims = [0.6, 1];
  
  xlims = [];
  ylims = [];

  for i = 1:numel(panel_indices)
    subset_gamma = plot_subset_gamma(panel_indices{i});
    subset_beta = plot_subset_beta(panel_cmbs(i, :));

    gamma_data = subset_gamma.data;
    beta_data = subset_beta.data;

    assert( eq_ignoring(subset_gamma.labels, subset_beta.labels, {'bands'}) );

    ax = subplot( sub_shape(1), sub_shape(2), i );

    scatter( gamma_data, beta_data );

    hold on;

    [r, p] = corr( gamma_data, beta_data );

    if ( isempty(xlims) )
      xlims = get( gca, 'xlim' );
    else
      xlim( ax, xlims );
    end
    if ( isempty(ylims) )
      ylims = get( gca, 'ylim' );
    else
      ylim( ax, ylims );
    end
    
    xlabel( 'Gamma' );
    ylabel( 'Beta' );

    ps = polyfit( gamma_data, beta_data, 1 );
    res = polyval( ps, xlims );

    plot( xlims, res );

    txt = sprintf( 'r = %0.2f, p = %0.2f', r, p );

    text( xlims(2)-((xlims(2)-xlims(1))/4), ylims(2), txt, 'parent', ax );

    title( strjoin(panel_cmbs(i, :), ', ') );
  end

  fname = strjoin( flat_uniques(plot_subset_gamma, {'outcomes', 'epochs', 'trialtypes', 'drugs'}), '_' );
  full_fname = fullfile( save_p, fname );
  save_in_subdirs = true;
  shared_utils.plot.save_fig( F, full_fname, {'epsc', 'png', 'fig'}, save_in_subdirs );
end

end