function req_savefig(post_plot_func_args, p, varargin)

%   REQ_SAVEFIG -- Call dsp3.req_savefig from post_plot_func
%
%     dsp3.util.post_plot.req_savefig( args, p ); extracts the figure
%     handle, fcat labels, and category specifiers from `args`, as provided 
%     to the post_plot_func callback in dsp3.multi_plot, and then saves the 
%     figure in the directory given by `p`.
%
%     dsp3.util.post_plot.req_savefig( args, p, ... ); provides additional
%     inputs to dsp3.req_savefig. See the documentation for that function
%     for valid inputs. Note that category specifiers are already provided.
%
%     See also dsp3.multi_plot, dsp3.req_savefig.

[fig, labs, spec] = dsp3.util.post_plot.fig_labels_specificity( post_plot_func_args{:} );
dsp3.req_savefig( fig, p, labs, spec, varargin{:} );

end