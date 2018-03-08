#include "ofApp.h"

//CGColorSpaceRef _colorSpace = nil;
//
//
//void convertToARGB(ofImage &image){
//    unsigned char *data = image.getPixels().getData();
//    int size = image.getWidth() * image.getHeight() * 4;
//    for (int i = 0; i < size; i+=4) {
//        unsigned char r = data[i];
//        unsigned char g = data[i+1];
//        unsigned char b = data[i+2];
//        unsigned char a = data[i+3];
//        data[i] = a;
//        data[i+1] = r;
//        data[i+2] = g;
//        data[i+3] = b;
//    }
//}
//
//CIImage * filteredImageUsingEnhanceFilterOnImage(CIImage * image)
//{
//    return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, @"inputBrightness", [NSNumber numberWithFloat:0.0], @"inputContrast", [NSNumber numberWithFloat:1.14], @"inputSaturation", [NSNumber numberWithFloat:0.0], nil].outputImage;
//}
//
////-------------------------------------------------------------
//
//CIImage* CIImageFrom(const ofImage &img){
//    ofImage srcImage = img;
//    srcImage.setImageType(OF_IMAGE_COLOR_ALPHA);
//    convertToARGB(srcImage);
//    srcImage.mirror(true, false);
//    NSUInteger length = srcImage.getPixelsRef().size();
//    NSUInteger bbp = 4;
//    NSUInteger bpr = srcImage.getWidth() * 4;
//    CGSize size = CGSizeMake(srcImage.getWidth(), srcImage.getHeight());
//    NSData *bitmapData = [NSData dataWithBytes:srcImage.getPixels().getData() length:length];
//    CIImage *dst = [CIImage imageWithBitmapData:bitmapData bytesPerRow:bpr size:size format:kCIFormatARGB8 colorSpace:_colorSpace];
//    return dst;
//}



void logSIMD(const simd::float4x4 &matrix)
{
    std::stringstream output;
    int columnCount = sizeof(matrix.columns) / sizeof(matrix.columns[0]);
    for (int column = 0; column < columnCount; column++) {
        int rowCount = sizeof(matrix.columns[column]) / sizeof(matrix.columns[column][0]);
        for (int row = 0; row < rowCount; row++) {
            output << std::setfill(' ') << std::setw(9) << matrix.columns[column][row];
            output << ' ';
        }
        output << std::endl;
    }
    output << std::endl;
}

ofMatrix4x4 matFromSimd(const simd::float4x4 &matrix){
    ofMatrix4x4 mat;
    mat.set(matrix.columns[0].x,matrix.columns[0].y,matrix.columns[0].z,matrix.columns[0].w,
            matrix.columns[1].x,matrix.columns[1].y,matrix.columns[1].z,matrix.columns[1].w,
            matrix.columns[2].x,matrix.columns[2].y,matrix.columns[2].z,matrix.columns[2].w,
            matrix.columns[3].x,matrix.columns[3].y,matrix.columns[3].z,matrix.columns[3].w);
    return mat;
}

//--------------------------------------------------------------
ofApp :: ofApp (ARSession * session){
    this->session = session;
    cout << "creating ofApp" << endl;
}

ofApp::ofApp(){}

//--------------------------------------------------------------
ofApp :: ~ofApp () {
    cout << "destroying ofApp" << endl;
}

//--------------------------------------------------------------
void ofApp::setup() {
    
    //_colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    ofBackground(127);
    
    img.load("OpenFrameworks.png");
    
    int fontSize = 8;
    if (ofxiOSGetOFWindow()->isRetinaSupportedOnDevice())
        fontSize *= 2;
    
    font.load("fonts/mono0755.ttf", fontSize);
    
    
    
    processor = ARProcessor::create(session);
    
    processor->setup();
    
    
    
    //camera.allocate(ofGetWidth(), ofGetHeight());
    ///cameraSmall.allocate(ofGetWidth()/4, ofGetHeight()/4);
    //pix.allocate(ofGetWidth()/4, ofGetHeight()/4, OF_PIXELS_RGBA);
}


vector < matrix_float4x4 > mats;

