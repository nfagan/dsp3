function plot_pref_index_over_time_redux(varargin)

import dsp2.process.format.add_trial_bin;
import shared_utils.container.cat_parse_double;

defaults = dsp3.get_behav_stats_defaults();
defaults.drug_type = 'drug';
defaults.do_permute = false;
defaults.config = dsp3.config.load();
defaults.n_keep_post = 6;
defaults.fractional_bin = false;
defaults.bin_fraction = 0.2;
defaults.apply_bin_threshold = false;
defaults.step_size = 25;
defaults.window_size = 25;
defaults.do_plot = true;

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;
drug_type = params.drug_type;
bs = params.base_subdir;
base_prefix = params.base_prefix;

if ( ~dsp3.isdrug(drug_type) ), return; end

if ( isempty(params.consolidated) )
  combined = dsp3.get_consolidated_data( conf );
else
  combined = params.consolidated;
end

labs = fcat.from( combined.trial_data.labels );
dat = combined.trial_data.data;

[behavlabs, I] = dsp3.get_subset( labs', drug_type );
behavdat = rowref( dat, I );

behavdat = indexpair( behavdat, behavlabs, findnone(behavlabs, params.remove) );

path_components = { 'behavior', dsp3.datedir, bs, drug_type, 'pref_index_over_time_redux' };

plot_p = char( dsp3.plotp(path_components, conf) );

%%  bin

bincat = 'trial_bin';
acat = 'administration';

binlabs = behavlabs';

s_size = params.step_size;
w_size = params.window_size;

frac = params.bin_fraction;

mask = fcat.mask( binlabs, @findnone, 'errors', @find, 'choice' );

bin_each = { 'days', acat, 'contexts' };

I = findall( binlabs, bin_each, mask );

for i = 1:numel(I)
  dsp3.add_absolute_trial_number( binlabs, I{i} );
  
  if ( params.fractional_bin )
    dsp3.fractional_bin_trials( binlabs, frac, I{i} );
  else
    dsp3.n_bin_trials( binlabs, s_size, w_size, I{i} );
  end
end

%%  pref within bin

spec = csunion( dsp3.prefspec(), bincat );
[prefdat, preflabs] = dsp3.get_pref( binlabs', spec );
prefdat = indexpair( prefdat, preflabs, find(~isnan(prefdat) & ~isinf(prefdat)) );

replace( preflabs, 'otherMinusNone', 'pro' );
replace( preflabs, 'selfMinusBoth', 'anti' );

if ( ~params.per_monkey ), collapsecat( preflabs, 'monkeys'); end

%%  slopes for each day, concatenating pre and post

usedat = prefdat;
uselabs = preflabs';

slopespec = csunion( cssetdiff(spec, {bincat, acat}), 'outcomes' );

mask = fcat.mask( uselabs, @find, 'choice', @findnone, {'<trial_bin>', 'trial_bin__NaN'} );

[slabs, I] = keepeach( uselabs', slopespec, mask );
slopes = zeros( size(I) );

admins = { 'pre', 'post' };
per_ns = cell( size(admins) );
per_means = cell( size(admins) );

setcat( slabs, acat, strjoin(admins, '_') );

for i = 1:numel(I)  
  for j = 1:numel(admins)
    [bin_i, bin_c] = findall( uselabs, bincat, find(uselabs, admins{j}, I{i}) );
    
    one_ns = fcat.parse( bin_c, sprintf('%s__', bincat) );

    assert( ~any(isnan(one_ns)) && issorted(one_ns, 'strictascend') );

    per_means{j} = rownanmean( usedat, bin_i );
    per_ns{j} = one_ns(:);
  end
  
  ns = vertcat( per_ns{:} );
  means = vertcat( per_means{:} );
  
  ps = polyfit( ns(:)', means(:)', 1 );
  slopes(i) = ps(1);
end

%%  bar

prefix = sprintf( '%sbar', base_prefix );

pltdat = slopes;
pltlabs = slabs';

mask = rowmask( pltdat );

pl = plotlabeled.make_common();
pl.x_order = { 'pro', 'anti' };

xcats = { 'outcomes' };
gcats = { 'drugs' };
pcats = dsp3.nonun_or_all( pltlabs, {'trialtypes', acat, 'monkeys'} );

if ( params.do_plot )
  
  pl.bar( pltdat(mask), pltlabs(mask), xcats, gcats, pcats );
  
  if ( params.do_save )
    fnames = unique( cshorzcat(xcats, gcats, pcats) );
    dsp3.req_savefig( gcf, plot_p, pltlabs, fnames, prefix );
  end
end

%%  stats - test against 0

usedat = slopes;
uselabs = slabs';

mask = rowmask( uselabs );

statspec = setdiff( csunion(spec, {'outcomes', 'drugs', 'monkeys'}), {'days', bincat} );

funcs = [ dsp3.descriptive_funcs(), {@signrank} ];

[m_tbl, ~, m_labs] = dsp3.descriptive_table( usedat, uselabs', statspec, funcs, mask );

%%  stats - compare drugs

usedat = slopes;
uselabs = slabs';

mask = rowmask( uselabs );

statspec = setdiff( csunion(spec, {'drugs', 'monkeys'}), {'days', bincat} );

a = 'pro';
b = 'anti';

outs = dsp3.ttest2( usedat, uselabs', statspec, a, b ...
  , 'mask', mask ...
  , 'descriptive_funcs', dsp3.descriptive_funcs() ...
);

%%  hist

prefix = sprintf( '%shist', base_prefix );

pltdat = slopes;
pltlabs = slabs';

mask = rowmask( pltdat );

pl = plotlabeled.make_common();
pl.panel_order = { 'pro', 'anti' };

pcats = dsp3.nonun_or_all( pltlabs, {'trialtypes', acat, 'outcomes', 'drugs'}, {acat, 'monkeys'} );

if ( params.do_plot )
  subset = pltdat(mask);
  subsetlabs = pltlabs(mask);
  
  [figs, ~, I] = pl.figures( @hist, subset, subsetlabs, 'monkeys', pcats, 100 );
  
  if ( params.do_save )
    for i = 1:numel(figs)
      dsp3.req_savefig( figs(i), plot_p, subsetlabs(I{i}), pcats, prefix );
    end
  end
end

end

