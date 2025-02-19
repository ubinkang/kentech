function compute_R_peak_from_Trips()
    clc; clear; close all;
    
    %% 1. Trips.mat 파일 불러오기
    load('Trips.mat', 'trips');  % trips 구조체에는 time, current, voltage, OCV, SOC 등이 포함되어 있다고 가정
    Ntrips = numel(trips);
    fprintf('총 %d개의 트립(충전/방전 이벤트)이 로드되었습니다.\n', Ntrips);
    
    %% 2. 각 트립에서 R_peak 계산
    R_peak = zeros(Ntrips, 1);
    for i = 1:Ntrips
        % 각 트립 데이터 추출
        timeVec = trips(i).time;       % 시간 벡터
        curr    = trips(i).current;      % 전류 벡터
        volt    = trips(i).voltage;      % 측정 전압 벡터
        ocv     = trips(i).OCV;          % OCV 벡터
        
        % 전류가 0인 경우는 NaN으로 처리 (0으로 나누는 것을 방지)
        valid = abs(curr) > 0;
        R_inst = nan(size(curr));
        R_inst(valid) = (ocv(valid) - volt(valid)) ./ abs(curr(valid));
        
        % R_inst 중 NaN이 아닌 값들의 최대값을 R_peak로 계산
        if any(~isnan(R_inst))
            R_peak(i) = max(R_inst(~isnan(R_inst)));
        else
            R_peak(i) = NaN;
        end
    end
    
    %% 3. 계산 결과를 trips 구조체에 추가 및 저장
    for i = 1:Ntrips
        trips(i).R_peak = R_peak(i);
    end
    save('Trips_with_R_peak.mat', 'trips');
    
    %% 4. 결과 출력
    fprintf('각 트립별 R_peak (m\Omega):\n');
    disp(R_peak);
end
