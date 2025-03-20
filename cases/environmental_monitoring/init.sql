-- Table for environmental stations
CREATE TABLE environmental_stations (
    station_id VARCHAR(10) PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    elevation_meters INT,
    activation_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP
);

-- Table for air quality readings
CREATE TABLE air_quality_readings (
    reading_id BIGINT PRIMARY KEY,
    station_id VARCHAR(10),
    measurement_timestamp TIMESTAMP,
    pm25_concentration DECIMAL(5,2),
    co2_ppm DECIMAL(6,1),
    temperature_celsius DECIMAL(4,1),
    quality_flag VARCHAR(20),
    FOREIGN KEY (station_id) REFERENCES environmental_stations(station_id)
);

-- Table for weather observations
CREATE TABLE weather_observations (
    observation_id BIGINT PRIMARY KEY,
    station_id VARCHAR(10),
    observation_date DATE,
    wind_speed_kmh DECIMAL(5,1),
    wind_direction_degrees INT,
    precipitation_mm DECIMAL(5,1),
    FOREIGN KEY (station_id) REFERENCES environmental_stations(station_id)
);

-- Table for team activities
CREATE TABLE team_activities (
    activity_id BIGINT PRIMARY KEY,
    station_id VARCHAR(10),
    researcher_id VARCHAR(10),
    activity_timestamp TIMESTAMP,
    activity_type VARCHAR(50),
    hours_worked DECIMAL(4,1),
    FOREIGN KEY (station_id) REFERENCES environmental_stations(station_id)
);

TRUNCATE TABLE environmental_stations;
TRUNCATE TABLE air_quality_readings;
TRUNCATE TABLE weather_observations;
TRUNCATE TABLE team_activities;

-- Insert data into environmental_stations
INSERT INTO environmental_stations (station_id, station_name, latitude, longitude, elevation_meters, activation_date, is_active, last_updated) VALUES
('ST001', 'Mountain Ridge', 39.7392, -104.9903, 1600, '2020-01-15', TRUE, '2025-03-15 10:00:00'),
('ST002', 'Valley Basin', 40.0150, -105.2705, 1500, '2021-06-01', TRUE, '2025-03-18 14:30:00'),
('ST003', 'Forest Edge', 39.5501, -105.7821, 1800, '2019-03-10', TRUE, '2025-03-19 09:15:00');

-- Insert data into air_quality_readings
INSERT INTO air_quality_readings (reading_id, station_id, measurement_timestamp, pm25_concentration, co2_ppm, temperature_celsius, quality_flag) VALUES
(1, 'ST001', '2025-03-01 08:00:00', 12.5, 410.5, 15.2, 'NORMAL'),
(2, 'ST001', '2025-03-01 12:00:00', 15.8, 420.0, 16.8, 'SUSPECT'),
(3, 'ST002', '2025-03-02 10:00:00', 8.9, 395.5, 14.5, 'NORMAL'),
(4, 'ST002', '2025-03-02 14:00:00', 10.2, 405.0, 15.9, 'NORMAL'),
(5, 'ST003', '2025-03-03 09:00:00', 20.1, 550.0, 13.8, 'SUSPECT'),
(6, 'ST003', '2025-03-03 15:00:00', 18.7, 530.5, 14.2, 'NORMAL');

-- Insert data into weather_observations
INSERT INTO weather_observations (observation_id, station_id, observation_date, wind_speed_kmh, wind_direction_degrees, precipitation_mm) VALUES
(1, 'ST001', '2025-03-01', 15.5, 45, 2.5),
(2, 'ST001', '2025-03-02', 10.2, 135, 0.0),
(3, 'ST002', '2025-03-02', 8.9, 225, 1.8),
(4, 'ST002', '2025-03-03', 12.4, 315, 0.5),
(5, 'ST003', '2025-03-03', 18.7, 90, 3.2),
(6, 'ST003', '2025-03-04', 14.3, 180, 0.0);

-- Insert data into team_activities
INSERT INTO team_activities (activity_id, station_id, researcher_id, activity_timestamp, activity_type, hours_worked) VALUES
(1, 'ST001', 'RES01', '2025-02-15 09:00:00', 'MAINTENANCE', 4.5),
(2, 'ST001', 'RES02', '2025-02-15 10:00:00', 'CALIBRATION', 2.0),
(3, 'ST002', 'RES03', '2025-03-01 13:00:00', 'DATA_COLLECTION', 3.5),
(4, 'ST002', 'RES01', '2025-03-01 14:00:00', 'MAINTENANCE', 2.5),
(5, 'ST003', 'RES02', '2025-03-02 08:00:00', 'CALIBRATION', 3.0),
(6, 'ST003', 'RES03', '2025-03-02 09:00:00', 'DATA_COLLECTION', 4.0);