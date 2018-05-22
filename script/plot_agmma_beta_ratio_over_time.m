import shared_utils.container.cat_parse_double;

F = figure(1);

io = dsp2.io.get_dsp_h5();

conf = dsp3.config.load();
conf2 = dsp2.config.load();

epoch = 'targacq';
is_drug = true;
is_within_site = false;

m_within = conf2.SIGNALS.meaned.mean_within;

if ( ~is_within_site )
  m_within = setdiff( m_within, {'sites'} );
end

P = dsp2.io.get_path( 'measures', 'coherence', 'nanmedian', epoch );
save_p = fullfile( conf.PATHS.data_root, 'plots', 'gamma_beta_ratio_over_time' ...
  , dsp3.get_datestr() );

coh = io.read( P );

coh = coh.rm( 'errors' );

if ( strcmp(epoch, 'targacq') )
  coh = coh.rm( 'cued' );
end

if ( is_drug )
  coh = coh.rm( 'unspecified' );
end

coh = dsp2.process.format.fix_channels( coh );
coh = dsp2.process.format.only_pairs( coh );
coh = dsp2.process.format.fix_block_number( coh );
coh = dsp2.process.format.fix_administration( coh );
coh = dsp2.process.format.rm_bad_days( coh );

%%

summarized = coh.each1d( m_within, @rowops.nanmedian );

%%

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
  freq_meaned_one = summarized.time_freq_mean( time_roi, freq_rois{i} );
  freq_meaned_one = freq_meaned_one.require_fields( 'bands' );
  freq_meaned_one( 'bands' ) = band_names{i};
  freq_meaned = freq_meaned.append( freq_meaned_one );
end

ratio = freq_meaned.only( 'gamma' ) ./ freq_meaned.only( 'beta' );

% ratio.data = 10 .* log10( ratio.data );

max_block_pre = max( cat_parse_double('block__', ratio.uniques_where('blocks', 'pre')) );
min_block_post = min( cat_parse_double('block__', ratio.uniques_where('blocks', 'post')) );

[I, C] = ratio.get_indices( 'days' );

blocks = ratio('blocks', :);

for i = 1:numel(I)
  c_post_ind = I{i} & ratio.where( 'post' );
  c_blocks = blocks( c_post_ind );
  nums = cat_parse_double( 'block__', c_blocks );
  nums = nums + max_block_pre;
  block_str = arrayfun( @(x) sprintf('block__%d', x), nums, 'un', false );
  blocks( c_post_ind ) = block_str;
end

ratio('blocks') = blocks;

% remove blocks that don't have all 4 outcomes
[I, C] = ratio.get_indices( {'days', 'blocks', 'sessions'} );

search_for = ratio.pcombs( 'outcomes' );
to_exclude = ratio.logic( false );

for i = 1:numel(I)
  subset = ratio.labels.keep(I{i});
  for j = 1:size(search_for, 1)
    if ( ~any(subset.where(search_for(j, :))) )
      to_exclude(I{i}) = true;
      break;
    end
  end
end

ratio(to_exclude) = [];

ratio = ratio.collapse( {'magnitudes'} );

% ratio = dsp2.process.manipulations.pro_v_anti( ratio );

%%

is_log_scale = true;
do_save = true;

F = figure(1);

block_labs = ratio('blocks');

panels_are = { 'epochs', 'bands', 'trialtypes', 'outcomes' };

[~, block_sort_ind] = sort( cat_parse_double('block__', block_labs) );

post_ind = find( strcmp(block_labs, sprintf('block__%d', max_block_pre + min_block_post)) );

clf( F );

pl = ContainerPlotter();
pl.order_by = block_labs(block_sort_ind);
pl.vertical_lines_at = post_ind - 0.5;

axs = pl.plot_by( ratio, 'blocks', {'drugs'}, panels_are );

if ( is_log_scale )
  set( axs, 'yscale', 'log' );
end

filename = strjoin( flat_uniques(ratio, union(panels_are, 'drugs')), '_' );

separate_folders = true;

if ( do_save )
  shared_utils.io.require_dir( save_p );
  shared_utils.plot.save_fig( F, fullfile(save_p, filename), {'epsc', 'png', 'fig'}, separate_folders );
end

%%  plot time series

t_series_each = setdiff( m_within, {'blocks', 'sessions'} );
search_for = ratio.pcombs( 'blocks' );
[~, sorted_ind] = sort( cat_parse_double('block__', search_for) );
search_for = search_for( sorted_ind );

[I, C] = ratio.get_indices( t_series_each );

time_course = Container();

for i = 1:numel(I);
  subset = ratio(I{i});
  blocks = subset('blocks');
  
  t_course_data = nan( 1, numel(search_for) );
  
  for j = 1:numel(blocks)
    subset_block = subset(blocks(j));
    
    assert( shape(subset_block, 1) == 1 );
    
    block_ind = strcmp( search_for, blocks{j} );
    
    t_course_data(block_ind) = subset_block.data;
  end
  
  time_course = append( time_course, set_data(one(subset), t_course_data) );
end

%%

pl = ContainerPlotter();
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;
pl.add_ribbon = true;
pl.x_lim = [0, 9];

axs = pl.plot( time_course, {'drugs'}, panels_are );

if ( is_log_scale )
  set( axs, 'yscale', 'log' );
end

filename = strjoin( flat_uniques(ratio, union(panels_are, 'drugs')), '_' );

filename = sprintf( 'connected_lines_%s', filename );

separate_folders = true;

if ( do_save )
  shared_utils.io.require_dir( save_p );
  shared_utils.plot.save_fig( gcf, fullfile(save_p, filename), {'epsc', 'png', 'fig'}, separate_folders );
end





