function dsp3_plot_bar_coherence_simple(varargin)

defaults = dsp3.get_behav_stats_defaults();
defaults.do_save = true;
defaults.is_cached = true;
defaults.remove = {};
defaults.smooth_func = @(x) smooth(x, 5);
defaults.drug_type = 'nondrug';
defaults.epochs = 'targacq';
defaults.spectra = true;
defaults.is_pro_minus_anti = false;
defaults.is_post_minus_pre = false;
defaults.specificity = 'sites';
defaults.measure = 'coherence';
defaults.cued_time_window = [ 0, 250 ];
defaults.choice_time_window = [-250, 0];
defaults.freq_window = [ 45, 60 ];
defaults.mask_inputs = {};
defaults.bar_ylims = [];
defaults.line_ylims = [];
defaults.freq_roi_name = '';
defaults.add_bar_points = false;
defaults.bar_plot_type = 'bar';
defaults.load_func = @default_load_func;

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;
epochs = params.epochs;
drug_type = params.drug_type;
meas_t = cellstr( params.measure );
spec_type = char( params.specificity );
base_subdir = params.base_subdir;

[data, labels, freqs, t] = params.load_func( params );
lower( labels );

% [~, matched_ind] = match_days_for_epochs( labels );
% data = data(matched_ind, :, :);

dayspec = { 'administration', 'days', 'trialtypes', 'outcomes', 'epochs' };
blockspec = csunion( dayspec, {'blocks', 'sessions'} );

if ( strcmp(spec_type, 'blocks') )
  sitespec = csunion( blockspec, {'channels', 'regions', 'sites'} );
elseif ( strcmp(spec_type, 'sites') )
  sitespec = csunion( dayspec, {'channels', 'regions', 'sites'} );
elseif ( strcmp(spec_type, 'days') )
  sitespec = csunion( dayspec, {'regions'} );
else
  error( 'Unrecognized specificity "%s".', spec_type );
end

components = { 'spectra', dsp3.datedir(), base_subdir, drug_type, 'nonz', spec_type };

plot_p = char( dsp3.plotp(components, conf) );
analysis_p = char( dsp3.analysisp(components, conf) );

params.plot_p = plot_p;
params.analysis_p = analysis_p;

%   pro v. anti if necessary
if ( haslab(prune(labels), 'self') )
  [data, labels] = dsp3.pro_v_anti( data, labels, cssetdiff(sitespec, 'outcomes') );  
end


replace( labels, 'selfMinusBoth', 'anti' );
replace( labels, 'otherMinusNone', 'pro' );

if ( params.is_pro_minus_anti )
  [data, labels] = dsp3.pro_minus_anti( data, labels, cssetdiff(sitespec, 'outcomes') );
end

if ( ~dsp3.isdrug(drug_type) ), collapsecat( labels, 'drugs' ); end

data = indexpair( data, labels, findnone(labels, params.remove) );

