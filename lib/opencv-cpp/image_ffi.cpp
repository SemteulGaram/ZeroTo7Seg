#include <iostream>
#include <vector>
#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

/*
* 7segment의 모서리를 따고, 사각형으로 바인딩. 너무 작은/큰 사각형은 배제
* parameter : img = 이진화 전처리된 이미지
* return : 사각형
*/
vector<Rect> calculate_rectangle_from_contours(Mat img) {
	vector<vector<Point>> contours;
	findContours(img, contours, RETR_LIST, CHAIN_APPROX_NONE);

	vector<vector<Point>> contours_poly(contours.size());
	vector<Rect> boundRect(contours.size());
	for (int i = 0; i < contours.size(); i++) {
		approxPolyDP(Mat(contours[i]), contours_poly[i], 3, true);
		boundRect[i] = boundingRect(Mat(contours_poly[i]));
	}
	vector<Rect> result;
	for (Rect r : boundRect) {
		if (r.area() > 50 && r.area() < 20000) {
			result.push_back(r);
		}
	}


	contours.clear();
	contours_poly.clear();
	boundRect.clear();
	return result;
}

/*
* 겹치는 영역이 있는 사각형들을 하나로 합침
* return : 겹처진 사각형들을 가지는 vector
*/
vector<Rect> Union_Intersect_Rectangles(vector<Rect> rects) {
	int index1 = 0;
	while (index1 < rects.size()) {
		int index2 = 0;
		while (index2 < rects.size()) {
			if ((index1 != index2) && ((rects[index1] & rects[index2]).area() > 0)) {
				rects[index1] = rects[index1] | rects[index2];
				rects.erase(rects.begin() + index2);
				index1 = 0;
				index2 = 1;
			}
			else
				index2++;
		}
		index1++;
	}

	return rects;
}

/*
*사각형이 서로 근접해 있는 지 구한다.
* 각 사각형들의 최대,최소의 거리가 임계값 보다 낮으면 근접해 있다.
* threshold_value : 사각형들이 근접해 있는 지 정할 임계값.
* return : 두 사각형이 근접해 있는가?
*/
bool Is_near(Rect r1, Rect r2) {
	int threshold_value = 20;
	Rect r(r1.x, r1.y - threshold_value, r1.width, r1.height + threshold_value);
	return !(r & r2).empty();
}

/*
* 사각형 집합에서 7sgements를 구성하는 segment들 찾는다.
* 세로 segment 1개 = 0.2~0.45 종횡비
* 가로 + 세로 segments = 0.6~1.3 종횡비
* 세로 segment 2개(숫자 1) = 0.1~0.2 종횡비
* 위 종횡비를 갖는 사각형들이 서로 근접해 있으면 하나의 세그먼트로 인식
* 위 사각형들이 서로 범위 안에 있어도 서로의 넓이가 크게 차이나는 경우 세그먼트가 아님
*/
vector<Rect> Union_near_segments(vector<Rect> rects) {
	int index1 = 0;
	while (index1 < rects.size()) {
		int index2 = 0;
		while (index2 < rects.size()) {
			double r1_aspect_ratio = (double)rects[index1].width / rects[index1].height;
			double r2_aspect_ratio = (double)rects[index2].width / rects[index2].height;
			double r1_area = (double)(rects[index1].area());
			double r2_area = (double)(rects[index2].area());
			if ((index1 != index2)
				&& Is_near(rects[index1], rects[index2])
				) {
				if (((r1_aspect_ratio < 0.45 && r2_aspect_ratio < 0.45) || ((r1_aspect_ratio > 0.7 && r1_aspect_ratio < 1.5) && (r2_aspect_ratio > 0.7 && r2_aspect_ratio < 1.5)))
					&& (r1_area > r2_area * 0.7 && r1_area < r2_area * 1.3)) {
					rects[index1] = rects[index1] | rects[index2];
					rects.erase(rects.begin() + index2);
					index1 = 0;
					index2 = 1;
				}
				else if (((r2_aspect_ratio > 0.6 && r2_aspect_ratio < 1.5) && r1_aspect_ratio < 0.45)
					&& (r2_area * 0.1 < r1_area && r2_area * 1.1 > r1_area)) {
					rects[index1] = rects[index1] | rects[index2];
					rects.erase(rects.begin() + index2);
					index1 = 0;
					index2 = 1;
				}

				else
					index2++;
			}
			else
				index2++;
		}
		index1++;

	}

	return rects;
}

/*
* 7segment 비율이 아닌 사각형 삭제
* 7segment 숫자 1 = 0.1~0.3
* 그 이외의 숫자 = 0.3~0.7
* return : vector<Rect>
*/
vector<Rect> delete_not_segments(vector<Rect> rects) {
	int index = 0;
	while (index < rects.size()) {
		double aspect_ratio = (double(rects[index].width)) / rects[index].height;
		if (aspect_ratio > .1 && aspect_ratio < .8)
			index++;
		else
			rects.erase(rects.begin() + index);
	}

	return rects;
}

