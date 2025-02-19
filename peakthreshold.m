function compute_R_peak_and_SOC_from_allTrips()
    clc; clear; close all;
    
    %% 1. Trips.mat 파일 불러오기
    load('Trips.mat', 'trips');  
    Ntrips = numel(trips);
    fprintf('총 %d개의 트립(충전/방전 이벤트)이 로드되었습니다.\n', Ntrips);
    
    %% 2. 모든 트립에 대해 positive current 조건을 만족하는 피크에서 R_peak와 해당 SOC 추출
    all_R_peak = [];
    all_SOC_peak = [];
    
    % ✅ Peak Threshold 설정 (유동적으로 변경 가능)
    peak_threshold = 5;  % 기본값 (사용자가 변경 가능)

    for i = 1:Ntrips
        % 각 트립 데이터 추출
        t = trips(i).time;       % 시간
        c = trips(i).current;    % 전류
        v = trips(i).voltage;    % 전압
        ocv = trips(i).OCV;      % OCV
        soc = trips(i).SOC;      % SOC
        
        % t가 duration 타입이면 초(sec)로 변환
        if isduration(t)
            t = seconds(t);
        end
        
        %% 3. findpeaks로 전압의 국소 최대 찾기
        [pksMaxAll, idxMaxAll] = findpeaks(v, 'MinPeakProminence', 0.02);
        
        %% 4. 전류 조건 필터링 (전류가 양수인 피크만 선택)
        condMax = (c(idxMaxAll) > 2.3);
        idxMax = idxMaxAll(condMax);
        pksMax = pksMaxAll(condMax);
        
        %% 5. 각 선택된 피크에서 R_peak와 해당 SOC 계산
        for j = 1:length(idxMax)
            idx_peak = idxMax(j);
            R_inst = abs((ocv(idx_peak) - v(idx_peak)) / abs(c(idx_peak)));
            R_val = 1000 * R_inst;  % mΩ 단위
            
            all_R_peak = [all_R_peak; R_val];
            all_SOC_peak = [all_SOC_peak; soc(idx_peak)];
        end
    end

    %% 6. `peak_threshold` 기반 이상치 제거 (Min/Max Threshold 대신 사용)
    if ~isempty(all_R_peak)
        % ✅ `peak_threshold` 값보다 높은 값만 유지
        valid_idx = (all_R_peak >= peak_threshold);

        filtered_R_peak = all_R_peak(valid_idx);
        filtered_SOC_peak = all_SOC_peak(valid_idx);
    else
        filtered_R_peak = all_R_peak;
        filtered_SOC_peak = all_SOC_peak;
    end
    
    %% 7. 결과 저장 (.mat 파일)
    R_peak_struct.R_peak = filtered_R_peak;
    R_peak_struct.SOC = filtered_SOC_peak;
    save('R_peak_and_SOC_threshold.mat', 'R_peak_struct');
    
    %% 8. 결과 출력 및 간단한 플로팅
    fprintf('총 %d개의 positive current peak 임피던스가 추출되었습니다. (peak_threshold 적용 후)\n', length(filtered_R_peak));
    
    figure;
    scatter(filtered_SOC_peak * 100, filtered_R_peak, 50, 'filled');
    xlabel('SOC [%]');
    ylabel('R_{peak} (mΩ)');
    title('Positive Current Peaks: R_{peak} vs SOC (peak_threshold 적용)');
    grid on;
end
