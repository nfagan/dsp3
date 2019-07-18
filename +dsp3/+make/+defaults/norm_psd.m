function defaults = norm_psd(varargin)

defaults = dsp3.get_common_make_defaults( varargin{:} );
defaults.norm_func = @rdivide;

end