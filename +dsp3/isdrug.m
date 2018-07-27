function tf = isdrug(drug_type)

%   ISDRUG -- True if a drug_type represents drug data.
%
%     IN:
%       - `drug_type` (char)
%     OUT:
%       - `tf` (logical)

tf = any( strcmpi(drug_type, {'drug', 'drug_wbd'}) );

end