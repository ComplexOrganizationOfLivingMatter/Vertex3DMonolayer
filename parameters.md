# Input Data for 3D analysis of  wound healing on monolayers

This is a Matlab project and it was tested for Matlab R2018a

v4.9 - 20/7/2020

## Citation

Ioannou, F., Dawi, M.A., Tetley, R.J., Mao, Y., Munoz, J.J., 
Development of a new 3D hybrid model for epithelia morphogenesis, 
Frontiers in Bioengineering and Biotechnology, Vol. 8, pp. 1-11, 2020, 
https://doi.org/10.3389/fbioe.2020.00405


## Initial setup

The inputs required for this vertex model can be seen at 'SetDefaults.m'. Here, we will explain the 'inputData\*.m' and the parameters used there.

The program can output a VTK files of each time step to display the cells' shape.

```Matlab 
Set.OutputVTK=true;
```
or

```Matlab
Set.OutputVTK=false;
```

One important parameter is the how much time will the model be evolving. For instance, if you want to set a final time of 40s, the T_end will be
```Matlab
Set.tend=15;
```
Also you can set the time-step size (in wound healing applied during closure).
```Matlab
Set.dt=1;
```
The time may also be declared as a vector. (__NEED TO BE CHECKED__)     
```Matlab
Set.t=[0:0.6:6 6+Set.dt:Set.dt:Set.tend];
```

If not declared, would look like:

```Matlab
Set.t=0:Set.dt:Set.tend
```

On each time step there is a relaxation and at the end of each step, we check if the process has converged. You can set the maximun number of iteration if not reached convergence.
```Matlab
Set.MaxIter=25;
```

__TODO__

```Matlab
Set.StepHalvingMax=3;
```

__TODO__

```Matlab
Set.yRelaxation=true; % trueBottom vertices no not follow %???
```

### Geometry

In order to perfectly match your experimental results, you __need__ too add the cell centers of each cell. They should be in an array of 2xN called ```X```, being N the number of cells within a Matlab file (.mat). Each cell centre are in pixel units. Examples of this file are 'CellCentres.m' and 'CellCentres99.m'

__TO CHECK__ Could you create the cell centers randomly?

```Matlab
Set.CellCentres='CellCentres.mat'
```
(__IMPROVE__) Geometrical properties of the vertex model, if not experimental lovation

Set.nx=8;
Set.ny=8;
Set.nz=1;

Cells initial height are expressed in micrometers (µm):
```Matlab
Set.h=3;
```

Scaling of X coordinates. 
```Matlab
Set.umPerPixel=0.0527;
```

### Boundary Conditions (BC)

In this vertex model exits several ways of defining the boundary conditions:

* 1: Incremental applied x-displacement at X=cont two boundaries. Stretching simulation.
* -1: Same as 1, but only applied on the first step.
* 2: Applied force. Stretching simulation.
* 3: Fixed boundary. z for bottom, x and y for domain boundary. Wound healing simulation.
* 4: Fixed z for bottom, simulation of propulsion and friction (Extracellular Matrix)
* 5: Free Boundary
* 6: Fixed z for bottom with a region of free z bottom

You can properly set this parameter by entering
```Matlab
Set.BCcode=3;
``` 
If option 6 is selected, ```Set.ZFreeX``` should be define as follows:
```Matlab
Set.ZFreeX=[X1 X2];
```
where X1 is __XXXXX__ and X2 __XXXXX__

### Model type
The model type referes to , in which we have 3 options:

1. Same top/bottom with no mid-plane vertices.
2. same top/bottom with mid-plane vertices.
3. different top/bottom with mid-plane vertices.

This features is defined as:
```Matlab
Set.ModelTop=1;
```

Note that in option 1, apico-basal intercalations ('scutoids') are not possible, whilst in option '2' are possible but unlikely. Option 3 allow scutoids and different apico-basal organization.

(__CHECK__)
The parameter ```RemodelDelta``` refers to tol<sub>R</sub>. When ```Set.RemodelDelta=0``` the standard Delaunay is recovered; while for ```RemodelDelta>0``` suboptimal stretched triangles and cells are permitted (elongated cells will appear). 

Recommended:

```Matlab
Set.RemodelDelta = 0.2;
```

Similarly, we can set the tolerance for filtering boundary triangles in Delaunay remodeling. Using the formula:

```
r/R > RemodelTolF
``` 

Triangles with r=cricumradius and R=inradius satisfying the above formula will be filtered.

```Matlab
Set.RemodelTolF=50;
```

## Material properties
λ<sub>V</sub>

Volume penalisation. When higher cells cannont change its volume.
For instance, if lambda_volume == 20, then effective volume change is 7% (approx)

```Matlab
Set.lambdaV=20;
```

The Nodal network (N), here is represented as a Delaunay (D) network, connecting each cell centre.

K<sub>d0</sub> which represents cytoplasm elasticity.
```Matlab
Mat.D.k0=0.5;
```

K<sub>d</sub> is related to citoplasm stiffness
```Matlab
Mat.D.k=0.3;
```

Epsilon<sup>c</sup>: Background cell's connectivity
Tension of each cell junction
Contractility
No distinction top, bottom ,lateral on nodal
```Matlab
Mat.D.EpsC=0.2;
```

% Vertex (V)
```Matlab
Mat.V.k0=0.05; % K_v0: cell junction elasticity
```

```Matlab
Mat.V.k=1.0; % K_v: cell junction stiffness
```

Gamma of the Rheological model
Remodelling rate: tissue fluidity and viscosity
Rest length changes (gamma)
```Matlab
Mat.V.gamma=0.2;
```

Epsilon_top, Epsilon_bottom and Epsilon_lateral
Contraction of the wound edge cell contractility
Wound edge cell cortex or junction
```Matlab
Mat.V.EpsCT=0.2; % Contractility Top
Mat.V.EpsCB=0.2; % Contractility Bottom
Mat.V.EpsCL=0.40; % Contractility Laterals
```


## Ablation

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

% value of applied contracitlity at vertices on bottom of wound edge;
Set.EpsCBWE=1.3;    

% Contractility timing
Set.StartTimeEcBot=6;  % The time at which the contractility start to be applied
Set.PeakTimeEcBot=18;   % The time at which the contractility reaches the prescribed value (hat function)
Set.EndTimeEcBot=24;    % The time at whihc the contractility reduced to zero (hat  function

%% Top ablation info
Set.EcTypeTop=2;
% EpsCTWE \~= 2.2, contractility is insufficient to close the wound
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

## Substrate friction + Propulsion
 __IMPORTANT__: while using these options, make sure that the botttom vertices are not fully fixed

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