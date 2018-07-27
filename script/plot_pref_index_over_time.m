function plot_pref_index_over_time()

import dsp2.process.format.add_trial_bin;
import shared_utils.container.cat_parse_double;

conf = dsp3.config.load();

combined = dsp3.get_consolidated_data();

behav = combined.trial_data;

drug_type = 'drug';

is_drug = true;
is_permonk = false;
do_permute = false;

behav = dsp3.get_subset( behav, drug_type );

% if ( strcmp(drug_type, 'nondrug') )
%   [unspc, tmp_behav] = behav.pop( 'unspecified' );
%   unspc = unspc.for_each( 'days', @dsp2.process.format.keep_350, 350 ); 
%   tmp_behav = append( tmp_behav, unspc );
%   behav = dsp2.process.manipulations.non_drug_effect( tmp_behav );
% elseif ( strcmp(drug_type, 'drug') )
%   behav = behav.rm( 'unspecified' );
% else
%   assert( strcmp(drug_type, 'unspecified'), 'Unrecognized drug type "%s"', drug_type );
%   behav = behav.only( 'unspecified' );
% end

plot_save_p = fullfile( conf.PATHS.data_root, 'plots' );

%%

N = 25;
step_size = 25;
allow_truncated_bin = false;
start_over_at = { 'days', 'administration', 'contexts' };
increment_for = { 'sessions', 'blocks' };

to_bin = behav( {'choice'} );

%   keep only the minimum number of `pre` trials across days
to_count = to_bin({'pre'});
mins_pre = min( get_data(to_count.each1d('days', @(x) size(x, 1))) );
to_count_post = to_bin({'post'});
mins_post = sum( get_data(to_count_post.each1d('days', @(x) double(size(x, 1) < 250))) );

[I, C] = to_bin.get_indices( 'days' );

all_keep = to_bin.logic( false );

for i = 1:numel(I)
  c_ind = I{i} & to_bin.where( 'pre' );
  one_day_pre = to_bin(c_ind);
  
  block_numbers = cat_parse_double( 'block__', one_day_pre('blocks', :) );
  
  assert( issorted(block_numbers), 'blocks are not sorted' );
  
  blocks = one_day_pre('blocks');
  
  for j = 1:numel(blocks)
    one_block = one_day_pre(blocks(j));
    trial_numbers = cat_parse_double( 'trial__', one_block('trials', :) );
    assert( issorted(trial_numbers), 'trials are not sorted' );
  end
  
  num_inds = find( c_ind );
  num_inds = num_inds(1:mins_pre);
  
  all_keep(num_inds) = true;
end

kept_pre = to_bin(all_keep);
to_bin = append( to_bin.rm('pre'), kept_pre );

[all_binned, all_bins] = dsp3.add_trial_bin( to_bin, N, step_size, start_over_at, increment_for );

%%

pref_each = { 'days', 'administration', 'trialtypes', 'contexts', 'trial_bin' };

pref_sb = all_binned({'self', 'both'});
pref_on = all_binned({'other', 'none'});

pref_sb = pref_sb.for_each( pref_each, @(x) dsp3.get_preference_index(x, 'both', 'self') );
pref_on = pref_on.for_each( pref_each, @(x) dsp3.get_preference_index(x, 'other', 'none') );

pref = append( pref_sb, pref_on );

pref(isnan(pref.data) | isinf(pref.data)) = [];

%%

save_p = fullfile( plot_save_p, 'behavior', 'preference_index_over_trials', datestr(now, 'mmddyy') );

n_keep_post = 6;

do_save = true;

drug_colors = { 'r', 'b' };

if ( ~is_permonk ), pref = collapse( pref, 'monkeys' ); end

drugs = pref.pcombs( {'drugs'} );

slopes = Container();

monk = pref.pcombs( 'monkeys' );

