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
    cout<<"interpret_motion_parameters <output_file> <list of analysis directories> \n"<<endl;
    
}
void calc_motion( const string & fmotion,const string & fmotion_disp ofstream & fout)
{
    
    ifstream fin(fmotion.c_str());
    //read_in_brain_mask
//    volume<float> mask;
//    read_volume(mask,brain_mask);
//    
//    float xdim=mask.xdim();
//    float ydim=mask.ydim();
//    float zdim=mask.zdim();
//    int xs=mask.xsize();
//    int ys=mask.ysize();
//    int zs=mask.zsize();
//    float max_dist=0;
//    for (int x=0;x<xs;++x)
//        for (int y=0;y<ys;++y)
//            for (int z=0; z<zs;++z)
//                if (mask.value(x,y,z)!=0)
//                {
//                    float xp=x*xdim;
//                    float yp=y*ydim;
//                    float zp=z*zdim;
//                    float dist=sqrtf(xp*xp+ yp*yp + zp*zp);
//                    if (max_dist<dist) max_dist=dist;
//                    
//                }
//    
    
    string line;
    // vector<float> tx,ty,tz,theta,phi,psi;
    int count=0;
//    float mean_tx=0,mean_ty=0,mean_tz=0,mean_theta=0,mean_phi=0,mean_psi=0;
//    float max_tx=1e-16,max_ty=1e-16,max_tz=1e-16,max_theta=1e-16,max_phi=1e-16,max_psi=1e-16;
//    float mean_motion=0;
    float mean_tx=0,mean_ty=0,mean_tz=0,mean_theta=0,mean_phi=0,mean_psi=0;
    float max_tx=1e-16,max_ty=1e-16,max_tz=1e-16,max_theta=1e-16,max_phi=1e-16,max_psi=1e-16;
    float mean_motion=0;

    while ( getline(fin,line) ) {
        //six parameters
        // cout<<"line "<<line<<endl;
        stringstream ss;
        ss<<line;
        float tx,ty,tz,theta,phi,psi;
//        ss>>tx>>ty>>tz>>theta>>phi>>psi;
        
        ss>>theta>>phi>>psi>>tx>>ty>>tz;

        mean_tx+=fabs(tx);
        mean_ty+=fabs(ty);
        mean_tz+=fabs(tz);
        mean_theta+=fabs(theta);
        mean_phi+=fabs(phi);
        mean_psi+=fabs(psi);
        if (max_tx< tx) max_tx = tx;
        if (max_ty< ty) max_ty = ty;
        if (max_tz< tz) max_tz = tz;
        if (max_theta< theta) max_theta = theta;
        if (max_phi< phi) max_phi = phi;
        if (max_psi< psi) max_psi = psi;
        mean_motion+=(fabs(tx)+fabs(ty)+fabs(tx))/3;
        ++count;
    }
    fin.close();
    mean_tx/=count;
    mean_ty/=count;
    mean_tz/=count;
    mean_theta/=count;
    mean_phi/=count;
    mean_psi/=count;
    mean_motion/=count;
    
    
    
    // insert code here...
    fout <<mean_motion<<",";
    fout <<mean_tx<<","<<mean_ty<<","<<mean_tz<<","<<mean_theta<<","<<mean_phi<<","<<mean_psi<<",";
   fout <<max_tx<<","<<max_ty<<","<<max_tz<<","<<max_theta<<","<<max_phi<<","<<max_psi<<",";
    fout <<mean_theta*max_dist<<","<<mean_phi*max_dist<<","<<mean_psi*max_dist<<","<<max_theta*max_dist<<","<<max_phi*max_dist<<","<<max_psi*max_dist<<","<<max_dist<<endl;

    
    
}


int main (int argc, const char * argv[])
{
    if (argc < 3)
    {
        usage();
        return 0;
    }
    ofstream fout(argv[1]);
    fout <<"mean_motion"<<",";
    fout <<"mean_tx"<<","<<"mean_ty"<<","<<"mean_tz"<<","<<"mean_theta"<<","<<"mean_phi"<<","<<"mean_psi"<<",";
    fout <<"max_tx"<<","<<"max_ty"<<","<<"max_tz"<<","<<"max_theta"<<","<<"max_phi"<<","<<"max_psi"<<",";
    fout <<"mean_theta*max_dist"<<","<<"mean_phi*max_dist"<<","<<"mean_psi*max_dist"<<","<<"max_theta*max_dist"<<","<<"max_phi*max_dist"<<","<<"max_psi*max_dist"<<","<<"max_dist"<<endl;
    if (fout.is_open())
    {
        int index=2;
        while (index < argc)
        {
            string base_image=string(argv[index]) + "/example_func";
            string motion_pars=string(argv[index]) + "/mc/prefiltered_func_data_mcf.par.txt";
            cout<<"calculate motion "<<base_image<<" "<<motion_pars<<endl;
        calc_motion(motion_pars,base_image,fout);
    
                fout.close();
            ++index;
        }
    }
                return 0;
}

