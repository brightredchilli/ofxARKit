
#pragma once

#include <stdio.h>
#include <ARKit/ARKit.h>
#include "ARUtils.h"
#include "ARShaders.h"
#include "ARDebugUtils.h"


namespace ARCore {

    typedef std::shared_ptr<class ARCameraView>ARCameraViewRef;
    
    // prepare for glm move with newer version of oF
    typedef ofVec2f vec2;

    class ARCameraView {

        //! Session object that's being used for ARKit
        ARSession * session;

        //! The current frame dimensions. This will change depending on 
        //! the settings implemented in your Session's initialization and 
        //! your device's capabilities. 
        vec2 mFrameDimensions;

        //! A flag to set for whether or not you want the view to return an FBO.  
        bool mUseFbo;
        
        // ============== PRIVATE FUNCTIONS ============ // 
        void buildFBO();
        public:
            ARCameraView(ARSession * session,bool mUseFbo=false);

    }
}