for monk_idx = 1:numel(monk)
  
  fig = figure(1);
  clf( fig );
  h = gobjects( 1, size(drugs, 1) );
  
  monk_str = strjoin( monk(monk_idx, :), '_' );
  monk_dat = pref( monk(monk_idx, :) );

  for idx = 1:size( drugs, 1 )

  plt = monk_dat( cshorzcat('choice', drugs(idx, :)) );

  bin_pre = max( cat_parse_double('trial_bin__', plt.uniques_where('trial_bin', 'pre')) );
  bin_post = max( cat_parse_double('trial_bin__', plt.uniques_where('trial_bin', 'post')) );

  [t_series_means, t_series_errs, map, outs] = dsp3.get_pref_over_time_means_errs( plt );

  max_post = bin_pre + n_keep_post;

  t_series_means = t_series_means(:, 1:max_post);
  t_series_errs = t_series_errs(:, 1:max_post);

  for i = 1:size(t_series_means, 1)
    subplot( 2, 1, i );
    means = t_series_means(i, :);
    errs = t_series_errs(i, :);

    h(idx) = errorbar( 1:numel(means), means, errs );
    hold on;
    plot( [bin_pre+0.5, bin_pre+0.5], get(gca, 'ylim'), 'k' );
    title_str = strjoin( outs(i), ' | ' );
    title( strrep(title_str, '_', ' ') );

    color = get( h(idx), 'color' );

    x_fit = 1:numel( means );

    ps = polyfit( x_fit, means, 1 );

    res = polyval( ps, x_fit );

    h_1 = plot( x_fit, res );

    set( h_1, 'color', color );

    cont = one( plt );
    cont('outcomes') = outs(i);

    slopes = append( slopes, set_data(cont, ps(1)) );
  end

  end
  
  labs = dsp2.util.general.array_join( drugs, ' | ' );

  legend( h, labs );

  if ( do_save )
    shared_utils.io.require_dir( save_p );
    fname = sprintf( 'saline_vs_ot_error_bars_small_limits_bin%d_step%d', N, step_size );
    fname = sprintf( '%s_%s', monk_str, fname );
    shared_utils.plot.save_fig( gcf, fullfile(save_p, fname), {'fig', 'png', 'epsc'} );
  end
end

%%  permute

if ( do_permute )

n_keep_post = 6;
n_reps = 1e3;

drugs = pref.pcombs( 'drugs' );

slopes = cell( n_reps+1, 1 );

parfor j = 1:n_reps + 1;
  fprintf( '\n %d of %d', j, n_reps );
  
  if ( j == 1 )
    shuffled_pref = pref;
  else
    shuffled_pref = pref.shuffle_each( {'outcomes', 'trial_bin'} );
  end
  
  shuffled_pref = shuffled_pref.require_fields( 'is_permuted' );
  
  over_drugs = Container();

  for idx = 1:size( drugs, 1 )

    plt = shuffled_pref( {'choice', drugs{idx, 1}} );

    bin_pre = max( shared_utils.container.cat_parse_double('trial_bin__', plt.uniques_where('trial_bin', 'pre')) );
    bin_post = max( shared_utils.container.cat_parse_double('trial_bin__', plt.uniques_where('trial_bin', 'post')) );

    [t_series_means, t_series_errs, map, outs] = dsp3.get_pref_over_time_means_errs( plt );

    max_post = bin_pre + n_keep_post;

    t_series_means = t_series_means(:, 1:max_post);
    t_series_errs = t_series_errs(:, 1:max_post);

    for i = 1:size(t_series_means, 1)
      means = t_series_means(i, :);
      errs = t_series_errs(i, :);

      x_fit = 1:numel( means );
      ps = polyfit( x_fit, means, 1 );
      res = polyval( ps, x_fit );
      
      cont = one( plt );

      cont('outcomes') = outs(i);
      
      if ( j == 1 )
        cont('is_permuted') = 'is_permuted__false';
      else
        cont('is_permuted') = 'is_permuted__true';
      end

      over_drugs = append( over_drugs, set_data(cont, ps(1)) );
    end
  end
  
  slope_difference = over_drugs({'oxytocin'}) - over_drugs({'saline'});
  
  slopes{j} = slope_difference;
end

slopes = Container.concat( slopes );

%%

[I, C] = slopes.get_indices( 'outcomes' );

stats = Container();

for i = 1:numel(I)
  
  subset_slope = slopes(I{i});
  subset_real = subset_slope({'is_permuted__false'});
  subset_fake = subset_slope({'is_permuted__true'});
  
  assert( shape(subset_real, 1) == 1 );
  assert( shape(subset_fake, 1) == n_reps );
  
  real_slope = subset_real.data;
  fake_slopes = subset_fake.data;
  
  real_sign = sign( real_slope );
  
  if ( real_sign == -1 )
    p_greater = sum( fake_slopes < real_slope );
  else
    p_greater = sum( real_slope > fake_slopes );
    assert( real_sign == 1 );
  end
  
  p_val = 1 - (p_greater / n_reps);
  
  stat_data = [ real_slope, p_val ];
  
  stats = append( stats, set_data(subset_real, stat_data) );
end

end




