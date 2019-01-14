function [ hListbox jListbox jScrollPane jDND ] = reorderableListbox( ...
    varargin )
%REORDERABLELISTBOX Create reorderable listbox.
%   REORDERABLELISTBOX, by itself, creates a listbox in the current figure
%   whose contents can be reordered by clicking and dragging items, and
%   returns a handle to it.
%
%   REORDERABLELISTBOX('PropertyName1',value1,'PropertyName2',value2,...)
%   creates a reorderable listbox with the specified properties. The
%   property 'Style' is automatically set to 'Listbox'. See UICONTROL for
%   more details.
%
%   REORDERABLELISTBOX(FIG,...) creates a reorderable listbox in the
%   specified figure.
%
%   [HLISTBOX,JLISTBOX,JSCROLLPANE,JDND] = REORDERABLELISTBOX(...) returns
%   the listbox's handle HLISTBOX, the underlying Java JList's handle
%   JLISTBOX, the Java JScrollPane's handle JSCROLLPANE, and the Java 
%   DropTarget's handle JDND. These handles can be used with GET and SET to
%   manipulate the listbox's properties, and the three Java handles also
%   support dot-referencing, i.e. JLISTBOX.getSelectedIndices().
%
%   The listbox created is a standard Matlab UICONTROL('Style','Listbox'),
%   whose underlying Java JList has the following properties modified:
%   'DragEnabled', 'DragSelectionEnabled', 'DropMode', 'DropTarget',
%   'MousePressedCallback', and 'MouseReleasedCallback'.
%
%   The user may specify their own 'MousePressedCallback' (JList),
%   'MouseReleasedCallback' (JList), 'DragOverCallback' (DropTarget), and
%   'DropCallback' (DropTarget) in the list of input property/value pairs.
%   These callbacks will be called at the end of the REORDERABLELISTBOX
%   default callbacks, with two inputs, HANDLE and EVENTDATA. The
%   'DragOverCallback' is given a third input, PERMORDER, which indicates
%   how the list has been reordered, i.e. STRING = STRING(PERMORDER). This
%   can be used to reorder any underlying data that the list may represent.
%
%   To reorder items, REORDERABLELISTBOX creates a drag-and-drop object
%   tied to the listbox. An unintended result is that list items can be
%   dragged off of the list and dropped onto other components. Items can
%   also be dragged from other objects onto the list; dropping onto the
%   list has no effect.
%
%   If the listbox displays erratic redraw behaviour when being reordered
%   rapidly (single cells being drawn too tall or too wide), you may need
%   to explicitly set the 'FixedCellHeight' and 'FixedCellWidth' properties
%   of JLISTBOX (values of -1 tell Java to automatically determine cell
%   size, but may lead to this erratic behaviour).
%
%   This utility makes use of the freely available FINDJOBJ, written by
%   Yair Altman and available on the Matlab File Exchange:
%   http://www.mathworks.com/matlabcentral/fileexchange/14317
%
%   Example 1:  Create an empty reorderable listbox on the current figure
%       reorderableListbox;
%
%   Example 2:  Create a reorderable listbox with three items
%       reorderableListbox( 'String', {'Item 1' 'Item 2' 'Item 3'} );
%
%   Example 3:  Create a reorderable listbox with three items on Figure 2
%       reorderableListbox( 2, 'String', {'Item 1' 'Item 2' 'Item 3'} );
%
%   Example 4:  Create a reorderable listbox with three items, store the
%               graphics handles, and change the scrollbar display policy
%       [ hListbox jListbox jScrollPane jDND ] = reorderableListbox( ...
%           'String', {'Item 1' 'Item 2' 'Item 3'} );
%       jScrollPane.setVerticalScrollBarPolicy( ...
%           javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED );
%       %or jScrollPane.setVerticalScrollBarPolicy( 20 );
%       %or set( jScrollPane, 'VerticalScrollBarPolicy', 20 );
%
%   Example 5:  Create a reorderable listbox that reorders an underlying
%               data set when the list order changes
%       data = [ 1 2 3 ];
%       reorderableListbox( 'String', {'Item 1' 'Item 2' 'Item 3'}, ...
%           'DragOverCallback', @dragOver );
%
%       % Nested function (with access to DATA)
%       function dragOver( jDND, jEventData, permOrder )
%           data = data( permOrder );
%       end
%
%   See also UICONTROL, FINDJOBJ, SET, GET.

