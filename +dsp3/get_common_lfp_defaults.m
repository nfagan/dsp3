function defaults = get_common_lfp_defaults(defaults)

if ( nargin == 0 )
  defaults = struct();
end

defaults.chronux_params = struct( 'Fs', 1e3, 'tapers', [1.5, 2] );
defaults.filter = true;
defaults.reference_subtract = true;
defaults.f1 = 2.5;
defaults.f2 = 250;
defaults.filter_order = 2;
defaults.sample_rate = 1e3;

end