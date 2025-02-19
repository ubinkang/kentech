%% 1. MergedData.mat 파일 불러오기
load('MergedData.mat', 'newData');  % newData 안에 SOC, Voltage, Current, OCV, Time 등이 있다고 가정

% "Time" 필드가 있는지 확인하고, 없으면 인덱스를 시간으로 사용
if isfield(newData, 'Time')
    timeVec = newData.Time;
else
    timeVec = (1:length(newData.Voltage))';  % 인덱스를 시간으로 사용
    warning('Time 필드가 없습니다. 인덱스를 시간으로 사용합니다.');
end

%% 2. 필요한 데이터 추출
Voltage_data   = newData.Voltage;    % 전압 데이터
Current_data   = newData.Current;    % 전류 데이터
OCV_data       = newData.OCV;        % OCV 데이터(보간된 값)
SOC_data       = newData.SOC;        % SOC 데이터

%% 3. Trip 설정 조건
threshold = -4.79;  % 전류가 -4.79 A 미만인 지점
minInterval = 1200; % 1200초(= 20분) 이상 떨어진 경우만 유효한 트립으로 간주

% 전류가 threshold 미만이 되는 모든 인덱스 찾기
negIdx = find(Current_data < threshold);

%% 4. Trip을 저장할 구조체 생성
tripCount = 0;
trips = struct([]);

% negIdx에서 인접한 쌍 (i, i+1)을 순회하면서 처리
for i = 1 : (length(negIdx) - 1)
    startIdx = negIdx(i);
    endIdx   = negIdx(i + 1);
    
    % 두 시점 사이의 실제 시간 간격 계산
    timeDiff = timeVec(endIdx) - timeVec(startIdx);
    
    % 1200초 이상 차이가 나는 경우만 유효 트립으로 처리
    if timeDiff >= minInterval
        tripCount = tripCount + 1;
        
        % tripCount번째 트립에 해당하는 데이터 범위 저장
        trips(tripCount).time    = timeVec(startIdx : endIdx);
        trips(tripCount).current = Current_data(startIdx : endIdx);
        trips(tripCount).voltage = Voltage_data(startIdx : endIdx);
        trips(tripCount).OCV     = OCV_data(startIdx : endIdx);
        trips(tripCount).SOC     = SOC_data(startIdx : endIdx);  % SOC 데이터 추가
    end
end

%% 5. 결과 확인 (구조체 내용)
disp(trips);

% (선택) trips를 mat 파일로 저장하고 싶다면
save('Trips.mat', 'trips');
