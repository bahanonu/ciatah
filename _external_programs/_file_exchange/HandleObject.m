classdef HandleObject < handle
	% creates an handle to memory, allows pointer-like functionality
	% started: 2014.02.06
	%
	% http://www.matlabtips.com/how-to-point-at-in-matlab/

	   properties
	      Object=[];
	   end

	   methods
	      function obj=HandleObject(obj,receivedObject)
	         obj.Object=receivedObject;
	      end
	   end
	end


	% function Parent()
	%    GIFT=HandleObject('Trampoline')
	%    giveDaughter(GIFT);
	%    GIFT.Object
	% end

	% function giveDaughter(receivedGIFT)
	% 	receivedGIFT.Object=['broken ',receivedGIFT.Object];
	% end