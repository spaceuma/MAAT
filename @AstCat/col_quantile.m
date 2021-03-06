function Y=col_quantile(AstC,P,Cols)
% Calculate the quantile for each column in an AstCat object.
% Package: @AstCat
% Description: Calculate the quantile for each column in an AstCat
%              object.
% Input  : - An AstCat object with a single element.
%          - Fraction (between 0 and 1) at which to return the value at
%            which the cumulative distribution of each column is equal
%            to this fraction. Seee quantile.m for additional details.
%          - Columns of AstCat on which to calculate the quantile.
%            This is either a cell array of column names or vector of
%            column indices. If empty use all columns. Default is empty.
% Output : - Vector of quantiles. Element per column.
% License: GNU general public license version 3
% Tested : Matlab R2015b
%     By : Eran O. Ofek                    Mar 2016
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: col_quantile(AstC,0.3,[1 2]);
% Reliable: 2
%--------------------------------------------------------------------------

if (nargin<3),
    Cols = [];
end

if (numel(AstC)>1),
    error('AstCat must contain a single element');
end


if (isempty(Cols)),
    Y      = quantile(AstC.Cat,P);
else
    ColInd = colname2ind(AstC,Cols);
    Y      = quantile(AstC.Cat(:,ColInd),P);
end
