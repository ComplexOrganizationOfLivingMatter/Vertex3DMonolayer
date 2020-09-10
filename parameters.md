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

### Nodal Network (N or D)
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

### Vertices network (V)

K<sub>v0</sub> is cell junction elasticity
```Matlab
Mat.V.k0=0.05;  
```

K<sub>v</sub> is cell junction stiffness.
```Matlab
Mat.V.k=1.0;
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

You can change the number of ablated cells by setting 'AblationN':
```Matlab
Set.AblationN=1;
```

(QUESTION) Basal == bottom?
```Matlab
Set.FixedBasal=1;
```

Set the time step at which ablation will take place:
```Matlab
Set.AblationTimeStep=1;
```

Regarding the mid-plane (or the possibility of apico-basal intercalations), you can set if the cells at the wound edge may undergo apico-basal intercaltions:
Option 1: mid-plane vertices allowed
Option 0: no mid-plane vertices allowed

```Matlab
Set.YmidWound=1;
```

You may also set a thrhold for intercalations on wound edge. It reflects the maximum aspect ratio allowed.
```Matlab
Set.WRemodelThreshold=0.1;
```
### Contractility
Different options for the contractility have been added. The following could be associated to bottom (suffix 'Bot'), top ('Top') or lateral ('Lat') contractility. Also, the variable refering to the actual value of the contractility changes: EpsCTWE (the 'T' means top), EpsCBWE ('B' from bottom) and EpsCLWE ('L' of lateral).

Step function (Option 1): given a starting time and a value, the contractility will reach that value at that time point. Thus, Set.StartTimeEcBot and Set.EpsCBWE are required to be set.

Hat function (Option 2): At a starting point (StartTimeEcBot), contractility starts to rise until it reaches a peak value (EpsCBWE) at some point (PeakTimeEcBot). Then, it starts to decrease reaching contracility equals to 0 at "EndTimeEcBot".

An example of the hat function for bottom contractility would be:

```Matlab
Set.EcTypeBot=2;
```

The time at which the contractility starts to be applied:

```Matlab
Set.StartTimeEcBot=6;
```
The time at which the contractility reaches the prescribed value (EpsCBWE):
```Matlab
Set.PeakTimeEcBot=18;
Set.EpsCBWE=1.3;
```
And the time at which the contractlity is reduced to zero.
```Matlab
Set.EndTimeEcBot=24;
```

The same type can be applied to the 'top' layer. Note that variables difer:
```Matlab
Set.EcTypeTop=2;
Set.EpsCTWE=2.3;
Set.StartTimeEcTop=1;
Set.PeakTimeEcTop=16;
Set.EndTimeEcTop=800;
```
Note that values contractility values of EpsCTWE <= 2.2, were found not to be sufficient to close the wound. See [article]( #Citation) for more information.

And another example of lateratl ablation information:
```Matlab
Set.EcTypeLat=1;
Set.EpsCLWE=0.01;
Set.StartTimeEcLat=13;
Set.PeakTimeEcLat=13;
Set.EndTimeEcLat=0;
```

## Substrate friction + Propulsion
 __IMPORTANT__: while using these options, make sure that the botttom vertices are not fully fixed

Need to understand better this section.

```Matlab
Set.Propulsion=false;
```
Friction viscosity:
```Matlab
Set.eta=.0;
```

Region 1 with Propulsion forces Set.mu1
```Matlab
Set.PropulsiveRegionX1=[0 round(Set.nx/5)];
Set.PropulsiveRegionY1=[0  Set.ny];
```
Velocity
```Matlab
Set.mu1=[.2 0 0]; 
```

Region 2 with Propulsion forces Set.mu2
```Matlab
Set.PropulsiveRegionX2=[round(Set.nx/1.33) Set.nx];
Set.PropulsiveRegionY2=[0  Set.ny];
Set.mu2=[-.2 0 0];
```