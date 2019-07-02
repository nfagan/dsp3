function defaults = get_common_make_defaults()

defaults = struct();
defaults.files = [];
defaults.files_containing = [];
defaults.files_not_containing = [];
defaults.overwrite = false;
defaults.append = true;
defaults.save = true;
defaults.is_parallel = true;
defaults.config = dsp3.config.load();

end