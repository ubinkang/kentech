%% 스크립트 시작
clc; clear; close all;

%% 1. 첫 번째 파일 불러오기 (OCV vs SOC 데이터)
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');
SOC_OCV = data1.meas.SOC;       % 첫 번째 파일의 SOC 데이터
OCV_data = data1.meas.Voltage;  % 첫 번째 파일의 OCV 데이터

%% 2. 두 번째 파일 불러오기 (V vs SOC 데이터)
data2 = load('03-21-17_00.29 25degC_UDDS_Pan18650PF_with_SOC.mat');
% 두 번째 파일의 측정 데이터 구조체를 그대로 가져옴
meas2 = data2.meas;  % 보통 SOC, Voltage, Current 등의 필드를 포함

%% 3. 중복 제거: 보간에 사용할 SOC_OCV와 OCV_data의 고유 샘플점 생성
[SOC_OCV_unique, uniqueIdx] = unique(SOC_OCV, 'stable');
OCV_unique = OCV_data(uniqueIdx);

%% 4. 첫 번째 파일의 OCV 데이터를 보간하여 두 번째 파일의 SOC에 맞추기
% 두 번째 파일의 SOC 값을 기준으로 첫 번째 파일의 OCV 값을 선형 보간('extrap' 옵션으로 외삽)
OCV_interp = interp1(SOC_OCV_unique, OCV_unique, meas2.SOC, 'linear', 'extrap');

%% 5. 두 번째 파일의 데이터를 그대로 두고, 새로운 OCV 데이터를 추가하여 새로운 구조체 생성
newData = meas2;      % 두 번째 파일의 모든 데이터를 그대로 복사
newData.OCV = OCV_interp;  % 보간된 OCV 데이터를 새로운 필드로 추가

%% 6. 새로운 데이터 구조체를 MAT 파일로 저장
save('MergedData.mat', 'newData');
fprintf('새로운 .mat 파일 "MergedData.mat"가 생성되었습니다.\n');
