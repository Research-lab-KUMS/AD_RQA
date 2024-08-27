%path to .mat time series
relPath = 'D:\Rezaei\RQA\Voxel_ROIs\DMLN(basal_parietal_ifnra)(AD6_13_AD4_13)';
rRelsPath = 'D:\Rezaei\RQA\Voxel_ROIs\DMLN(basal_parietal_ifnra)(AD6_13_AD4_13)\RPs';
mRelsPath = 'D:\Rezaei\RQA\Voxel_ROIs\DMLN(basal_parietal_ifnra)(AD6_13_AD4_13)\RQA_measures';

measures = rp_measures(relPath, rRelsPath, mRelsPath);
%save(fullfile(relsPath,'RQA.mat'), 'measures');

function struct = importfile(path)
%reads the field from the .mat struct
%returns a struct
newData = load('-mat', path);
vars = fieldnames(newData);
struct = newData.(vars{1});
end


function mArray = rp_measures(relPath, rRelsPath, mRelsPath)

%this function reads the data from all 4 classes given a relative path to 4
%seperate folders per each class.
%then with the given period of thereshold calculate recurrence rate for
%each voxel and save them seperatly in 4 different folders with the given
%relative relsPaty (1 per each class). this is done for each step of
%threshold. also rerutns an array of tuples including the min rr per step

AD_4m_path = fullfile(relPath, '\4M\AD');
WT_4m_path = fullfile(relPath, '\4M\WT');
AD_6m_path = fullfile(relPath, '\6M\AD');
WT_6m_path = fullfile(relPath, '\6M\WT');

AD_4m_root_flist = dir(AD_4m_path);
WT_4m_root_flist = dir(WT_4m_path);
AD_6m_root_flist = dir(AD_6m_path);
WT_6m_root_flist = dir(WT_6m_path);

AD_4m_root_flist(1:2) = [];
WT_4m_root_flist(1:2) = [];
AD_6m_root_flist(1:2) = [];
WT_6m_root_flist(1:2) = [];

root_flist = [AD_4m_root_flist; WT_4m_root_flist; AD_6m_root_flist; WT_6m_root_flist];
%prerequisites to calculate RP
dim = 6;
td = 3;
radius = 24.88; %9.16 4.58 9.95 19.90 14.92 17.91
norm = 'nonormalize';
method = 'euclidean';

reverseStr = '';
parpool(12);


mSPath = '';
rSPath = '';
for k = 1:length(root_flist)
    fprintf('\n file %d %s\n', k, root_flist(k).name);
    mArray = [];
    rArray = [];
    regions = dir(fullfile(root_flist(k).folder, root_flist(k).name));
    if(contains(root_flist(k).folder, '4M\AD'))
        mSPath = fullfile(mRelsPath, 'AD_4m');
        rSPath = fullfile(rRelsPath, 'AD_4m');
    elseif(contains(root_flist(k).folder, '4M\WT'))
        mSPath = fullfile(mRelsPath, 'WT_4m');
        rSPath = fullfile(rRelsPath, 'WT_4m');
    elseif(contains(root_flist(k).folder, '6M\AD'))
        mSPath = fullfile(mRelsPath, 'AD_6m');
        rSPath = fullfile(rRelsPath, 'AD_6m');
    elseif(contains(root_flist(k).folder, '6M\WT'))
        mSPath = fullfile(mRelsPath, 'WT_6m');
        rSPath = fullfile(rRelsPath, 'WT_6m');
    end
    tic;
    regions(1:2) = [];
    for p = 1:length(regions)
        voxels = importfile(fullfile(regions(p).folder, regions(p).name));
        subID =  root_flist(k).name;
        regionID = regions(p).name;
        regionID = erase(regionID,".mat");
        mTempArray = {};
        rTempArray = {};
        fprintf(' region %d %s\n', p, regions(p).name);
        tic;
        parfor i = 1:height(voxels)
            if ~all(voxels(i,:)==0)
                voxelID = i;
                m = crqa(voxels(i,:),dim, td, radius, norm, method, 'nogui');
                reP = crp(voxels(i,:),dim, td, radius, norm, method, 'silent');
                c = {subID, regionID, voxelID, m};
                d = {subID, regionID, voxelID, reP};
                rTempArray = [rTempArray, {d}];
                mTempArray = [mTempArray, {c}];
            end
        end
        toc;
        mArray = [mArray, mTempArray];
        rArray = [rArray, rTempArray];
       
    end
    toc;
    if ~exist(mSPath, 'dir')
        mkdir(mSPath);
    end
    if ~exist(rSPath, 'dir')
        mkdir(rSPath);
    end
    mFname = append(subID, '_RQA', '.mat');
    rFname = append(subID, '_RP', '.mat');
    save(fullfile(mSPath,mFname),'mArray');
    save(fullfile(rSPath,rFname),'rArray');
    percentDone = 100 * k / length(root_flist);
    msg = sprintf('\nPercent done: %3.1f', percentDone);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
end
delete(gcp('nocreate'));
fprintf('\n finished! \n')
end
