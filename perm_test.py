import numpy as np
import pandas as pd
from tqdm import tqdm
import scipy
from mlxtend.evaluate import permutation_test
from joblib import Parallel, delayed
import warnings

warnings.filterwarnings('ignore')

seed = 5
pnum = 10000 # number of permutations
n_jobs = 14 # how many parallel jobs
 
def permutation(data1, data2, pnum, seed, region, voxel):
    # pass the region and voxel to ensure the correct order of these cols in
    # the final dataframe in case the parallel process changes it
    
    return (permutation_test(data1, data2,
                        method='approximate',
                        num_rounds=pnum,
                        seed=seed), region, voxel)

def compare(df1, df2, n_jobs, pnum, seed):
    
    gs1 = df1.groupby('Region_ID')
    gs2 = df2.groupby('Region_ID')

    results = pd.DataFrame(columns=['Region_ID', 'Voxel_ID',
                                    'PVAL_APPRX_RR',
                                    'PVAL_APPRX_DET',
                                    'PVAL_APPRX_AVG_DL',
                                    'PVAL_APPRX_EDL',])

    for g1, g2 in tqdm(zip(gs1, gs2)):
        
        region = g1[0]
        
        _gs1 = g1[1].groupby('Voxel_ID')
        _gs2 = g2[1].groupby('Voxel_ID')

        rr_res = Parallel(n_jobs=n_jobs)(delayed(permutation)
                                     (_g1[1]['RR'], _g2[1]['RR'], pnum, seed, region, _g1[0])
                                     for _g1, _g2 in zip(_gs1, _gs2))

        det_res = Parallel(n_jobs=n_jobs)(delayed(permutation)
                                     (_g1[1]['DET'], _g2[1]['DET'], pnum, seed, region, _g1[0])
                                     for _g1, _g2 in zip(_gs1, _gs2))
        
        avgdl_res = Parallel(n_jobs=n_jobs)(delayed(permutation)
                                     (_g1[1]['AVG_DL'], _g2[1]['AVG_DL'], pnum, seed, region, _g1[0])
                                     for _g1, _g2 in zip(_gs1, _gs2))
        
        edl_res = Parallel(n_jobs=n_jobs)(delayed(permutation)
                                     (_g1[1]['EDL'], _g2[1]['EDL'], pnum, seed, region, _g1[0])
                                     for _g1, _g2 in zip(_gs1, _gs2))
        
        region = [x[1] for x in rr_res]
        voxel = [x[2] for x in rr_res]
        
        rr_pvalues = [x[0] for x in rr_res]
        det_pvalues = [x[0] for x in det_res]
        avgdl_pvalues = [x[0] for x in avgdl_res]
        edl_pvalues = [x[0] for x in edl_res]
        
        row = pd.DataFrame({'Region_ID': region,
                            'Voxel_ID':voxel,
                            'PVAL_APPRX_RR': rr_pvalues,
                            'PVAL_APPRX_DET': det_pvalues,
                            'PVAL_APPRX_AVG_DL': avgdl_pvalues,
                            'PVAL_APPRX_EDL': edl_pvalues})
        
        results = pd.concat([results, row], ignore_index=True)
        
    return results

main_dir = r'D:\Rezaei\RQA\Voxel_ROIs\DMLN(basal_parietal_ifnra)(AD6_13_AD4_13)\RQAs\10%_of_mean\RQA_measures'

ad4m_dir = r'{}\AD_4M_RQA.csv'.format(main_dir)
wt4m_dir = r'{}\WT_4M_RQA.csv'.format(main_dir)
ad6m_dir = r'{}\AD_6M_RQA.csv'.format(main_dir)
wt6m_dir = r'{}\WT_6M_RQA.csv'.format(main_dir)

ad4m = pd.read_csv(ad4m_dir)
wt4m = pd.read_csv(wt4m_dir)

ad6m = pd.read_csv(ad6m_dir)
wt6m = pd.read_csv(wt6m_dir)

ad_wt_4m = compare(ad4m, wt4m, n_jobs, pnum, seed)
ad_wt_6m = compare(ad6m, wt6m, n_jobs, pnum, seed)  

ads = compare(ad4m, ad6m, n_jobs, pnum, seed)
wts = compare(wt4m, wt6m, n_jobs, pnum, seed)  

with pd.ExcelWriter(r'{}\Comparison_Result.xlsx'.format(main_dir)) as writer:  
    ad_wt_4m.to_excel(writer, sheet_name='AD_NO_4M', index=None)
    ad_wt_6m.to_excel(writer, sheet_name='AD_NO_6M', index=None)
    wts.to_excel(writer, sheet_name='4M_6M_NO', index=None)
    ads.to_excel(writer, sheet_name='4M_6M_AD', index=None)
    