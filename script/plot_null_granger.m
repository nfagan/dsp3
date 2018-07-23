function plot_null_granger(kept, varargin)

defaults.drug_type = 'nondrug';
defaults.save_figs = true;
defaults.is_proanti = true;
defaults.is_permonk = false;
defaults.config = dsp3.config.load();

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;
drug_type = params.drug_type;

assert( all(ismember(drug_type, {'nondrug', 'drug', 'replication'})) ...
  , 'Unrecognized manipulation "%s".', drug_type );

save_figs = params.save_figs;
is_drug = strcmpi( drug_type, 'drug' );
is_proanti = params.is_proanti;
is_permonk = params.is_permonk;
base_prefix = params.drug_type;

plotp = char( dsp3.plotp({'granger', dsp3.datedir}, conf) );

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
lims = [ -0.03, 0.03 ];

figs = 'monkeys';
I = findall( labs, figs );

for i = 1:numel(I)
  
mask = find( labs, 'choice', I{i} );

pl = plotlabeled.make_common( 'x', freqs );
pl.fig = figure(2);
pl.shape = [2, 4];
% set_smoothing( pl, 5 );

axs = pl.lines( rowref(dat, mask), labs(mask), lines, panels );
% shared_utils.plot.set_ylims( axs, lims );

if ( save_figs )
  dsp3.req_savefig( gcf, plotp, labs(mask), csunion(lines, panels), prefix );
end

end

%%  minus null

usedat = dat;
uselabs = labs';

bands = { [4, 8], [8, 13], [13, 30], [30, 60], [60, 100] };
bandnames = { 'theta', 'alpha', 'beta', 'gamma', 'high_gamma' };

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

figs = 'monkeys';
I = findall( pltlabs, figs );

for i = 1:numel(I)

mask = find( pltlabs, {'theta', 'beta', 'gamma'}, I{i} );

pl = plotlabeled.make_common();

uncats = getcats( pltlabs, 'un' );
xcats = cssetdiff( 'outcomes', uncats );
gcats = cssetdiff( 'regions', uncats );
pcats = cssetdiff( { 'bands', 'trialtypes', 'administration', 'drugs', 'epochs', 'monkeys' }, uncats );

pl.bar( pltdat(mask), pltlabs(mask), xcats, gcats, pcats );

if ( save_figs )
  dsp3.req_savefig( gcf, plotp, pltlabs(mask), unique([xcats, gcats, pcats]), prefix );
end

end

