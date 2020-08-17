function [ nodalConnectivity,Ener,nodesCoords0,nodesCoords,verticesCoords,Cell,Mat,Set,Stress,Ablated] = MainIncrements( Mat,Set )
%% Main Subroutine for model inisialisation and incremental loop
% INPUT
% Set = General settings. See SetDefaults.m for itsstructure
% Mat = Material parameters. See SetDefaults.m for itsstructure
% OUTPUT
% C   = Model triangulasion
% Ener(i,:) = Energy terms at time increment i
% LOCALc
% nodalConnectivity(i,:) nodes in nodal bar element i % C before
% verticesConnectivity(i,:) vertices in vertex bar element i % Cv before
% trianglesConnectivity(i,:) nodes forming triangle i % T before renaming
% nodesCoords(i,:) coordinates of node i %X before
% verticesCoords(i,:) coordinates of vertex i %Y before
% nodesCoords0 = Initial Nodal coordinates %X0 before
% verticesCoords0 = Initial vertices coordinates %Y0 before

if ~exist(strcat('.',Esc(),'Main.m'),'file')
    cd ..
    if ~exist(strcat('.',Esc(),'Main.m'),'file')
        error('Run Main from folder that contains file Main.m');
    end
end

% DiaryFile='Output.log';
% if exist(DiaryFile,'file')
%     delete(DiaryFile)
% end
%  diary(DiaryFile);
%  
 
%MAININCREMENTS is called from Main.m
addpath(strcat(pwd));
addpath(strcat(pwd,Esc,'Geo'));
addpath(strcat(pwd,Esc,'Utility'));
addpath(strcat(pwd,Esc,'Wound'));
addpath(strcat(pwd,Esc,'Rheology'));
addpath(strcat(pwd,Esc,'VTK'));
addpath(strcat(pwd,Esc,'Remodel'));
%% Default settings
[Mat,Set]=SetDefaults(Mat,Set);
if Set.Profiler
    profile on
end

%% Initialize
fprintf('Initialising model\n');
Set.iIncr=0;
if ~isfield(Set,'t')
    Set.t=0:Set.dt:Set.tend;
end
Set.Nincr=length(Set.t);
[nodesCoords,nodesCoordsN,nodesCoords0,nodalConnectivity,verticesConnectivity,trianglesConnectivity,Cell,verticesCoords,verticesCoordsN,verticesCoords0,L,Ln,L0,N,Set,xExternal,Ablated,Ymid]= InitializeModel(Set);
Stress.D.s=zeros(size(nodalConnectivity,1),1);
Stress.V.s=zeros(size(verticesConnectivity,1),1);
Ener.D.e=zeros(size(nodalConnectivity,1),3); % energy due to [Elastic, tissue comtract, Wound contraactility]
Ener.V.e=zeros(size(verticesConnectivity,1),3); % energy due to [Elastic, tissue comtract, Wound contraactility]
% Initialise Mat.nDelay, Ld and ld. Ld{end}=rest length a t-Delay,Ld{1}=rest length at previous time
[Ld,ld,Mat]=DelayInit(nodalConnectivity,verticesConnectivity,Ln,Mat,nodesCoords,verticesCoords,Set);
Set=ContractilityInit(Set);
[Set]=MarkPropulsiveCells(nodesCoords,Cell,Set);
Vol=zeros(length(Cell),Set.Nincr);
CreateVTK(nodesCoords,nodesCoords0,nodalConnectivity,verticesConnectivity,Cell,Ablated,L,L0,Stress,Set,verticesCoords,verticesCoords0,'VTKResults')
%% Dofs and External force
fprintf('Applying Boundary Conditions\n');
[gext,dofP,U0]=BC(Set,nodesCoords,xExternal);
dof=GetDofs(Ablated,Set,dofP,Ymid);
gext(dofP)=0;
x=[reshape(nodesCoords',Set.nodes*Set.dim,1);reshape(verticesCoords',Set.nvert*Set.dim,1)]; % row of displacements
%% Loop on Time increments
fprintf('Starting Increments\n');
 dxr=0;
