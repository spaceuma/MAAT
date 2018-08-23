function [SN,SNrad]=sn_det_psf(S,Sigma,B,R,Radius)
% Calculate S/N for detection of a Gaussian PSF
% Package: telescope.sn
% Description: Calculate the S/N (signal-to-noise ratio) for a point
%              source with a symmetric Gaussian profile for PSF (optimal)
%              detection.
%              Note this is different than PSF photometry (see
%              sn_psf_phot.m).
% Input  : - Source signal [electrons].
%          - Sigma of PSF [pixels].
%          - Background [e/pix].
%          - Readout noise [e].
%          - PSF radius [pix]. Default is 20.
% Output : - Theoretical S/N of PSF photometry (with radius
%            from 0 to infinity).
%          - S/N of PSF photometry with PSF truncated at Radius.
% License: GNU general public license version 3
% Tested : Matlab R2014a
%     By : Eran O. Ofek                    Aug 2015
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: SN=telescope.sn.sn_det_psf(1000,1,500,10)
% Reliable: 2
%--------------------------------------------------------------------------

if (nargin==4),
    Radius = 20;
end


SN = sqrt(S.^2./(4.*pi.*(B+R.^2).*Sigma.^2));

SNrad = sqrt(S.^2.*(1 - exp(-(Radius./Sigma).^2))./(4.*pi.*(B+R.^2).*Sigma.^2));