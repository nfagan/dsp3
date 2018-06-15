meas = 'z_raw_power';
manip = 'pro_v_anti';
drug_type = 'nondrug';
epoch = 'targacq';

mats = dsp3.require_intermediate_mats( fullfile(meas, drug_type, manip, epoch) );

zlabels = fcat();
zdata = [];

for i = 1:numel(mats)
  dsp3.progress( i, numel(mats) );
  
  meas_file = shared_utils.io.fload( mats{i} );
  
  append( zlabels, fcat.from(meas_file.zlabels, meas_file.zcats) );
  zdata = [ zdata; meas_file.zdata ];
  freqs = meas_file.frequencies;
  t = meas_file.time;
end

%%

mean_spec = { 'contexts', 'trialtypes', 'regions' };

[meanlabs, I] = keepeach( zlabels', mean_spec );
meandat = rowop( zdata, I, @(x) nanmean(x, 1) );

%%

ts = [ -250, 0 ];
t_ind = t >= ts(1) & t <= ts(2);

tmeaned = squeeze( nanmean(zdata(:, :, t_ind), 3) );

pl = plotlabeled();
pl.fig = figure(2);
pl.x = freqs;
pl.error_func = @plotlabeled.nansem;
% pl.y_lims = [-0.3, 0.3];

plt = labeled( tmeaned, zlabels );

axs = pl.lines( plt, 'contexts', {'trialtypes', 'regions'} );

arrayfun( @(x) xlim(x, [0, 100]), axs );
arrayfun( @(x) set(x, 'nextplot', 'add'), axs );
arrayfun( @(x) plot(x, get(x, 'xlim'), [0, 0]), axs );

%%

cont = SignalContainer( meandat, SparseLabels.from_fcat(meanlabs) );
cont.frequencies = freqs;
cont.start = t(1);
cont.stop = t(end);
cont.step_size = t(2)-t(1);

%%

f = figure(1);
clf();

cont.spectrogram( {'contexts', 'regions'} ...
  , 'shape', [2, 2] ...
  , 'frequencies', [0, 100] ...
);