stagesIdeal = repmat(pIdeal,1,Nbits);

stagesMismatch = stagesIdeal;
stagesMismatch(1) = pMismatch;

stagesOffset = stagesIdeal;
stagesOffset(1) = pOffset;

stagesFinite = stagesIdeal;
stagesFinite(1) = pFinite;


model.mdacStage = @mdacStage;
model.pipelineADC = @pipelineADC;

function [vout,decision] = mdacStage(vin,p)
    ratio = p.C2/p.C1;
    decision = double(vin >= p.Vref/2+p.Vos);
    vout = ((1+ratio).*vin-ratio.*decision*p.Vref) ...
        /(1+(1+ratio)/p.A0);
end

function [code,bits,residues] = pipelineADC(vin,stages)
    nBits = numel(stages);
    residues = zeros(numel(vin),nBits);
    residues(:,1) = vin(:);
    bits = zeros(numel(vin),nBits);
    for k = 1:nBits-1
        [residues(:,k+1),bits(:,k)] = mdacStage(residues(:,k),stages(k));
    end
    bits(:,nBits) = double(residues(:,nBits) >= ...
        stages(nBits).Vref/2+stages(nBits).Vos);
    code = bits*(2.^(nBits-1:-1:0)).';
end
