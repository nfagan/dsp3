function tf = isnondrug(drug_type)

%   ISNONDRUG -- True if a drug_type represents non-drug data.
%
%     IN:
%       - `drug_type` (char)
%     OUT:
%       - `tf` (logical)

%   non-drug, non-drug with bad days
tf = any( strcmpi(drug_type, {'nondrug', 'nondrug_wbd'}) );

end