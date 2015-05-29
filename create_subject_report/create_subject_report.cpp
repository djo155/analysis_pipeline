//
//  main.cpp
//  interpret_motion_parameters
//
//  Created by Brian Patenaude on 10/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>
#include <cmath>
#include <string>
#include "newimage/newimageall.h"

using namespace NEWIMAGE;
using namespace std;

void usage(){
    
    cout<<"\n Usage : "<<endl;
    cout<<"create_subject_report <output_file> <name of output summary file> <raw 4D timeseries> <list of analysis directories> \n"<<endl;
    
}
void calc_motion( const string & fmotion_disp, const string & fmotion_disp_rel, float & mean_disp, float & max_disp, unsigned int &  N_disp_gt_05 )
{
    float thresh=0.5;
    mean_disp=0.0;
    max_disp=1e-16;
    N_disp_gt_05=0;
    
    //do .abs file
    {
        ifstream fin_disp(fmotion_disp.c_str());
        string line;
        int count=0;
        while ( getline(fin_disp,line) ) {
            //six parameters
            stringstream ss;
            ss<<line;
            float disp;
            ss>>disp;
            mean_disp+=disp;
            if (max_disp< disp) max_disp = disp;
            ++count;
        }
        mean_disp /= count;
        fin_disp.close();
    }
    //do .rel file
    {
        ifstream fin_disp(fmotion_disp_rel.c_str());
        string line;
        int count=0;
        while ( getline(fin_disp,line) ) {
            //six parameters
            stringstream ss;
            ss<<line;
            float disp_rel;
            ss>>disp_rel;
            if (disp_rel > thresh)
            ++N_disp_gt_05;
        }
        fin_disp.close();
    }

   

    
}

