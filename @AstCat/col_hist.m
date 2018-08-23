function [N,X]=col_hist(AstC,Col,varargin)
% Run hist on a column in an AstCat object.
% Package: @AstCat
% Description: Run the hist.m function on a column in
%              an AstCat class.
% Input  : - A single element AstCat object.
%          - Column name or index on which to calculate the
%            histogram.
%          * Additional arguments to pass to the hist.m
%            function.
% Output : - Number of elements in each bin.
%          - Bin position.
% License: GNU general public license version 3
% Tested : Matlab R2015b
%     By : Eran O. Ofek                    Mar 2016
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: [N,X]=col_hist(AstC,'XWIN_IMAGE')
% Reliable: 
%--------------------------------------------------------------------------



if (numel(AstC)>1),
    error('hist on AstCat works on a single element AstCat');
end

ColInd = colname2ind(AstC,Col);
Val = AstC.Cat(:,ColInd);
if (istable(Val)),
    Val = table2array(Val);
end
[N,X] = hist(Val,varargin{:});



