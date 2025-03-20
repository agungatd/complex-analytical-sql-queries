WITH StationBase AS (
    -- Base CTE to standardize station data and filter active stations
    SELECT 
        s.station_id,
        s.station_name,
        s.latitude,
        s.longitude,
        s.elevation_meters,
        s.activation_date,
        ROW_NUMBER() OVER (PARTITION BY s.station_id ORDER BY s.last_updated DESC) as rn
    FROM environmental_stations s
    WHERE s.is_active = TRUE
    AND s.last_updated >= DATEADD(month, -12, GETDATE())
),

AirQualityMetrics AS (
    -- Aggregates air quality readings with quality flags
    SELECT 
        sb.station_id,
        DATE_TRUNC('day', aq.measurement_timestamp) as measurement_date,
        AVG(aq.pm25_concentration) as avg_pm25,
        AVG(aq.co2_ppm) as avg_co2,
        MAX(aq.temperature_celsius) as max_temp,
        COUNT(CASE WHEN aq.quality_flag = 'SUSPECT' THEN 1 END) as suspect_readings,
        COUNT(*) as total_readings
    FROM StationBase sb
    INNER JOIN air_quality_readings aq 
        ON sb.station_id = aq.station_id
        AND sb.rn = 1
    WHERE aq.measurement_timestamp >= DATEADD(day, -30, GETDATE())
    GROUP BY sb.station_id, DATE_TRUNC('day', aq.measurement_timestamp)
),

WeatherPatterns AS (
    -- Processes weather data with wind direction categorization
    SELECT 
        sb.station_id,
        w.observation_date,
        AVG(w.wind_speed_kmh) as avg_wind_speed,
        MAX(w.precipitation_mm) as total_precipitation,
        CASE 
            WHEN AVG(w.wind_direction_degrees) BETWEEN 0 AND 90 THEN 'NE'
            WHEN AVG(w.wind_direction_degrees) BETWEEN 91 AND 180 THEN 'SE'
            WHEN AVG(w.wind_direction_degrees) BETWEEN 181 AND 270 THEN 'SW'
            ELSE 'NW'
        END as wind_quadrant
    FROM StationBase sb
    LEFT JOIN weather_observations w 
        ON sb.station_id = w.station_id
        AND w.observation_date >= DATEADD(day, -30, GETDATE())
    GROUP BY sb.station_id, w.observation_date
),

TeamActivity AS (
    -- Calculates research team activity metrics
    SELECT 
        sb.station_id,
        DATE_TRUNC('week', ta.activity_timestamp) as activity_week,
        COUNT(DISTINCT ta.researcher_id) as unique_researchers,
        SUM(ta.hours_worked) as total_hours,
        COUNT(CASE WHEN ta.activity_type = 'CALIBRATION' THEN 1 END) as calibration_events
    FROM StationBase sb
    INNER JOIN team_activities ta 
        ON sb.station_id = ta.station_id
        AND ta.activity_timestamp >= DATEADD(month, -3, GETDATE())
    WHERE sb.rn = 1
    GROUP BY sb.station_id, DATE_TRUNC('week', ta.activity_timestamp)
),

CombinedMetrics AS (
    -- Combines all metrics with complex correlations
    SELECT 
        aqm.station_id,
        sb.station_name,
        sb.elevation_meters,
        aqm.measurement_date,
        aqm.avg_pm25,
        aqm.avg_co2,
        aqm.max_temp,
        aqm.suspect_readings * 100.0 / NULLIF(aqm.total_readings, 0) as suspect_percentage,
        wp.avg_wind_speed,
        wp.total_precipitation,
        wp.wind_quadrant,
        ta.unique_researchers,
        ta.total_hours,
        ta.calibration_events,
        RANK() OVER (
            PARTITION BY aqm.station_id 
            ORDER BY aqm.avg_pm25 DESC
        ) as pm25_rank
    FROM AirQualityMetrics aqm
    INNER JOIN StationBase sb 
        ON aqm.station_id = sb.station_id
        AND sb.rn = 1
    LEFT JOIN WeatherPatterns wp 
        ON aqm.station_id = wp.station_id
        AND aqm.measurement_date = wp.observation_date
    LEFT JOIN TeamActivity ta 
        ON aqm.station_id = ta.station_id
        AND DATE_TRUNC('week', aqm.measurement_date) = ta.activity_week
)

-- Final result set with additional filtering
SELECT 
    cm.*,
    CASE 
        WHEN cm.suspect_percentage > 10 
        AND cm.calibration_events < 1 
        THEN 'NEEDS_ATTENTION'
        ELSE 'NORMAL'
    END as station_status
FROM CombinedMetrics cm
WHERE cm.pm25_rank <= 3
OR cm.avg_co2 > 500
ORDER BY cm.station_id, cm.measurement_date DESC;