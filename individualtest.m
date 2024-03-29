%% Set estimation parameters and data choice
clear all
%%
dataname = 'Empirical_result/GB_result/IPCADATA_FNW36_RNKDMN_CON_K6'
clearvars -except Krange K dataname
load([dataname]);
K=6
%%
Rrange              = [1:36];
collect             = nan(36,1);
bootsims            = 1000;
N                   =12813;
T=599;
RFITS_GB_null            = nan(N,T);

%% Bootstrap
for R=Rrange
als_opt.MaxIterations       = 10000;
als_opt.Tolerance           = 1e-6;

nuGB= GammaBeta
nuGB(R,:)=0

for t=1:T
    XFITS_GB_null(:,t)        = W(:,:,t)*nuGB*Factor(:,t);
end


if bootsims>0
    tic
    
    RESID =  X- XFITS_GB;
    boot_GB = nan(1000, K);
    rng('shuffle')
    for boot=1:bootsims
        % bootstrap indexes
        btix    = [];
        block   = 1;        
        tmp     = 0;
        while tmp<T
            fillin = unidrnd(T) + (0:(block-1));
            fillin = fillin(fillin<=T);
            btix(tmp+(1:length(fillin))) = fillin;
            tmp = tmp+length(fillin);
        end
        btix    = btix(1:T);

        dof     = 5;
        tvar    = dof/(dof-2);

        % Data construction
        % bsxfun calculation among all the factors in matrix 
        X_b     = XFITS_GB_null + bsxfun(@times, RESID(:,btix) , (1/sqrt(tvar))*random('t',dof,1,T) );% yes wild
        LOC_1= ~isnan(X_b)  

         
        % Estimation
        GB_Old  =nuGB;
        F_Old   = Factor;

        tol         = 1;
        iter        = 0;
        while iter<=als_opt.MaxIterations && tol>als_opt.Tolerance
            [GB_New,F_New] = num_IPCA_estimate_ALS(GB_Old,W,X_b,Nts);
            tol     = max([ abs(GB_New(:)-GB_Old(:)) ; abs(F_New(:)-F_Old(:)) ]);
            F_Old   = F_New;
            GB_Old  = GB_New;
            iter    = iter+1;
        end
        
        boot_GB(boot,:) = GB_New(R:R,1:end);
        
    end
    timing.boot.sims = bootsims;
    timing.boot.time = toc;

A=GammaBeta(R:R,:);
result=mean(sum(boot_GB.^2,2)>mySOS(A))
collect(R,1)=result

end
end
%%
