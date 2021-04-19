function Sim=flag_cr_mextractor(Sim,varargin)
% Flag cosmic rays (CR) in MASK images based on mextractor data.
% Package: @SIM
% Description: Flag cosmic rays (CR) in MASK images based on mextractor data.
% Input  : - A SIM object that contains a catalog generated by mextractor.
%          * Arbitrary number of pairs of arguments: ...,keyword,value,...
%            where keyword are one of the followings:
%            'Method' - One of the following CR detection method:
%                   'SN_UNFfit' - fit SN_UNF - SN vs. mag and select
%                             outliers below the line.
%                   'SN_UNF0'   - select SN_UNF - SN<0
%                   'chi2backcr' select based on difference between
%                             chi2back and chi2cr.
%                   'HT'        -
%            'FlagNameBitCR' - CR bit mask name.
%                   Default is 'Bit_CR'.
%            'ColX' - Column names in which to look for the X coordinate.
%                   Default is {'XWIN_IMAGE','X'}.
%            'ColY' - Column names in which to look for the Y coordinate.
%                   Default is {'YWIN_IMAGE','Y'}.
%            'ColMag'- Column names in which to look for the magnitude.
%                   Default is {'MAG_PSF','MAG_APER','MAG'}.
%            'Verbose' - Verbose. Default is false.
% Output : - A SIM object with the CR flagged in the MASK image.
% License: GNU general public license version 3
%     By : Eran O. Ofek                    Jul 2017
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: Sim=flag_cr_mextractor(Sim);
% Reliable: 2
%--------------------------------------------------------------------------

CatField    = AstCat.CatField;
ImageField  = SIM.ImageField;

DefV.Method               = 'SN_UNFfit';    % 'SN_UNF0' | 'SN_UNFfit' | 'HT'
DefV.FlagNameBitCR        = 'Bit_CR';
DefV.ColX                 = {'XWIN_IMAGE','X'};
DefV.ColY                 = {'YWIN_IMAGE','Y'};
DefV.ColMag               = {'MAG_PSF','MAG_APER','MAG'};
DefV.Verbose              = true;

InPar = InArg.populate_keyval(DefV,varargin,mfilename);



if (~all(isfield_populated(Sim,CatField)))
    error('Catalaog field in SIM object must be populated');
end


    
Nsim = numel(Sim);
for Isim=1:1:Nsim
    SizeIm = size(Sim(Isim).(ImageField));
    FlagIm = false(SizeIm);
    
    switch lower(InPar.Method)
        case 'sn_unf0'
            % select CR by : SN - SN_UNF<0
            
            Delta       = col_get(Sim(Isim),'SN') - col_get(Sim(Isim),'SN_UNF');
            Ind         = find(Delta<0);
            
            [~,ColIndX] = select_exist_colnames(Sim(Isim),InPar.ColX');
            [~,ColIndY] = select_exist_colnames(Sim(Isim),InPar.ColY');
            
            if (~isempty(Ind))
                X           = Sim(Isim).(CatField)(Ind,ColIndX);
                Y           = Sim(Isim).(CatField)(Ind,ColIndY);

                X = round(X);
                Y = round(Y);
                
                FlagInImage = X>0 & Y>0 & X<=SizeIm(2) & Y<=SizeIm(1);
                
                FlagIm(Y(FlagInImage),X(FlagInImage)) = true;
            end
            
        case 'sn_unffit'
            % select CR by fitting SN - SN_UNF and looking for outliers
            % below the fitted line
            
            [~,ColIndX]   = select_exist_colnames(Sim(Isim),InPar.ColX');
            [~,ColIndY]   = select_exist_colnames(Sim(Isim),InPar.ColY');
            [~,ColIndMag] = select_exist_colnames(Sim(Isim),InPar.ColMag');
            
            Delta       = col_get(Sim(Isim),'SN') - col_get(Sim(Isim),'SN_UNF');
            Mag         = col_get(Sim(Isim),ColIndMag);
           
            Iok = ~isnan(Mag) & Delta>0;
            P = polyfit(Mag(Iok),log10(Delta(Iok)),1);
            
            % 5 sigma threshold
            Thresh = 5;
            Ymag = polyval(P,Mag);
            Ind  = find(10.^Ymag - Thresh > Delta);
            
            if (~isempty(Ind))
                X           = Sim(Isim).(CatField)(Ind,ColIndX);
                Y           = Sim(Isim).(CatField)(Ind,ColIndY);

                X = round(X);
                Y = round(Y);
                
                FlagInImage = X>0 & Y>0 & X<=SizeIm(2) & Y<=SizeIm(1);
                
                FlagIm(Y(FlagInImage),X(FlagInImage)) = true;
                
            end
            
            
        case 'chi2backcr'
            % the difference: chi2back - chi2cr
            
            [~,ColIndX]   = select_exist_colnames(Sim(Isim),InPar.ColX');
            [~,ColIndY]   = select_exist_colnames(Sim(Isim),InPar.ColY');
            [~,ColIndMag] = select_exist_colnames(Sim(Isim),InPar.ColMag');

            Delta       = col_get(Sim(Isim),'PSF_CHI2BACK') - col_get(Sim(Isim),'PSF_CHI2CR');
            Mag         = col_get(Sim(Isim),ColIndMag);
           
            % The delta<5000 term is arbitrary...
            % in order to make the fit good for the faint mag
            
            
            
            %MaxDelta = 2000;
            Iok = ~isnan(Mag) & Delta>0;
            
            if (sum(Iok)<5)
                warning('Number of stars is too small - consider changing CR algorithm [dont use chi2backcr] or ignore CR');
            end
            
            B = timeseries.binning([Mag(Iok), Delta(Iok)],0.5,[NaN NaN],{'MidBin',@numel,@median,@Util.stat.rstd});
            if (~isempty(B))
                DeltaCalc = interp1(B(:,1),B(:,3),Mag);
                StdInt    = interp1(B(:,1),B(:,4),Mag,'nearest');
                Thresh    = 6;
                Ind       = find((Delta - DeltaCalc)>Thresh.*StdInt & StdInt>1e-5);

                if (~isempty(Ind))
                    X           = Sim(Isim).(CatField)(Ind,ColIndX);
                    Y           = Sim(Isim).(CatField)(Ind,ColIndY);

                    X = round(X);
                    Y = round(Y);

                    FlagInImage = X>0 & Y>0 & X<=SizeIm(2) & Y<=SizeIm(1);

                    FlagIm(Y(FlagInImage),X(FlagInImage)) = true;

                end
            else
                Ind = [];
                warning('Can not use flag_cr_mextractor - not enough stars');
            end
            
        case 'ht'
            error('HT option does not available yet');
            
            
            
        otherwise
            error('Uknown Method option');
    end
    
    if (InPar.Verbose)
        fprintf('%d CR flagged in image %d\n',numel(Ind),Isim);
    end
    
    % set bit mask
    Sim(Isim) = bitmask_set(Sim(Isim),FlagIm,InPar.FlagNameBitCR);
end

    
            
            