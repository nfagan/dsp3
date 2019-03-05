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

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;
epochs = params.epochs;
drug_type = params.drug_type;
meas_t = cellstr( params.measure );
spec_type = char( params.specificity );
base_subdir = params.base_subdir;

meas_types = cellfun( @(x) sprintf('at_%s', x), meas_t, 'un', 0 );

p = dsp3.get_intermediate_dir( shared_utils.io.fullfiles(meas_types, drug_type, epochs), conf );
load_inputs = { 'get_meas_func', @(meas) meas.measure, 'is_cached', params.is_cached };

[data, labels, freqs, t] = dsp3.load_signal_measure( shared_utils.io.findmat(p), load_inputs{:} );

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
params.plot_p = plot_p;

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

plot_bars( data, labels', freqs, t, params );

end

function plot_bars(data, labels, freqs, t, params)

assert( numel(freqs) == size(data, 2) );
assert( numel(t) == size(data, 3) );

is_drug = dsp3.isdrug( params.drug_type );

mask = fcat.mask( labels, params.mask_inputs{:} );

if ( is_drug )
  xcats = {};
  gcats = { 'drugs' };
  pcats = { 'trialtypes', 'outcomes', 'administration', 'measure', 'regions' };
else
  if ( params.is_pro_minus_anti )
    xcats = { 'trialtypes' };
    gcats = {};
    pcats = { 'outcomes', 'administration', 'measure', 'regions' };
  else
    xcats = { 'outcomes' };
    gcats = { 'trialtypes' };
    pcats = { 'administration', 'measure', 'regions' };
  end  
end

f_ind = freqs >= params.freq_window(1) & freqs <= params.freq_window(2);

cued_t_ind = t >= params.cued_time_window(1) & t <= params.cued_time_window(2);
choice_t_ind = t >= params.choice_time_window(1) & t <= params.choice_time_window(2);

is_cued = find( labels, 'targOn' );
is_choice = find( labels, 'targAcq' );

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

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  
  plot_p = params.plot_p;
  pltcats = unique( cshorzcat(xcats, gcats, pcats) );
  
  prefix = sprintf( 'bar__%spro_anti_%s', params.base_prefix, params.measure );
  
  dsp3.req_savefig( gcf, plot_p, pltlabs, pltcats, prefix );
end

end