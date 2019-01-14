function out = simbin(mat1,mat2,type,mask)

% Computes 106 measures of similarity and dissimilarity (distance) between
% two binary matrices. Matrices can be any dimensions, but must have the
% same dimensions. A mask can be used to indicate the relevant elements of
% the matrices (needed when the measure takes into account elements present
% in neither binary object). See further information below (including next 
% to each measure). 
%
% IMPORTANT: naming conventions for certain measures (e.g., the 5 Sokal and
% Sneath measures) are inconsistent across different researchers, different
% formulas for the same 'measure' exist in the literature, and different 
% measures have similar names (e.g., Anderberg's vs. Anderberg's D). Thus, 
% you should check that the formula used below corresponds to the 
% particular measure that you wish to compute. 
%
% Usage: out = overlap_similarity(mat1,mat2,type,mask)
%           mat1: 1st binary matrix
%           mat2: 2nd binary matrix
%           type: measure of (dis)similarity to be used
%           mask: binary mask indicating relevant matrix elements
%
%
% Further Information:
%
% All measures are symmetric (i.e., it does not matter which matrix is mat1
% vs. mat 2) except:
%                    AD, AMPLE, BUB1, BUB2, cole, diceasym1, diceasym2,
%                    digby, fleiss, forbes, GKlambda, GKtau, GK2, Ko2, LH,
%                    MP, Pcs, Pmsc, Pei1, Pei2, PHI, PH, Q0, RDeprob, SS4,
%                    SS5, tarantula, YQ, YQD, YY
%
% Computation of these measures takes into account (in some way) the 
% elements present in neither binary object (i.e., d) (which may not be 
% optimal if you want a straightforward measure of overlap):
%                    AD, AMPLE, baulieu, bc, Bshape, BUB1, BUB2, CK, cole, 
%                    dennis, digby, disper, eyraud, faith, FD, fleiss, 
%                    GKlambda, GKtau, GK1, GK2, GK3, GK4, GLS, goodall, 
%                    gower, GW, hamann, HD, inprod, Kcam, Kpoai, LH, 
%                    meanman, michael, MK, MP, pattern, Pcs, Pmsc, Pei1, 
%                    Pei2, PHI, PH, Q0, RDeprob, Rpattern, RR, RT, scott, 
%                    SM, Spattern, SS1, SS3, SS4, SS5, Stau, stiles, 
%                    tarantula, tarwid, var, YQ, YQD, YY
%
% Positive monotomic relationship: bc, pattern
%                                  BSeuc, meanman, mirkin, var
%                                  BUB1, BUB2
%                                  DK, johnson
%                                  disper, MK, Stau
%                                  int, RR
%                                  hamann, inprod, SM
%                                  chord, hellinger
%                                  faith, tversky
%                          
% Negative monotomic relationship: BB with savage
%                                  BLWMN with dice
%                                  BSeuc, meanman, mirkin, and var with hamann, inprod, and SM
%                                  Bpattern with bc and pattern
%                                  Beuc with RT
%                                  steffensen with int and RR
%                                  YQ with YQD
%
% TAG:       MEASURE NAME:
% AMPLE      Analyzing Method Patterns to Locate Errors (Dallmeier et al, 2005) (similarity)
% AD         Anderberg's D (similarity)
% anderberg  Anderberg 1973 (similarity)
% baulieu    Baulieu 1989 (dissimilarity) (also called size difference)
% BB         Braun and Blanquet 1932 (similarity)
% bc         bc (dissimilarity)
% benini     Benini 1901 (similarity)
% Beuc       Binary euclidean distance (dissimilarity)
% BLWMN      Binary Lance and Williams nonmetric (dissimilarity) (also called Sokal and Sneath nonmetric or Bray and Curtis)
% Bpattern   Browsing pattern (similarity)
% BSeuc      Binary squared euclidean distance (dissimilarity) (also called Hamming, city block, Manhattan, or Filkov)
% Bshape     Binary shape (dissimilarity)
% BUB1       Baroni-Urbani and Buser 1976 1 (similarity)
% BUB2       Baroni-Urbani and Buser 1976 2 (similarity)
% chiY       Chi Square with correction of Yates 
% chord      Chord (dissimilarity)
% CK         Cohen's kappa (similarity)
% cole       Cole 1949 (similarity)
% dennis     Dennis (similarity)
% dice       Dice (similarity) (also called Nei and Lei's genetic coefficient, Czekanowski, or Sorenson, or Bray)
% diceasym1  Dice asymmetric 1 (similarity)
% diceasym2  Dice asymmetric 2 (similarity)
% digby      Digby 1983 (similarity)
% disper     Dispersion (similarity)
% DK         Driver and Kroeber 1932 (similarity) (also called Kulczynski 1927 2)
% eyraud     Eyraud 1936 (similarity)
% fager      Fager (similarity)
% faith      Faith (similarity)
% FaMc       Fager and McGowan 1963 (similarity)
% FD         Forbes 1907's D (similarity)
% fleiss     Fleiss 1975 (similarity)
% forbes     Forbes 1925 (similarity)
% fossum     Fossum (similarity) (also called Jones and Curtis)
% gilbert    Gilbert's coefficient (similarity)
% gini       Gini 1912 index (similarity)
% GK1        Goodman and Kruskal 1954 1 (similarity)
% GK2        Goodman and Kruskal 1954 2 (similarity)
% GK3        Goodman and Kruskal 1954 3 (similarity)
% GK4        Goodman and Kruskal 1954 4 (similarity)
% GKlambda   Goodman and Kruskal's lambda (similarity)
% GKtau      Goodman and Kruskal's tau (similarity)
% goodall    Goodall 1967's angular transformation of simple matching coefficient (similarity) (also called Austin and Colwell)
% gower      Gower (similarity)
% GW         Gilbert and Wells 1966 (similarity)
% hamann     Hamann 1961 (similarity)
% HD         Hawkins and Dotson 1975 (similarity)
% hellinger  Hellinger (dissimilarity)
% inprod     Inner product (similarity)
% int        Intersection of two masks (similarity)
% jaccard    Jaccard 1908 (similarity) (also called similarity ratio or Tanimioto)
% johnson    Johnson 1967 (similarity) (also called McConnaughey 1964)
% Kcam       Kuhns 1965's coefficient of arithmetic means (similarity)
% Ko1        Koppen 1884 (similarity)
% Ko2        Koppen 1870 (similarity)
% Kpoai      Kuhns 1965's proportion of overlap above independence (similarity)
% kulczynski Kulczynski 1927 1 (similarity)
% meanman    Mean Manhattan (dissimilarity) (also called Canberra or Sneath total difference)
% michael    Michael 1920 (similarity)
% mirkin     Mirkin (dissimilarity)
% MK         Maron and Kuhns 1960 (similarity)
% modgini    Modified gini index (similarity)
% mountford  Mountford 1962 (similarity)
% MP         Maxwell and Pilliner 1968 (similarity)
% ochiai     Ochiai 1957 (similarity) (also called Driver and Kroeber or Otsuka)
% pattern    Pattern (dissimilarity)
% Pcs        Pearson 1905 chi-square (similarity)
% Pei1       Peirce 1884 1 (similarity)
% Pei2       Peirce 1884 2 (similarity)
% PH         Pearson and Heron 1913 (similarity)
% PHI        Fourfold point correlation (similarity) (also called Pearson and Heron 1913)
% Pmsc       Pearson 1905's coefficient of mean square contingency (similarity)
% Q0         Q0 (Batagelj and Bren 1995) (dissimilarity)
% Rcost      R cost
% RDeprob    Relative decrease of error probability (similarity)
% Rpattern   Retrieval pattern (similarity)
% RR         Russell and Rao 1940 (similarity)
% RT         Rogers and Tanimoto 1960 (similarity)
% savage     Savage (dissimilarity)
% Scost      S cost
% scott      Scott 1955 (similarity)
% simpson    Simpson 1943's ecological coexistence coefficient (similarity) (also called overlap)
% SM         Sokal and Michener 1958's simple matching (similarity) (also called Rand or Kendall)
% soergel    Soergel distance
% sorensen   Sorensen 1948 (similarity)
% sorgenfrei Sorgenfrei 1958 (similarity) (also called Fowlkes-Mallows)
% Spattern   Sneath pattern difference (dissimilarity)
% SS1        Sokal and Sneath 1963 1 (similarity)
% SS2        Sokal and Sneath 1963 2 (similarity)
% SS3        Sokal and Sneath 1963 3 (similarity)
% SS4        Sokal and Sneath 1963 4 (similarity) (also called Anderberg)
% SS5        Sokal and Sneath 1963 5 (similarity) (also called Ochiai 2)
% Stau       Stuart's tau (similarity)
% steffensen Steffensen 1934 (dissimilarity)
% stiles     Stiles (similarity)
% Tcost      T combined cost
% tarantula  Tarantula (Jones et al., 2002 & 2005) (similarity)
% tarwid     Tarwid 1960 (similarity)
% tversky    Tversky 1977's feature contrast model (similarity)
% Ucost      U cost
% unigram    Unigram subtuples
% US         Upholt 1977's S
% US         Upholt 1977's F 
% var        Variance (dissimilarity)
% YQ         Yule 1911's Q coefficient of association (similarity)
% YQD        Yule's Q (Yule and Kendall, 1957) distance (dissimilarity)
% YY         Yule 1912's Y (or omega) coefficient of colligation (similarity)
% 
% 
% Author: Jeffrey M. Spielberg (jspielb2@gmail.com)
% Version: 05.06.16
% 
% WARNING: This is a beta version. There no known bugs, but only limited 
% testing has been perfomed. This software comes with no warranty (even the
% implied warranty of merchantability or fitness for a particular purpose).
% Therefore, USE AT YOUR OWN RISK!!!
%
% Copyleft 2014-2016. Software can be modified and redistributed, but 
% modifed, redistributed versions must have the same rights

mat1 = double(mat1>0);
mat2 = double(mat2>0);

if nargin==2||isempty(type)
    type = 'dice';
    mask = ones(size(mat1));
elseif nargin<4
    mask = ones(size(mat1));
elseif nargin==4
    mask = double(mask>0);
end

mat1  = mat1.*mask;
mat2  = mat2.*mask;
nmat1 = not(mat1).*mask;
nmat2 = not(mat2).*mask;

a = sumn(mat1.*mat2);
b = sumn(nmat1.*mat2);
c = sumn(mat1.*nmat2);
d = sumn(nmat1.*nmat2);
tot = a+b+c+d;
q = (a+b)*(a+c)*(b+d)*(c+d);

switch type
    case 'AD'           % Anderberg's D (similarity) (measures the reduction in error probability when one item is used to predict the other) (range: 0:1)
        t1  = max(a,b)+max(c,d)+max(a,c)+max(b,d);
        t2  = max((a+c),(b+d))+max((a+d),(c+d));
        out = (t1-t2)/(2*tot);
    case 'AMPLE'        % Analyzing Method Patterns to Locate Errors (Dallmeier et al, 2005) (similarity) (undefined when a+b and/or c+d are 0)
        out = abs((a/(a+b))-(c/(c+d)));
    case 'anderberg'    % Anderberg 1973 (similarity)
        out = (8*a)/((8*a)+b+c);
    case 'baulieu'      % Baulieu 1989 (dissimilarity) (also called size difference) (range: 0:Inf)
        out = ((b-c)^2)/(tot^2);
    case 'BB'           % Braun and Blanquet 1932 (similarity) (range: 0:1)
        out = a/max((a+b),(a+c));
    case 'bc'           % bc (dissimilarity)
        out = (4*b*c)/(tot^2);
    case 'benini'       % Benini 1901 (similarity)
        out = (a-((a+b)*(a+c)))/(a+min(b,c)-((a+b)*(a+c)));
    case 'Beuc'         % Binary euclidean distance (dissimilarity) (range: 0:Inf)
        out = sqrt(b+c);
    case 'BLWMN'        % Binary Lance and Williams nonmetric (dissimilarity) (also called Sokal and Sneath nonmetric or Bray and Curtis) (range: 0:1)
        out = (b+c)/((2*a)+b+c);
    case 'Bpattern'     % Browsing pattern (similarity)
        out = a-(b*c);
    case 'BSeuc'        % Binary squared euclidean distance (dissimilarity) (also called Hamming, city block, Manhattan, or Filkov) (range: 0:Inf)
        out = b+c;
    case 'Bshape'       % Binary shape (dissimilarity) (range: no limits)
        out = ((tot*(b+c))-((b-c)^2))/(tot^2);
    case 'BUB1'         % Baroni-Urbani and Buser 1976 1 (similarity) (range: 0:1)
        out = (sqrt(a*d)+a)/(sqrt(a*d)+a+b+c);
    case 'BUB2'         % Baroni-Urbani and Buser 1976 2 (similarity)
        out = (sqrt(a*d)+a-b-c)/(sqrt(a*d)+a+b+c);
    case 'chiY'         % Chi Square with correction of Yates
        out = (tot*(abs((a*d)-(b*c))-(tot/2))^2)/q;
    case 'chord'        % Chord (dissimilarity)
        out = sqrt(2*(1-(a/sqrt((a+b)*(a+c)))));
    case 'CK'           % Cohen's kappa (similarity)
        out = (2*((a*d)-(b*c)))/(((a+b)*(b+d))+((a+c)*(c+d)));
    case 'cole'         % Cole 1949 (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = ((a*d)-(b*c))/min(((a+b)*(a+c)),((b+d)*(c+d)));
    case 'dennis'       % Dennis (similarity)
        out = ((a*d)-(b*c))/sqrt(tot*(a+b)*(a+c));
    case 'dice'         % Dice (similarity) (also called Nei and Lei's genetic coefficient, Czekanowski, Sorenson, Bray, Upholt's F, Gower and Legendre's T, or percent positive agreement) (range: 0:1)
        out = (2*a)/((2*a)+b+c);
    case 'diceasym1'    % Dice asymmetric 1 (similarity)
        out = a/(a+c);
    case 'diceasym2'    % Dice asymmetric 2 (similarity)
        out = a/(a+b);
    case 'digby'        % Digby 1983 (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (((a*d)^(3/4))-((b*c)^(3/4)))/(((a*d)^(3/4))+((b*c)^(3/4)));
    case 'disper'       % Dispersion (similarity) (range: -1:1)
        out = ((a*d)-(b*c))/(tot^2);
    case 'DK'           % Driver and Kroeber 1932 (similarity) (also called Kulczynski 1927 2) (measures the conditional probability that both items are positive) (range: 0:1)
        out = (a/2)*((1/(a+b))+(1/(a+c)));
    case 'eyraud'       % Eyraud 1936 (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (a-((a+b)*(a+c)))/q;
        %out = ((tot^2)*((tot*a)-((a+b)*(a+c))))/q; % Alternative formula
    case 'fager'        % Fager (similarity)
        out = (a/sqrt((a+b)*(a+c)))-(1/(2*sqrt(min((a+b),(a+c)))));
        %out = (a/(((a+b)*(a+c))^2))-(max(b,c)/2); % Alternative formula
    case 'faith'        % Faith (similarity)
        out = (a+(0.5*d))/tot;
    case 'FaMc'         % Fager and McGowan 1963 (similarity)
        out = (a/sqrt((a+b)*(a+c)))-((a+max(b,c))/2);
    case 'FD'           % Forbes 1907's D (similarity) (also called Kocher and Wong)
        out = (a*tot)/((a+b)*(a+c));
    case 'fleiss'       % Fleiss 1975 (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (((a*d)-(b*c))*(((a+b)*(b+d))+((a+c)*(c+d))))/(2*q);
    case 'forbes'       % Forbes 1925 (similarity) (also called Loevinger's H) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = ((tot*a)-((a+b)*(a+c)))/((tot*min((a+b),(a+c)))-((a+b)*(a+c)));
        %out = ((tot*a)-((a+b)*(a+c)))/((tot*min(b,c))-((a+b)*(a+c))); % Alternative formula
    case 'fossum'       % Fossum (similarity) (also called Jones and Curtis)
        out = (tot*((a-0.5)^2))/((a+b)*(a+c));
    case 'gilbert'      % Gilbert's coefficient (similarity) (undefined under certain circumstances)
        out = (a-((a+b)*(a+c)))/(a+b+c-((a+b)*(a+c)));
    case 'gini'         % Gini 1912 index (similarity) (undefined under certain circumstances)
        out = (a-((a+b)*(a+c)))/sqrt((1-((a+b)^2))*(1-((a+c)^2)));
    case 'GKlambda'     % Goodman and Kruskal's lambda (similarity) (measures the proportional reduction in error using one item to predict another) (range: 0:1)
        t1  = max(a,b)+max(c,d)+max(a,c)+max(b,d);
        t2  = max((a+c),(b+d))+max((a+d),(c+d));
        out = (t1-t2)/((2*tot)-t2);
    case 'GKtau'        % Goodman and Kruskal's tau (similarity) (undefined when a+b and/or c+d are 0)
        out = (((((a-((a+b)*(a+c)))^2)+((b-((a+b)*(b+d)))^2))/(a+b))/(1-((a+c)^2)-((b+d)^2)))+(((((c-((a+c)*(c+d)))^2)+((d-((b+d)*(c+d)))^2))/(c+d))/(1-((a+c)^2)-((b+d)^2)));
    case 'GK1'          % Goodman and Kruskal 1 1954 (similarity)
        out = ((2*min(a,d))-b-c)/((2*min(a,d))+b+c);
    case 'GK2'          % Goodman and Kruskal 2 1954 (similarity)
        out = (max(a,c)+max(b,d)-max((a+b),(c+d)))/(1-max((a+b),(c+d)));
    case 'GK3'          % Goodman and Kruskal 3 1954 (similarity)
        out = (a+d-max(a,d)-((b+c)/2))/(1-max(a,d)-((b+c)/2));
    case 'GK4'          % Goodman and Kruskal 4 1954 (similarity)
        out = ((max(a,b)+max(c,d)+max(a,c)+max(b,d))/(2-max((a+c),(b+d))-max((a+b),(c+d))))-((max((a+c),(b+d))+max((a+b),(c+d)))/(2-max((a+c),(b+d))-max((a+b),(c+d))));
    case 'goodall'      % Goodall 1967's angular transformation of simple matching coefficient (similarity) (also called Austin and Colwell)
        out = asin(sqrt((a+d)/tot))/(50*pi);
    case 'gower'        % Gower (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (a+d)/sqrt(q);
    case 'GW'           % Gilbert and Wells 1966 (similarity) (undefined when a+b and/or a+c are 0)
        out = log((a*tot)/((a+b)*(a+c)));
    case 'hamann'       % Hamann 1961 (similarity) (range: -1:1)
        out = ((a+d)-(b+c))/tot;
    case 'HD'           % Hawkins and Dotson 1975 (similarity)
        out = 0.5*((a/(a+b+c))+(d/(b+c+d)));
    case 'hellinger'    % Hellinger (dissimilarity)
        out = 2*sqrt(1-(a/sqrt((a+b)*(a+c))));
    case 'inprod'       % Inner product (similarity)
        out = a+d;
    case 'int'          % Intersection of two masks (similarity)
        out = a;
    case 'jaccard'      % Jaccard 1908 (similarity) (also called similarity ratio or Tanimioto) (range: 0:1)
        out = a/(a+b+c);
    case 'johnson'      % Johnson 1967 (similarity) (also called McConnaughey 1964)
        out = (a/(a+b))+(a/(a+c));
    case 'Kcam'         % Kuhns 1965's coefficient of arithmetic means (similarity)
        out = (2*((a*d)-(b*c)))/(tot*((2*a)+b+c));
    case 'Ko1'          % Koppen 1884 (similarity)
        out = a+((b+c)/2);
    case 'Ko2'          % Koppen 1870 (similarity) (undefined when a+b and/or 1-a-b are 0)
        out = (((a+b)*(1-a-b))-c)/((a+b)*(1-a-b));
    case 'Kpoai'        % Kuhns 1965's proportion of overlap above independence (similarity) (undefined when a+c and/or a+c are 0)
        out = ((a*d)-(b*c))/(tot*(a/((a+b)*(a+c)))*((2*a)+b+c-(((a+b)*(a+c))/tot)));
    case 'kulczynski'   % Kulczynski 1927 1 (similarity) (range: 0:Inf)
        out = a/(b+c);
    case 'meanman'      % Mean Manhattan (dissimilarity) (also called Canberra or Sneath total difference)
        out = (b+c)/tot;
    case 'michael'      % Michael 1920 (similarity) (range: 0:1)
        out = (4*((a*d)-(b*c)))/(((a+d)^2)+((b+c)^2));
    case 'mirkin'       % Mirkin (dissimilarity)
        out = 2*(b+c);
    case 'MK'           % Maron and Kuhns 1960 (similarity)
        out = ((a*d)-(b*c))/tot;
    case 'modgini'      % Modified gini index (similarity)
        out = (a-((a+b)*(a+c)))/(1-(abs(b-c)/2)-((a+b)*(a+c)));
    case 'mountford'    % Mountford 1962 (similarity)
        out = a/((0.5*((a*b)+(a*c)))+(b*c));
    case 'MP'           % Maxwell and Pilliner 1968 (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (2*((a*d)-(b*c)))/q;
    case 'ochiai'       % Ochiai 1957 (similarity) (also called Driver and Kroeber or Otsuka) (binary form of cosine similarity) (range: 0:1)
        out = a/sqrt((a+b)*(a+c));
    case 'pattern'      % Pattern (dissimilarity) (range: 0:1)
        out = (b*c)/(tot^2);
    case 'Pcs'          % Pearson 1905 chi-square (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (tot*(((a*d)-(b*c))^2))/q;
    case 'Pmsc'         % Pearson 1905's coefficient of mean square contingency (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        ch2 = (tot*(((a*d)-(b*c))^2))/q;
        out = sqrt(ch2/(tot+ch2));
    case 'Pei1'         % Peirce 1884 1 (similarity) (undefined when a+c and/or b+d are 0)
        out = ((a*b)-(b*c))/((a+c)*(b+d));
    case 'Pei2'         % Peirce 1884 2 (similarity) (undefined when a+c and/or b+d are 0)
        out = ((a*b)+(b*c))/((a*b)+(2*b*c)+(c*d));
    case 'PHI'          % Fourfold point correlation (similarity) (also called Pearson and Heron 1913) (binary form of the Pearson product-moment correlation) range: 0:1) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = ((a*d)-(b*c))/sqrt(q);
    case 'PH'           % Pearson and Heron 1913 (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = cos((180*sqrt(b*c))/(sqrt(a*d)+sqrt(b*c)));
    case 'Q0'           % Q0 (Batagelj and Bren 1995) (dissimilarity) (range: 0:Inf) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (b*c)/(a*d);
    case 'Rcost'        % R cost
        out = log(1+(a/(a+b)))*log(1+(a/(a+c)));
    case 'RDeprob'      % Relative decrease of error probability (similarity)
        out = (max(a,b)+max(c,d)-max((a+c),(b+d)))/(1-max((a+c),(b+d)));
    case 'Rpattern'     % Retrieval pattern (similarity)
        out = a*d;
    case 'RR'           % Russell and Rao 1940 (similarity) (range: 0:1)
        out = a/tot;
    case 'RT'           % Rogers and Tanimoto 1960 (similarity) (binary dot product) (range: 0:1)
        out = (a+d)/(a+d+(2*(b+c)));
    case 'savage'       % Savage (dissimilarity)
        out = 1-(a/(a+max(b,c)));
    case 'Scost'        % S cost
        out = log(1+min(b,c)/(a+1))^-.5;
    case 'scott'        % Scott 1955 (similarity)
        out = ((4*((a*d)-(b*c)))-((b-c)^2))/(((2*a)+b+c)+(b+c+(2*d)));
    case 'simpson'      % Simpson 1943's ecological coexistence coefficient (similarity) (also called overlap) (range: 0:1)
        out = a/min((a+b),(a+c));
    case 'SM'           % Sokal and Michener 1958's simple matching (similarity) (also called Rand or Kendall) (range: 0:1)
        out = (a+d)/tot;
    case 'soergel'      % Soergel distance
        out = (b+c)/(b+c+d);
    case 'sorensen'     % Sorensen 1948 (similarity)
        out = (4*a)/((4*a)+b+c);
    case 'sorgenfrei'   % Sorgenfrei 1958 (similarity) (also called Fowlkes-Mallows)
        out = (a^2)/((a+b)*(a+c));
    case 'Spattern'     % Sneath pattern difference (dissimilarity)
        out = (2*sqrt(b*c))/tot;
    case 'SS1'          % Sokal and Sneath 1963 1 (similarity) (also called Gower and Legendre's S)
        out = (2*(a+d))/((2*(a+d))+b+c);
    case 'SS2'          % Sokal and Sneath 1963 2 (similarity)
        out = a/(a+(2*(b+c)));
    case 'SS3'          % Sokal and Sneath 1963 3 (similarity) (range: 0:Inf)
        out = (a+d)/(b+c);
    case 'SS4'          % Sokal and Sneath 1963 4 (similarity) (also called Anderberg) (measures the conditional probability that both items are in the same state [present or absent]) (range: 0:1) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = ((a/(a+b))+(a/(a+c))+(d/(b+d))+(d/(c+d)))/4;
    case 'SS5'          % Sokal and Sneath 1963 5 (similarity) (also called Ochiai 2) (range: 0:1) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (a*d)/sqrt(q);
    case 'Stau'         % Stuart's tau (similarity)
        out = 2*((a*d)-(b*c));
    case 'steffensen'   % Steffensen 1934 (dissimilarity)
        out = (a-((a+b)*(a+c)))/2;
    case 'stiles'       % Stiles (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0 and other circumstances)
        out = log10((tot*((abs((a*d)-(b*c))-(tot/2))^2))/q);
    case 'tarantula'    % Tarantula (Jones et al., 2002 & 2005) (similarity) (undefined when a+b and/or c+d are 0)
        out = (a/(a+b))/((a/(a+b))+(c/(c+d)));
    case 'tarwid'       % Tarwid 1960 (similarity)
        out = ((tot*a)-((a+b)*(a+c)))/((tot*a)+((a+b)*(a+c)));
    case 'Tcost'        % T combined cost
        R = log(1+(a/(a+b)))*log(1+(a/(a+c)));
        S = log(1+min(b,c)/(a+1))^-.5;
        U = log(1+((min(b,c)+a)/(max(b,c)+a)));
        out = sqrt(U*S*R);
    case 'tversky'      % Tversky 1977's feature contrast model (similarity)
        out = a-b-c;
    case 'Ucost'        % U cost
        out = log(1+((min(b,c)+a)/(max(b,c)+a)));
    case 'unigram'      % Unigram subtuples
        out = log((a*d)/(b*c))-(3.29*sqrt((1/a)+(1/b)+(1/c)+(1/d)));
    case 'UF'           % Upholt 1977's F (also called Gower and Legendre's T)
        out = (2*a)/((2*a)+b+c);
    case 'US'           % Upholt's S 1977
        F = (2*a)/((2*a)+b+c);
        out = (0.5*(-F+sqrt((F^2)+(8*F))))^(1/tot);
    case 'var'          % Variance (dissimilarity) (range: 0:Inf)
        out = (b+c)/(4*tot);
    case 'YQ'           % Yule 1911's Q coefficient of association (similarity) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = ((a*d)-(b*c))/((a*d)+(b*c));
    case 'YQD'          % Yule's Q distance (dissimilarity) (range: -1:1) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (b*c)/((a*d)+(b*c));
    case 'YY'           % Yule 1912's Y (or omega) coefficient of colligation (similarity) (range: -1:1) (undefined when a+b, b+d, a+c, and/or c+d are 0)
        out = (sqrt(a*d)-sqrt(b*c))/(sqrt(a*d)+sqrt(b*c));
end

function out = sumn(in)
out = sum(in(:));
