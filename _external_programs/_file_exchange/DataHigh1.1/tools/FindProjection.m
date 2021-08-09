function varargout = FindProjection(varargin)
%  FindProjection
%
%  Displays a predefined projection, by rotating the current projection
%  vectors towards the desired vectors.
%
%  It will only use the basic features (trajs or clusters).  It will favor
%  clusters over trajectories, meaning if you have mixed data, DataHigh
%  will only focus on clusters.
%
%  Future work:  allow modular additions for new cost functions
%
%  Copyright Benjamin Cowley, Matthew Kaufman, Zachary Butler, Byron Yu, 2012-2013

% ---GNU General Public License Copyright---
% This file is part of DataHigh.
% 
% DataHigh is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, version 2.
% 
% DataHigh is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details in COPYING.txt found
% in the main DataHigh directory.
% 
% You should have received a copy of the GNU General Public License
% along with DataHigh.  If not, see <http://www.gnu.org/licenses/>.
%
% If planning to re-distribute, do not delete original code 
% (but original code can be commented out).  Make changes clear, 
% obvious, and well-documented.  All changes must be explicitly 
% listed in an added section at the top of the changed file, 
% the main DataHigh.m file, and in a readme_CHANGES.txt file 
% in the main DataHigh directory. Explicitly list the authors
% who made the changes, and that the original authors do not
% endorse any changes.  If changes are useful, consider 
% contacting the authors to incorporate into the next DataHigh 
% code release.
%
% Copyright Benjamin Cowley, Matthew Kaufman, Zachary Butler, Byron Yu, 2012-2013

% Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @FindProjection_OpeningFcn, ...
                       'gui_OutputFcn',  @FindProjection_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
% End initialization code - DO NOT EDIT
end



% Opening function
function FindProjection_OpeningFcn(hObject, eventdata, handles, varargin)

    handles.DataHighFig = varargin{1};
    hd = guidata(handles.DataHighFig);
    handles.functions = varargin{2};
    handles.functions.setUpPanel(handles.mainAxes, hd.max_limit);
    handles.proj_vecs = hd.proj_vecs;
    handles.ProjectionPursuitFig = hObject;
    guidata(hObject, handles);
    
    handles.functions.plot_panel(handles.DataHighFig, hd, handles.mainAxes, handles.proj_vecs);
end


% Output function
function varargout = FindProjection_OutputFcn(hObject, eventdata, handles)
    % set position of ProjectionPursuitFigure
    set(handles.ProjectionPursuitFig, 'Units', 'normalized', 'OuterPosition', [.1 .1 .6 .8]);
    guidata(hObject, handles);
end



% Particular views



