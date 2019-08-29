function f = make_req_savefig(save_p, varargin)

args = varargin;
f = @(varargin) dsp3.util.post_plot.req_savefig( varargin, save_p, args{:} );

end

function varargout = pass_outputs(plot_func_args, save_p, varargin)

varargout = varargin(1:nargout);

end