%   Copyright 2012 Erik Koopmans:   erik.koopmans(at)mail.mcgill.ca
%   $Revision: 1.1.1 $  $Date: 2012/07/31 15:23:00 $

%   Changelog:
%       2012/07/31 (1.1.1): Separated DropCallback from
%           MouseReleasedCallback, for more user customization.
%       2012/07/31 (1.1.0): Added support for user-definable callbacks
%           (MousePressed, MouseReleased, DragOver); added permOrder.
%       2012/07/27 (1.0.1): Fixed problem with findjobj returning multiple
%           objects (jScrollPane was non-unary when the listbox was very
%           small); improved documentation.
%       2012/07/26 (1.0.0): Version 1.0 posted to Matlab File Exchange:
%           http://www.mathworks.com/matlabcentral/fileexchange/
%           37642-reorderable-listbox


% Store user callbacks to be appended to existing callbacks
callbackStrs = { 'MousePressed' 'MouseReleased' 'DragOver' 'Drop' };
nCallbacks = length( callbackStrs );
userCallback = cell( 1, nCallbacks );

% Loop through each of the callbacks, find them in varargin
for i = 1 : nCallbacks
    ind = find( strcmpi(varargin, [callbackStrs{i} 'Callback']), 1 );
    
    % If the callback was found, store it and remove from varargin
    if ~isempty( ind )
        userCallback(i) = varargin( ind+1 );
        varargin = varargin([ 1:ind-1 ind+2:end ]);
    end
end

% Check whether the first argument was a figure handle
if nargin > 0 && isnumeric( varargin{1} ) && isscalar( varargin{1} )
    % Create the listbox in the specified figure
    fig = varargin{1};
    hListbox = uicontrol( fig, 'Style', 'Listbox', varargin{2:end} );
else
    % Create the listbox
    hListbox = uicontrol( 'Style', 'Listbox', varargin{:} );
end
% Get the listbox's underlying Java control
jScrollPane = findjobj( hListbox );
jScrollPane = jScrollPane(1);
jListbox = jScrollPane.getViewport.getComponent(0);

% Convert the listbox object to a callback-capable reference handle
jListbox = handle( jListbox, 'CallbackProperties' );

% Add a callback to track the mouse drag position
set( jListbox, 'MousePressedCallback', @mousePressed, ...
    'MouseReleasedCallback', @mouseReleased );

% Create a drag-and-drop object with a DragOverCallback and DropCallback
jDND = handle( java.awt.dnd.DropTarget(), 'CallbackProperties' );
set( jDND, 'DragOverCallback', @dragOver, 'DropCallback', @drop );

% Configure drag-and-drop on the listbox and attach the DND object
set( jListbox, 'DragSelectionEnabled', false, 'DragEnabled', true, ...
    'DropMode', javax.swing.DropMode.INSERT );
jListbox.setDropTarget( jDND );