/*
* 세그먼트의 넓이의 평균을 구해 평균값보다 일정이상 낮은 세그먼트들 삭제
* 7segment 숫자 1의 경우 평균보다 많이 낮아지므로 평균 넓이에 임계값 곱함
* return : 7segments vector<Rect>
*/
vector<Rect> delete_small_segments(vector<Rect> segments) {

	int index = 0;
	double area_avg = 0.0;
	for (Rect r : segments)
		area_avg += r.area();
	area_avg = area_avg / segments.size();
	while (index < segments.size()) {
		double aspect_ratio = (double(segments[index].width)) / segments[index].height;
		if (aspect_ratio < 0.3 && (double)segments[index].area() > area_avg * 0.15)
			index++;
		else if (segments[index].area() > area_avg * 0.7)
			index++;
		else
			segments.erase(segments.begin() + index);
	}
	return segments;
}

/*
* 같은 줄에 위치하는 7segment들 합치기
*/
vector<Rect> merge_7segment_into_line(vector<Rect> segments) {
	int index1 = 0;
	while (index1 < segments.size()) {
		int index2 = 0;
		while (index2 < segments.size()) {
			int r1_min_y = segments[index1].y;
			int r1_height = segments[index1].height;
			int r1_max_y = r1_height + r1_min_y;
			int r1_min_x = segments[index1].x;
			int r1_max_x = segments[index1].width + r1_min_x;
			int r2_min_y = segments[index2].y;
			int r2_max_y = segments[index2].height + r2_min_y;
			int r2_min_x = segments[index2].x;
			int r2_max_x = segments[index2].width + r2_min_x;
			double r1_aspect_ratio = double(segments[index1].width) / segments[index1].height;
			if ((index1 != index2)
				&& (r1_min_y - 20 < r2_min_y && r2_min_y < r1_max_y + 20)
				&& (r1_min_y - 20 < r2_max_y && r2_max_y < r1_max_y + 20)
				&& ((r1_min_x > r2_max_x && r1_min_x - r1_height < r2_max_x)
					|| (r1_max_x < r2_min_x &&r1_max_x + r1_height > r2_min_x))
				&& (double(segments[index2].height) / segments[index1].height > 0.9)) {
				segments[index1] = segments[index1] | segments[index2];
				segments.erase(segments.begin() + index2);
				if (index1 > index2)
					index1--;
			}
			else
				index2++;
		}
		index1++;
	}
	return segments;
}

/*
* OCR로 인식할 혈압 7segment만 남기고 나머지 삭제
*/
vector<Rect> delete_useless_segments(vector<Rect> lines) {
	int index = 0;
	while(index < lines.size()) {
		double aspect_ratio = (double)lines[index].width / lines[index].height;
		if (aspect_ratio < .8 && aspect_ratio > 1.8)
			lines.erase(lines.begin() + index);
		else
			index++;
	}
	int index1 = lines.size() - 1;
	while (index1 > 0) {
		int index2 = 0;
		while (index2 < index1) {
			if (lines[index2].y > lines[index2 + 1].y) {
				Rect temp = lines[index2];
				lines[index2] = lines[index2 + 1];
				lines[index2 + 1] = temp;
			}
			index2++;
		}
		index1--;
	}
	if (lines.size() >= 3)
		lines.erase(lines.begin() + 2, lines.begin() + lines.size());

	return lines;
}

/*
* 이미지 전처리
* 1. 이미지를 회색조로 변경
* 2. 회색조 이미지에 블러를 적용하여 경계들을 모호하게 함.
* 3. 블러 처리된 이미지를 threshold를 이용하여 이진화.
* return : 이진화된 이미지
*/
Mat image_preprocess(Mat img, int threshold_value) {
	Mat temp;
	img.copyTo(temp);
	cvtColor(temp, temp, COLOR_BGR2GRAY);
	GaussianBlur(temp, temp, Size(5, 5), 0, 0);
	threshold(temp, temp, threshold_value, 255, THRESH_BINARY);
	return temp;
}

/*
* 이미지 전처리에 사용할 가장 적합한 threshold 값 선택
* 1번 threshold 값 : 연속적으로 일정한 7segments의 개수의 빈도값을 가지는 구간의 threshold 값 평균
* 2번 threshold 값: 가장 많은 7segment의 개수를 가지는 구간의 threshold값 평균
* return : 2개의 threshold 값이 들어있는 vector
*/