function rand_proj_button_Callback(hObject, eventdata, handles)
%  rotates to a random set of projection vectors

    h = guidata(handles.DataHighFig);
    
    [q r] = qr(randn(h.num_dims));

    rotate_to_desired(hObject, handles, q(:,1:2)');
    
end


function pca_button_Callback(hObject, eventdata, handles)
%  The desired vectors are the first two PCs of the data
%  (trajectories' datapoints are concatenated)

    dh_handles = guidata(handles.DataHighFig);
    D = dh_handles.D;
    conditions = unique({D.condition});
    D = D(ismember({D.condition}, conditions(dh_handles.selected_conds)));
    
%     if (ismember('cluster', {D.type}))
%         datapoints = [D(ismember({D.type}, 'cluster')).data];
%     else
%         datapoints = [];
%         for i = 1:length(D)
%             datapoints(:,i) = D(i).data(:,end);
%         end
%     end
            
    [u sc lat] = princomp([D.data]');
    
    rotate_to_desired(hObject, handles, u(:,1:2)');
    
end



function lda_button_Callback(hObject, eventdata, handles)
% The desired vectors are from Fisher's linear discriminant analysis
%
% If only two conditions (should only be a one-d projection), qr gives us a
% second projection vector (that can be considered random) anyway, so it's
% ok

    dh_handles = guidata(handles.DataHighFig);
    conditions = unique({dh_handles.D.condition});
    conditions = conditions(dh_handles.selected_conds);
    D = dh_handles.D(ismember({dh_handles.D.condition}, conditions));
    
    if (ismember('cluster', {D.type}))
        D = D(ismember({D.type}, 'cluster')); % get rid of any trajs
        
        if (length(conditions) <= 1) % LDA should do nothing for one condition
            return;
        end
    else
        if (length(conditions) == 1)  %  goal: only one cond, so make points in the traj far apart
            if (length(D) == 1) % only one trajectory, so LDA will fail
                return;
            end
            newData = [];
            index = 1;
            for itrial = 1:length(D)
                D(itrial).epochStarts = [D(itrial).epochStarts size(D(itrial).data,2)];  %change epochStarts to include the end
                for j = 1:length(D(1).epochStarts)
                    newData(index).condition = num2str(j);
                    newData(index).data = D(itrial).data(:,D(itrial).epochStarts(j));
                    index = index+1;
                end
            end
            D = newData;
            conditions = unique({D.condition});
        end 
        % else, just use the full trajectory
    end
    

    sigma = zeros(dh_handles.num_dims);
    m = [];

    for cond = 1:length(conditions)
        sigma = sigma + cov([D(ismember({D.condition}, conditions(cond))).data]',1);
        m(:,cond) = mean([D(ismember({D.condition}, conditions(cond))).data],2);
    end

    Sigma_within = sigma ./ length(conditions);
    Sigma_between = cov(m',1);

    [w e] = eig(Sigma_within \ Sigma_between);

    % LDA does *not* return orthogonal eigenvectors
    % perform Gram-Schmidt to find nearest 2nd orthogonal vector
    
    [q r] = qr(w);

    rotate_to_desired(hObject, handles, q(:,1:2)');

end



function pca_clustermeans_button_Callback(hObject, eventdata, handles)
% plot the stimulus space..i.e. the space defined by the first two PCs
% taken on all cluster means

    dh_handles = guidata(handles.DataHighFig);
    
    if (length(unique({dh_handles.D.condition})) == 1) % there's only one condition, so no means
        return;
    end
    

    % find the means
    conditions = unique({dh_handles.D.condition});
    conditions = conditions(dh_handles.selected_conds);
    m = [];
    for icond = 1:length(conditions)
       m = [m mean([dh_handles.D(ismember({dh_handles.D.condition}, conditions{icond})).data],2)];
    end
    [u sc lat] = princomp(m');
    
    rotate_to_desired(hObject, handles, u(:,1:2)');

end



function projpursuit_button_Callback(hObject, eventdata, handles)
%  Use Tukey's projection pursuit for the viewer...
%  won't be implemented this time around, could just use XGobi
end




function load_proj_button_Callback(hObject, eventdata, handles)
%  Load the desired vectors as the current projection vectors

    hd = guidata(handles.DataHighFig);
    
    hd.proj_vecs = orth(real(handles.proj_vecs)')';
    
    % update the Q matrices, since you are changing the vectors
    [hd.Q1 hd.Q2] = hd.functions.calculateQ(handles.DataHighFig, hd); 
    guidata(handles.DataHighFig, hd);
   
    close(handles.ProjectionPursuitFig);

    figure(handles.DataHighFig);   % make DataHigh the active figure to plot
    handles.functions.choose_conditions(handles.DataHighFig, hd.selected_conds);  % replot everything

end


% % Third idea, what GGobi uses
function rotate_to_desired(hObject, handles, desired_vecs)
% helper function that modifies the current axes
%  rotates the current projection vectors by a small angle until that
%  the current vectors equal the desired vectors



    dh_handles = guidata(handles.DataHighFig);

    % idea:
    %  I found a nice idea in (Section 2.2 Cook, Buja, Lee, and Wickham: Grand Tours,
    %  Projection Pursuit Guided TOurs and Manual Controls) which
    %  calculates the principal angles between the projection matrices
    %
    % don't use qr here...we need to keep exact vectors, not just the span

    
    proj_vecs = handles.proj_vecs;
    

    
    % make sure desired_vecs are normalized
    desired_vecs(1,:) = desired_vecs(1,:) ./ norm(desired_vecs(1,:));
    desired_vecs(2,:) = desired_vecs(2,:) ./ norm(desired_vecs(2,:));
    
    check_desired = desired_vecs(1,:) * desired_vecs(2,:)';
    if (check_desired > 0) % desired vecs are not orthogonal
        desired_vecs(2,:) = desired_vecs(2,:) - desired_vecs(1,:)*desired_vecs(2,:)' * desired_vecs(1,:); % subtract the parallel component
        desired_vecs(2,:) = desired_vecs(2,:) ./ norm(desired_vecs(2,:));
    end

    check = proj_vecs * desired_vecs';
    if (check(1,1) > .99 && check(2,2) > .99) % this is the current view
        return; % so no need to move, do nothing
    end
    
    
    % Find shortest path between spaces using SVD
    [Va lambda Vz] = svd(proj_vecs * desired_vecs');


    % find principal directions in each space
    Ba = proj_vecs' * Va;
    Bz = desired_vecs' * Vz;


    % orthonormalize Bz to get B_star, ensuring projections are orthogonal
    % to Ba
    % don't use qr...screwed me up, as it negates some vectors
    B_star(:,1) = Bz(:,1) - Ba(:,1)'*Bz(:,1)*Ba(:,1) - Ba(:,2)'*Bz(:,1)*Ba(:,2);
    B_star(:,1) = B_star(:,1) ./ norm(B_star(:,1));
    B_star(:,2) = Bz(:,2) - B_star(:,1)'*Bz(:,2)*B_star(:,1) - Ba(:,1)'*Bz(:,2)*Ba(:,1) - Ba(:,2)'*Bz(:,2)*Ba(:,2);
    B_star(:,2) = B_star(:,2) ./ norm(B_star(:,2));

    % calculate the principal angles
    tau = acos(diag(lambda));

    % increment angles
    for t = 0:(1/100):1
        
        % compute the rotation vector comprised of Ba and B_star
        % as t-->1, Bt should converge to Bz
        % also note that projection vectors are always orthogonal
        Bt = [];

        Bt(:,1) = cos(tau(1)*t)*Ba(:,1) + sin(tau(1)*t)*B_star(:,1);
        Bt(:,2) = cos(tau(2)*t)*Ba(:,2) + sin(tau(2)*t)*B_star(:,2);



        % need to rotate principal vectors back to original basis,
        % so that initial projection begins with the old projection vectors
        % (if not, you will still get same desired vectors, but the first
        % projection will start rotated from the original projection)
        proj_vecs = Va * Bt';  % transform back into the original coordinates

        % normalize projection vectors
        proj_vecs(1,:) = proj_vecs(1,:) ./ norm(proj_vecs(1,:));
        proj_vecs(2,:) = proj_vecs(2,:) ./ norm(proj_vecs(2,:));

        handles.functions.plot_panel(handles.DataHighFig, dh_handles, handles.mainAxes, proj_vecs);
        drawnow;
    end


    % Set the projection to exactly the desired vecs
    handles.proj_vecs = proj_vecs;
    

    guidata(hObject, handles);
    
end





   







%
%  First idea
%  I finally found a better idea how to do this, so I'm archiving this one.
%  This computed a line between the two vectors, and slowly moved on vector
%  along that line.
%  Works, but not optimal!
%
% function rotate_to_desired_old(hObject, handles, desired_vecs)
% % helper function that modifies the current axes
% %  rotates the current projection vectors by a small angle until that
% %  vector is equal to the desired
% 
% 
%     dh_handles = guidata(handles.DataHighFig);
% 
%     % idea:
%     %  find the distance between vecs1.  Slowly move vec1 towards the
%     %  desired vec1 in steps.  At each step, subtract the projected vec2
%     %  onto vec1 from vec2, to ensure vec2 is orthogonal from vec1.  Then,
%     %  keep vec1 fixed but slowly decrease the distance between vec2 and
%     %  desired vec2, again subtracting the projected part to keep vec1
%     %  orthogonal to vec2
%     
%     proj_vecs = handles.proj_vecs;
%     
%     check = proj_vecs * desired_vecs';
%     if (check(1,1) > .99 && check(2,2) > .99) % this is the current view
%         return; % so no need to move, do nothing
%     end
%     
%     % Step 1:  Make vec1 closer to desired_vec1, while keeping vec2
%     % orthogonal.
%     
%     step_length = 100;
%     
%     p1 = (desired_vecs(1,:) - proj_vecs(1,:))';
%     step_dist1 = norm(p1)/step_length;
%     if (step_dist1 < 1e-10)  % the user clicked the same projection, so ignore
%             p2 = (desired_vecs(2,:) - proj_vecs(2,:))';  % if they also didn't move the second vector
%             step_dist2 = norm(p2)/step_length;
%             if (step_dist2 < 1e-10)
%                 return;
%             end
%     end
%     u1 = p1/norm(p1);
% 
%     
%     for i = 1:step_length
%         proj_vecs(1,:) = proj_vecs(1,:) + step_dist1 * u1';
%         parallel_vec2 = (proj_vecs(2,:) * proj_vecs(1,:)') * proj_vecs(1,:);
%         proj_vecs(2,:) = proj_vecs(2,:) - parallel_vec2;
%         proj_vecs(2,:) = proj_vecs(2,:) / norm(proj_vecs(2,:));
%         
%         handles.functions.plot_panel(handles.DataHighFig, dh_handles, handles.mainAxes, proj_vecs);
%         drawnow;
% 
%     end
% 
% 
%     % Step 2:  Now fix vec1, but keep moving vec2 closer to desired_vec2
%     
%     p2 = (desired_vecs(2,:) - proj_vecs(2,:))';
%     step_dist2 = norm(p2)/step_length;
%     u2 = p2/norm(p2);
%     orig_vec2 = proj_vecs(2,:);
% 
%     for i = 1:step_length
%         orig_vec2 = orig_vec2 + step_dist2 * u2';
%         parallel_vec2 = (orig_vec2 * proj_vecs(1,:)') * proj_vecs(1,:);
%         proj_vecs(2,:) = orig_vec2 - parallel_vec2;
%         proj_vecs(2,:) = proj_vecs(2,:) / norm(proj_vecs(2,:));
% 
%         handles.functions.plot_panel(handles.DataHighFig, dh_handles, handles.mainAxes, proj_vecs);
%         drawnow;
%     end
% 
%     % Set the projection to exactly the desired vecs
% %     handles.functions.plot_panel(handles.DataHighFig, dh_handles, handles.mainAxes, desired_vecs);
% %     drawnow;
%     handles.proj_vecs = proj_vecs;
% 
%     guidata(hObject, handles);
%     
% end
%  



%
%  Second idea:
%  Look at current proj vec1 and desired vec1
%  Together, they make a plane, 
%  Slowly rotate the data in that plane as proj vec1 rotates closer to
%  desired vec1
%  Then do the same for vec2
%
% function rotate_to_desired(hObject, handles, desired_vecs)
% % helper function that modifies the current axes
% %  rotates the current projection vectors by a small angle until that
% %  vector is equal to the desired
% 
% 
%     dh_handles = guidata(handles.DataHighFig);
% 
%     % idea:
%     %  find the plane that both vec1 and vec2 lie in
%     %  then, rotate vec1 to equal vec2 by first changing the basis of vec1,
%     %  then rotating it (with the plane in the first two dims), and then
%     %  returning to the original basis.
%     
%     proj_vecs = handles.proj_vecs;
%     
%     check = proj_vecs * desired_vecs';
%     if (check(1,1) > .99 && check(2,2) > .99) % this is the current view
%         return; % so no need to move, do nothing
%     end
%     
%     % make sure desired_vecs are normalized
%     desired_vecs(1,:) = desired_vecs(1,:) ./ norm(desired_vecs(1,:));
%     desired_vecs(2,:) = desired_vecs(2,:) ./ norm(desired_vecs(2,:));
%     
%     check_desired = desired_vecs(1,:) * desired_vecs(2,:)';
%     if (check_desired > 0) % desired vecs are not orthogonal
%         desired_vecs(2,:) = desired_vecs(2,:) - desired_vecs(1,:)*desired_vecs(2,:)' * desired_vecs(2,:); % subtract the parallel component
%         desired_vecs(2,:) = desired_vecs(2,:) ./ norm(desired_vecs(2,:));
%     end
%     
%     % Step 1:  Make vec1 closer to desired_vec1, while keeping vec2
%     % orthogonal.
%     
%     alpha = acos((desired_vecs(1,:) * proj_vecs(1,:)'));
%     step_length = 100;
%     R = find_rotation_matrix(proj_vecs(1,:), desired_vecs(1,:), cos(alpha/step_length));
%     for i = 1:step_length
%         proj_vecs = (R * proj_vecs')';
% 
%         handles.functions.plot_panel(handles.DataHighFig, dh_handles, handles.mainAxes, proj_vecs);
%         drawnow;
%     end
% 
% 
%     % Step 2:  Now fix vec1, but keep moving vec2 closer to desired_vec2
%     beta = acos(desired_vecs(2,:) * proj_vecs(2,:)');
%     step_length = 100;
%     R = find_rotation_matrix(proj_vecs(2,:), desired_vecs(2,:), cos(beta/step_length));
%     for i = 1:step_length
%         proj_vecs = (R * proj_vecs')';
%         handles.functions.plot_panel(handles.DataHighFig, dh_handles, handles.mainAxes, proj_vecs);
%         drawnow;
%     end
% 
% 
%     % Set the projection to exactly the desired vecs
% %     handles.functions.plot_panel(handles.DataHighFig, dh_handles, handles.mainAxes, desired_vecs);
% %     drawnow;
%     handles.proj_vecs = proj_vecs;
% 
%     guidata(hObject, handles);
%     
% end
% 
% 
% function R = find_rotation_matrix(v1, v2, alpha)
% % R = find_rotation_matrix(v1, v2)
% %
% % v1: Nx1, v2: Nx1
% %
% % given two vectors, find the rotation matrix that could transform v1 to v2
% %
% % in other words, find R such that v2 = R * v1
% %
% %  Thus, if you have a point that also needs to be rotated by the same
% %  angle, use x_new = R * x_old.
% %
% % Author: bcowley 2012
% 
% 
%     % Idea:  
%     %
%     %  find w1 and w2, such that W = [w1 w2 : : :] is the Gram-Schmidt matrix found
%     %  by performing Gram-Schmidt on V = [v1 v2 : : :]
%     %
%     %  then, find the angle between v1 and v2, alpha
%     %
%     %  R = W * [rotation_matrix_1_1(alpha)] * W' 
% 
%     if (size(v1,1)==1)
%         v1 = v1';
%     end
%     if (size(v2,1)==1)
%         v2 = v2';
%     end
%     
%     v1 = v1 / norm(v1);
%     v2 = v2 / norm(v2);
%     
%     % find bases
%     V = randn(length(v1), length(v1));
%     V(:,1) = v1;
%     V(:,2) = v2;
% 
%     [W r] = qr(V);
%     W(:,1) = sign(W(:,1)'*V(:,1))*W(:,1);  % QR may change the signs...
%     W(:,2) = sign(W(:,2)'*V(:,2))*W(:,2);
% 
%     
%     % get rotation matrix
% 
%     Rmatrix = eye(length(v2));
%     Rmatrix(1,1) = alpha;
%     Rmatrix(1,2) = -sqrt(1-alpha^2);
%     Rmatrix(2,1) = sqrt(1-alpha^2);
%     Rmatrix(2,2) = alpha;
%     
%     R = W * Rmatrix * W';
% 
% end



function find_proj_helpbutton_Callback(hObject, eventdata, handles)
% help button for find projections

    helpbox(['FindProjection shows different 2-d projections found\n' ...
        'by common cost functions.\n\n' ...
        'Random displays a random projection.\n\n' ...
        'PCA displays the projection with the greatest variance.\n\n' ...
        'LDA displays the projection that best linearly separates\n' ...
        'the population activity between experimental conditions.\n\n' ...
        'PCA Cluster Means displays the projection in which the means\n' ...
        'of the experimental conditions are most spread out.']);
end