% This is used by the nested functions to track the mouse drag
startInd = [];


    function mousePressed( jListbox, jEventData )
        %MOUSEPRESSED   JList 'MousedPressedCallback'.
        %   MOUSEPRESSED executes when the mouse is clicked on the listbox.
        %   The mouse's position is recorded and the listbox gains focus.
        
        % Find the index of the clicked item, store it for future reference
        startInd = jListbox.locationToIndex( jEventData.getPoint ) + 1;
        
        % Make sure the listbox gains focus when it's clicked
        jListbox.requestFocus();
        
        % Call the user-defined MousePressedCallback, if given
        doCallback( userCallback{1}, jListbox, jEventData );
        
    end

    function mouseReleased( jListbox, jEventData )
        %MOUSERELEASED  JList 'MousedReleasedCallback'.
        %   MOUSERELEASED executes when the mouse is released after a
        %   listbox click (but not after a drag). The drag-tracking
        %   variable STARTIND is cleared.
        %
        %   This function, with DROP, tries to prevent drags from other
        %   objects from triggering the reorder behaviour. However, if an
        %   item is dragged from the listbox to another object, neither
        %   function gets called, and the listbox can still be reordered by
        %   other drags.

        % Clear the drag-tracking variable
        startInd = [];
        
        % Call the user-defined MouseReleasedCallback, if given
        doCallback( userCallback{2}, jListbox, jEventData );
        
    end

    function drop( jDND, jEventData )
        %DROP   DropTarget 'DropCallback'.
        %   DROP executes after a mouse drag to the listbox. The
        %   drag-tracking variable STARTIND is cleared.
        %
        %   This function, with MOUSERELEASED, tries to prevent drags from
        %   other objects from triggering the reorder behaviour. However,
        %   if an item is dragged from the listbox to another object,
        %   neither function gets called, and the listbox can still be
        %   reordered by other drags.

        % Clear the drag-tracking variable
        startInd = [];
        
        % Call the user-defined DropCallback, if given
        doCallback( userCallback{4}, jDND, jEventData );
        
    end

    function permOrder = dragOver( jDND, jEventData )
        %DRAGOVER   DropTarget 'DragOverCallback'.
        %   DRAGOVER executes when the mouse is dragged over the listbox.
        %   The mouse's movement is tracked, and if it has moved by at
        %   least one item, the list is reordered by calling SHIFTLIST.
        
        % Find the index of the mouse position, compute the distance moved
        mouseInd = jListbox.locationToIndex( jEventData.getLocation ) + 1;
        moveInd = mouseInd - startInd;
        
        % Only proceed if the mouse has moved at least one item
        if moveInd
            % Retrieve the list contents and selection
            str = get( hListbox, 'String' );
            val = get( hListbox, 'Value' );
            
            % Update the selection (the click isn't always registered)
            if ~ismember( startInd, val )
                val = startInd;
            end
            
            % Update the log of the mouse's position
            startInd = mouseInd;
            
            % Shift the selected items by moveInd, and update the listbox
            [ str val permOrder ] = shiftList( str, val, moveInd );
            set( hListbox, 'String', str, 'Value', val );
            
            % Make sure the selected items are visible
            if moveInd > 0
                jListbox.ensureIndexIsVisible( val(end)-1 );
            else
                jListbox.ensureIndexIsVisible( val(1)-1 );
            end
        else
            % If list doesn't change, create default permOrder
            str = get( hListbox, 'String' );
            permOrder = 1 : length( str );
        end
        
        % Call the user-defined DragOverCallback, if given
        doCallback( userCallback{3}, jDND, jEventData, permOrder );
        
    end

    function [ newstr newval permOrder ] = shiftList( str, val, shiftAmt )
        %SHIFTLIST  Shifts entries up or down in a list.
        %   [STR VAL] = SHIFTLIST(STR,VAL,SHIFTAMT) shifts the items at
        %   index VAL in list STR by the amount SHIFTAMT. Positive SHIFTAMT
        %   causes a shift down the list; negative shifts up the list.
        %
        %   [STR VAL PERMORDER] = SHIFTLIST(...) returns the permutation
        %   order of the shift. This is the index mapping from the original
        %   STR to the new STR, i.e. STR = STR(PERMORDER). PERMORDER can be
        %   used to reorder an underlying data set that the list may
        %   represent.
        
        % Return if there's not enough info or no shift to be performed
        if nargin < 2
            [ newstr newval permOrder ] = deal( {}, [], ':' );
            return
        elseif nargin < 3 || ~shiftAmt
            [ newstr newval permOrder ] = deal( str, val, 1:length(str) );
            return
        end
        
        % Find the number of items selected and in the list
        nItems = length( str );
        nSelected = length( val );
        
        if shiftAmt > 0
            % Shift down: add shiftAmt, capping at end of list
            newval = min( val+shiftAmt, nItems - (nSelected-1 :-1: 0) );
        else
            % Shift up: add shiftAmt (neg), capping at start of list
            newval = max( val+shiftAmt, (1 : nSelected) );
        end
        
        % Determine the permutation order needed to go from str to newstr
        allItems = 1 : nItems;
        permOrder([ newval setdiff(allItems,newval) ]) = ...
            [ val setdiff(allItems,val) ];
        
        % Assign newstr
        newstr = str( permOrder );
        
    end

    function doCallback( callback, varargin )
        %DOCALLBACK     Executes a callback with a set of inputs.
        %   DOCALLBACK(CALLBACK) executes the callback function specified.
        %
        %   DOCALLBACK(CALLBACK,IN1,IN2,...) executes the callback, giving
        %   it a set of inputs IN1, IN2, etc.
        %
        %   CALLBACK may be a cell array, containing a callback function in
        %   the first cell and additional inputs in the remaining cells.
        %   These inputs will be appended to those in VARARGIN.
        
        % Return if there's no callback specified
        if nargin < 1 || isempty( callback )
            return
        end
        
        % Check if the callback contains extra inputs, put them at the end
        if iscell( callback )
            varargin = [ varargin callback(2:end) ];
            callback = callback{1};
        end
        
        % Execute the callback with the specified inputs
        callback( varargin{:} );
    end

end
