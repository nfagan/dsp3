function plot_agent_selective_psth(targ_psth, targ_labels, t, varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
params = dsp3.parsestruct( defaults, varargin );

make_plot( targ_psth, targ_labels', t, params );

end

function make_plot(psth, labels, t, params)

mask = fcat.mask( labels ...
  , @findnone, 'errors' ...
  , @find, {'choice'} ...
);

[unit_I, unit_C] = findall( labels, {'unit_uuid', 'region'}, mask );

for i = 1:numel(unit_I)
  reg = unit_C{2, i};
  
  pl = plotlabeled.make_common();
  pl.x = t(1, :);
  pl.group_order = { 'self', 'both', 'other', 'none' };
  pl.add_smoothing = true;
  pl.smooth_func = @(x) smooth( x, 5 );
  
  gcats = { 'outcomes' };
  pcats = { 'agent_selectivity', 'unit_uuid', 'region' };
  
  pltdat = psth(unit_I{i}, :);
  pltlabs = labels(unit_I{i});
  
  axs = pl.lines( pltdat, pltlabs, gcats, pcats );
  
  if ( params.do_save )
    plot_p = get_plot_p( params, reg );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, plot_p, prune(pltlabs), pcats );
  end
end

end

function plot_p = get_plot_p(params, varargin)

plot_p = fullfile( dsp3.dataroot(params.config), 'plots' ...
  , 'cell_type_agent_specificity', dsp3.datedir, 'psth', params.base_subdir, varargin{:} );

end

