function defaults = coherence(varargin)

defaults = dsp3.get_common_lfp_defaults( dsp3.get_common_make_defaults(varargin{:}) );
defaults.transform_func = @(x) x;
defaults.step_size = 0.05;
defaults.reference_func = @dsp3.ref_subtract;

end