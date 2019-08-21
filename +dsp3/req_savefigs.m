function req_savefigs(figs, p, labs, varargin)

%   REQ_SAVEFIGS -- Save multiple figures.
%
%     See also dsp3.req_savefig, dsp3.multi_plot

validateattributes( labs, {'cell'}, {'numel', numel(figs)}, mfilename, 'figure labels' );

for i = 1:numel(figs)
  dsp3.req_savefig( figs(i), p, labs{i}, varargin{:} );
end

end