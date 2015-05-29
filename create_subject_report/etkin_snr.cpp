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
    cout<<"etkin_snr <raw_4D_timeseries> <mask_name> \n"<<endl;
    
}


int do_work( const string & raw_func, const string & maskname ){
 
        
        //-------------let's do some SNR stuff--------------------
//-------FOR SNR STUFF LET OMIT THE FIRST 5 volumes, because we throw away anyways
        const unsigned int Ndiscard = 5 ;
//    cout<<"Discarding the first "<<Ndiscard<<" volumes"<<endl;
//        cout<<"Reading in functional data... "<<raw_func<<endl;
        volume4D<float> raw_fmri;
        read_volume4D(raw_fmri,raw_func);

        volume<float> SNR,sx,sxx;
        volume<float> mask;
        read_volume(mask,maskname);
    
        SNR=sx=sxx=mask;
        SNR=0;
        sx=0;
        sxx=0;

        int Nt=raw_fmri.tsize();
        int xsize=raw_fmri.xsize();
        int ysize=raw_fmri.ysize();
        int zsize=raw_fmri.zsize();
        
//        cout<<"start loading the data "<<zsize<<" "<<Nt<<endl;
        //claulctae mean and standard deviations
        vector< vector<float> > mean_slice_signal(zsize);
        vector<unsigned int> n_per_slice;
        for (int t=Ndiscard; t<Nt ; t++)
        {
//            cout<<"timepoint "<<t<<endl;
            const float* br_ptr =mask.fbegin();
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
        float ssnr=0;
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
        mask_volume(SNR,mask);
//        save_volume(SNR,"SNR");
    
        float vsnr=0;//SNR.mean(brain_mask);

        //calculate SNR
        const float* br_ptr =mask.fbegin();
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
        vsnr/=Nsnr;
    
    cout<<"vSNR/sSNR "<<ssnr<<" "<<vsnr<<endl;
    
    return 0;
}
int main (int argc, const char * argv[])
{
    if (argc < 2)
    {
        usage();
        return 0;
    }
    string rawfunc = string(argv[1]);
    string maskname = string(argv[2]);
    do_work(rawfunc,maskname);
    
    return 0;
}

