function stats__gamma_beta_ratio_overtime(varargin)

defaults = dsp3.get_behav_stats_defaults();
defaults.do_plot = false;
defaults.meast = 'at_coherence';
defaults.drug_type = 'nondrug';
defaults.epochs = 'targacq';

params = dsp3.parsestruct( defaults, varargin );

do_save = params.do_save;
do_plt = params.do_plot;

%%

conf = params.config;
meast = params.meast;
drugt = params.drug_type;
epochs = params.epochs;
per_monk = params.per_monkey;
per_mag = params.per_magnitude;
bs = params.base_subdir;
base_prefix = params.base_prefix;

mag_type = ternary( per_mag, 'magnitude', 'non_magnitude' );
path_components = { 'gamma_beta_ratio_over_time', dsp3.datedir, bs, drugt, mag_type };

analysis_p = char( dsp3.analysisp(path_components, conf) );
plot_p = char( dsp3.plotp(path_components, conf) );

intermediate_dirs = dsp3.fullfiles( meast, drugt, epochs );
coh_p = dsp3.get_intermediate_dir( intermediate_dirs );
mats = shared_utils.io.find( coh_p, '.mat' );

basespec = { 'measure', 'epochs', 'bands', 'outcomes', 'trialtypes', 'days', 'drugs' };

if ( per_monk ), basespec{end+1} = 'monkeys'; end

dayspec = csunion( basespec, 'days' );
sitespec = csunion( basespec, {'days', 'channels', 'regions'} );
blockspec = csunion( basespec, {'days', 'sessions', 'blocks'} );

%%  load data

[data, labels, freqs, t] = dsp3.load_signal_measure( mats ...
  , 'get_meas_func', @(meas) meas.measure ...
);

dsp3.add_context_labels( labels );

data = indexpair( data, labels, findnone(labels, params.remove) );

%%  time mean

t_ind = t >= -250 & t <= 0;
t_dim = 3;
t_meaned = nanmean( dimref(data, t_ind, t_dim), t_dim );

[bandmeans, bandlabs] = dsp3.get_band_means( t_meaned, labels', freqs, dsp3.get_bands('map') );

gamma_ind = find( bandlabs, 'gamma' );
beta_ind = find( bandlabs, 'beta' );

ratio = bandmeans(gamma_ind) ./ bandmeans(beta_ind);
bandlabs = setcat( bandlabs(gamma_ind), 'bands', 'gamma div beta' );

%%  remove blocks without 4 outcomes

blockdat = ratio;
blocklabs = bandlabs';

checkspec = cssetdiff( blockspec, 'outcomes' );

mask = fcat.mask( blocklabs, @findnone, 'errors' );

outs = combs( blocklabs, 'outcomes', mask );
I = findall( blocklabs, checkspec, mask );

tokeep = [];

for i = 1:numel(I)
  cts = count( blocklabs, outs, I{i} );
  
  if ( any(cts == 0) ), continue; end
  
  tokeep = union( tokeep, I{i} );  
end

blockdat = indexpair( blockdat, blocklabs, tokeep );

%%

[alignlabs, max_pre] = dsp3.align_blocks_post( blocklabs' );

%%  

pltdat = blockdat;
pltlabs = alignlabs';

mask = fcat.mask( pltlabs, @findnone, {'errors', 'cued'} );

xcats = { 'blocks' };
gcats = { 'drugs' };
pcats = dsp3.nonun_or_all( pltlabs, {'outcomes', 'trialtypes', 'monkeys'} );

pl = plotlabeled.make_common();
pl.panel_order = dsp3.outcome_order();
pl.add_fit = true;
pl.fit_func = @plotlabeled.polyfit_linear;

axs = pl.errorbar( rowref(pltdat, mask), pltlabs(mask), xcats, gcats, pcats );

shared_utils.plot.hold( axs );
shared_utils.plot.add_vertical_lines( axs, max_pre+0.5 );

if ( do_save )
  prefix = sprintf( '%sgamma_beta_over_time', base_prefix );
  dsp3.req_savefig( gcf, plot_p, pltlabs, cshorzcat(xcats, gcats, pcats), prefix );
end

%%  slope permutation

tic;

uselabs = alignlabs';
usedat = blockdat;

mask = find( ~isnan(usedat) );

[meanlabs, I] = keepeach( uselabs', csunion(blockspec, sitespec), mask );
meandat = rownanmean( usedat, I );

permlabs = meanlabs';
permdat = meandat;

iters = 1e3;

permspec = cssetdiff( basespec, 'days' );
shufcat = 'blocks';
slopecat = 'slope_type';

I = findall( permlabs, permspec );

slopes = zeros( numel(I)*iters + numel(I), 1 );
slopelabs = fcat();
stp = 1;

testlabs = fcat();
testdat = zeros( size(I) );

for i = 1:numel(I)
  [real_inds, real_c] = findall( permlabs, shufcat, I{i} );
  block_ns = fcat.parse( real_c, 'block__' );
  
  assert( ~any(isnan(block_ns)) );
  
  matched_ns = arrayfun( @(x, y) repmat(x, size(y{1})), block_ns(:), real_inds, 'un', 0 );
  matched_ns = vertcat( matched_ns{:} );
  
  vals = cellfun( @(x) permdat(x), real_inds, 'un', 0 );
  vals = vertcat( vals{:} );
  
  addsetcat( permlabs, slopecat, 'shuffled' );
  shuf_slopes = zeros( iters, 1 );
  
  for j = 1:iters
    fake_ns = matched_ns(randperm(numel(matched_ns)));
    
    p = polyfit( vals, fake_ns, 1 );
    
    slopes(stp) = p(1);
    stp = stp + 1;
    shuf_slopes(j) = p(1);
  end 
  
  append1( slopelabs, permlabs, I{i}, iters );
  
  %   real val
  realp = polyfit( vals, matched_ns, 1 );
  real_slope = realp(1);
  slopes(stp) = real_slope;
  stp = stp + 1;
  
  append1( slopelabs, setcat(permlabs, slopecat, 'real'), I{i} );
  
  %   test
  s = sign( real_slope );
  
  if ( s == 1 )
    %   real slope is positive
    testdat(i) = sum( shuf_slopes > real_slope ) / iters;
  else
    assert( s == -1 );
    %   real slope is negative
    testdat(i) = sum( shuf_slopes < real_slope ) / iters;
  end
  
  append1( testlabs, permlabs, I{i} );
end

toc;
%%
tblspec = dsp3.nonun_or_all( testlabs, permspec );
[t, rc] = tabular( testlabs, tblspec );

tbl = fcat.table( cellrefs(testdat, t), rc{:} );

if ( do_save )
  prefix = sprintf( '%s_permutation_table', base_prefix );
  dsp3.savetbl( tbl, analysis_p, testlabs, permspec, prefix );
end

end
