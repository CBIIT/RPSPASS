function [Data] = PostGateOutlierRemoval(Data)

% obtain the remaining acquisition IDs after outliers have been removed
Acq_ID_Post = unique(Data.AcqID(~Data.outliers));

% create an empty array for interval concentration
Int_Conc = zeros(1,max(Data.AcqID));


for i = 1:numel(Acq_ID_Post)

    % obtained the concentration of particles per acqusition
    Int_Conc(Acq_ID_Post(i)) = sum(Data.AcqID == Acq_ID_Post(i))/Data.acqvol(Acq_ID_Post(i));
    Int_Ratio(Acq_ID_Post(i)) = sum(Data.AcqID == Acq_ID_Post(i))/Data.SpikeInNum(Acq_ID_Post(i));
    
end

% find the outliers in the concentration between acquisitions
[~, Conc_outlier] = rmoutliers(Int_Conc,'grubbs');

% create array of unique acquisition interval IDs
Uq_AcqID = 1:Data.RPSPASS.MaxInt;

% merge outliers with previous outlier removal arrays
Data.RPSPASS.FailedAcq = or(Data.RPSPASS.FailedAcq, Conc_outlier);

Failed_AcqIDs = Uq_AcqID(Data.RPSPASS.FailedAcq);

for i = 1:numel(Failed_AcqIDs)
    Data.outliers(Data.AcqID==Failed_AcqIDs(i)) = true;
end

end