function labels = missing_labels(labs)

%   MISSING_LABELS -- Get labels that are not present entries in a category.
%
%     labels = missing_labels( labs ) returns the subset of labels in
%     `labs` that are not present entries in a category of `labs`; i.e.,
%     labels for which `count(labs, labels)` would return 0.
%
%     See also fcat/count, fcat/prune
%
%     IN:
%       - `labs` (fcat)
%     OUT:
%       - `labels` (cell array of strings, char)

labels = getlabs( labs );
labels( count(labs, labels) > 0 ) = [];

end