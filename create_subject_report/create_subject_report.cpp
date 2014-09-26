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

//STRUCTURAL IMAGE
        fhtml<<"<p> <b> T1-weighted Structural Image</b> <br>"<<endl;
        fhtml<<"<a href=\""<<sub_dir+"/qc/structural_allaxial.png\" width=\"1000\""<<"\">"<<sub_dir+"/struct/orig "<<"</a>"<<endl;
        fhtml<<"<img src=\""<<sub_dir+"/qc/structural.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;
        
        fhtml<<"<p> <b> Mid Time Point Functional Image</b> <br>"<<endl;
        fhtml<<"<a href=\""<<sub_dir+"/qc/example_func_allaxial.png\" width=\"1000\""<<"\">"<<sub_dir+"/example_func "<<"</a>"<<endl;
        fhtml<<"<img src=\""<<sub_dir+"/qc/example_func.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;

        fhtml<<"<p> <b> Brain Extraction from Highres Structural</b> <br>"<<endl;
        fhtml<<"<a href=\""<<sub_dir+"/qc/brain_extraction_allaxial.png\" width=\"1000\""<<"\">"<<sub_dir+"/struct/brain_fnirt_mask "<<"</a>"<<endl;
        fhtml<<"<img src=\""<<sub_dir+"/qc/brain_extraction.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;
        
        
        fhtml<<"<p> <b> Registration of Functional Image to Structural </b> <br>"<<endl;
        fhtml<<"<a href=\""<<sub_dir+"/qc/example_func2highres_allaxial.png\" width=\"1000\""<<"\">"<<sub_dir+"/reg/example_func_2_highres "<<"</a>"<<endl;
        fhtml<<"<img src=\""<<sub_dir+"/qc/example_func2highres.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;

        fhtml<<"<p> <b> Registration of Structural Image to MNI152 </b> <br>"<<endl;
        fhtml<<"<a href=\""<<sub_dir+"/qc/highres2standard_allaxial.png\" width=\"1000\""<<"\">"<<sub_dir+"/reg/example_func_2_highres "<<"</a>"<<endl;
        fhtml<<"<img src=\""<<sub_dir+"/qc/highres2standard.png\""<<" width=\"1000\" "<<">"<<endl;
        fhtml<<"</p>"<<endl;

        
        
        
        
        fhtml<<"<p> <b> Motion Plots</b> <br>"<<endl;
        
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

