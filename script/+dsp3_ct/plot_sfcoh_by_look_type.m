conf = dsp3.set_dataroot( '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/' );
[coh, coh_labs, freqs, t] = dsp3_sfq.load_per_day_sfcoh( conf );

look_outs = dsp3_find_iti_looks( ...
    'config', conf ...
  , 'require_fixation', false ...
  , 'look_back', -3.3 ...
  , 'is_parallel', true ...
);

labels = dsp3_add_iti_first_look_labels( look_outs.labels', look_outs, 0.15 );

%%

new_labs = dsp3_ct.add_first_look_labels_to_sfcoh( coh_labs', labels );
dsp3_ct.add_site_labels( new_labs );

setcat( new_labs, 'duration', 'long_enough__true', find(new_labs, 'no_look') );

%%

require_all_sites = false;
keep_prop = 0.2;

f_ind = freqs >= 10 & freqs <= 100;
t_ind = t >= -300 & t <= 300;

site_mask = fcat.mask( new_labs ...
  , @find, {'choice', 'selected-site'} ...
  , @findnone, 'errors' ...
);

site_spec = dsp3_ct.site_specificity();
look_spec = csunion( site_spec, {'duration', 'looks_to'} );

site_I = findall( new_labs, site_spec, site_mask );
all_to_keep = {};
for i = 1:numel(site_I)
  no_look_ind = find( new_labs, 'no_look', site_I{i} );
  rest_ind = setdiff( site_I{i}, no_look_ind );
  num_to_keep = ceil( numel(no_look_ind) * keep_prop );
  to_keep = sort( no_look_ind(randperm(numel(no_look_ind), num_to_keep)) );
  all_to_keep{end+1, 1} = sort( [to_keep; rest_ind] );
end

site_mask = vertcat( all_to_keep{:} );

if ( require_all_sites )
  [site_coh, site_labs] = dsp3_ct.site_meaned_sfcoh( coh, new_labs', site_mask );
  
  [~, missing_removed] = dsp3_ct.remove_missing_sites( site_coh, site_labs' );
  present_sites = combs( missing_removed, 'sites' );
  present_ind = find( site_labs, present_sites );

  site_mask = find( new_labs, present_sites, site_mask );
end

[site_coh, site_labs] = dsp3_ct.site_meaned_sfcoh( coh, new_labs', site_mask, look_spec );

site_coh = site_coh(:, f_ind, t_ind);
plt_f = freqs(f_ind);
plt_t = t(t_ind);

%%

tmp_coh = site_coh;
tmp_labs = site_labs';

do_save = true;
plot_p = char( dsp3.plotp({'sfcoh_by_gaze', dsp3.datedir, 'spectra'}) );

pro_v_anti = true;
pro_minus_anti = false;

clims = [-0.02, 0.02];

proanti_each = setdiff( look_spec, 'outcomes' );

if ( pro_v_anti )
  [tmp_coh, tmp_labs] = dsp3.pro_v_anti( tmp_coh, tmp_labs', proanti_each );
end
if ( pro_minus_anti )
  [tmp_coh, tmp_labs] = dsp3.pro_minus_anti( tmp_coh, tmp_labs', proanti_each );
end

fig_cats = { 'trialtypes', 'looks_to' };
pcats = { 'outcomes', 'regions', 'trialtypes', 'looks_to' };

formats = { 'epsc', 'png', 'fig', 'svg' };

plt_mask = fcat.mask( tmp_labs ...
  , @find, {'long_enough__true'} ...
);

fig_I = findall_or_one( tmp_labs, fig_cats, plt_mask );

store_labs = cell( size(fig_I) );
store_axs = cell( size(fig_I) );
figs = gobjects( size(fig_I) );

pl = plotlabeled.make_spectrogram( plt_f, plt_t );

for i = 1:numel(fig_I)
  fig = figure(i);
  pl.fig = fig;
  
  plt_coh = tmp_coh(fig_I{i}, :, :);
  plt_labs = prune( tmp_labs(fig_I{i}) );

  axs = pl.imagesc( plt_coh, plt_labs, pcats );
  shared_utils.plot.hold( axs, 'on' );
  
  shared_utils.plot.tseries_xticks( axs, plt_t );
  shared_utils.plot.fseries_yticks( axs, round(flip(plt_f)), 5 );
  shared_utils.plot.add_vertical_lines( axs, find(plt_t == 0) );
  
%   shared_utils.plot.set_clims( axs, [-15e-3, 15e-3] );
  
  store_axs{i} = axs(:);
  store_labs{i} = plt_labs;
  figs(i) = fig;
end

axs = vertcat( store_axs{:} );

if ( isempty(clims) )
  shared_utils.plot.match_clims( axs );
else
  shared_utils.plot.set_clims( axs, clims );
end

if ( do_save )
  for i = 1:numel(fig_I)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), plot_p, store_labs{i}, pcats, '', formats ); 
  end
end