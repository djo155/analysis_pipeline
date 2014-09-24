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
    cout<<"create_subject_report <output_file> <list of analysis directories> \n"<<endl;
    
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

int do_work( const string & htmlname , const string & sub_dir ){
    ofstream fhtml(htmlname.c_str());
    if (fhtml.is_open())
    {
        fhtml<<"<html>"<<endl;
        //set style
        fhtml<<"<style>"<<endl;
        fhtml<<"body { \n background-color: rgba(117,172,169,0.3); \n }"<<endl;
        fhtml<<"</style>"<<endl;


        fhtml<<"<body>"<<endl;
        fhtml<<"Analysis Report for <a href=\"file://"<<sub_dir<<"\"> "<<sub_dir<<"</a> <br>"<<endl;

        fhtml<<"<p> <b> Motion Plots</b> <br>"<<endl;
        
        fhtml<<" <table border=\"1\" style=\"width:20%\">"<<endl;
         fhtml<<"<tr>"<<endl;
         fhtml<<"<td>Mean RMS Displacment</td>"<<endl;
         fhtml<<"<td>0</td>"<<endl;
        fhtml<<"</tr>"<<endl;

        fhtml<<"<tr>"<<endl;
         fhtml<<"<td>Maximnum RMS displacement</td>"<<endl;
        fhtml<<"<td>0</td>"<<endl;

         fhtml<<"</tr>"<<endl;
        fhtml<<"</table>"<<endl;

        
        
        fhtml<<"<img src=\""<<sub_dir+"/mc/disp.png\""<<" alt=\"mean_disp\" width=\"747\" height=\"167\">"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<sub_dir+"/mc/trans.png\""<<" alt=\"mean_trans\" width=\"747\" height=\"167\">"<<endl;
        fhtml<<"<br>"<<endl;
        fhtml<<"<img src=\""<<sub_dir+"/mc/rot.png\""<<" alt=\"mean_rot\" width=\"747\" height=\"167\">"<<endl;

        fhtml<<"</p>"<<endl;
        fhtml<<"</body>"<<endl;
        fhtml<<"</html>"<<endl;

    }
    return 0;
}
int main (int argc, const char * argv[])
{
    if (argc < 2)
    {
        usage();
        return 0;
    }
    string outname = string(argv[1]) + ".html";
    string analysis_dir = argv[2];
    do_work(outname,analysis_dir);
    
    return 0;
}

