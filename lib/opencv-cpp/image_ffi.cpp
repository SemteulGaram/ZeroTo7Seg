#include <iostream>
#include <vector>
#include <opencv2/opencv.hpp>

using namespace cv;

void image_ffi (uchar *buf, uint *size) {
    
    std::vector<uchar> vec(buf, buf + size[0]);
    Mat img1 = imdecode(Mat(vec), IMREAD_COLOR);

    // do resize image using cv2
    Mat img2;
    resize(img1, img2, Size(img1.cols*0.8, img1.rows*0.8));

    // binary image
    Mat img3;
    cvtColor(img2, img3, COLOR_BGR2GRAY);

    // do threshold image using cv2
    Mat img4;
    threshold(img3, img4, 127, 255, THRESH_BINARY);

    // do contour image using cv2
    std::vector<std::vector<Point>> contours;
    std::vector<Vec4i> hierarchy;
    findContours(img4, contours, hierarchy, RETR_TREE, CHAIN_APPROX_SIMPLE, Point(0, 0));
    
    for (int i = 0; i < contours.size(); i++) {
        Scalar color = Scalar(136, 51, 255);
        drawContours(img2, contours, i, color, 4, LINE_8, hierarchy, 0, Point());
    }

    std::vector <uchar> retv;
    cv::imencode(".jpg", img2, retv);
    memcpy(buf, retv.data(), retv.size());
    size[0] = retv.size();
}

/*
cv::Mat drawing = cv::Mat::zeros(img3.size(), CV_8UC3);
CV_LOAD_IMAGE_COLOR

{
    std::vector <uchar> v(buf, buf + size[0]);
    cv::Mat img = cv::imdecode(cv::Mat(v), cv::IMREAD_COLOR);


    cv::GaussianBlur(img, img, cv::Size(15, 15), 0, 0);
    cv::putText(img, "Hello World!", cv::Size(30, 30), 1, 1.5, 2, 2);


    std::vector <uchar> retv;
    cv::imencode(".jpg", img, retv);
    memcpy(buf, retv.data(), retv.size());
    size[0] = retv.size();
}
*/