void calculateSNR( const volume4D<float> & raw_fmri, const  volume<float> & brain_mask_in, float & vsnr, float & ssnr, unsigned int Ndiscard )
{
    volume<float> SNR,sx,sxx;
     volume<float> brain_mask = brain_mask_in;
    SNR=sx=sxx=brain_mask;
    SNR=0;
    sx=0;
    sxx=0;
    
    int Nt=raw_fmri.tsize();
    int xsize=raw_fmri.xsize();
    int ysize=raw_fmri.ysize();
    int zsize=raw_fmri.zsize();
    
    //        cout<<"sizes "<<xsize<<" "<<sx.xsize();
    //look for all zero voxels in time series
    
    for (int z=0; z<zsize ; z++)
        for (int y=0; y<ysize ; y++)
        for (int x=0; x<xsize ; x++)
    {
        float sum=0;
        for (int t=Ndiscard; t<Nt ; t++)
        {
            sum+=raw_fmri[t].value(x,y,z);
        }
        if (sum == 0 )
        brain_mask.value(x,y,z)=0;
        
    }
    
    //        cout<<"start loading the data"<<endl;
    //claulctae mean and standard deviations
    vector< vector<float> > mean_slice_signal(zsize, vector<float>());
    vector<unsigned int> n_per_slice;
    for (int t=Ndiscard; t<Nt ; t++)
    {
        //            cout<<"timepoint "<<t<<endl;
        const float* br_ptr =brain_mask.fbegin();
        //const float* snr_ptr =brain_mask.fbegin();
        const float* raw_ptr =(raw_fmri[t].fbegin());
        float* sx_ptr =const_cast<float*>(sx.fbegin());
        float* sxx_ptr =const_cast<float*>(sxx.fbegin());
        
        //volume<float> v_t(xsize,ysize,zsize);
        for (int z=0; z<zsize ; z++)
        {
            unsigned int Nslice=0;
            float mean_slice=0;
            for (int y=0; y<ysize ; y++)
                for (int x=0; x<xsize ; x++,raw_ptr++,br_ptr++,++sx_ptr,++sxx_ptr  )
                {
                    if (*br_ptr>0)
                    {
                        *sx_ptr +=*raw_ptr;
                        *sxx_ptr += (*raw_ptr)*(*raw_ptr);
                        mean_slice += *raw_ptr;
                        ++Nslice;
                    }
                }
            n_per_slice.push_back(Nslice);
            mean_slice_signal[z].push_back(mean_slice/Nslice);
            
        }
    }
    
    //        //claculate ssnr
    ssnr=0;
    {
        unsigned int Ntotal=0;
        float SNR_total=0;
        unsigned int slice = 0 ;
        vector< unsigned int >::iterator i_N = n_per_slice.begin();
        for (vector< vector<float> >::iterator i = mean_slice_signal.begin(); i != mean_slice_signal.end(); ++i,++slice, ++i_N)
        {
            //                cout<<"slice "<<slice<<" "<<i->size()<<" "<<*i_N<<endl;
            if ( *i_N > 0 )
            {
                float sxtemp=0;
                float sxxtemp=0;
                
                for (vector<float>::iterator ii = i->begin() ; ii != i->end(); ++ii)
                {
                    sxtemp+=*ii;
                    sxxtemp+=(*ii)*(*ii);
                }
                unsigned int N = i->size();
                
                //                    cout<<"Slice SNR "<<(sxtemp/N) / sqrt(( sxxtemp  - (sxtemp * sxtemp/N) ) / (N-1) )<<" "<<N<<endl;
                //                    SNR_total +=  N * (sx/N) /  sqrt(( sxx  - (sx * sx/N) ) / (N-1) );//i kbnoew there is a redundant N multiplicaton, but makes more obvious
                SNR_total += sxtemp /  sqrt(( sxxtemp  - (sxtemp * sxtemp/N) ) / (N-1) );//i kbnoew there is a redundant N multiplicaton, but makes more obvious
                
                Ntotal+=N;
                //                    cout<<"slice is NOT empty "<<SNR_total<<" "<<Ntotal<<endl;
                
            }
            //                else{
            //                    cout<<"slice is empty "<<SNR_total<<" "<<Ntotal<<endl;
            //                }
        }
        SNR_total /=Ntotal;
        //
        ssnr = SNR_total;
    }
    
    //        cout<<"ssnr "<<ssnr<<endl;
    Nt=Nt-Ndiscard;
    SNR=sx/Nt;//mean
    sxx= (sxx - sx*sx/Nt)/(Nt-1);
    sxx=sqrt(sxx);
    
    
    
    SNR/=sxx;
//    mask_volume(SNR,brain_mask);
    //save_volume(SNR,"SNR");
    //save_volume(brain_mask,"brain_mask");

    vsnr=0;//SNR.mean(brain_mask);
    
    //calculate SNR
    const float* br_ptr =brain_mask.fbegin();
    unsigned int Nsnr=0;
    for (int z=0; z<zsize ; z++)
        for (int y=0; y<ysize ; y++)
            for (int x=0; x<xsize ; x++,br_ptr++)
            {
                if (*br_ptr>0)
                {
                    vsnr+=SNR.value(x,y,z);
                    ++Nsnr;
                }
            }
    cout<<"Number of Brain Voxles "<<Nsnr<<endl;
    vsnr/=Nsnr;
    
    
}


