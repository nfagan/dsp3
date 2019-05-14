function f = make_filename(labels, existing_filenames)

%   MAKE_FILENAME -- Make string from most significant categories.
%
%     filename = dsp3.make_filename( labels ); creates a string suitable
%     for use as a filename by joining entries in the most significant
%     category(ies) of `labels`. If `labels` is empty, then `filename` is
%     the empty string ('').
%
%     filename = dsp3.make_filename( ..., existing ); creates a string such
%     that `filename` is not one of the entries of `existing`.
%
%     EX //
%
%       f1 = dsp3.make_filename( fcat.example )
%       f2 = dsp3.make_filename( fcat.example, f1 )
%
%     See also dsp3.most_significant_categories, fcat

if ( nargin < 2 || (~ischar(existing_filenames) && isempty(existing_filenames)) )
  existing_filenames = {};
else
  existing_filenames = cellstr( existing_filenames );
end

f = '';
category_indices = 1;

possible_categories = dsp3.most_significant_categories( labels, ncats(labels) );

while ( numel(category_indices) <= numel(possible_categories) )
  f = get_filename( labels, possible_categories(category_indices) );
  
  if ( ~file_exists(f, existing_filenames) )
    return
  end
  
  category_indices(end+1) = category_indices(end) + 1;
end

f = force_make_unique( f, existing_filenames );

end

function f = force_make_unique(f, existing_filenames)

tmp_f = f;
stp = 1;

while ( file_exists(tmp_f, existing_filenames) )
  tmp_f = sprintf( '%s%d', f, stp );
  stp = stp + 1;
end

f = tmp_f;

end

function tf = file_exists(filename, existing)

tf = any( strcmpi(existing, filename) );

end

function c = minimize_total_length(c, target_length)

total_length = sum( reshape(cellfun(@numel, c), [], 1) );
total_length = total_length + numel( c ) - 1; % n-1 join characters

if ( total_length <= target_length )
  return
end

factor = floor( total_length / target_length );

if ( factor <= 1 )
  return
end

for i = 1:numel(c)
  n_c = numel( c{i} );
  keep_n = min( ceil(n_c / factor), n_c );
  
  c{i} = c{i}(1:keep_n);  
end

end

function f = get_filename(labels, cats)

prefer_length_less_than = 75;

c = minimize_total_length( unique(combs(labels, cats)), prefer_length_less_than );
f = fcat.trim( strjoin(unique(c), '-') );

end