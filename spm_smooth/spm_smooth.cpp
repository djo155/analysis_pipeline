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

//FSL INCLUDE
#include "newimage/newimageall.h"
#include "utils/options.h"


using namespace NEWIMAGE;
using namespace Utilities;

using namespace std;



//-------------These here come from FSL utils/options.h -----------------//
//Pretty much cut and paste

string title="spm_smooth_kernel Stanford University (Brian Patenaude) \n \t This function is used to create masks for the connectviity matrices inorder to facility netowrk specific analysis";
string examples="image_correlation -i <connection_matrix.nii.gz> -o <output_base>";



Option<bool> verbose(string("-v,--verbose"), false,
                     string("switch on diagnostic messages"),
                     false, no_argument);
Option<bool> help(string("-h,--help"), false,
                  string("display this message"),
                  false, no_argument);

//Standard Inputs
Option<float> fwhm(string("-w,--fwhm"), 6,
					  string("Full Width Half Max"),
					  true, requires_argument);
Option<string> inname(string("-i,--in"), string(""),
                      string("Filename of functional image"),
                      true, requires_argument);


Option<string> outname(string("-o,--output"), string(""),
					   string("Output name"),
					   true, requires_argument);
int nonoptarg;
//-------------DONE These here come from FSL utils/options.h -----------------//

void  spm_kernel(volume<float> & kern_out,  const float & fwhm, const float & xdim, const int & dim)
{
    float fwhm_x = fwhm / xdim;
//    cout<<"fwhm_x "<<fwhm_x<<endl;
    float s_x = powf(fwhm_x / sqrtf(8*log(2)),2) ;
    float s1_x = fwhm_x / sqrtf(8*log(2));
    float w1_x = 0.5*sqrtf(2/s_x);
    float w2_x = -0.5/s_x;
    float w3_x = sqrtf(0.5*s_x/M_PI);
    
//    cout<<"s_x "<<s_x<<endl;
//    cout<<"w123 "<<w1_x<<" "<<w2_x<<" "<<w3_x<<endl;
//
    volume<float>* kern;
    
    int xlim  = roundf(6*s1_x);
    if (dim == 0 )
    {
        kern = new volume<float>(2*xlim +1 ,1,1);
        
    }else if (dim == 1 )
    {
        kern = new volume<float>(1,2*xlim +1 ,1);
        
    }else if (dim == 2 )
    {
        kern = new volume<float>(1,1,2*xlim +1);
        
    }
    (*kern)=0;
    
    for (int x = -xlim ; x <= xlim ; ++x)
    {
//        cout<<"x "<<x<<endl;
//        cout<<"t1 "<<(w3_x*expf(w2_x*powf((x+1),2)) )<<endl;
        float krn = 0.5*(erf(w1_x*(x+1))*(x+1)       + erf(w1_x*(x-1))*(x-1)     - 2*erf(w1_x*x)* x ) \
        + w3_x*(expf(w2_x*powf((x+1),2))   + expf(w2_x*powf((x-1),2))  - 2*expf(w2_x*powf(x,2)));
        
        if (krn<0) krn=0;

        
        if (dim == 0 )
        {
            kern->value(x + xlim ,0,0)=krn;
        }else if (dim == 1 )
        {
            kern->value(0, x + xlim,0)=krn;
            
        }else if (dim == 2 )
        {
            kern->value(0,0,x + xlim )=krn;
            
        }
    }
    

    kern_out = *kern;
//    return kern_out;
    delete kern;
}

int do_work( const string & inname, const float & fwhm, const string & outname ){
    volume4D<float> imfunc;
    read_volume4D(imfunc,inname);
    //this implementation taken out of spm_smoothkern.m in SPM8
    volume<float> krn;
    spm_kernel(krn, fwhm,imfunc.xdim(),0);
    volume<int> mask;
    copyconvert(imfunc[0],mask);
//    mask=1;

    for (int t = 0 ; t < imfunc.tsize(); ++t)
        imfunc[t]=convolve(imfunc[t],krn,mask,0,1);
    
    spm_kernel(krn, fwhm,imfunc.ydim(),1);

    for (int t = 0 ; t < imfunc.tsize(); ++t)
        imfunc[t]=convolve(imfunc[t],krn,mask,0,1);
    spm_kernel(krn, fwhm,imfunc.zdim(),2);

    for (int t = 0 ; t < imfunc.tsize(); ++t)
        imfunc[t]=convolve(imfunc[t],krn,mask,0,1);
    
    
    
    save_volume4D(imfunc,outname);
    
           return 0;
}

//This main is consostent across FSL programs, cut and paste. Just change options to do_work and options

int main (int argc,  char * argv[])
{
    
	Tracer tr("main");
	OptionParser options(title, examples);
	
	try {
		// must include all wanted options here (the order determines how
		//  the help message is printed)
        options.add(inname);
		options.add(fwhm);
        options.add(outname);
		options.add(verbose);
		options.add(help);
        
    	nonoptarg = options.parse_command_line(argc, argv);
        if (  (!options.check_compulsory_arguments(true) ))
		{
			options.usage();
			exit(EXIT_FAILURE);
		}
        
        do_work(inname.value(), fwhm.value(), outname.value());

    } catch(X_OptionError& e) {
		options.usage();
		cerr << endl << e.what() << endl;
		exit(EXIT_FAILURE);
	} catch(std::exception &e) {
		cerr << e.what() << endl;
	}
    return 0;
}

