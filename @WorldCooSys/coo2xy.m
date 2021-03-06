function [Coo,Y]=coo2xy(Head,Long,Lat,Tol,OutType)
% Coordinate to X/Y given an WorldCooSys object.
% Package: @WorldCooSys
% Description: Given an WCS or HEAD object (or e.g., a SIM image, etc) read
%              the WCS from the header and convert Longitude/Latitude
%              to X/Y in the image plane.
%              Support SIP and PV distortions.
% Input  : - An HEAD object (or SIM, AstCat).
%          - Vector of Longitudes (e.g., RA)
%            [radian, sexagesimal string or vector] see convertdms.m
%          - Vector of Latitudes (e.g., Dec)
%            [radian, sexagesimal string or vector] see convertdms.m
%          - Tolerance value for the SIP distortion iterative computation
%            [pixels] (default value is 1e-4).
%          - Output type: 'astcat'|'struct'|'mat'.
%            Default is 'astcat'. However, if two ouput arguments are
%            requested than force ouput to 'mat'.
% Output : - Either an AstCat object or structure array with
%            the X/Y coordinates, or a vector of the X coordinates [pixel].
%          - Vector of Y [pixel].
% Tested : Matlab R2014a
%     By : Eran O. Ofek, Tali Engel        Dec 2014
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: Coo = coo2xy(S,1,[1;2;1.2]);
%          Coo = coo2xy(S(9),'09:42:24.887','+09:04:03.70');
%          [X,Y] = coo2xy(S(9),'09:42:24.887','+09:04:03.70');
% Reliable: 2
%--------------------------------------------------------------------------

Def.Tol     = 1e-4;        
Def.OutType = 'astcat';    % 'mat'|'struct'|'astcat' 
if (nargin==3)
    Tol     = Def.Tol;
    OutType = Def.OutType;
elseif (nargin==4)
    OutType = Def.OutType;
elseif (nargin==5)
    % do nothing
else
    error('Illegal number of input arguments');
end

if (isempty(Tol))
    Tol = Def.Tol;             
end

if (nargout>1)
    % if two output arguments
    % then force output to 'mat'
    OutType = 'mat';
end

% Get WCS from Header
if (HEAD.ishead(Head))
    % An HEAD object
    if (any(isempty_wcs(Head)))
        % The WorldCooSys is HEAD is empty
        Head = populate_wcs(Head);
    end
end
WCS = Head;

% convert Long/Lat to radinas
if (ischar(Long) || size(Long,2)==3)
    Long = celestial.coo.convertdms(Long,'gH','r');
end
if (ischar(Lat) || size(Lat,2)==4)
    Lat  = celestial.coo.convertdms(Lat,'gD','R');
end
% make sure that Long/Lat have the same size
if (numel(Long)~=numel(Lat))
    if (numel(Long)==1)
        Long = Long.*ones(size(Lat));
    elseif (numel(Lat)==1)
        Lat  = Lat.*ones(size(Long));
    else
        error('Axes have different lengths');
    end
end

% define output
Nwcs = numel(WCS);
switch lower(OutType)
    case 'astcat'
        Coo = AstCat(size(WCS));
    case 'struct'
        Coo = Util.struct.struct_def({'Cat','ColCell'},Nwcs,1);
    otherwise
        % do nothing
end
    

% for each Header
for Iwcs=1:1:Nwcs
    
    if (isnan(WCS(Iwcs).WCS.CTYPE1))
        % no valid WCS in header
        X = nan(size(Long));
        Y = nan(size(Lat));
    else
        ProjType1 = WCS(Iwcs).WCS.CTYPE1(6:8);   % see also read_ctype.m
        ProjType2 = WCS(Iwcs).WCS.CTYPE2(6:8);
        if (~strcmp(ProjType1,ProjType2))
            error('Axes have different projection types');
        end

        RAD = 180./pi;

        % sky to xy (distortion is not taken into account)
        %Long = convertdms(Long,'gH','r');
        %Lat  = convertdms(Lat,'gD','r');
        % transformation
        if (~strcmp(WCS(Iwcs).WCS.CUNIT1,WCS(Iwcs).WCS.CUNIT2))
            error('CUNIT1 must be identical to CUNIT2');
        end
        switch lower(WCS(Iwcs).WCS.CUNIT1)
            case {'deg','degree'}
                Factor = RAD;
            case {'rad','radian'}
                Factor = 1;
            otherwise
                error('Unknown CUNIT option');
        end

        switch lower(ProjType1)
            case 'tan'
                if (size(Long,1)==1)
                    Long = Long.';
                end
                if (size(Lat,1)==1)
                    Lat = Lat.';
                end
                [DX,DY]=celestial.proj.pr_gnomonic(Long,Lat,1,[WCS(Iwcs).WCS.CRVAL1, WCS(Iwcs).WCS.CRVAL2]./Factor);
                XY     = bsxfun(@plus,(WCS(Iwcs).WCS.CD^-1)*[DX.';DY.'].*Factor,[WCS(Iwcs).WCS.CRPIX1; WCS(Iwcs).WCS.CRPIX2]);
                X0      = XY(1,:).';
                Y0      = XY(2,:).';
               %[X0,Y0] = sky2xy_tan(WCS,Long,Lat,HDUnum);
