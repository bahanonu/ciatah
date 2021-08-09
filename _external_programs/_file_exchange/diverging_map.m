function[map] = diverging_map(s,rgb1,rgb2)
%This function is based on Kenneth Moreland's code for greating Diverging
%Colormaps.  Created by Andy Stein.
%
%s is a vector that goes between zero and one 

map = zeros(length(s),3);
for i=1:length(s)
    map(i,:) = diverging_map_1val(s(i),rgb1,rgb2);
end
end

% Interpolate a diverging color map.
    function[result] = diverging_map_1val(s, rgb1, rgb2)
    %s1 is a number between 0 and 1

        lab1 = RGBToLab(rgb1);
        lab2 = RGBToLab(rgb2);
  
        msh1 = LabToMsh(lab1);
        msh2 = LabToMsh(lab2);

        % If the endpoints are distinct saturated colors, then place white in between
        % them.
        if msh1(2) > 0.05 && msh2(2) > 0.05 && AngleDiff(msh1(3),msh2(3)) > 0.33*pi    
            % Insert the white midpoint by setting one end to white and adjusting the
            % scalar value.
            Mmid = max(msh1(1), msh2(1));
            Mmid = max(88.0, Mmid);
            if (s < 0.5)
                msh2(1) = Mmid;  msh2(2) = 0.0;  msh2(3) = 0.0;
                s = 2.0*s;
            else
                msh1(1) = Mmid;  msh1(2) = 0.0;  msh1(3) = 0.0;
                s = 2.0*s - 1.0;
            end
        end

        % If one color has no saturation, then its hue value is invalid.  In this
        % case, we want to set it to something logical so that the interpolation of
        % hue makes sense.
        if ((msh1(2) < 0.05) && (msh2(2) > 0.05))
            msh1(3) = AdjustHue(msh2, msh1(1));
        elseif ((msh2(2) < 0.05) && (msh1(2) > 0.05))
            msh2(3) = AdjustHue(msh1, msh2(1));
        end

        mshTmp(1) = (1-s)*msh1(1) + s*msh2(1);
        mshTmp(2) = (1-s)*msh1(2) + s*msh2(2);
        mshTmp(3) = (1-s)*msh1(3) + s*msh2(3);

        % Now convert back to RGB
        labTmp = MshToLab(mshTmp);
        result = LabToRGB(labTmp);
        1;
    end


%Convert to and from a special polar version of CIELAB (useful for creating
%continuous diverging color maps).
    function[Msh] = LabToMsh(Lab)  
        L = Lab(1);
        a = Lab(2);
        b = Lab(3);

        M = sqrt(L*L + a*a + b*b);
        s = (M > 0.001) * acos(L/M);
        h = (s > 0.001) * atan2(b,a);

        Msh = [M s h];
    end

    function[Lab] = MshToLab(Msh)
        M = Msh(1);
        s = Msh(2);
        h = Msh(3);

        L = M*cos(s);
        a = M*sin(s)*cos(h);
        b = M*sin(s)*sin(h);

        Lab = [L a b];
    end

%Given two angular orientations, returns the smallest angle between the two.
    function[adiff] = AngleDiff(a1, a2)
        v1    = [cos(a1) sin(a1)];
        v2    = [cos(a2) sin(a2)];        
        adiff = acos(dot(v1,v2));
    end
        
%% For the case when interpolating from a saturated color to an unsaturated
%% color, find a hue for the unsaturated color that makes sense.
    function[h] = AdjustHue(msh, unsatM)

        if msh(1) >= unsatM-0.1                    
            %%The best we can do is hold hue constant.
            h = msh(3);
        else
            % This equation is designed to make the perceptual change of the
            % interpolation to be close to constant.
            hueSpin = (msh(2)*sqrt(unsatM^2 - msh(1)^2)/(msh(1)*sin(msh(2))));
    
            % Spin hue away from 0 except in purple hues.
            if (msh(3) > -0.3*pi)
                h = msh(3) + hueSpin;
            else
                h = msh(3) - hueSpin;
            end
        end
    end

    function [xyz] = LabToXYZ(Lab)
        %LAB to XYZ
        L = Lab(1); a = Lab(2); b = Lab(3);

        var_Y = ( L + 16 ) / 116;
        var_X = a / 500 + var_Y;
        var_Z = var_Y - b / 200;

        if ( var_Y^3 > 0.008856 ) 
          var_Y = var_Y^3;
        else
          var_Y = ( var_Y - 16.0 / 116.0 ) / 7.787;
        end
        if ( var_X^3 > 0.008856 ) 
          var_X = var_X^3;
        else
          var_X = ( var_X - 16.0 / 116.0 ) / 7.787;
        end
        if ( var_Z^3) > 0.008856 
          var_Z = var_Z^3;
        else
          var_Z = ( var_Z - 16.0 / 116.0 ) / 7.787;
        end

        ref_X = 0.9505;
        ref_Y = 1.000;
        ref_Z = 1.089;


        x = ref_X * var_X;     %ref_X = 0.9505  Observer= 2 deg Illuminant= D65
        y = ref_Y * var_Y;     %ref_Y = 1.000
        z = ref_Z * var_Z;     %ref_Z = 1.089

        xyz = [x y z];
    end

    function[Lab] = XYZToLab(xyz)
        x = xyz(1); y = xyz(2); z = xyz(3);

        ref_X = 0.9505;
        ref_Y = 1.000;
        ref_Z = 1.089;
        var_X = x / ref_X;  %ref_X = 0.9505  Observer= 2 deg, Illuminant= D65
        var_Y = y / ref_Y;  %ref_Y = 1.000
        var_Z = z / ref_Z;  %ref_Z = 1.089

        if ( var_X > 0.008856 ), var_X = var_X^(1/3);
        else                     var_X = ( 7.787 * var_X ) + ( 16.0 / 116.0 ); end
        if ( var_Y > 0.008856 ), var_Y = var_Y^(1/3);
        else                     var_Y = ( 7.787 * var_Y ) + ( 16.0 / 116.0 ); end
        if ( var_Z > 0.008856 ), var_Z = var_Z^(1/3);
        else                     var_Z = ( 7.787 * var_Z ) + ( 16.0 / 116.0 ); end

        L = ( 116 * var_Y ) - 16;
        a = 500 * ( var_X - var_Y );
        b = 200 * ( var_Y - var_Z );

        Lab = [L a b];
    end

