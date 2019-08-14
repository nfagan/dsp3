function defaults = psd(varargin)

defaults = dsp3.get_common_lfp_defaults( dsp3.get_common_make_defaults(varargin{:}) );
defaults.transform_func = @(x) x;
defaults.reference_func = @dsp3.ref_subtract;

end