vector<int> find_best_threshold_img(Mat img) {
	int threshold_value = 32;
	vector<int> pre_value = { 0,0,0 };
	vector<vector<int>> threshold_results;

	while (threshold_value < 127) {
		Mat img2 = image_preprocess(img, threshold_value);
		vector<Rect> rects = delete_small_segments(
			delete_not_segments(
				Union_near_segments(
					Union_Intersect_Rectangles(
						calculate_rectangle_from_contours(img2)))));

		int count = rects.size();
		if (threshold_value == 32) {
			pre_value[0] = count;
			pre_value[1] = 1;
			pre_value[2] = 32;
		}
		else if (pre_value[0] == count) {
			pre_value[1] = pre_value[1] + 1;
			pre_value[2] = pre_value[2] + threshold_value;
		}
		else {
			if (pre_value[0] != 0)
				threshold_results.push_back(pre_value);
			pre_value[0] = count;
			pre_value[1] = 1;
			pre_value[2] = threshold_value;
		}
		threshold_value += 2;

		rects.clear();
		img2.release();
	}
	threshold_results.push_back(pre_value);
	vector<int> max_frequency = { 0,0,0 };

	vector<int> max_count = { 0,0,0 };
	for (vector<int> val : threshold_results) {
		if (val[1] > max_frequency[1])
			max_frequency = val;
		if (val[0] > max_count[0] && val[0] >= 2)
			max_count = val;
		val.clear();
	}
	int max_frequency_threshold = max_frequency[2] / max_frequency[1];
	int max_count_threshold = max_count[2] / max_count[1];

    pre_value.clear();
    threshold_results.clear();
	max_frequency.clear();
	max_count.clear();
	vector<int> vec = { max_frequency_threshold , max_count_threshold };
	return vec;
}

void Reverse(Mat img) {
	int w_count = 0;
	int b_count = 0;
	int count = 1;


	uchar* pointer_row = img.ptr<uchar>(7);
	for (int col = 0; col < img.cols; col++)
	{
		int b = (int) (pointer_row[col + 0]);
		if (b > 127)
			w_count++;
		else
			b_count++;

	}
	if(b_count > w_count)
		img = 255 - img;
}

void ffi_ocr_preprocess (uchar *buf, uint *size) {
    vector<uchar> vec(buf, buf + size[0]);
	Mat img = imdecode(Mat(vec), IMREAD_COLOR);
	double ratio = 500 / double(img.size().height);
	double width = img.size().width * (500 / double(img.size().height));
	resize(img, img, Size(int(img.size().width * (500 / double(img.size().height))), 500));
	vector<int> v = find_best_threshold_img(img);

	Mat img1 = image_preprocess(img,v[0]);
	vector<Rect> rects1 = delete_useless_segments(
		merge_7segment_into_line(
			delete_small_segments(
				delete_not_segments(
					Union_near_segments(
						Union_Intersect_Rectangles(
							calculate_rectangle_from_contours(img1)))))));




	if (rects1.size() == 2) {
		Mat img2 = img1(Range(rects1[0].y, rects1[0].height + rects1[0].y), Range(rects1[0].x, rects1[0].width + rects1[0].x));
		resize(img2, img2, Size(int(img2.size().width * (28 / double(img2.size().height))), 28));
		Mat img3 = img1(Range(rects1[1].y, rects1[1].height + rects1[1].y), Range(rects1[1].x, rects1[1].width + rects1[1].x));
		resize(img3, img3, Size(int(img3.size().width * (28 / double(img3.size().height))), 28));

		Reverse(img2);
		Reverse(img3);
		copyMakeBorder(img2, img2, 10, 10, 10, 50, BORDER_CONSTANT, Scalar(255, 255, 255));
		copyMakeBorder(img3, img3, 10, 10, 0, 10, BORDER_CONSTANT, Scalar(255, 255, 255));
		Mat result;
		hconcat(img2, img3, result);
		threshold(result, result, 127, 255, THRESH_BINARY);

        for (int i = 0; i < rects1.size(); i++) {
            Rect temp(int(rects1[i].x / ratio), int(rects1[i].y / ratio)
                , int(rects1[i].width / ratio), int(rects1[i].height / ratio));
            rects1[i] = temp;
        }

        vector <uchar> retv;
        imencode(".jpg", result, retv);
        memcpy(buf, retv.data(), retv.size());
        size[0] = retv.size();
        size[1] = rects1[0].x;
        size[2] = rects1[0].y;
        size[3] = rects1[0].width;
        size[4] = rects1[0].height;
        size[5] = rects1[1].x;
        size[6] = rects1[1].y;
        size[7] = rects1[1].width;
        size[8] = rects1[1].height;

        img2.release();
        img3.release();
        result.release();
        retv.clear();
	}
    else{
        for(int i = 0; i <= 8; i++)
            size[i] = 0;
    }
    v.clear();
    rects1.clear();
    img.release();
    img1.release();


}