Set.StepHalving=0;
i=1;
while i<=Set.Nincr
    Set.iter=1;
    Set.iIncr=i;
    if i>1
        Set.dt=(Set.t(i)-Set.t(i-1));
    else
        Set.dt=Set.t(2);
    end
    %---------------------  Applied Displacement---------------------------
    if (Set.BCcode>0 || i==1) && Set.StepHalving==0
        x(dofP)=x(dofP)+U0(:,3)*i/Set.Nincr;
    end
    %---------------------  Update Configuration --------------------------
    nodesCoords=reshape(x(1:Set.dim*Set.nodes),Set.dim,Set.nodes)';
    verticesCoords=reshape(x(Set.dim*Set.nodes+1:Set.dim*(Set.nodes+Set.nvert)),Set.dim,Set.nvert)';
    verticesCoords=UpdateY(trianglesConnectivity,nodesCoords,N,verticesCoords,Ablated.Yr,Ablated.YrZ,Ymid);% update vertices
    %---------------------  Update Lengths --------------------------------
    L=UpdateL(nodalConnectivity,verticesConnectivity,L,Ln,Ld{end},ld{end},Mat,nodesCoords,nodesCoordsN,verticesCoords,verticesCoordsN,Set,Ablated);
    %---------------------- Ablate-----------------------------------------
    if Set.iIncr==Set.AblationTimeStep && Set.AblationN>0
        [Ablated,Cell,nodesCoords,trianglesConnectivity,nodalConnectivity,verticesConnectivity,verticesCoords,N,L,Ln,L0,Stress,nodesCoords0,verticesCoords0,nodesCoordsN,verticesCoordsN,xExternal,Set,x,dof,Ymid]=BuildWound...
            (Ablated,Cell,nodesCoords,trianglesConnectivity,nodalConnectivity,verticesConnectivity,verticesCoords,N,L,Ln,L0,Stress,nodesCoords0,verticesCoords0,nodesCoordsN,verticesCoordsN,xExternal,Set,Ymid);
    end 
    %---------------------- Remodel----------------------------------------
    if Set.StepHalving==0
        [Ablated,Cell,nodesCoords,trianglesConnectivity,nodalConnectivity,verticesConnectivity,verticesCoords,N,L,Ln,L0,Stress,nodesCoords0,verticesCoords0,nodesCoordsN,verticesCoordsN,xExternal,Set,x,dof,Ymid]=Remodel...
            (Ablated,Cell,nodesCoords,trianglesConnectivity,nodalConnectivity,verticesConnectivity,verticesCoords,L,Ln,L0,Stress,nodesCoords0,verticesCoords0,nodesCoordsN,xExternal,Set,Ymid);
        Xnn=nodesCoords; % Store values after remodelling in case step halving is activated
        Ynn=verticesCoords;
        Lnn=L;
        dof0=dof;
    end
    %---------------------- Compute K,g------------------------------------
    % Solution X such that X+U gint(X)+gext=0
    [Cell,Ener,g,K,Set,L,Stress]=gKGlob(Ablated,nodalConnectivity,verticesConnectivity,Cell,Mat,L,L0,N,Stress,Set,i,trianglesConnectivity,nodesCoords,verticesCoords,verticesCoordsN,Ymid);
    %---------------------  Applied External force-------------------------
    gext=[gext(1:Set.nodes*Set.dim);zeros(length(x)-Set.nodes*Set.dim,1)];
    g=g-gext*i/Set.Nincr;   
    gr=norm(g(dof));
    dx=zeros(size(x));  
    while (gr>Set.tol || dxr>Set.tol) && Set.iter<Set.MaxIter
        %% Newton Raphson loops
        %---------------------- Solve and Add Increment -------------------
        dx(dof)=-K(dof,dof)\g(dof);
        x=x+dx; % update nodes
        
        %---------------------  Update Configuration ----------------------
        nodesCoords=reshape(x(1:Set.dim*Set.nodes),Set.dim,Set.nodes)';
        verticesCoords=reshape(x(Set.dim*Set.nodes+1:Set.dim*(Set.nodes+Set.nvert)),Set.dim,Set.nvert)';
        verticesCoords=UpdateY(trianglesConnectivity,nodesCoords,N,verticesCoords,Ablated.Yr,Ablated.YrZ,Ymid);% update vertices
        
        %---------------------  Update Lengths ----------------------------
        L=UpdateL(nodalConnectivity,verticesConnectivity,L,Ln,Ld{end},ld{end},Mat,nodesCoords,nodesCoordsN,verticesCoords,verticesCoordsN,Set,Ablated);
        
        %---------------------- Recompute K,g------------------------------
        [Cell,Ener,g,K,Set,L,Stress]=gKGlob(Ablated,nodalConnectivity,verticesConnectivity,Cell,Mat,L,L0,N,Stress,Set,i,trianglesConnectivity,nodesCoords,verticesCoords,verticesCoordsN,Ymid);
        g=g-gext*i/Set.Nincr;
        
        dxr=norm(dx(dof)./x(dof));
        gr=norm(g(dof));
        if length(dof)<length(g)
            gr=gr/norm(g); % relative norm
        end
        fprintf('Step: % i,Iter: %i, dt=%e, Time=%e, ||gr||= %e ||dxr||= %e\n',i,Set.iter,Set.dt,Set.t(i),gr,dxr);
        Set.iter=Set.iter+1;
    end
    if gr>Set.tol || dxr>Set.tol || any(isnan(g(dof))) || any(isnan(dx(dof)))
        if Set.StepHalving<Set.StepHalvingMax
            if Set.StepHalving==0 && ~exist('dt0')
                dt0=Set.dt;
            end
            Set.StepHalving=Set.StepHalving+1;
            fprintf('Increment %i did not converge after %i iterations. Applying Step Halving %i.\n',i,Set.iter,Set.StepHalving);
            if i==1
                Set.t=[Set.t(i)/2 Set.t(i:end)];
                Set=UpdateEpsCW(Set,i); % adds new value
                Set.Nincr=Set.Nincr+1;
            elseif dt0/Set.StepHalvingMinDt > (Set.t(i)-Set.t(i-1))/2
                Set.t=[Set.t(1:i-1) Set.t(i-1)+dt0/Set.StepHalvingMinDt Set.t(i+1:end)];
                Set.StepHalving=Set.StepHalvingMax;
            else
                Set.t=[Set.t(1:i-1) Set.t(i-1)+(Set.t(i)-Set.t(i-1))/2 Set.t(i:end)];
                Set=UpdateEpsCW(Set,i); % adds new interpolated value to Set.EpsCWX
                Set.Nincr=Set.Nincr+1;
            end
            nodesCoords=Xnn; % Copy previous coordinates, with new remodelling
            verticesCoords=Ynn;
            L=Lnn;
            x=[reshape(nodesCoords',Set.dim*Set.nodes,1) ; reshape(verticesCoords',Set.dim*Set.nvert,1)];
            if Set.StepHalving==Set.StepHalvingMax % Remove relaxed dof
                dofYr=size(nodesCoords,1)*size(nodesCoords,2)+[Ablated.Yr(Ablated.Yr>0)*3-2 ; Ablated.Yr(Ablated.Yr>0)*3-1 ; Ablated.Yr(Ablated.Yr>0)*3];
                dof(ismember(dof,dofYr))=[]; % In last attempt, fix vertex displacements
            end
        else
            fprintf('Increment %i did not converge after %i iterations and %i Step Halvings.\n',i,Set.iter,Set.StepHalvingMax);
            break;
        end
    else
        if length(dof)~=length(dof0)
            warning('Increment converged with fixed relaxed vertex displacements.');
            % Apply same horizontal dissplacement of ring nodes to relaxed vertices
            verticesCoords=ForceRadialYDisplacement(Ablated,nodesCoords,nodesCoordsN,verticesCoords);
        end
        nodesCoordsN=nodesCoords;
        verticesCoordsN=verticesCoords;
        Ln=L;
        if Mat.nDelay>0
            for t=size(Ld,1):-1:2
                Ld{t}=Ld{t-1};
                ld{t}=ld{t-1};
            end
            Ld{1}=Ln;
            ld{1}=Lengths(nodalConnectivity,verticesConnectivity,nodesCoords,verticesCoords);
        end
        Ablated=WoundSize(Ablated,Cell,nodalConnectivity,verticesConnectivity,nodesCoords0,Set,verticesCoords,nodesCoords);
        CreateVTK(nodesCoords,nodesCoords0,nodalConnectivity,verticesConnectivity,Cell,Ablated,L,L0,Stress,Set,verticesCoords,verticesCoords0,'VTKResults')
        for c=1:length(Cell)
            Vol(c,i)=Cell{c}.Vol;
        end
        Ablated.Vol=Vol(:,1:i);
        fprintf('STEP %i has converged in %i iterations. Time=%e\n',Set.iIncr,Set.iter,Set.t(i))
        if ~isempty(Ablated.AbNodesBot) && size(Ablated.RemodelN,1)>=i && length(Ablated.AreaTop)>=i && length(Ablated.NRingB)>=i
            fprintf('Remodellings=%i %i. AreaTop=%e. NRing=%i\n',Ablated.RemodelN(i,:),(Ablated.AreaTop(i)/Ablated.AreaTop(1))*100, Ablated.NRingB(i))
            plot(Set.t(1:i),Ablated.AreaTop(1:i)/Ablated.AreaTop(1)*100);
        end
        Set.StepHalving=0;
        save('Results')
        i=i+1;
    end
