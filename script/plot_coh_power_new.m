conf = dsp3.config.load();
conf.PATHS.data_root = '/Volumes/172.28.142.122/dsp3';

d1 = 'at_coherence/nondrug/targacq';
d2 = 'at_raw_power/nondrug/targacq';

meas_ps = cellfun( @(x) dsp3.get_intermediate_dir(x, conf), {d1, d2}, 'un', 0 );

mats = shared_utils.io.find( meas_ps, '.mat' );

dat = cell( size(mats) );
labs = fcat.empties( size(dat) );
freqs = cell( size(dat) );
t = cell( size(dat) );

for i = 1:numel(mats)
  dsp3.progress( i, numel(mats) );
  xp = shared_utils.io.fload( mats{i} );
  
  fs = xp.measure.frequencies;
  ts = xp.measure.get_time_series();
  c_dat = xp.measure.data;
  
  f_ind = fs >= 0 & fs <= 100;
  t_ind = ts >= -500 & ts <= 500;
  
  c_dat = c_dat(:, f_ind, t_ind);
  
  dat{i} = c_dat;
  labs{i} = fcat.from( xp.measure.labels );
  freqs{i} = fs(f_ind);
  t{i} = ts(t_ind);
end

dat = vertcat( dat{:} );
labs = vertcat( fcat(), labs{:} );

t = t{1};
freqs = freqs{1};

%%

tic;

f_ind = freqs >= 0 & freqs <= 100;
t_ind = t >= -500 & t <= 500;

mask = find( labs, 'pre' );
% mask = 1:length(labs);

I = find( ~trueat(labs, findor(labs, {'errors', 'cued'})) );
I = intersect( I, mask );

sub_spec = { 'sites', 'channels', 'regions', 'days', 'administration' };

[sublabs, ind] = keepeach( labs', sub_spec, I );
subdat = zeros( [numel(ind)*2, notsize(dat, 1)] );
repmat( sublabs, 2 );

for i = 1:numel(ind)
  c_ind = ind{i};
  
  s_ind = find( labs, 'self', c_ind );
  b_ind = find( labs, 'both', c_ind );
  o_ind = find( labs, 'other', c_ind );
  n_ind = find( labs, 'none', c_ind );
  
  sb = nanmean( rowref(dat, s_ind), 1 ) - nanmean( rowref(dat, b_ind), 1 );
  on = nanmean( rowref(dat, o_ind), 1 ) - nanmean( rowref(dat, n_ind), 1 );
  
  sb_row = i;
  on_row = i + numel(ind);
  
  subdat(sb_row, :, :) = sb;
  subdat(on_row, :, :) = on;
end

setcat( sublabs, 'outcomes', 'self - both', 1:numel(ind) );
setcat( sublabs, 'outcomes', 'other - none', numel(ind)+1:length(sublabs) );

toc;

%%

import shared_utils.plot.tseries_xticks;
import shared_utils.plot.fseries_yticks;
import shared_utils.plot.add_vertical_lines;

pltspec = { 'outcomes', 'regions', 'trialtypes', 'administration', 'drugs' };

% pltdat = rowref(dat, I);
% pltlabs = labs(I);

pltdat = subdat;
pltlabs = sublabs';

pltdat = pltdat(:, f_ind, t_ind);

cmap = 'jet';

xtick_spc = 5;
ytick_spc = 10;

invert_y = true;
plt_freqs = round( freqs(f_ind) );

if ( invert_y ), plt_freqs = flipud( plt_freqs ); end

pl = plotlabeled();
pl.summary_func = @plotlabeled.nanmean;
pl.invert_y = invert_y;
pl.smooth_func = @(x) imgaussfilt(x, 2);
pl.add_smoothing = true;
% pl.mask = find( pltlabs, 'acc' );
pl.mask = '';
% pl.shape = [4, 2];

axs = imagesc( pl, pltdat, pltlabs, pltspec );
set( axs, 'nextplot', 'add' );

ind0 = find( t(t_ind) == 0 );

tseries_xticks( axs, t(t_ind), xtick_spc );
fseries_yticks( axs, plt_freqs, ytick_spc );
add_vertical_lines( axs, ind0, 'k--' );

arrayfun( @(x) colormap(x, cmap), axs );
