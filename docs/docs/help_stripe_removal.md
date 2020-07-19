# Stripe removal from movies

Some cameras will produce vertical and/or horizontal stripes in the movies that users will want to remove. Below is an example of process to remove strip from movies. The underlying function is `removeStripsFromMovie` and users can remove using `modelPreprocessMovie` module in the `calciumImagingAnalysis` class.

Vertical and horizontal stripes can be removed with the vertical and horizontal aspect of the the Fourier spectrum. In my default implementation for users I attenuate at lower frequencies since those usually do not contain the camera-induced stripes. If users have experimental induced stripes, they should lower the frequency threshold to include low frequency (spatially large) stripes.

## Example implementation
Below is an example removal of stripes showing both the Fourier domain analysis in the top row and the real domain processing in the bottom row. Bottom right shows the difference between the original and filtered movie, indicating where the stripes have been removed.

<a href="https://user-images.githubusercontent.com/5241605/51817825-4e391480-2281-11e9-9a17-cc972c26230a.png" target="_blank">![picture1](https://user-images.githubusercontent.com/5241605/51817825-4e391480-2281-11e9-9a17-cc972c26230a.png)</a>

<!-- ![picture1](https://user-images.githubusercontent.com/5241605/51817825-4e391480-2281-11e9-9a17-cc972c26230a.png) -->

## removeStripsFromMovie
To run this on any `inputMovie` movie matrix already loaded in MATLAB, do the following.
```MATLAB
% This will produce a result similar to above.
removeStripsFromMovie(inputMovie,'stripOrientation',both,'meanFilterSize',7,'freqLowExclude',10,'bandpassType','highpass')
```

## calciumImagingAnalysis
To use within the `calciumImagingAnalysis` class, select `modelPreprocessMovie` module and have `stripeRemoval` selected then on the options page, choose whether to remove vertical, horizontal, or both stripes.
![image](https://user-images.githubusercontent.com/5241605/71019922-1bbe2300-20b0-11ea-9c5f-232326884db4.png)
![image](https://user-images.githubusercontent.com/5241605/71020018-5922b080-20b0-11ea-9637-abead3c26110.png)