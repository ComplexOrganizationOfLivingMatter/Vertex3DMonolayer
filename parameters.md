# Input Data for 3D analysis of  wound healing on monolayers

20/7/2020 - v4.9

## Reference:
Ioannou, F., Dawi, M.A., Tetley, R.J., Mao, Y., Munoz, J.J., 
Development of a new 3D hybrid model for epithelia morphogenesis, 
Frontiers in Bioengineering and Biotechnology, Vol. 8, pp. 1-11, 2020, 
https://doi.org/10.3389/fbioe.2020.00405

## Paramaters

The inputs required for this vertex model can be seen at: 'SetDefaults.m'

Here, we will explain the 'inputData\*.m' and the parameters used there.

### Initial setup

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
% Set.t=[0:0.6:6 6+Set.dt:Set.dt:Set.tend];
```

If not declared, would look like:

```Matlab
Set.t=0:Set.dt:Set.tend
```

Maximum number of iterations within a time step
Set.MaxIter=25;

Set.yRelaxation=true; % trueBottom vertices no not follow %???

Set.StepHalvingMax=3;