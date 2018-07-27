function plot_null_granger(kept, varargin)

defaults.drug_type = 'nondrug';
defaults.save_figs = true;
defaults.is_proanti = true;
defaults.is_permonk = false;
defaults.base_subdir = '';
defaults.base_prefix = '';
defaults.lims = [];
defaults.config = dsp3.config.load();

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;
drug_type = params.drug_type;
base_subdir = params.base_subdir;

assert( all(ismember(drug_type, {'nondrug', 'drug', 'replication', 'old'})) ...
  , 'Unrecognized manipulation "%s".', drug_type );

save_figs = params.save_figs;
is_drug = strcmpi( drug_type, 'drug' );
is_proanti = params.is_proanti;
is_permonk = params.is_permonk;

base_prefix = sprintf( '%s%s', params.drug_type, params.base_prefix );

plotp = char( dsp3.plotp({'granger', dsp3.datedir}, conf) );

monkdir = ternary( is_permonk, 'per_monk', 'across_monks' );
prodir = ternary( is_proanti, 'pro_v_anti', 'per_outcome' );
epochdir = strjoin( kept('epochs'), '_' );

outcome_order = ternary( is_proanti, {'pro', 'anti'}, {'self', 'both', 'other', 'none'} );

plotp = fullfile( plotp, base_subdir, drug_type, epochdir, monkdir, prodir );

%%  MAKE PRO V ANTI

if ( is_proanti )
  kept = dsp2.process.manipulations.pro_v_anti( kept );
end

if ( is_drug )
  kept = dsp2.process.manipulations.post_minus_pre( kept );
end

if ( ~is_permonk )
  kept = collapse( kept, 'monkeys' );
end

%%  lines -- not minus null

kept_copy = rm( kept, dsp2.process.format.get_bad_days() );

labs = fcat.from( kept_copy.labels );
dat = kept_copy.data;
freqs = kept_copy.frequencies;

replace( labs, 'otherMinusNone', 'pro' );
replace( labs, 'selfMinusBoth', 'anti' );

%%

prefix = base_prefix;

lines = dsp3.nonun_or_all( labs, {'administration', 'permuted'} );
panels = dsp3.nonun_or_all( labs, {'outcomes', 'drugs', 'regions', 'epochs', 'trialtypes', 'monkeys'} );

figcats = { 'monkeys', 'trialtypes' };
I = findall( labs, figcats );

line_axs = cell( size(I) );
figs = cell( size(I) );
masks = cell( size(I) );
has_fig = false( size(I) );

for i = 1:numel(I)
  
mask = findnot( labs, {'targAcq', 'cued'}, I{i} );

if ( isempty(mask) ), continue; end

fig = figure(i);
shared_utils.plot.prevent_legend_autoupdate( fig );

pl = plotlabeled.make_common( 'x', freqs );
pl.sort_combinations = true;
pl.fig = fig;
pl.shape = [2, 4];
pl.panel_order = outcome_order;
% set_smoothing( pl, 5 );

if ( ~isempty(params.lims) )
  pl.y_lims = params.lims;
end

axs = pl.lines( rowref(dat, mask), labs(mask), lines, panels );

masks{i} = mask;
line_axs{i} = axs;
figs{i} = fig;
has_fig(i) = true;

end

bands = dsp3.get_bands();
find_func = @(x) [find(freqs >= x(1), 1, 'first'), find(freqs <= x(2), 1, 'last')];
inds = cellfun( find_func, bands, 'un', 0 );
inds(cellfun(@isempty, inds)) = [];

line_axs = horzcat( line_axs{:} );

shared_utils.plot.match_ylims( line_axs );
shared_utils.plot.hold( line_axs );
shared_utils.plot.add_vertical_lines( line_axs, freqs(horzcat(inds{:})) );

if ( save_figs )
  for i = 1:numel(figs)
    if ( has_fig(i) )
      dsp3.req_savefig( figs{i}, plotp, labs(masks{i}), csunion(lines, panels), prefix );
    end
  end
end

close( figs{:} );

%%  minus null

usedat = dat;
uselabs = labs';

[bands, bandnames] = dsp3.get_bands();

[banddat, bandlabs] = dsp3.get_band_means( usedat, uselabs', freqs, bands, bandnames );

subeach = { 'bands', 'days', 'drugs', 'regions', 'channels', 'sites' ...
  , 'epochs', 'trialtypes', 'outcomes', 'administration' };

lab1 = 'permuted__false';
lab2 = 'permuted__true';

[subdat, sublabs] = dsp3.a_summary_minus_b( banddat, bandlabs', subeach, lab1, lab2 );

%%  bar minus null

prefix = sprintf( 'bar__%s', base_prefix );

pltdat = subdat;
pltlabs = sublabs';

figcats = { 'monkeys', 'trialtypes' };
I = findall( pltlabs, figcats );

figs = cell( size(I) );
masks = cell( size(I) );
axes = cell( size(I) );

for i = 1:numel(I)

mask = find( pltlabs, {'theta', 'beta', 'gamma'}, I{i} );

fig = figure(i);

pl = plotlabeled.make_common();
pl.fig = fig;
pl.sort_combinations = true;
pl.panel_order = bandnames;
pl.x_order = outcome_order;

uncats = getcats( pltlabs, 'un' );
xcats = cssetdiff( 'outcomes', uncats );
gcats = cssetdiff( 'regions', uncats );
pcats = cssetdiff( { 'bands', 'trialtypes', 'administration', 'drugs', 'epochs', 'monkeys' }, uncats );

axes{i} = pl.bar( pltdat(mask), pltlabs(mask), xcats, gcats, pcats );
figs{i} = fig;
masks{i} = mask;

end

shared_utils.plot.match_ylims( horzcat(axes{:}) );

if ( save_figs )
  for i = 1:numel(figs)
    dsp3.req_savefig( figs{i}, plotp, pltlabs(masks{i}), unique([xcats, gcats, pcats]), prefix );
  end
end

close( figs{:} );

end


