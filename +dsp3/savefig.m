function savefig(f, p, formats, separate_dirs)

if ( nargin < 3 )
  formats = { 'epsc', 'png', 'fig' };
end

if ( nargin < 4 )
  separate_dirs = true;
end

shared_utils.plot.save_fig( f, p, formats, separate_dirs );

end