end

Set.t(i:end)=[];
toc
if Set.Profiler
    profile viewer
end
diary off;
end
%%
function Set=UpdateEpsCW(Set,i)
if ~isfield(Set,'EpsCWBot') || ~isfield(Set,'EpsCWLat') || ~isfield(Set,'EpsCWLat')
    return
end
if i==1
    Set.EpsCWBot=[Set.EpsCWBot(1) Set.EpsCWBot];
    Set.EpsCWTop=[Set.EpsCWTop(1) Set.EpsCWTop];
    Set.EpsCWLat=[Set.EpsCWLat(1) Set.EpsCWLat];
elseif i==length(Set.EpsCWBot)
    Set.EpsCWBot=[Set.EpsCWBot Set.EpsCWBot(end)];
    Set.EpsCWTop=[Set.EpsCWTop Set.EpsCWTop(end)];
    Set.EpsCWLat=[Set.EpsCWLat Set.EpsCWLat(end)];
else
    ti=Set.t(i);
    tim=Set.t(i-1);
    tip=Set.t(i+1);
    a=(ti-tim)/(tip-tim);
    EpsCWBot=Set.EpsCWBot(i-1)+a*(Set.EpsCWBot(i)-Set.EpsCWBot(i-1));
    EpsCWTop=Set.EpsCWTop(i-1)+a*(Set.EpsCWTop(i)-Set.EpsCWTop(i-1));
    EpsCWLat=Set.EpsCWLat(i-1)+a*(Set.EpsCWLat(i)-Set.EpsCWLat(i-1));
    Set.EpsCWBot=[Set.EpsCWBot(1:i-1);  EpsCWBot ;Set.EpsCWBot(i:end)];
    Set.EpsCWTop=[Set.EpsCWTop(1:i-1);  EpsCWTop ;Set.EpsCWTop(i:end)];
    Set.EpsCWLat=[Set.EpsCWLat(1:i-1);  EpsCWLat ;Set.EpsCWLat(i:end)];