%             case 'sin'
%                 % SIN: Slant Ortographic
%                 if (size(Long,1)==1)
%                     Long = Long.';
%                 end
%                 if (size(Lat,1)==1)
%                     Lat = Lat.';
%                 end
%                 [DX,DY]=celestial.proj.pr_sin(Long,Lat,[WCS(Iwcs).WCS.CRVAL1, WCS(Iwcs).WCS.CRVAL2]./Factor);
%                 XY     = bsxfun(@plus,(WCS(Iwcs).WCS.CD^-1)*[DX.';DY.'].*Factor,[WCS(Iwcs).WCS.CRPIX1; WCS(Iwcs).WCS.CRPIX2]);
%                 X0      = XY(1,:).';
%                 Y0      = XY(2,:).';
            case 'ait'               
                if (WCS(Iwcs).WCS.CRVAL1~=0 || WCS(Iwcs).WCS.CRVAL2~=0)
                    error('This version does not support CRVAL ne 1');
                end
                [X,Y] = celestial.proj.pr_hammer_aitoff(Long,Lat,Factor);
                %Vec = WCS.CD*[X - WCS.CRPIX1;Y - WCS.CRPIX2]; 
                X0     = WCS(Iwcs).WCS.CRPIX1 + X./WCS.WCS.CDELT1;
                Y0     = WCS(Iwcs).WCS.CRPIX2 + Y./WCS.WCS.CDELT2;        
                %[X0,Y0] = sky2xy_ait(WCS,Long,Lat,HDUnum);
            otherwise
                error('Unsupported projection type: %s',ProjType1);
        end

        % in case distortion data is not given in header (in SIP notation)    
        if (~Util.struct.isfield_notempty(WCS(Iwcs).WCS,'sip'))
            X=X0;
            Y=Y0;
        else
            if (~isstruct(WCS(Iwcs).WCS.sip))
                X=X0;
                Y=Y0;
            else
                % if distortion data is given in the header using the SIP notation,
                % an iterative computation is required in order to get to the correct 
                % (x,y) coordinates.
                % The distortion keywords according to the SIP convention:
                % U,V: relative pixel coordinates with origin at CRPIX1 and CRPIX2
                % F(U,V),G(U,V): the distortion polynomial

                % initializations:        
                delU = 10;    
                delV = 10;     
                % convert to relative pixel coordinates
                U0 = X0 - WCS(Iwcs).WCS.CRPIX1;            % U0=U+f(U,V)
                V0 = Y0 - WCS(Iwcs).WCS.CRPIX2;            % V0=V+g(U,V)
                U1 = U0;                         % values of (U,V) at the first step of the iterative process.
                V1 = V0;

                % sip coefficients (from header)                
                Ap     = WCS(Iwcs).WCS.sip.Ap;
                Aq     = WCS(Iwcs).WCS.sip.Aq;
                Acoeff = WCS(Iwcs).WCS.sip.Acoeff;
                Bp     = WCS(Iwcs).WCS.sip.Bp;
                Bq     = WCS(Iwcs).WCS.sip.Bq;
                Bcoeff = WCS(Iwcs).WCS.sip.Bcoeff;

                F = zeros(length(Long),1);
                G = zeros(length(Long),1);

                iter = 1;

                while ((delU>Tol) || (delV>Tol))
                    iter = iter+1;                      % iter = 2,3,... since U0,V0 are considered as the result of the first iteration
                    % the distortion correction is different for each point (X(I),Y(I)):
                    for I = 1:length(U1)
                        F(I) = sum(Acoeff.*(U1(I).^Ap).*(V1(I).^Aq));
                        G(I) = sum(Bcoeff.*(U1(I).^Bp).*(V1(I).^Bq));
                    end        

                    U2 = U0 - F;                        % U2 = U0 - F(U1,V1)
                    V2 = V0 - G;                        % V2 = V0 - G(U1,V1)

                    delU = max(abs(U2-U1));  
                    delV = max(abs(V2-V1));  

                    U1 = U2;
                    V1 = V2;
                end

                X2 = U2 + WCS(Iwcs).WCS.CRPIX1;               
                Y2 = V2 + WCS(Iwcs).WCS.CRPIX2;               

                X = X2;                                    
                Y = Y2;

                % fprintf('convergence was achieved after %d iterations\n',iter);
            end
        end
    end

    switch lower(OutType)
        case 'astcat'
            Coo(Iwcs).Cat      = [X,Y];
            Coo(Iwcs).ColCell  = {'X','Y'};
            Coo(Iwcs).ColUnits = {'pix','pix'};
            Coo                = colcell2col(Coo);
        case 'struct'
            Coo(Iwcs).Cat     = [X,Y];
            Coo(Iwcs).ColCell = {'X','Y'};
        case 'mat'
            if (nargout<2)
                Coo = [X,Y];
            else
                Coo = X;
                %Y = Y;
            end
                
            if (Iwcs>1)
                warning('mat output is requested for multi element object - mat contains data from last object only');
            end
        otherwise
            error('Unknown OutType option');
    end
                
end



