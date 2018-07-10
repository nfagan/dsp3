conf = dsp3.config.load();
consolidated = dsp3.get_consolidated_data();

%%

import shared_utils.io.fullfiles;

epochs = { 'targacq' };
drug_type = 'nondrug';
manip = 'pro_v_anti';
meas_types = { 'z_scored_raw_power', 'z_scored_coherence' };

p = fullfiles( conf.PATHS.dsp2_analyses, meas_types, epochs, drug_type, manip );
p = p( cellfun(@shared_utils.io.dexists, p) );

plot_p = dsp3.plotp( {'spectra', dsp3.datedir()} );

mats = shared_utils.io.find( p, '.mat' );

%%

cfunc = @shared_utils.char.contains;

labs = cell( size(mats) );
dat = cell( size(labs) );
freqs = [];
t = [];

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  file = mats{i};
  
  if ( cfunc(file, 'coherence') )
    meas_t = 'coherence';
  elseif ( cfunc(file, 'raw_power') )
    meas_t = 'rawpower';
  else
    error( 'Failed to parse meas type from filename.' );
  end
  
  meas = shared_utils.io.fload( file );
  
  t = meas.get_time_series();
  freqs = meas.frequencies;
  
  t_ind = t >= -500 & t <= 500;
  f_ind = freqs <= 100;
  
  lab = fcat.from( meas.labels );
  setcat( addcat(lab, 'measure'), 'measure', meas_t );  
  
  labs{i} = lab;
  dat{i} = meas.data(:, f_ind, t_ind);
  
  freqs = freqs(f_ind);
  t = t(t_ind);
end

labels = vertcat( fcat(), labs{:} );
data = vertcat( dat{:} );

assert_rowsmatch( data, labels );
assert( size(data, 2) == numel(freqs) );
assert( size(data, 3) == numel(t) );

replace( labels, 'selfMinusBoth', 'anti' );
replace( labels, 'otherMinusNone', 'pro' );

%%

do_save = false;
prefix = 'z_spectra';

pltdat = data;
pltlabs = labels';

mask = find( pltlabs, {'choice', 'coherence'} );

t_ind = t >= -500 & t <= 500;
f_ind = true( size(freqs) );
p_freqs = freqs(f_ind);
p_t = t(t_ind);

pl = plotlabeled.make_spectrogram( p_freqs, p_t );
pl.panel_order = { 'pro', 'anti' };
pl.c_lims = [ -0.2, 0.2 ];

pcats = { 'measure', 'outcomes', 'regions', 'trialtypes' };

axs = pl.imagesc( pltdat(mask, f_ind, t_ind), pltlabs(mask), pcats );

shared_utils.plot.fseries_yticks( axs, round(flip(p_freqs)), 5 );
shared_utils.plot.tseries_xticks( axs, p_t, 5 );

if ( do_save )
  shared_utils.io.require_dir( plot_p );
  fname = sprintf( '%s_%s', prefix, dsp3.fname(pltlabs, pcats, mask) );
  dsp3.savefig( gcf, fullfile(plot_p, fname) );
end

%%  lines, over freqs

do_save = false;
prefix = 'z_lines';

t_ind = t >= -250 & t <= 0;
t_meaned = squeeze( nanmean(data(:, :, t_ind), 3) );

pltdat = t_meaned;
pltlabs = labels';

mask = find( pltlabs, {'choice', 'rawpower'} );

pl = plotlabeled.make_common();
pl.group_order = { 'pro', 'anti' };
pl.x = freqs;
pl.y_lims = [ -0.25, 0.25 ];

pcats = { 'measure', 'regions', 'trialtypes' };
gcats = { 'outcomes' };

axs = pl.lines( pltdat(mask, :), pltlabs(mask), gcats, pcats );

arrayfun( @(x) xlabel(x, 'Hz'), axs );

if ( do_save )
  shared_utils.io.require_dir( plot_p );
  fname = sprintf( '%s_%s', prefix, dsp3.fname(pltlabs, pcats, mask) );
  dsp3.savefig( gcf, fullfile(plot_p, fname) );
end

%%  lines, over time

do_save = false;
prefix = 'z_lines_overtime';

[bands, bandnames] = dsp3.get_bands();
[pltdat, pltlabs] = dsp3.get_band_means( data, labels', freqs, bands, bandnames );

mask = find( pltlabs, {'choice', 'rawpower'} );

pl = plotlabeled.make_common();
pl.one_legend = true;
pl.x = t;
pl.y_lims = [ -0.5, 0.5 ];
pl.group_order = { 'pro', 'anti' };

pcats = { 'measure', 'regions', 'trialtypes', 'bands' };
gcats = { 'outcomes' };

axs = pl.lines( pltdat(mask, :), pltlabs(mask), gcats, pcats );

arrayfun( @(x) xlabel(x, sprintf('ms from %s', char(pltlabs('epochs')))), axs );

if ( do_save )
  shared_utils.io.require_dir( plot_p );
  fname = sprintf( '%s_%s', prefix, dsp3.fname(pltlabs, pcats, mask) );
  dsp3.savefig( gcf, fullfile(plot_p, fname) );
end