end
end
%%
function Y=ForceRadialYDisplacement(Ablated,X,Xn,Y)
% In order to garantee convergence after several step-halving, relaxed
% vertices are fixed. In cases when step halving is continuously applied,
% wound area remains constant. For avoiding this, vertices are moved the
% same displacement as the one of nodes at wound ring.
nTop=length(Ablated.NRingBot);
nBot=length(Ablated.NRingTop);
Xcb=sum(X(Ablated.NRingBot,:))/nBot;
Xct=sum(X(Ablated.NRingTop,:))/nTop;
Xcbn=sum(Xn(Ablated.NRingBot,:))/nBot;
Xctn=sum(Xn(Ablated.NRingTop,:))/nTop;
if size(X,1)~=size(Xn,1) 
    return;
end
Rt=0;
Rb=0;
Rtn=0;
Rbn=0;
for i=1:nBot
    Rb=Rb+norm(X(Ablated.NRingBot(i),:)-Xcb)/nBot;
    Rbn=Rbn+norm(Xn(Ablated.NRingBot(i),:)-Xcbn)/nBot;
end
for i=1:nTop
    Rt=Rt+norm(X(Ablated.NRingTop(i),:)-Xct)/nTop;
    Rtn=Rtn+norm(Xn(Ablated.NRingTop(i),:)-Xctn)/nTop;
end
dRt=abs(Rt-Rtn); % variation of mean Radious between time-step. Force positive for closing.
dRb=abs(Rb-Rbn); % variation of mean Radious between time-step
nTop=size(Ablated.VRingTop,1);
nBot=size(Ablated.VRingBot,1);
for i=1:nTop
    Yi=Ablated.VRingTop(i,1);
    Y(Yi,:)=Y(Yi,:)+(Xct-Y(Yi,:))*dRt/norm(Y(Yi,:)-Xct);
end
for i=1:nBot
    Yi=Ablated.VRingBot(i,1);
    Y(Yi,:)=Y(Yi,:)+(Xcb-Y(Yi,:))*dRb/norm(Y(Yi,:)-Xcb);
end
end