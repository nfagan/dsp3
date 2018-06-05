conf = dsp3.config.load();

xcorr_mats = dsp3.require_intermediate_mats( 'xcorr/nonref/targacq' );

plot_p = fullfile( conf.PATHS.data_root, 'plots', 'xcorr', datestr(now, 'mmddyy') );

%%
got_lags = false;

values = [];
labs = fcat();

for i = 1:numel(xcorr_mats)
  dsp3.progress( i, numel(xcorr_mats) );
  
  xcorr_file = shared_utils.io.fload( xcorr_mats{i} );
  
  if ( ~got_lags )
    lags = xcorr_file.data{1}.lags;
    got_lags = true;
  end
  
  vals = cell2mat( cellfun(@(x) x.value, xcorr_file.data, 'un', false) );
  
  I = find( xcorr_file.labels, 'bla_acc' );
  
  values = [ values; vals(I, :) ];
  append( labs, xcorr_file.labels(I) );
end

%%

drug_type = 'nondrug';

cont = Container( values, SparseLabels.from_fcat(labs) );
cont = dsp3.get_subset( cont, drug_type, {'days', 'sites', 'channels', 'regions', 'bands'} );

%%

ref_type = 'nonreference';

[blalabs, I] = only( fcat.from(cont.labels), {'bla_acc', 'choice'} );
bladat = cont.data(I, :);

[~, I] = remove( blalabs, 'errors' );
bladat = bladat(I, :);

setcat( addcat(blalabs, 'ref_type'), 'ref_type', ref_type );

%%

specificity = { 'bands', 'regions', 'days', 'administration', 'outcomes', 'trialtypes', 'epochs' };
[meanlabs, I] = keepeach( blalabs', specificity );
meandat = rownanmean( bladat, I );

blalabeled = labeled( meandat, meanlabs );

%%

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.x = lags;
pl.one_legend = true;

figure(1);
clf();

lines_are = { 'outcomes' };
panels_are = { 'bands', 'trialtypes', 'regions', 'administration' };

axs = pl.lines( blalabeled, lines_are, panels_are );

arrayfun( @(x) set(x, 'nextplot', 'add'), axs );
shared_utils.plot.add_vertical_lines( axs, 0 );

fname = joincat( getlabels(blalabeled), {'outcomes', 'ref_type', 'bands', 'trialtypes', 'regions'} );

shared_utils.io.require_dir( plot_p );

shared_utils.plot.save_fig( gcf, fullfile(plot_p, fname), {'epsc', 'png', 'fig'}, true );

