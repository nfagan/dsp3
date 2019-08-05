function plot_sfcoh_over_time_in_trial_bins(coh, coh_labs)

if ( nargin == 0 )
  [coh, coh_labs] = dsp3_sfq.load_targacq_coh_for_over_time();
else
  assert_ispair( coh, coh_labs );
end

%%

trial_step = 20;
trial_bin = 20;
restrict_to_minimum = false;
is_pro_minus_anti = false;

max_bin = 7;

use_labs = add_bin_labels( coh_labs', trial_step, trial_bin, restrict_to_minimum, {'contexts'} );

base_prefix = sprintf( '%d_max_%d_', trial_step, max_bin );

%%

proanti_each = { 'bands', 'days', 'regions', 'channels', 'trialtypes', 'trial_bin' };
base_mask = fcat.mask( use_labs ...
  , @findnone, 'trial_bin__NaN' ...
);

%%

[pref_index, pref_labs] = get_pref_index( use_labs, proanti_each, base_mask );
[pref_index, pref_labs] = one_set_preference( pref_index, pref_labs, [proanti_each, {'outcomes'}] );

%%

do_save = true;

params = struct();
params.pro_v_anti = true;
params.pro_minus_anti = is_pro_minus_anti;
params.do_save = do_save;
% params.y_lims = [-0.2, 0.2];
params.restrict_to_minimum = restrict_to_minimum;
params.base_prefix = base_prefix;
params.max_bin = 7;

plot_and_regress( coh, use_labs', proanti_each, base_mask, 'sfcoh_over_time', params );

%%

params = struct();
params.pro_v_anti = false;
params.pro_minus_anti = is_pro_minus_anti;
params.do_save = do_save;
params.y_lims = [];
params.restrict_to_minimum = restrict_to_minimum;
params.base_prefix = base_prefix;
params.max_bin = 7;

plot_and_regress( pref_index, pref_labs', proanti_each, rowmask(pref_labs), 'pref_over_time', params );

end

function [pref_index, pref_labs] = one_set_preference(pref_index, pref_labs, each)

except_each = { 'bands', 'regions', 'channels' };

each_I = findall( pref_labs, setdiff(each, except_each) );
keep_ind = cellfun( @(x) x(1), each_I );

pref_index = pref_index(keep_ind);
pref_labs = prune( pref_labs(keep_ind) );

collapsecat( pref_labs, except_each );

end

function plot_and_regress(pltdat, pltlabs, proanti_each, base_mask, kind, params)

assert_ispair( pltdat, pltlabs );

pro_v_anti = params.pro_v_anti;
pro_minus_anti = params.pro_minus_anti;
do_save = params.do_save;
prefix = ternary( params.restrict_to_minimum, 'min__', 'all__' );
prefix = sprintf( '%s%s', params.base_prefix, prefix );

path_components = { kind, dsp3.datedir };
conf = dsp3.config.load();

save_p = char( dsp3.plotp(path_components, conf) );
analysis_p = char( dsp3.analysisp(path_components, conf) );

figs_each = { 'regions' };
xcats = { 'trial_bin' };
gcats = { 'outcomes' };
pcats = { 'regions', 'bands' };

fig_I = findall( pltlabs, figs_each, base_mask );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  
  subset_dat = pltdat(fig_I{i});
  subset_labs = prune( pltlabs(fig_I{i}) );
  
  if ( pro_v_anti )
    [subset_dat, subset_labs] = dsp3.pro_v_anti( subset_dat, subset_labs, proanti_each );
  end
  if ( pro_minus_anti )
    [subset_dat, subset_labs] = dsp3.pro_minus_anti( subset_dat, subset_labs, proanti_each );
  end
  
  trial_bins = combs( subset_labs, 'trial_bin' );
  [bin_nums, bin_order] = sort( fcat.parse(trial_bins, 'trial_bin__') );
  
  if ( ~isempty(params.max_bin) )
    keep_bins = bin_nums <= params.max_bin;
    subset_dat = indexpair( subset_dat, subset_labs, find(subset_labs, trial_bins(keep_bins)) );
    prune( subset_labs );
  end
  
  pl.x_order = trial_bins(bin_order);
  pl.y_lims = dsp3.field_or_default( params, 'y_lims', [] );
  
  axs = pl.errorbar( subset_dat, subset_labs, xcats, gcats, pcats );
  
  if ( do_save )
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, subset_labs, [gcats, pcats, figs_each], prefix );
  end
  
  all_bins = cellstr( subset_labs, 'trial_bin' );
  all_bin_nums = fcat.parse( all_bins, 'trial_bin__' );
  
%   [rho, p] = corr( all_bin_nums, subset_dat, 'rows', 'complete', 'type', 'spearman' );
  fit_regressions( all_bin_nums, subset_dat, subset_labs, [gcats, pcats], do_save, analysis_p, prefix );
end

end

function [pref, pref_labs] = get_pref_index(labels, each, mask)

[pref, pref_labs] = dsp3.get_pref( labels', each, mask );
setcat( pref_labs, 'outcomes', 'anti', find(pref_labs, 'selfMinusBoth') );
setcat( pref_labs, 'outcomes', 'pro', find(pref_labs, 'otherMinusNone') );

end

function labels = add_bin_labels(labels, trial_step, trial_bin, restrict_to_minimum, addtl)

addcat( labels, 'trial_bin' );

reg_I = findall( labels, {'bands', 'regions'} );

assert( trial_step == trial_bin, 'Sliding window not yet implemented.' );

start_over_each = { 'days' };

for idx = 1:numel(reg_I)
  start_I = findall( labels, start_over_each, reg_I{idx} );
  min_this_comb = inf;
  
  for i = 1:numel(start_I)    
    [block_I, block_C] = findall( labels, [{'block_order'}, addtl], start_I{i} );
    [~, block_order] = sort( fcat.parse(block_C(1, :), 'block_order__') );
    block_I = block_I(block_order);
    block_C = block_C(:, block_order);
    
    bin_start_map = containers.Map();

    for j = 1:numel(block_I)
      [trial_I, trial_C] = findall( labels, 'trials', block_I{j} );
      [~, trial_order] = sort( fcat.parse(trial_C, 'trial__') );
      trial_I = trial_I(trial_order);

      binned_inds = shared_utils.vector.slidebin( 1:numel(trial_I), trial_bin, trial_step );
      
      bin_ind_key = strjoin( block_C(2:end, j) );
      if ( ~isKey(bin_start_map, bin_ind_key) )
        bin_start_map(bin_ind_key) = 1;
      end
      
      bin_ind = bin_start_map(bin_ind_key);

      for k = 1:numel(binned_inds)      
        inds_this_trial = cat_expanded( 1, trial_I(binned_inds{k}) );
        setcat( labels, 'trial_bin', sprintf('trial_bin__%d', bin_ind), inds_this_trial );
        bin_ind = bin_ind + 1;
      end
      
      bin_start_map(bin_ind_key) = bin_ind;
      
      if ( numel(binned_inds) < min_this_comb )
        min_this_comb = numel( binned_inds );
      end
    end
  end
  
  if ( restrict_to_minimum )
    valid_values = arrayfun( @(x) sprintf('trial_bin__%d', x), 1:min_this_comb, 'un', 0 );
    invalid_inds = setdiff( reg_I{idx}, findor(labels, valid_values, reg_I{idx}) );
    setcat( labels, 'trial_bin', 'trial_bin__NaN', invalid_inds );
  end
end

prune( labels );

end

function fit_regressions(x, y, labels, each, do_save, save_p, prefix)

each_I = findall( labels, each );

for i = 1:numel(each_I)
  subset_x = x(each_I{i});
  subset_y = y(each_I{i});
  subset_labs = prune( labels(each_I{i}) );
  
  mdl = fitlm( subset_x, subset_y );
  coeffs = mdl.Coefficients;
  coeffs(:, end+1) = { mdl.Rsquared.Adjusted };
    
%   [rho, p] = corr( subset_x, subset_y, 'rows', 'complete', 'type', 'spearman' );
%   coeffs = table( rho, p, 'variablenames', {'rho', 'p'} );
  
  if ( do_save )
    dsp3.req_writetable( coeffs, save_p, subset_labs, each, prefix );
  end
end

end
