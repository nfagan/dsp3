function plot_pref_index_over_time(varargin)

import dsp2.process.format.add_trial_bin;
import shared_utils.container.cat_parse_double;

defaults = dsp3.get_behav_stats_defaults();
defaults.drug_type = 'drug';
defaults.do_permute = false;
defaults.config = dsp3.config.load();
defaults.n_keep_post = 6;
defaults.fractional_bin = true;
defaults.bin_fraction = 0.2;
defaults.apply_bin_threshold = false;

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;
drug_type = params.drug_type;
is_permonk = params.per_monkey;
do_save = params.do_save;
do_permute = params.do_permute;
bs = params.base_subdir;
n_keep_post = params.n_keep_post;
base_pref = params.base_prefix;

if ( ~dsp3.isdrug(drug_type) )
  return;
end

if ( isempty(params.consolidated) )
  combined = dsp3.get_consolidated_data( conf );
else
  combined = params.consolidated;
end

behav = require_fields( combined.trial_data, { 'channels', 'regions', 'sites' } );
behav = remove( dsp3.get_subset(behav, drug_type), params.remove );

path_components = { 'behavior', dsp3.datedir, bs, drug_type, 'pref_index_over_time' };

plot_save_p = char( dsp3.plotp(path_components, conf) );

%%  check descriptives pre and post

countspec = { 'days', 'trialtypes' };

behavlabs = fcat.from( behav.labels );
mask = fcat.mask( behavlabs, @find, {'choice'} );

[countlabs, I] = keepeach( behavlabs', countspec, mask );

countdat = cellfun( @numel, I );

funcs = [ dsp3.descriptive_funcs(), {@min, @max} ];

tspec = { 'monkeys', 'drugs' };

tbl = dsp3.descriptive_table( countdat, countlabs', tspec, funcs );

%%  fractional bin trials

if ( params.fractional_bin )
  
  frac = params.bin_fraction;
  N = frac * 100;
  step_size = NaN;

  binlabs = behavlabs';

  mask = fcat.mask( binlabs, @findnone, 'errors', @find, 'choice' );

  bin_each = { 'days', 'administration', 'contexts' };

  I = findall( binlabs, bin_each, mask );

  for i = 1:numel(I)
    dsp3.add_absolute_trial_number( binlabs, I{i} );
    dsp3.fractional_bin_trials( binlabs, frac, I{i} );
  end
  
  all_binned = Container( rowzeros(rows(binlabs)), SparseLabels.from_fcat(binlabs) );
  all_binned = all_binned({'choice'});

else
  
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

end

%%

pref_each = { 'days', 'administration', 'trialtypes', 'contexts', 'trial_bin' };

pref_sb = all_binned({'self', 'both'});
pref_on = all_binned({'other', 'none'});

pref_sb = pref_sb.for_each( pref_each, @(x) dsp3.get_preference_index(x, 'both', 'self') );
pref_on = pref_on.for_each( pref_each, @(x) dsp3.get_preference_index(x, 'other', 'none') );

pref = append( pref_sb, pref_on );

pref(isnan(pref.data) | isinf(pref.data)) = [];

%%  max bin

if ( params.apply_bin_threshold )

  preflabs = fcat.from( pref.labels );

  minspec = { 'monkeys', 'administration' };
  minseach = { 'days' };

  mask = fcat.mask( preflabs, @find, 'post' );

  I = findall( preflabs, minspec, mask );

  fullind = setdiff( rowmask(preflabs), mask );

  for i = 1:numel(I)
    inds = findall( preflabs, minseach, I{i} );

    maxs = zeros( size(inds) );
    c_bins = cell( size(inds) );

    for j = 1:numel(inds)
      bins = fcat.parse( cellstr(preflabs, 'trial_bin', inds{j}), 'trial_bin__' );
      assert( ~any(isnan(bins)) );
      maxs(j) = max( bins );
      c_bins{j} = bins;
    end

    mins = min( maxs );

    bin_inds = cellfun( @(x, y) x(y <= mins), inds, c_bins, 'un', 0 );  

    for j = 1:numel(bin_inds)
      fullind = union( fullind, bin_inds{j} );
    end    
  end

  pref = pref(double(fullind));
  
end

%%

save_p = plot_save_p;

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

    if ( ~isinf(n_keep_post) )
      max_post = bin_pre + n_keep_post;

      t_series_means = t_series_means(:, 1:max_post);
      t_series_errs = t_series_errs(:, 1:max_post);
    end

    for i = 1:size(t_series_means, 1)
      subplot( 2, 1, i );
      means = t_series_means(i, :);
      errs = t_series_errs(i, :);

      h(idx) = errorbar( 1:numel(means), means, errs );
      hold on;
      plot( [bin_pre+0.5, bin_pre+0.5], get(gca, 'ylim'), 'k' );
      title_str = strjoin( outs(i), ' | ' );
      title_str = strjoin( {title_str, monk_str}, ' | ' );
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
    fname = sprintf( '%s_%s_%s', base_pref, monk_str, fname );
    shared_utils.plot.save_fig( gcf, fullfile(save_p, fname), {'fig', 'png', 'epsc'} );
  end
end

%%  permute

if ( do_permute )

  n_reps = 1e3;

  drugs = pref.pcombs( 'drugs' );

  slopes = cell( n_reps+1, 1 );

  parfor j = 1:n_reps+1
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

  %
  % stats
  %

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
      assert( real_sign == 1 );
      p_greater = sum( real_slope > fake_slopes );
    end

    p_val = 1 - (p_greater / n_reps);

    stat_data = [ real_slope, p_val ];

    stats = append( stats, set_data(subset_real, stat_data) );
  end

end