//--------------------------------------------------------------
void ofApp::update(){
    
    processor->update();
    
    mats.clear();
    
    if (session.currentFrame){
        NSInteger anchorInstanceCount = session.currentFrame.anchors.count;
        
        for (NSInteger index = 0; index < anchorInstanceCount; index++) {
            ARAnchor *anchor = session.currentFrame.anchors[index];
            
            // Flip Z axis to convert geometry from right handed to left handed
            matrix_float4x4 coordinateSpaceTransform = matrix_identity_float4x4;
            coordinateSpaceTransform.columns[2].z = -1.0;
            
            matrix_float4x4 newMat = matrix_multiply(anchor.transform, coordinateSpaceTransform);
            mats.push_back(newMat);
            logSIMD(newMat);
            //anchorUniforms->modelMatrix = matrix_multiply(anchor.transform, coordinateSpaceTransform);
        }
    }
    
}


ofCamera camera;
//--------------------------------------------------------------
void ofApp::draw() {
    ofEnableAlphaBlending();
    
    ofDisableDepthTest();
    
    //camera.begin();
    processor->draw();
    //camera.end();
    
    
//    camera.draw(0,0);
//    cameraSmall.begin();
//    camera.draw(0,0, cameraSmall.getWidth(), cameraSmall.getHeight());
//    cameraSmall.end();

    //cameraSmall.draw(0,0);
    
    //cameraSmall.readToPixels(pix);
    //cameraImg.setFromPixels(pix);
    
    //cameraImg.draw(0,0);
    
    ofEnableDepthTest();
    
    
    if (session.currentFrame){
        if (session.currentFrame.camera){
           
            camera.begin();
            processor->setARCameraMatrices();
            
            ofDisableDepthTest();
            ARPointCloud * pointCloud = session.currentFrame.rawFeaturePoints;
            int pointCount = pointCloud.count;
            cout << pointCount << endl;
            
            ofSetColor(255);
            for (int i = 0; i < pointCount; i++){
                vector_float3 temp = pointCloud.points[i];
                ofPoint me = ofPoint(temp.x, temp.y, temp.z);
                cout << me << endl;
                
                ofPushMatrix();
                ofTranslate(me);
                ofNoFill();
                ofDrawRectangle(0,0,0.1, 0.1);

                //ofDrawSphere(me.x, me.y, me.z, 100 * 100 * sin(ofGetElapsedTimef()));
                ofPopMatrix();
            }
            
            ofEnableDepthTest();
            
            
            
            for (int i = 0; i < mats.size(); i++){
                ofPushMatrix();
                //mats[i].operator=(const simd_float4x4 &)
                ofMatrix4x4 mat;
                mat.set(mats[i].columns[0].x, mats[i].columns[0].y,mats[i].columns[0].z,mats[i].columns[0].w,
                        mats[i].columns[1].x, mats[i].columns[1].y,mats[i].columns[1].z,mats[i].columns[1].w,
                        mats[i].columns[2].x, mats[i].columns[2].y,mats[i].columns[2].z,mats[i].columns[2].w,
                        mats[i].columns[3].x, mats[i].columns[3].y,mats[i].columns[3].z,mats[i].columns[3].w);
                ofMultMatrix(mat);

                ofSetColor(255);
                ofRotate(90,0,0,1);
                
                //float aspect = ARCommon::getNativeAspectRatio();
                //img.draw(-aspect/8,-0.125,aspect/4,0.25);
                ofNoFill();
                ofDrawRectangle(0,0,0.1, 0.1);

                ofPopMatrix();
            }
            
            ofSetColor(255,0,0);
            for (int i = 0; i < pts.size(); i++){
                ofPushMatrix();
                ofTranslate(pts[i]);
                ofRect(0,0,0.05, 0.05);
                ofPopMatrix();
            }
            ofSetColor(255);
            
            camera.end();
        }
        
    }
    ofDisableDepthTest();
    // ========== DEBUG STUFF ============= //
    int w = MIN(ofGetWidth(), ofGetHeight()) * 0.6;
    int h = w;
    int x = (ofGetWidth() - w)  * 0.5;
    int y = (ofGetHeight() - h) * 0.5;
    int p = 0;
    
    x = ofGetWidth()  * 0.2;
    y = ofGetHeight() * 0.11;
    p = ofGetHeight() * 0.035;
    
    //ofSetColor(ofColor::black);
    font.drawString("frame num      = " + ofToString( ofGetFrameNum() ),    x, y+=p);
    font.drawString("frame rate     = " + ofToString( ofGetFrameRate() ),   x, y+=p);
    font.drawString("screen width   = " + ofToString( ofGetWidth() ),       x, y+=p);
    font.drawString("screen height  = " + ofToString( ofGetHeight() ),      x, y+=p);
    

//    ofRect(0,0,100,100);
//    
//    // detect rectangles
//    ofSetColor(0, 128, 255, 128);
//    
//    
//    
//    CIImage* frame = CIImageFrom(cameraImg);
//    frame = filteredImageUsingEnhanceFilterOnImage(frame);
//    //CIImage *frame = [CIImage imageWithCVPixelBuffer:session.currentFrame.capturedImage];
//    //        cout << "Frame: " << frame.debugDescription.cString << endl;
//    
//    //cout << frame.extent.size.width << " " << frame.extent.size.height << endl;
//    
//    float wScale = ofGetWidth()/(float)frame.extent.size.width;
//    float hScale = ofGetHeight()/(float)frame.extent.size.height;
//    
//    ofPushMatrix();
//    ofScale(wScale, hScale);
//    
//    if(frame != nil){
//        
//        //NSDictionary *options = @{CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: @(1.0)};
//        NSDictionary *options = @{CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorTracking: @true};
//        
//        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:options];
//        NSArray *features = [detector featuresInImage:frame];
//        for(CIRectangleFeature *feature in features){
//            //                cout << "(" << feature.topLeft.x << "," << feature.topLeft.y << ")" << "W:" << (feature.bottomRight.x-feature.topLeft.x) << "  H:" << (feature.bottomRight.y-feature.topLeft.y) << endl;
//            ofMesh m;
//            m.setMode(OF_PRIMITIVE_TRIANGLE_STRIP);
//            // looks like the x and the y are switched? what why?
//            //                m.addVertex(ofVec2f(feature.topLeft.x, feature.topLeft.y));
//            //                m.addVertex(ofVec2f(feature.topRight.x, feature.topRight.y));
//            //                m.addVertex(ofVec2f(feature.bottomLeft.x, feature.bottomLeft.y));
//            //                m.addVertex(ofVec2f(feature.bottomRight.x, feature.bottomRight.y));
//            m.addVertex(ofVec2f(feature.topLeft.x, feature.topLeft.y));
//            m.addVertex(ofVec2f(feature.topRight.x, feature.topRight.y));
//            m.addVertex(ofVec2f(feature.bottomLeft.x, feature.bottomLeft.y));
//            m.addVertex(ofVec2f(feature.bottomRight.x, feature.bottomRight.y));
//            m.draw();
//        }
//    }
//    ofPopMatrix();
//    ofSetColor(255);
    
}

//--------------------------------------------------------------
void ofApp::exit() {
    //
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs &touch){
    
    processor->anchorController->addAnchor();
    
    // get the mat that's added to add anchor
    // fuck with points
    
    float zZoom = -0.2;
    ARFrame * currentFrame = session.currentFrame;
    if (currentFrame) {
        // Create a transform with a translation of 0.2 meters in front of the camera
        matrix_float4x4 translation = matrix_identity_float4x4;
        translation.columns[3].z = zZoom;
        matrix_float4x4 transform = matrix_multiply(currentFrame.camera.transform, translation);
        matrix_float4x4 coordinateSpaceTransform = matrix_identity_float4x4;
        coordinateSpaceTransform.columns[2].z = -1.0;
        matrix_float4x4 newMat = matrix_multiply(transform, coordinateSpaceTransform);
        ofMatrix4x4 mat = ARCommon::toMat4(newMat);
        pts.push_back( ofPoint(0,0,0) * mat);
    }

    
    
    
    
    


    
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs &touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    processor->updateDeviceInterfaceOrientation();
    processor->deviceOrientationChanged();
    
}


//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs& args){
    
}


