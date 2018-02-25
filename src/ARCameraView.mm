

#include "ARCameraView.h"

namespace ARCore {

    ARCameraView::ARCameraView(ARSession * session, bool mUseFbo):
    mUseFbo(mUseFbo){
        this->session = session;    
        auto dimensions = session.currentFrame.camera.imageResolution;
        
        
        // set camera frame dimensions.
        viewDimensions.x = diemensions.width;
        viewDimensions.y = dimensions.height;


    }
}