plot_lines( data, labels', freqs, t, params );
plot_bars( data, labels', freqs, t, params );

end

function [data, labels, freqs, t] = default_load_func(params)

epochs = params.epochs;
drug_type = params.drug_type;
meas_t = cellstr( params.measure );
conf = params.config;

meas_types = cellfun( @(x) sprintf('at_%s', x), meas_t, 'un', 0 );

p = dsp3.get_intermediate_dir( shared_utils.io.fullfiles(meas_types, drug_type, epochs), conf );
load_inputs = { 'get_meas_func', @(meas) meas.measure, 'is_cached', params.is_cached };

[data, labels, freqs, t] = dsp3.load_signal_measure( shared_utils.io.findmat(p), load_inputs{:} );

end

function [labels, matched_ind] = match_days_for_epochs(labels)

day_I = findall( labels, 'days' );
epochs = combs( labels, 'epochs' );

if ( numel(epochs) == 1 )
  matched_ind = rowmask( labels );
  return;
end

inds_to_remove = [];

for i = 1:numel(day_I)
  for j = 1:numel(epochs)
    if ( count(labels, epochs{j}, day_I{i}) == 0 )
      inds_to_remove(end+1) = i;
      break;
    end
  end
end

keep_I = day_I;
keep_I(inds_to_remove) = [];

matched_ind = vertcat( keep_I{:} );
keep( labels, matched_ind );

end

function plot_lines(data, labels, freqs, t, params)

%%

addcat( labels, 'band' );

if ( ~isempty(params.freq_roi_name) )
  setcat( labels, 'band', params.freq_roi_name );
end

mask = fcat.mask( labels, params.mask_inputs{:} );

if ( params.is_pro_minus_anti )
  gcats = { 'trialtypes' };
  pcats = { 'outcomes', 'administration', 'measure', 'regions', 'band' };
else
  gcats = { 'outcomes' };
  pcats = { 'trialtypes', 'administration', 'measure', 'regions', 'band' };
end  

f_ind = freqs >= params.freq_window(1) & freqs <= params.freq_window(2);

plt_dat = squeeze( nanmean(data(mask, f_ind, :), 2) );
plt_labs = prune( labels(mask) );

pl = plotlabeled.make_common();
pl.x = t;
pl.error_func = @plotlabeled.nansem;

if ( ~isempty(params.line_ylims) )
  pl.y_lims = params.line_ylims;
end

axs = pl.lines( plt_dat, plt_labs, gcats, pcats );

shared_utils.plot.set_xlims( axs, [-300, 300] );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, 0 );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  
  plot_p = params.plot_p;
  full_plot_p = fullfile( plot_p, 'lines' );
  
  pltcats = unique( cshorzcat(gcats, pcats) );
  prefix = sprintf( '%s%s', params.base_prefix, params.measure );
  
  dsp3.req_savefig( gcf, full_plot_p, plt_labs, pltcats, prefix, {'epsc', 'png', 'fig', 'svg'} );
end

end

function plot_bars(data, labels, freqs, t, params)

addcat( labels, 'band' );

if ( ~isempty(params.freq_roi_name) )
  setcat( labels, 'band', params.freq_roi_name );
end

assert( numel(freqs) == size(data, 2) );
assert( numel(t) == size(data, 3) );

is_drug = dsp3.isdrug( params.drug_type );

mask = fcat.mask( labels, params.mask_inputs{:} );

if ( is_drug )
  xcats = {};
  gcats = { 'drugs' };
  pcats = { 'trialtypes', 'outcomes', 'administration', 'measure', 'regions', 'band' };
else
  if ( params.is_pro_minus_anti )
    xcats = { 'trialtypes' };
    gcats = {};
    pcats = { 'outcomes', 'administration', 'measure', 'regions', 'band' };
  else
    xcats = { 'outcomes' };
    gcats = { 'trialtypes' };
    pcats = { 'administration', 'measure', 'regions', 'band' };
  end  
end

f_ind = freqs >= params.freq_window(1) & freqs <= params.freq_window(2);

cued_t_ind = t >= params.cued_time_window(1) & t <= params.cued_time_window(2);
choice_t_ind = t >= params.choice_time_window(1) & t <= params.choice_time_window(2);

is_cued = find( labels, 'targon' );
is_choice = find( labels, 'targacq' );

all_data = nan( rows(data), 1 );
all_data(is_cued) = squeeze( nanmean(nanmean(data(is_cued, f_ind, cued_t_ind), 2), 3) );
all_data(is_choice) = squeeze( nanmean(nanmean(data(is_choice, f_ind, choice_t_ind), 2), 3) );

pltlabs = prune( labels(mask) );
pltdat = all_data(mask);

assert_ispair( pltdat, pltlabs );

pl = plotlabeled.make_common();
pl.panel_order = { 'pro', 'anti' };
pl.x_order = { 'pro', 'anti' };

if ( ~isempty(params.bar_ylims) )
  pl.y_lims = params.bar_ylims;
end

pl.add_points = params.add_bar_points;

switch ( params.bar_plot_type )
  case 'bar'
    axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );
  case 'violin'
    axs = pl.violinplot( pltdat, pltlabs, [xcats, gcats], pcats );
  case 'box'
    axs = pl.boxplot( pltdat, pltlabs, [xcats, gcats], pcats, true );
  otherwise
    error( 'Unrecognized bar plot type "%s".', params.bar_plot_type );
end

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  
  plot_p = params.plot_p;
  pltcats = unique( cshorzcat(xcats, gcats, pcats) );
  
  prefix = sprintf( 'bar__%spro_anti_%s', params.base_prefix, params.measure );
  
  dsp3.req_savefig( gcf, plot_p, pltlabs, pltcats, prefix, {'epsc', 'png', 'fig', 'svg'} );
end

%%  Stats

if ( params.is_pro_minus_anti )
  ttest_a = 'choice';
  ttest_b = 'cued';
else
  ttest_a = 'pro';
  ttest_b = 'anti';
end

ttest_each = setdiff( pltcats, whichcat(pltlabs, ttest_a) );
ttest_outs = dsp3.ttest2( pltdat, pltlabs', ttest_each, ttest_a, ttest_b );

signrank_each = pltcats;
signrank_outs = dsp3.signrank1( pltdat, pltlabs', signrank_each );

signrank2_outs = dsp3.signrank2( pltdat, pltlabs', ttest_each, ttest_a, ttest_b );
ranksum_outs = dsp3.ranksum( pltdat, pltlabs', ttest_each, ttest_a, ttest_b );

if ( params.do_save )
  stats_p = get_stats_p( params );
  
  dsp3.save_ttest2_outputs( ttest_outs, fullfile(stats_p, 'ttest') );
  dsp3.save_signrank1_outputs( signrank_outs, fullfile(stats_p, 'signrank1') );
  dsp3.save_signrank1_outputs( signrank2_outs, fullfile(stats_p, 'signrank2') );
  dsp3.save_ranksum_outputs( ranksum_outs, fullfile(stats_p, 'ranksum') );
end

end

function p = get_stats_p(params)

freq_roi = params.freq_roi_name;
condition_name = ternary( params.is_pro_minus_anti, 'pro_v_anti', 'choice_v_cued' );

p = fullfile( params.analysis_p, freq_roi, condition_name );

end