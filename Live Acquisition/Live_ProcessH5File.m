function [app, Data] = Live_ProcessH5File(app, filepath, filenames, FileID, FileGroup)


if isempty(FileGroup)
    info = h5info(fullfile(filepath, filenames));
    fnames = info.Groups(1).Groups;
else
    fnames = FileGroup{FileID};
end

t = 0;
time = [];
AcqID = [];
vol = 0;
cumvol =[];
non_norm_d = [];
trans_time = [];
sn = [];
sy = [];
acq_int = [];
int_vol = [];
raw_vol = [];

for i = 1:size(fnames,1)
    if ~isempty(FileGroup)
        CompFilename = fullfile(filepath, FileGroup{FileID}{i});
        info = h5info(CompFilename);
        % define index to find pertinent criteria for software function
        timeind = double(info.Attributes(strcmp({info.Attributes.Name}, 'acqtime')).Value);
        samprate = double(info.Attributes(strcmp({info.Attributes.Name}, 'n_samp')).Value);
        acqvol = double(info.Attributes(strcmp({info.Attributes.Name}, 'measured_volume')).Value);
        sfactInd = double(info.Attributes(strcmp({info.Attributes.Name}, 'diameterScalingFactor')).Value);
        data = h5read(CompFilename, '/pks');
    else
        % define index to find pertinent criteria for software function
        timeind = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'acqtime')).Value);
        samprate = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'n_samp')).Value);
        acqvol = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'measured_volume')).Value);
        sfactInd = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'diameterScalingFactor')).Value);
        readstr = [fnames(i).Name,'/',fnames(i).Datasets(2).Name];
        data = h5read(fullfile(filepath, filenames), readstr);
    end


    trans_t = data.pk_width;
    signois = data.pk_sn;
    sym = data.pk_sym;

    % diameter calculation
    [nCS1_diam] = nCS1_Scaling_Factor(data, sfactInd);
    non_norm = nCS1_diam;

    % time calculation
    timepoint = (double(data.pk_index) * (timeind/samprate)) + t;
    t = t + timeind;

    % volume calculation
    v = (double(data.pk_index) * (acqvol/samprate)) + vol;
    vol = vol + acqvol;

    % aggregate data across each acquisition
    time = [time; timepoint];
    AcqID = [AcqID; i*ones(size(non_norm,1),1)];
    non_norm_d = [non_norm_d; non_norm];
    cumvol = [cumvol; v];
    trans_time = [trans_time; trans_t];
    sn = [sn; signois];
    sy = [sy; sym];
    acq_int = [acq_int; timeind];
    int_vol = [int_vol; acqvol];
end

% sample data
if isempty(FileGroup)
    Data.Info(:,[1 2]) = horzcat({info.Groups(1).Groups(i).Attributes.Name}', {info.Groups(1).Groups(i).Attributes.Value}'); % h5 information
else
    Data.Info(:,[1 2]) = horzcat({info.Attributes.Name}', {info.Attributes.Value}'); % h5 informationend
end
Data.time = time; % Time (secs)
Data.AcqID = AcqID; % Acquisition
Data.non_norm_d = non_norm_d; % Uncalibrated Diameter (nm)
Data.diam = nan(size(Data.non_norm_d,1),1);
Data.acqvol = int_vol .* 1e9; % total volume of each acquisition (pL)
Data.cumvol = cumvol .* 1e9; % Cumulative Volume (pL)
Data.ttime = trans_time; % Transit time (µs)
Data.signal2noise = sn; % Signal to noise ratio
Data.symmetry = sy; % Pulse symmetry
Data.outliers = false(size(Data.time,1),1); % default matrix for outlier removal
Data.acq_int = acq_int; % acquisition time
Data.CaliFactor = []; % deterimed calibration factor for each acquisition
Data.SpikeInGateMax = []; % determined maximum diameter for spike-in gate
Data.SpikeInGateMin = []; % determined minimum diameter for spike-in gate
Data.UngatedTotalEvents = size(Data.AcqID,1); % total number of detected events before outlier removal

% sample metadata
cartstr = Data.Info{strcmp(Data.Info(:,1),'cartridge_class'),2};
Data.maxDiam = str2double(cartstr(regexp(cartstr, '\d')));
Data.moldID = Data.Info{strcmp(Data.Info(:,1),'moldID'),2};
Data.BoxID =  Data.Info{strcmp(Data.Info(:,1),'cartridge_box_date'),2};
Data.Date =  Data.Info{strcmp(Data.Info(:,1),'stats_gen_date'),2};



end