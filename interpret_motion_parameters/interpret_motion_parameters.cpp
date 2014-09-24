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
void calc_motion( const string & subject, const string & fmotion,const string & fmotion_disp, const string & fmotion_disp_rel, ofstream & fout)
{
    

    float mean_tx=0,mean_ty=0,mean_tz=0,mean_theta=0,mean_phi=0,mean_psi=0, mean_disp=0,mean_disp_rel=0;
    float max_tx=1e-16,max_ty=1e-16,max_tz=1e-16,max_theta=1e-16,max_phi=1e-16,max_psi=1e-16, max_disp=1e-16, max_disp_rel=1e-16;

    
//do .par file
    {
        ifstream fin(fmotion.c_str());
        
        string line;
        int count=0;
        while ( getline(fin,line) ) {
            //six parameters
            stringstream ss;
            ss<<line;
            float tx,ty,tz,theta,phi,psi;
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
            ++count;
        }
        fin.close();
        
        mean_tx/=count;
        mean_ty/=count;
        mean_tz/=count;
        mean_theta/=count;
        mean_phi/=count;
        mean_psi/=count;
    }
    //do mean displacement
    
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
            mean_disp+=fabs(disp);
            if (max_disp< disp) max_disp = disp;
            ++count;
        }
        fin_disp.close();
        
        mean_disp/=count;
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
            mean_disp_rel+=fabs(disp_rel);
            if (max_disp_rel< disp_rel) max_disp_rel = disp_rel;
            ++count;
        }
        fin_disp.close();
        
        mean_disp_rel/=count;
    }

    
    
    // insert code here...
    fout <<subject<<",";
    fout <<mean_disp<<","<<max_disp<<",";
    fout <<mean_disp_rel<<","<<max_disp_rel<<",";
    fout <<mean_tx<<","<<mean_ty<<","<<mean_tz<<","<<mean_theta<<","<<mean_phi<<","<<mean_psi<<",";
    fout <<max_tx<<","<<max_ty<<","<<max_tz<<","<<max_theta<<","<<max_phi<<","<<max_psi<<endl;

    
    
}


int main (int argc, const char * argv[])
{
    if (argc < 3)
    {
        usage();
        return 0;
    }
    ofstream fout(argv[1]);
    fout<<"Subject,";
    fout <<"mean_RMSabs_Displacement"<<","<<"max_RMSabs_Displacement"<<",";
    fout <<"mean_RMSrel_Displacement"<<","<<"max_RMSrel_Displacement"<<",";
    fout <<"mean_tx"<<","<<"mean_ty"<<","<<"mean_tz"<<","<<"mean_theta"<<","<<"mean_phi"<<","<<"mean_psi"<<",";
    fout <<"max_tx"<<","<<"max_ty"<<","<<"max_tz"<<","<<"max_theta"<<","<<"max_phi"<<","<<"max_psi"<<endl;
    if (fout.is_open())
    {
        int index=2;
        while (index < argc)
        {
            cout<<"Reading "<<argv[index]<<"..."<<endl;
            string motion_pars_rel=string(argv[index]) + "/mc/prefiltered_func_data_mcf_rel.rms";
            string motion_pars_abs=string(argv[index]) + "/mc/prefiltered_func_data_mcf_abs.rms";
            string motion_pars=string(argv[index]) + "/mc/prefiltered_func_data_mcf.par.txt";
            calc_motion(argv[index],motion_pars,motion_pars_abs,motion_pars_rel,fout);
            
            ++index;
        }
        fout.close();
        
    }
    return 0;
}

