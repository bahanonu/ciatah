function [MSD,tau,D] = Kehl(Trajectory)

% Kehl.m measures the mean squared displacement (MSD) from a trajectory.
% Kehl is written by Maxime Deforet, May 21 2013. MSKCC.
% Contact : maxime.deforet@gmail.com

% This code contains no loop. Each step is "vectorized", therefore pretty
% fast.
% The idea is to compute all the possible pairings in only one time.

% Trajectory = list of T positions (x,y,t). Or (x,t) or (x,y,z,t) or even
% higher dimension (x1,x2,x3,...t)
% tau is the list of all the possible time intervals within the trajectory.
% MSD is a list of mean squared displacements, for each value of tau.

% MSD(tau) = sqrt( x(i)^2 - x(i+tau)^2 ), averaged over i.

T =  size(Trajectory,1); % T is the number of point in the trajectory;

[ I j ] = find(triu(ones(T), 1)); % list of indices of possible pairings
D = zeros(T, T);
D( I + T*(j-1) ) = (sum(abs( Trajectory(I,1:end-1) - Trajectory(j,1:end-1) ).^2, 2)); % Squared distance computation in one line !

% Time intervals between the two points of each pairing :
dt = zeros(T, T);
dt( I + T*(j-1) ) = -( Trajectory(I,end) - Trajectory(j,end) );

% Then D is a list of squared distances. dt is a list of corresponding
% time intervals. Now we have to average all D values over different dt
% values

% We first remove all 0 values from dt matrix, and from D as well.
idx_0=find(dt==0);
dt(idx_0)=[];
D(idx_0)=[];

% Then we sort dt in ascending order, and sort D in the same way.
[DT,idx]=sort(dt(:));
DD=D(idx);
% We now have DD and DT, respectively a list of squared distances, and
% the corresponding time intervals.

% Now we have to compute the mean DD for each possible value of DT.
% Let's get the first and last indices of each set of DT
First_idx=find(DT-circshift(DT,1)~=0);
Last_idx=find(DT-circshift(DT,-1)~=0);
% For instance, DT=1 start at First_idx(1) and end at Last_idx(1)
%               DT=2 start at First_idx(2) and end at Last_idx(2)...

% To get the average, we first compute the cumulative (starting from 0), then we
% get "the derivative of the cumulative".
C=cumsum([0,DD]);
% For each possible value of DT, the mean of DD is the difference between
% the initial index and the last index of the cumulative, divided by the
% number of elements between those two indices :
MSD=(C(Last_idx+1)-C(First_idx))'./(Last_idx-First_idx+1); 
tau=DT(First_idx); % list of intervals


% plot(tau,MSD)