function[rgb] = XYZToRGB(xyz)
  
  %ref_X = 0.9505;        %Observer = 2 deg Illuminant = D65
  %ref_Y = 1.000;
  %ref_Z = 1.089;
  
  x = xyz(1); y = xyz(2); z = xyz(3);
  r = x *  3.2406 + y * -1.5372 + z * -0.4986;
  g = x * -0.9689 + y *  1.8758 + z *  0.0415;
  b = x *  0.0557 + y * -0.2040 + z *  1.0570;

  % The following performs a "gamma correction" specified by the sRGB color
  % space.  sRGB is defined by a canonical definition of a display monitor and
  % has been standardized by the International Electrotechnical Commission (IEC
  % 61966-2-1).  The nonlinearity of the correction is designed to make the
  % colors more perceptually uniform.  This color space has been adopted by
  % several applications including Adobe Photoshop and Microsoft Windows color
  % management.  OpenGL is agnostic on its RGB color space, but it is reasonable
  % to assume it is close to this one.
  if (r > 0.0031308), r = 1.055 * r^( 1 / 2.4 ) - 0.055;
  else r = 12.92 * (r); end
  if (g > 0.0031308), g = 1.055 * g^( 1 / 2.4 ) - 0.055;
  else  g = 12.92 * (g); end
  if (b > 0.0031308), b = 1.055 * b^( 1 / 2.4 ) - 0.055;
  else b = 12.92 * (b); end

  % Clip colors. ideally we would do something that is perceptually closest
  % (since we can see colors outside of the display gamut), but this seems to
  % work well enough.
  maxVal = r;
  if (maxVal < g), maxVal = g; end
  if (maxVal < b), maxVal = b; end
  if (maxVal > 1.0)    
    r = r/maxVal;
    g = g/maxVal;
    b = b/maxVal;
  end
  if (r<0), r=0; end
  if (g<0), g=0; end
  if (b<0), b=0; end
  
  rgb = [r g b];
end

%-----------------------------------------------------------------------------
function[xyz] = RGBToXYZ(rgb)

  r = rgb(1); g = rgb(2); b = rgb(3);

  % The following performs a "gamma correction" specified by the sRGB color
  % space.  sRGB is defined by a canonical definition of a display monitor and
  % has been standardized by the International Electrotechnical Commission (IEC
  % 61966-2-1).  The nonlinearity of the correction is designed to make the
  % colors more perceptually uniform.  This color space has been adopted by
  % several applications including Adobe Photoshop and Microsoft Windows color
  % management.  OpenGL is agnostic on its RGB color space, but it is reasonable
  % to assume it is close to this one.
  if ( r > 0.04045 ), r = (( r + 0.055 ) / 1.055)^2.4;
  else                r = r / 12.92; end
  if ( g > 0.04045 ), g = (( g + 0.055 ) / 1.055)^2.4;
  else                g = g / 12.92; end
  if ( b > 0.04045 ), b = (( b + 0.055 ) / 1.055)^2.4;
  else                b = b / 12.92; end

  %Observer. = 2 deg, Illuminant = D65
  x = r * 0.4124 + g * 0.3576 + b * 0.1805;
  y = r * 0.2126 + g * 0.7152 + b * 0.0722;
  z = r * 0.0193 + g * 0.1192 + b * 0.9505;
  
  xyz = [x y z];
end

function[rgb] = LabToRGB(Lab)
  xyz = LabToXYZ(Lab);
  rgb = XYZToRGB(xyz);
end

function[Lab] = RGBToLab(rgb)
  xyz = RGBToXYZ(rgb);
  Lab = XYZToLab(xyz);
end