int do_work( const string & htmlname , const string & summary_name, const string & raw_func, const string & mc_corr,  const string & sub_dir ){

    cout<<"inside do work "<<endl;
    ofstream fsum( (summary_name + ".csv").c_str() );
    if ( ! fsum.is_open() )
    {
        cerr<<"Failed to open "<<(summary_name + ".csv")<<endl;
        exit (EXIT_FAILURE);
        
    }
    
    ofstream fsumh( (summary_name + "header.csv").c_str() );

    
    ofstream fhtml(htmlname.c_str());
    if (fhtml.is_open())
    {
        cout<<"writing html..."<<endl;
        fhtml<<"<html>"<<endl;
        //set style
        fhtml<<"<style>"<<endl;
        fhtml<<"body { \n background-color: rgba(117,172,169,0.3); \n }"<<endl;
        fhtml<<"</style>"<<endl;


        fhtml<<"<body>"<<endl;
        fhtml<<"Analysis Report for <a href=\"file://"<<sub_dir<<"\"> "<<sub_dir<<"</a> <br>"<<endl;

//STRUCTURAL IMAGE
        fhtml<<"<p> <b> T1-weighted Structural Image</b> <br>"<<endl;
        fhtml<<"<a href=\""<<"structural_allaxial.png\" width=\"1000\""<<">"<<sub_dir+"/struct/orig "<<"</a>"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"structural.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;
        
        fhtml<<"<p> <b> Mid Time Point Functional Image</b> <br>"<<endl;
        fhtml<<"<a href=\""<<"example_func_allaxial.png\" width=\"1000\""<<">"<<sub_dir+"/example_func "<<"</a>"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"example_func.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;

        fhtml<<"<p> <b> Brain Extraction from Highres Structural</b> <br>"<<endl;
        fhtml<<"<a href=\""<<"brain_extraction_allaxial.png\" width=\"1000\""<<">"<<sub_dir+"/struct/brain_fnirt_mask "<<"</a>"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"brain_extraction.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;
        
        
        fhtml<<"<p> <b> Registration of Functional Image to Structural </b> <br>"<<endl;
        fhtml<<"<a href=\""<<"example_func2highres_allaxial.png\" width=\"1000\""<<">"<<sub_dir+"/reg/example_func_2_highres "<<"</a>"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"example_func2highres.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;

        fhtml<<"<p> <b> Registration of Structural Image to MNI152 </b> <br>"<<endl;
        fhtml<<"<a href=\""<<"highres2standard_allaxial.png\" width=\"1000\""<<">"<<sub_dir+"/reg/highres2standard_warped "<<"</a>"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"highres2standard.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;

        
        fhtml<<"<p> <b> Subcortical Segmentation using FIRST in Structural Space </b> <br>"<<endl;
        fhtml<<"<a href=\""<<"firstseg_allaxial.png\" width=\"1000\""<<">"<<sub_dir+"/struct/first_all_fast_firstseg "<<"</a>"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"firstseg.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;
        
        
        fhtml<<"<p> <b> Tissue Segmentation using FAST in Structural Space </b> <br>"<<endl;
        fhtml<<"<a href=\""<<"fastpveseg_allaxial.png\" width=\"1000\""<<">"<<sub_dir+"/struct/brain_fnirt_pveseg "<<"</a>"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"fastpveseg.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;
        cout<<"done structural stuff..."<<endl;

        //-------------let's do some SNR stuff--------------------
//-------FOR SNR STUFF LET OMIT THE FIRST 5 volumes, because we throw away anyways
        const unsigned int Ndiscard = 5 ;
        cout<<"start SNR stuff "<<raw_func<<endl;
        volume4D<float> raw_fmri, mc_fmri;
        read_volume4D(raw_fmri,raw_func);
        read_volume4D(mc_fmri,mc_corr);

        volume<float> brain_mask;
        read_volume(brain_mask,sub_dir+"/struct/brain_fnirt_mask_2_example_func");
        cout<<"ron reading images"<<endl;
        float vsnr,ssnr,mc_vsnr, mc_ssnr;
        
        calculateSNR(raw_fmri,brain_mask,vsnr,ssnr,Ndiscard);
        calculateSNR(mc_fmri,brain_mask, mc_vsnr,mc_ssnr,Ndiscard);

        
        
        
                      fhtml<<"<p> <b> Signal-To-Noise Ratio</b> <br>"<<endl;
        fhtml<<"<br> The following SNR values were performed after the deletion of the first 5 volumes, but without another processing of the time seriees. <br> The suggested interpretation of Slice-Based SNR (sSNR) is: <br><br>"<<endl;
        
        fhtml<<" <table border=\"1\" style=\"width:20%\">"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Good</td>"<<endl;
        fhtml<<"<td> =>150 </td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Bad</td>"<<endl;
        fhtml<<"<td> <99 </td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"</table> <br>"<<endl;

        fhtml<<" <table border=\"1\" style=\"width:40%\">"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Voxel-based Signal to Noise Ratio (vSNR)</td>"<<endl;
        fhtml<<"<td>"<<vsnr<<"</td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Slice-based Signal to Noise Ratio (sSNR)</td>"<<endl;
        fhtml<<"<td>"<<ssnr<<"</td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Motion Corrected Voxel-based Signal to Noise Ratio (vSNR)</td>"<<endl;
        fhtml<<"<td>"<<mc_vsnr<<"</td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Motion Corrected Slice-based Signal to Noise Ratio (sSNR)</td>"<<endl;
        fhtml<<"<td>"<<mc_ssnr<<"</td>"<<endl;
        fhtml<<"</tr>"<<endl;

        fhtml<<"</table>"<<endl;

        //summary file
        fsumh<<"Volume-Based-SNR,Sliced-Based-SNR,Volume-Based-SNR-mc,Sliced-Based-SNR-mc";
        fsum<<vsnr<<","<<ssnr<<","<<mc_vsnr<<","<<mc_ssnr;
        
        //------------------------------------------
        

                      fhtml<<"</p>"<<endl;
        
        fhtml<<"<p> <b> Motion Plots</b> <br>"<<endl;
        fhtml<<"<br> The suggested interpretation of Maximum Absolute Motion is : <br><br>"<<endl;
        fhtml<<" <table border=\"1\" style=\"width:20%\">"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Good</td>"<<endl;
        fhtml<<"<td> <1.49 </td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Bad</td>"<<endl;
        fhtml<<"<td> >2mm </td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"</table> <br>"<<endl;
        
        fhtml<<"<br> The suggested interpretation for Number of Movements > 0.5mm is : <br><br>"<<endl;
        fhtml<<" <table border=\"1\" style=\"width:20%\">"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Good</td>"<<endl;
        fhtml<<"<td> <5 </td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Bad</td>"<<endl;
        fhtml<<"<td> >5 </td>"<<endl;
        fhtml<<"</tr>"<<endl;
        fhtml<<"</table> <br>"<<endl;

        string motion_pars_rel=sub_dir + "/mc/prefiltered_func_data_mcf_rel.rms";
        string motion_pars_abs=sub_dir + "/mc/prefiltered_func_data_mcf_abs.rms";
        float max_disp,mean_disp;
        
        unsigned int N_disp_gt_05;
        calc_motion( motion_pars_abs, motion_pars_rel,mean_disp, max_disp, N_disp_gt_05 );
        
        
        fhtml<<" <table border=\"1\" style=\"width:40%\">"<<endl;
         fhtml<<"<tr>"<<endl;
         fhtml<<"<td>Mean RMS Absolute Displacment</td>"<<endl;
         fhtml<<"<td>"<<mean_disp<<"</td>"<<endl;
        fhtml<<"</tr>"<<endl;

        fhtml<<"<tr>"<<endl;
         fhtml<<"<td>Maximnum RMS Absolute displacement</td>"<<endl;
        fhtml<<"<td>"<<max_disp<<"</td>"<<endl;

        fhtml<<"<tr>"<<endl;
        fhtml<<"<td>Number of Relative Motions > 0.5mm</td>"<<endl;
        fhtml<<"<td>"<<N_disp_gt_05<<"</td>"<<endl;
        
         fhtml<<"</tr>"<<endl;
        fhtml<<"</table> <br>"<<endl;
///SUMMARY
        fsumh<<",Mean-RMS-Absolute-Displacment,Maximnum-RMS-Absolute-displacement,Number_of_Relative_Motions_GT_0.5mm"<<endl;
        fsum<<","<<mean_disp<<","<<max_disp<<","<<N_disp_gt_05<<endl;
        ///END SUMMARY
        fhtml<<"<img src=\""<<"disp.png\""<<" alt=\"mean_disp\" width=\"747\" height=\"167\">"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"trans.png\""<<" alt=\"mean_trans\" width=\"747\" height=\"167\">"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<"rot.png\""<<" alt=\"mean_rot\" width=\"747\" height=\"167\">"<<endl;

        fhtml<<"</p>"<<endl;
        fhtml<<"</body>"<<endl;
        fhtml<<"</html>"<<endl;
        
        
        cout<<"Open report file in web browser:"<<endl;
        cout<<htmlname<<endl;

    }else{
            cerr<<"Failed to open "<<(htmlname)<<endl;
            exit (EXIT_FAILURE);
            
        
    }
    return 0;
}
int main (int argc, const char * argv[])
{
    cout<<"create_subject_report"<<endl;
    if (argc < 2)
    {
        usage();
        return 0;
    }
    cout<<"reading in inputs..."<<endl;
    string outname = string(argv[1]) + ".html";
    string sumname = string(argv[2]);
    string rawfunc = string(argv[3]);
    string mc_corr =string(argv[4]);
    string analysis_dir = string(argv[5]);
    cout<<"do_work..."<<endl;
    do_work(outname,sumname,rawfunc,mc_corr,analysis_dir);
    
    return 0;
}

