% Inputa Data for 3D analysis of  wound healing on monolayers
%
% v4.9
% 20/7/2020
% REFERENCE:
%
% Ioannou, F., Dawi, M.A., Tetley, R.J., Mao, Y., Munoz, J.J.
% Development of a new 3D hybrid model for epithelia morphogenesis
% Frontiers in Bioengineering and Biotechnology, Vol. 8, pp. 1-11, 2020
%

%% Initial setup
% Does the program outputs the VTK files
Set.OutputVTK=true;
% Maximum number of iterations within a time step
Set.MaxIter=25;
% ??
Set.StepHalvingMax=3;

%Q: How can I couple simulations with natural procedures?
Set.yRelaxation=true; % trueBottom vertices no not follow %???
Set.tend=15;          % Final time % tend = 150 (40 seconds)
Set.dt=1;             % Time-step size (in wound healing applied during closure)
% May be declared as a vector:
% Set.t=[0:0.6:6 6+Set.dt:Set.dt:Set.tend]; % Time history. If not declared, Set.t=0:Set.dt:Set.tend
% Set.t=[0:0.6:6 12:3:72]; % Filippos

%% GEOMETRY:
% For experimental location of Cell Centres:
% Set.CellCentres='CellCentres106.mat';%'Xtb.mat';% CellCentres.mat=62 cells. CellCentres1.mat=153 cells, CellCentres221.mat=221 cells, ...

% Geometrical properties if not experimental lovation
Set.nx=8;
Set.ny=8;
Set.nz=1;
Set.h=3; % Height in um
Set.umPerPixel=0.0527; % Scaling of X coordinates. Units in *.mat files with cell centres are in pixel units.

%% BOUNDARY CONDITIONS (BC):
% =1: Incremental applied x-displacement at X=cont two boundaries. Stretching simulation.
% =-1: Same as 1, but only applied on the first step.
% =2: Applied force. Stretching simulation.
% =3: Fixed boundary. z for bottom, x and y for domain boundary. Wound healing simulation.
% =4: Fixed z for bottom, simulation of propulsion and friction (Extracellular Matrix)
% =5: Free Boundary
% =6: Fixed z for bottom with a region of free z bottom
Set.BCcode=3; 

%Only if Set.BCcode == 6
%The Region of wiht Free-Z defined by Set.ZFreeX=[X1 X2];
Set.ZFreeX=[round(Set.nx/5) round(Set.nx/1.2500)];

%% Model type
% 1 = same top/bottom with no mid-plane vertices % scutoids are not possible
% 2 = same top/bottom with mid-plane vertices % scutoids are possible but unlikely
% 3 = different top/bottom with mid-plane vertices % scutoids are possible
Set.ModelTop=1;


%% Q: Don't know the difference between gamma and Remodelling delta 
% Tolerance for graded Delaunay when Set.Remodel>0
% RemodelDelta=0 standard Delaunay
% RemodelDelta>0 allows elongated cells.
% Recommended = 0.2
Set.RemodelDelta = 0.2;

% Tolerance for filtering boundary triangles in Delaunay Remodeling.
% r/R>TolF are filtered, r=cricumradius, R=inradius.
Set.RemodelTolF=50;

%% --------- MATERIAL PROPERTIES --------- %%
% Volume penalisation
% When higher cells cannont change its volume
% if lambda_volume == 20, then effective volume change is 7% (approx)
Set.lambdaV=20;

%% Delaunay (D) = Nodal (N)
Mat.D.k0=0.5; %K_d0: cytoplasm elasticity
Mat.D.k=0.3; %K_d: cytoplasm stiffness

% Epsilon_c: Background cell's connectivity
% Tension of each cell junction
% Contractility
% No distinction top, bottom ,lateral on nodal
Mat.D.EpsC=0.2;

% Vertex (V)
Mat.V.k0=0.05; % K_v0: cell junction elasticity
Mat.V.k=1.0; % K_v: cell junction stiffness
% Gamma of the Rheological model
% Remodelling rate: tissue fluidity and viscosity
Mat.V.gamma=0.2;

% Epsilon_top, Epsilon_bottom and Epsilon_lateral
% Contraction of the wound edge cell contractility
% Wound edge cell cortex or junction
Mat.V.EpsCT=0.2; % Contractility Top
Mat.V.EpsCB=0.2; % Contractility Bottom
Mat.V.EpsCL=0.40; % Contractility Laterals

%% --------- Ablation --------- %%
% Number of ablated cells
Set.AblationN=1;
% ? Basal = bottom
Set.FixedBasal=1;
% The time step at which ablation will take place.
Set.AblationTimeStep=1;
% YmidWound:
% =1 mid-plane vertices on the wound edge
% =0 without mid-plane vertices on the wound edge
Set.YmidWound=1;
% Threshold for intercalation on the wound edge: it is the maximum allowed
% aspect ratio
Set.WRemodelThreshold=0.1;

%% Bottom ablation info
% Type of The contractility  profile. See 'help ContractilityInit'
% =1 Step function (needed parameter Set.StartTimeEcBot, Set.EpsCBWE)
% =2 Hat  function  (needed parameter Set.StartTimeEcBot, Set.PeakTimeEcBot, Set.EndTimeEcBot, Set.EpsCBWE)
Set.EcTypeBot=2;
Set.EpsCBWE=1.3;    % value of applied contracitlity at vertices on bottom of wound edge;

% Contractility timing
Set.StartTimeEcBot=6;  % The time at which the contractility start to be applied
Set.PeakTimeEcBot=18;   % The time at which the contractility reaches the prescribed value (hat function)
Set.EndTimeEcBot=24;    % The time at whihc the contractility reduced to zero (hat  function

%% Top ablation info
Set.EcTypeTop=2;
% EpsCTWE ~= 2.2, contractility is insufficient to close the wound
Set.EpsCTWE=2.3; % contractilty top wound edge
Set.StartTimeEcTop=1;
Set.PeakTimeEcTop=16; % 6+6+Set.dt;
Set.EndTimeEcTop=800;

%% Lateral ablation info
Set.EcTypeLat=1;
Set.EpsCLWE=0.01;    % contractility lateral wound edge
Set.StartTimeEcLat=13;
Set.PeakTimeEcLat=13;
Set.EndTimeEcLat=0;

%% --------- Substrate friction + Propulsion --------- %%
%% IMPORTANT: while using these options, make sure that the botttom vertices are not fully fixed

Set.Propulsion=false;

Set.eta=.0;        % friction viscosity

% Region 1 with Propulsion forces Set.mu1
Set.PropulsiveRegionX1=[0 round(Set.nx/5)];
Set.PropulsiveRegionY1=[0  Set.ny];
Set.mu1=[.2 0 0];       % velocity

% Region 2 with Propulsion forces Set.mu2
Set.PropulsiveRegionX2=[round(Set.nx/1.33) Set.nx];
Set.PropulsiveRegionY2=[0  Set.ny];
Set.mu2=[-.2 0 0];       % velocity